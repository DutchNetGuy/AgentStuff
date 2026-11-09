#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build index/catalog.json and index/catalog.md from packages/*/manifest.json.
.DESCRIPTION
    Exits 1 with a clear message (package and field) when a manifest is invalid,
    and writes nothing in that case. The output is byte-identical to build_index.py.
.PARAMETER RepoRoot
    Repository root. Default: the folder above scripts/.
.EXAMPLE
    pwsh scripts/Build-Index.ps1
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ValidTypes = @('skill', 'agent', 'addition', 'tool')
# Required fields from docs/package-format.md; dotted names are nested.
$RequiredStrings = @(
    'name', 'type', 'version', 'summary', 'problem',
    'install.source', 'install.target',
    'docs.readme', 'docs.readme_nl', 'docs.flow',
    'origin.author', 'origin.generalised_from', 'origin.first_published'
)
$RequiredLists = @('triggers', 'compatible_with')

function Read-Manifest {
    <#
    .SYNOPSIS  Reads every packages/*/manifest.json.
    .PARAMETER Root  Repository root.
    .OUTPUTS   [pscustomobject] @{ Manifests; Errors }
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Root)

    $manifests = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $files = Get-ChildItem -Path (Join-Path $Root 'packages') -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'manifest.json' } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
    foreach ($file in $files) {
        $folder = Split-Path -Leaf (Split-Path -Parent $file)
        try {
            $data = Get-Content -LiteralPath $file -Raw -Encoding utf8 |
                ConvertFrom-Json -AsHashtable -ErrorAction Stop
        } catch {
            $errors.Add("package '$folder': manifest.json cannot be read: $($_.Exception.Message)")
            continue
        }
        if ($data -isnot [System.Collections.IDictionary]) {
            $errors.Add("package '$folder': manifest.json must contain a JSON object")
            continue
        }
        $manifests.Add([pscustomobject]@{ Folder = $folder; Data = $data })
    }
    return [pscustomobject]@{ Manifests = $manifests.ToArray(); Errors = $errors.ToArray() }
}

function Get-FieldValue {
    <#
    .SYNOPSIS  Returns a (possibly nested) field value, or $null when absent.
    .PARAMETER Data   Manifest hashtable.
    .PARAMETER Dotted Field name, e.g. install.source.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Data,
        [Parameter(Mandatory)] [string]$Dotted
    )
    $value = $Data
    foreach ($part in $Dotted.Split('.')) {
        if ($value -isnot [System.Collections.IDictionary] -or -not $value.Contains($part)) { return $null }
        $value = $value[$part]
    }
    # -NoEnumerate keeps a one-element list a list (the A5 unwrap pitfall).
    Write-Output -NoEnumerate $value
}

function Test-Manifest {
    <#
    .SYNOPSIS  Returns the validation errors of one manifest (empty array = valid).
    .PARAMETER Root      Repository root.
    .PARAMETER Manifest  Object with Folder and Data.
    .OUTPUTS   [string[]]
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Root,
        [Parameter(Mandatory)] $Manifest
    )
    $folder = $Manifest.Folder
    $data = $Manifest.Data
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($field in $RequiredStrings) {
        $value = Get-FieldValue -Data $data -Dotted $field
        if ($null -eq $value -or ([string]$value).Trim() -eq '') {
            $errors.Add("package '$folder': required field '$field' is missing or empty")
        }
    }
    foreach ($field in $RequiredLists) {
        if ((Get-FieldValue -Data $data -Dotted $field) -isnot [System.Collections.IList]) {
            $errors.Add("package '$folder': required field '$field' is missing or not a list")
        }
    }
    if ($data['type'] -isnot [string] -or $data['type'] -cnotin $ValidTypes) {
        $errors.Add("package '$folder': field 'type' must be one of $($ValidTypes -join ', ')")
    }
    if ($data['name'] -cne $folder) {
        $errors.Add("package '$folder': field 'name' must equal the folder name")
    }
    $source = Get-FieldValue -Data $data -Dotted 'install.source'
    if ($source -is [string] -and $source.Trim() -ne '' -and
        -not (Test-Path -LiteralPath (Join-Path (Join-Path (Join-Path $Root 'packages') $folder) $source) -PathType Container)) {
        $errors.Add("package '$folder': field 'install.source' points to a folder that does not exist: $source")
    }
    return $errors.ToArray()   # callers wrap the call in @() to get an array back
}

function Test-AllManifest {
    <#
    .SYNOPSIS  Validates all manifests and returns every error found.
    .OUTPUTS   [string[]]
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Root,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Manifests
    )
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($manifest in $Manifests) {
        $errors.AddRange([string[]]@(Test-Manifest -Root $Root -Manifest $manifest))
    }
    return $errors.ToArray()   # callers wrap the call in @() to get an array back
}

function Build-Catalog {
    <#
    .SYNOPSIS  Turns manifests into catalog entries, sorted by name (ordinal).
    .OUTPUTS   [pscustomobject[]] with name, type, version, summary, problem, triggers, path
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Manifests)

    $entries = @(foreach ($m in $Manifests) {
        [pscustomobject]@{
            name     = [string]$m.Data['name']
            type     = [string]$m.Data['type']
            version  = [string]$m.Data['version']
            summary  = [string]$m.Data['summary']
            problem  = [string]$m.Data['problem']
            triggers = [string[]]@($m.Data['triggers'])
            path     = "packages/$($m.Data['name'])/"
        }
    })
    $names = [string[]]@($entries | ForEach-Object { $_.name })
    [System.Array]::Sort($names, $entries, [System.StringComparer]::Ordinal)
    return ,@($entries)
}

function ConvertTo-JsonString {
    <#
    .SYNOPSIS  Quotes a string the way Python json.dumps(ensure_ascii=False) does.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('"')
    foreach ($ch in $Text.ToCharArray()) {
        switch ($ch) {
            '"'     { [void]$sb.Append('\"') }
            '\'     { [void]$sb.Append('\\') }
            "`n"    { [void]$sb.Append('\n') }
            "`r"    { [void]$sb.Append('\r') }
            "`t"    { [void]$sb.Append('\t') }
            "`b"    { [void]$sb.Append('\b') }
            "`f"    { [void]$sb.Append('\f') }
            default {
                if ([int][char]$ch -lt 32) { [void]$sb.Append(('\u{0:x4}' -f [int][char]$ch)) }
                else { [void]$sb.Append($ch) }
            }
        }
    }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function Get-CatalogJson {
    <#
    .SYNOPSIS  Returns the catalog as JSON text: 2-space indent, trailing newline.
    .DESCRIPTION
        Serialised by hand (not ConvertTo-Json) so the text equals Python's
        json.dumps(obj, indent=2, ensure_ascii=False).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Entries,
        [Parameter(Mandatory)] [string]$Generated
    )
    $q = { param($s) ConvertTo-JsonString -Text $s }
    $blocks = foreach ($e in $Entries) {
        if ($e.triggers.Count -eq 0) { $triggers = '[]' }
        else {
            $items = ($e.triggers | ForEach-Object { '        ' + (& $q $_) }) -join ",`n"
            $triggers = "[`n$items`n      ]"
        }
        @(
            '    {'
            '      "name": ' + (& $q $e.name) + ','
            '      "type": ' + (& $q $e.type) + ','
            '      "version": ' + (& $q $e.version) + ','
            '      "summary": ' + (& $q $e.summary) + ','
            '      "problem": ' + (& $q $e.problem) + ','
            '      "triggers": ' + $triggers + ','
            '      "path": ' + (& $q $e.path)
            '    }'
        ) -join "`n"
    }
    $packages = if (@($blocks).Count -eq 0) { '[]' } else { "[`n" + (@($blocks) -join ",`n") + "`n  ]" }
    return "{`n  `"generated`": " + (& $q $Generated) + ",`n  `"packages`": $packages`n}`n"
}

function Get-TableCell {
    <#
    .SYNOPSIS  Escapes a value for use inside a Markdown table cell.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)
    return $Text.Replace('|', '\|')
}

function Get-CatalogMarkdown {
    <#
    .SYNOPSIS  Returns the catalog as a Markdown table for people.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Entries,
        [Parameter(Mandatory)] [string]$Generated
    )
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Catalog')
    $lines.Add('')
    $lines.Add("Generated $Generated from the package manifests. Do not edit by hand; change a manifest and run ``scripts/build_index.py`` or ``scripts/Build-Index.ps1``.")
    $lines.Add('')
    $lines.Add('| Package | Type | Version | Problem it solves | Triggers |')
    $lines.Add('|---|---|---|---|---|')
    foreach ($e in $Entries) {
        $lines.Add("| [$(Get-TableCell $e.name)](../packages/$($e.name)/README.md) | $(Get-TableCell $e.type) | $(Get-TableCell $e.version) | $(Get-TableCell $e.problem) | $(Get-TableCell ($e.triggers -join ', ')) |")
    }
    return ($lines -join "`n") + "`n"
}

function Write-IndexFile {
    <#
    .SYNOPSIS  Writes index/catalog.json and index/catalog.md (utf8 without BOM, LF).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Root,
        [Parameter(Mandatory)] [string]$JsonText,
        [Parameter(Mandatory)] [string]$MarkdownText
    )
    $indexDir = Join-Path $Root 'index'
    New-Item -ItemType Directory -Path $indexDir -Force | Out-Null
    $utf8 = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText((Join-Path $indexDir 'catalog.json'), $JsonText, $utf8)
    [System.IO.File]::WriteAllText((Join-Path $indexDir 'catalog.md'), $MarkdownText, $utf8)
}

function Invoke-BuildIndex {
    <#
    .SYNOPSIS  Recipe: read manifests, validate, build catalog, write json, write markdown.
    .OUTPUTS   [int] exit code
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Root)

    $Root = (Resolve-Path -LiteralPath $Root).Path
    $read = Read-Manifest -Root $Root
    $errors = @($read.Errors) + @(Test-AllManifest -Root $Root -Manifests $read.Manifests)
    if ($errors.Count -gt 0) {
        [Console]::Error.WriteLine('Index not built, nothing written:')
        foreach ($e in $errors) { [Console]::Error.WriteLine("  - $e") }
        return 1
    }
    $generated = Get-Date -Format 'yyyy-MM-dd'
    $entries = Build-Catalog -Manifests $read.Manifests
    Write-IndexFile -Root $Root `
        -JsonText (Get-CatalogJson -Entries $entries -Generated $generated) `
        -MarkdownText (Get-CatalogMarkdown -Entries $entries -Generated $generated)
    Write-Host "Wrote index/catalog.json and index/catalog.md ($($entries.Count) package(s))."
    return 0
}

exit (Invoke-BuildIndex -Root $RepoRoot)
