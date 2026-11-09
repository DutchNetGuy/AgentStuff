#requires -Version 7.0
<#
.SYNOPSIS
    Publishes content as a self-contained HTML page and adds it to the cockpit manifest.
.DESCRIPTION
    Writes <SiteRoot>/<slug>.html from page-template.html and upserts an entry in
    <SiteRoot>/artifacts.json (newest first). Both files are written atomically, so the
    shell never reads a half-written file. Prints one line: the file path, or the URL when
    -BaseUrl is given. Exits 0 on success, 1 on any error.
.PARAMETER Title
    Page title (browser tab, heading, navigation list).
.PARAMETER BodyHtml
    The page content as an HTML fragment. Not sanitised: only pass content you wrote.
.PARAMETER BodyFile
    Path to a file holding the HTML fragment. Use instead of -BodyHtml for long content.
.PARAMETER Name
    Slug for the file name. Default: derived from the title.
.PARAMETER SiteRoot
    Folder with index.html and artifacts.json. Default: ../site relative to this script.
.PARAMETER BaseUrl
    URL under which SiteRoot is served. Empty (default): print the file path instead.
.EXAMPLE
    ./New-Artifact.ps1 -Title 'Disk report' -BodyHtml '<p>Host <span class="id">web01</span> is at 91%.</p>'
#>
[CmdletBinding(DefaultParameterSetName = 'Html')]
param(
    [Parameter(Mandatory)] [string]$Title,
    [Parameter(Mandatory, ParameterSetName = 'Html')] [string]$BodyHtml,
    [Parameter(Mandatory, ParameterSetName = 'File')] [string]$BodyFile,
    [string]$Name,
    [string]$SiteRoot = (Join-Path $PSScriptRoot '../site'),
    [string]$BaseUrl = ''
)

function ConvertTo-ArtifactSlug {
    <#
    .SYNOPSIS  Turns free text into a safe file-name stem.
    .OUTPUTS   [string] lowercase, only [a-z0-9-]; empty when nothing usable remains
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Text)

    $slug = $Text.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    return $slug.Trim('-')
}

function Build-ArtifactHtml {
    <#
    .SYNOPSIS  Fills page-template.html with title, date and body.
    .OUTPUTS   [string] the complete HTML page
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string]$BodyHtml,
        [Parameter(Mandatory)] [string]$Generated
    )

    $templatePath = Join-Path $PSScriptRoot 'page-template.html'
    $template = Get-Content -LiteralPath $templatePath -Raw
    $safeTitle = [System.Net.WebUtility]::HtmlEncode($Title)
    # Body goes in last so placeholders inside the body are never expanded.
    return $template.Replace('{{TITLE}}', $safeTitle).Replace('{{DATE}}', $Generated.Replace('T', ' ').Substring(0, 16)).Replace('{{BODY}}', $BodyHtml)
}

function Write-FileAtomic {
    <#
    .SYNOPSIS  Writes text to a temp file in the same folder, then renames it over the target.
    .OUTPUTS   [string] full path of the target
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Content
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    $temp = "$full.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [System.IO.File]::WriteAllText($temp, $Content, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $temp -Destination $full -Force
    }
    finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
    }
    return $full
}

function Update-ArtifactManifest {
    <#
    .SYNOPSIS  Upserts one entry in <SiteRoot>/artifacts.json, newest first, atomically.
    .DESCRIPTION
        An entry with the same slug is replaced. A manifest that exists but is not a JSON
        array raises an error instead of being overwritten.
    .OUTPUTS   [string] full path of the manifest
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$SiteRoot,
        [Parameter(Mandatory)] [string]$Slug,
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string]$Generated
    )

    $manifestPath = Join-Path $SiteRoot 'artifacts.json'
    $existing = @()
    if (Test-Path -LiteralPath $manifestPath) {
        $raw = Get-Content -LiteralPath $manifestPath -Raw
        if ($raw.Trim()) {
            $parsed = $raw | ConvertFrom-Json -NoEnumerate
            if ($parsed -isnot [System.Array]) { throw "artifacts.json is not a JSON array: $manifestPath" }
            $existing = @($parsed)
        }
    }
    $kept = @($existing | Where-Object { $_.slug -ne $Slug } | ForEach-Object {
            # ConvertFrom-Json turns ISO strings into DateTime; write them back as the same ISO form.
            if ($_.generated -is [datetime]) { $_.generated = $_.generated.ToString('yyyy-MM-ddTHH:mm:ss') }
            $_
        })
    $entry = [pscustomobject]@{ slug = $Slug; title = $Title; file = "$Slug.html"; generated = $Generated }
    $entries = @($entry) + $kept
    $json = $entries | ConvertTo-Json -Depth 4 -AsArray
    return Write-FileAtomic -Path $manifestPath -Content ($json + "`n")
}

function New-Artifact {
    <#
    .SYNOPSIS  Recipe: slug -> HTML -> write page -> update manifest -> report location.
    .OUTPUTS   [pscustomobject] @{ Location; Path; Slug }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string]$BodyHtml,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string]$SiteRoot,
        [string]$BaseUrl = ''
    )

    $slug = ConvertTo-ArtifactSlug -Text $Name
    if (-not $slug) { throw "Cannot derive a slug from '$Name'. Pass -Name with letters or digits." }
    if (-not (Test-Path -LiteralPath $SiteRoot)) { New-Item -ItemType Directory -Path $SiteRoot -Force | Out-Null }

    $generated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
    $html = Build-ArtifactHtml -Title $Title -BodyHtml $BodyHtml -Generated $generated
    $path = Write-FileAtomic -Path (Join-Path $SiteRoot "$slug.html") -Content $html
    $null = Update-ArtifactManifest -SiteRoot $SiteRoot -Slug $slug -Title $Title -Generated $generated
    $location = if ($BaseUrl) { "$($BaseUrl.TrimEnd('/'))/$slug.html" } else { $path }

    return [pscustomobject]@{ Location = $location; Path = $path; Slug = $slug }
}

# --- entrypoint ---
if ($MyInvocation.InvocationName -ne '.') {
    try {
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            if (-not (Test-Path -LiteralPath $BodyFile)) { throw "Body file not found: $BodyFile" }
            $BodyHtml = Get-Content -LiteralPath $BodyFile -Raw
        }
        if (-not $Name) { $Name = $Title }
        $result = New-Artifact -Title $Title -BodyHtml $BodyHtml -Name $Name -SiteRoot $SiteRoot -BaseUrl $BaseUrl
        Write-Output $result.Location
        exit 0
    }
    catch {
        [Console]::Error.WriteLine("New-Artifact failed: $($_.Exception.Message)")
        exit 1
    }
}
