#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Writes one row to a local SQLite event log: as a Claude Code hook target, or as a deliberate event from the agent.

.DESCRIPTION
    Two modes:

    Hook mode (no -Summary). Reads the hook JSON from stdin (hook_event_name, session_id, tool_name,
    tool_input, tool_response) and writes one row per tool call: source 'auto', level 'info',
    event_type empty. success is 0 for 'PostToolUseFailure', otherwise 1. The summary depends on the
    tool (Read/Edit/Write = file_path, Bash = command, Grep/Glob = pattern, Agent = description,
    WebFetch = url, anything else = compact JSON of tool_input); detail is the tool response, or the error field for a failed call when the platform sends one.
    Hook mode never blocks the agent: every error is caught, one line goes to stderr, and the script
    exits 1 (exit code 2 would block the tool call in Claude Code).

    Deliberate mode (-Summary given). Writes an event the agent chose to log (source 'agent').
    Errors are thrown so the caller sees them; on success one line "logged: <event_type> <id>" goes
    to stdout.

    Masking. Summary and detail pass through Protect-EventText BEFORE they are truncated and BEFORE
    the INSERT. It replaces: values of keys that look like token, apikey, api_key, api-key, password,
    passwd, pwd, secret, authorization or auth (key=value or key: value, case-insensitive); the value
    after 'Bearer' and 'Basic'; the password in user:password@ inside a URL; and long token-like
    strings (32 or more characters of [A-Za-z0-9_+=] with at least one letter and one digit; '/' and
    '-' are not part of the class, so paths and UUIDs stay readable); PEM private key blocks; and
    the value after 'password'/'passwd' or '--password' separated by a space. Known side effect:
    a 40-character git SHA is masked too.

    Known gaps. This is a safety net, NOT a perfect scanner. Not caught: -p<password> directly
    attached (mysql, sshpass), keys whose name is only 'key' or 'credential', short tokens under
    32 characters, and secrets in unusual shapes. Keep the rule "never put a secret in a command".
    Also: hook mode writes one stderr line and exits 1 on failure, which an async hook usually does
    not show anywhere.

    Truncation. Summary is cut at 200 characters, detail at 2000, with '...' appended when cut.

    Database. Path from the environment variable AGENT_EVENTS_DB, otherwise 'data/events.db'
    relative to the current directory (the folder is created when missing). On every call the
    statements of schema.sql (next to this script) are executed (CREATE ... IF NOT EXISTS and
    PRAGMA journal_mode=WAL), and busy_timeout is set to 5000 ms on the connection, so several
    sessions can write at the same time.

    Identity. agent_name = AGENT_NAME, otherwise the name of the current folder, otherwise 'agent'.
    topic = AGENT_TOPIC, otherwise 'unknown'. In deliberate mode session_id = -SessionId, otherwise
    AGENT_SESSION_ID, otherwise CLAUDE_SESSION_ID.

    Requires the PSSQLite module (Install-Module PSSQLite -Scope CurrentUser). No other modules.

.PARAMETER EventType
    Kind of deliberate event, for example decision, blocker, milestone. Default 'info'.

.PARAMETER Summary
    Short description of the event. Giving it switches the script to deliberate mode.

.PARAMETER Level
    verbose, progress, info, warning or error. Default 'info'.

.PARAMETER Category
    Free grouping, used for filtering and cleanup.

.PARAMETER IssueId
    Ticket or work item as text (for example CHG0012345).

.PARAMETER SessionId
    Session id for a deliberate event. Default: AGENT_SESSION_ID, then CLAUDE_SESSION_ID.

.EXAMPLE
    # Hook mode (called by Claude Code, JSON arrives on stdin):
    '{"hook_event_name":"PostToolUse","session_id":"abc","tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":"ok"}' | pwsh -NoProfile -File ./log-event.ps1

.EXAMPLE
    # Deliberate event from the agent:
    pwsh -NoProfile -File ./log-event.ps1 -EventType decision -Summary 'Chose option B' -IssueId CHG0012345 -Level warning
#>
[CmdletBinding()]
param(
    [string]$EventType = 'info',
    [string]$Summary,
    [ValidateSet('verbose', 'progress', 'info', 'warning', 'error')]
    [string]$Level = 'info',
    [string]$Category,
    [string]$IssueId,
    [string]$SessionId
)

$ErrorActionPreference = 'Stop'

$script:SummaryMax = 200
$script:DetailMax = 2000

function Protect-EventText {
    <#
    .SYNOPSIS
        Masks secret-looking values in a text. A safety net, not a perfect scanner.
    #>
    param([AllowNull()][string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return $Text }

    # 0. PEM private key blocks (multi-line), first so the key body is never seen piecemeal
    $Text = [regex]::Replace($Text, '(?s)-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----', '-----BEGIN PRIVATE KEY----- *** -----END PRIVATE KEY-----')

    # 1. URL with user:password@  ->  user:***@
    $Text = [regex]::Replace($Text, '(?i)(\b[a-z][a-z0-9+.\-]*://[^\s:/@]+:)[^\s@/]+(@)', '${1}***${2}')

    # 2. Bearer / Basic credentials
    $Text = [regex]::Replace($Text, '(?i)\b(Bearer|Basic)\s+[A-Za-z0-9_\-+/=.~]+', '${1} ***')

    # 3. key=value / key: value / "key":"value" for secret-looking keys.
    #    The value may start with "Bearer ***" or "Basic ***" from step 2; that is replaced as a whole.
    $keys = 'token|api[_-]?key|apikey|password|passwd|pwd|secret|authorization|auth'
    $kv = '(?i)(\b[\w\-]*(?:' + $keys + ')[\w\-]*["'']?\s*[=:]\s*)("[^"]*"|''[^'']*''|(?:(?:Bearer|Basic)\s+)?[^\s,;&"'']+)'
    $Text = [regex]::Replace($Text, $kv, {
            param($m)
            $value = $m.Groups[2].Value
            $quote = if ($value.Length -ge 2 -and ($value[0] -eq '"' -or $value[0] -eq "'")) { $value[0] } else { '' }
            $m.Groups[1].Value + $quote + '***' + $quote
        })

    # 3b. Space-separated passwords: 'password <value>', 'passwd <value>' (netrc), '--password <value>'
    $Text = [regex]::Replace($Text, '(?i)(?<!\w)((?:--)?(?:password|passwd))(\s+)(?!\*\*\*)[^\s,;&"'']+', '${1}${2}***')

    # 4. Long token-like strings: 32+ characters of [A-Za-z0-9_+=] with at least one letter and one digit.
    #    '/' and '-' are not part of the class, so paths and UUIDs stay readable.
    $Text = [regex]::Replace($Text, '(?=[A-Za-z0-9_+=]*[A-Za-z])(?=[A-Za-z0-9_+=]*[0-9])[A-Za-z0-9_+=]{32,}', '***')

    return $Text
}

function Limit-EventText {
    <#
    .SYNOPSIS
        Cuts a text to MaxLength characters and appends '...' when it was cut.
    #>
    param([AllowNull()][string]$Text, [int]$MaxLength)

    if ($null -eq $Text) { return $null }
    if ($Text.Length -gt $MaxLength) { return $Text.Substring(0, $MaxLength) + '...' }
    return $Text
}

function ConvertTo-EventText {
    <#
    .SYNOPSIS
        Turns a value (string, object, null) into text; objects become compact JSON.
    #>
    param($Value)

    if ($null -eq $Value) { return $null }
    if ($Value -is [string]) { return $Value }
    return ($Value | ConvertTo-Json -Compress -Depth 5)
}

function Get-AgentName {
    # AGENT_NAME, else the current folder name, else 'agent'.
    if ($env:AGENT_NAME) { return $env:AGENT_NAME }
    $leaf = Split-Path -Leaf (Get-Location).Path
    if ([string]::IsNullOrWhiteSpace($leaf)) { return 'agent' }
    return $leaf
}

function Get-HookSummary {
    # Per-tool summary text (not yet masked or truncated).
    param([string]$ToolName, $ToolInput)

    switch ($ToolName) {
        { $_ -in 'Read', 'Edit', 'Write' } { return ConvertTo-EventText $ToolInput.file_path }
        'Bash' { return ConvertTo-EventText $ToolInput.command }
        { $_ -in 'Grep', 'Glob' } { return ConvertTo-EventText $ToolInput.pattern }
        'Agent' { return ConvertTo-EventText $ToolInput.description }
        'WebFetch' { return ConvertTo-EventText $ToolInput.url }
        default { return ConvertTo-EventText $ToolInput }
    }
}

function Open-EventDatabase {
    # Opens the database, creates the folder and schema when needed, sets busy_timeout.
    $dbPath = if ($env:AGENT_EVENTS_DB) { $env:AGENT_EVENTS_DB } else { Join-Path (Get-Location).Path 'data/events.db' }
    $dbDir = Split-Path -Parent $dbPath
    if ($dbDir -and -not (Test-Path -LiteralPath $dbDir)) {
        $null = New-Item -ItemType Directory -Path $dbDir -Force
    }

    Import-Module PSSQLite
    $conn = New-SQLiteConnection -DataSource $dbPath
    try {
        Invoke-SqliteQuery -SQLiteConnection $conn -Query 'PRAGMA busy_timeout = 5000' | Out-Null

        $schemaPath = Join-Path $PSScriptRoot 'schema.sql'
        $schema = Get-Content -LiteralPath $schemaPath -Raw
        $schema = [regex]::Replace($schema, '--[^\r\n]*', '')   # drop comments
        foreach ($statement in ($schema -split ';')) {
            if ($statement.Trim()) {
                Invoke-SqliteQuery -SQLiteConnection $conn -Query $statement | Out-Null
            }
        }
    }
    catch {
        $conn.Dispose()
        throw
    }
    return $conn
}

function Add-EventRow {
    # Inserts one row (parameters only, no string concatenation) and returns its id.
    param($Connection, [hashtable]$Row)

    $query = @'
INSERT INTO events (timestamp, session_id, issue_id, tool_name, success, source, event_type, level, category, summary, detail, agent_name, topic)
VALUES (@timestamp, @session_id, @issue_id, @tool_name, @success, @source, @event_type, @level, @category, @summary, @detail, @agent_name, @topic)
'@
    $sqlParameters = @{}
    foreach ($name in $Row.Keys) {
        $sqlParameters[$name] = if ($null -eq $Row[$name]) { [DBNull]::Value } else { $Row[$name] }
    }
    Invoke-SqliteQuery -SQLiteConnection $Connection -Query $query -SqlParameters $sqlParameters | Out-Null
    return (Invoke-SqliteQuery -SQLiteConnection $Connection -Query 'SELECT last_insert_rowid() AS id').id
}

$deliberate = [bool]$Summary
$conn = $null
try {
    $topic = if ($env:AGENT_TOPIC) { $env:AGENT_TOPIC } else { 'unknown' }
    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'

    if ($deliberate) {
        $sessionValue = if ($SessionId) { $SessionId }
        elseif ($env:AGENT_SESSION_ID) { $env:AGENT_SESSION_ID }
        else { $env:CLAUDE_SESSION_ID }

        $row = @{
            timestamp  = $now
            session_id = $sessionValue
            issue_id   = $IssueId
            tool_name  = $null
            success    = 1
            source     = 'agent'
            event_type = $EventType
            level      = $Level
            category   = $Category
            summary    = Limit-EventText (Protect-EventText $Summary) $script:SummaryMax
            detail     = $null
            agent_name = Get-AgentName
            topic      = $topic
        }
        $conn = Open-EventDatabase
        $id = Add-EventRow -Connection $conn -Row $row
        Write-Output "logged: $EventType $id"
    }
    else {
        $inputJson = [Console]::In.ReadToEnd()
        if ([string]::IsNullOrWhiteSpace($inputJson)) { exit 0 }
        $data = $inputJson | ConvertFrom-Json

        $summaryText = Get-HookSummary -ToolName $data.tool_name -ToolInput $data.tool_input
        $detailText = ConvertTo-EventText $data.tool_response
        if ([string]::IsNullOrEmpty($detailText)) { $detailText = ConvertTo-EventText $data.error }

        $row = @{
            timestamp  = $now
            session_id = $data.session_id
            issue_id   = $null
            tool_name  = $data.tool_name
            success    = if ($data.hook_event_name -eq 'PostToolUseFailure') { 0 } else { 1 }
            source     = 'auto'
            event_type = $null
            level      = 'info'
            category   = $null
            summary    = Limit-EventText (Protect-EventText $summaryText) $script:SummaryMax
            detail     = Limit-EventText (Protect-EventText $detailText) $script:DetailMax
            agent_name = Get-AgentName
            topic      = $topic
        }
        $conn = Open-EventDatabase
        $null = Add-EventRow -Connection $conn -Row $row
    }
}
catch {
    if ($deliberate) { throw }
    # Hook mode must never block the agent: one line on stderr, exit 1 (exit 2 would block).
    [Console]::Error.WriteLine("log-event: $($_.Exception.Message -replace '\s+', ' ')")
    exit 1
}
finally {
    if ($conn) { $conn.Dispose() }
}
