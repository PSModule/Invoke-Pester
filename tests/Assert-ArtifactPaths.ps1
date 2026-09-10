[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $TestResultPath,

    [Parameter(Mandatory)]
    [string] $CodeCoveragePath,

    [string] $UnexpectedTestResultPath,

    [string] $UnexpectedCodeCoveragePath
)

function Resolve-ArtifactPath {
    <#
        .SYNOPSIS
        Resolves an artifact path against the GitHub workspace.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    $workspacePath = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $Path
    return [System.IO.Path]::GetFullPath($workspacePath)
}

function Get-ReportPath {
    <#
        .SYNOPSIS
        Gets the configured report path and its JSON companion path.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $reportPath = Resolve-ArtifactPath -Path $Path
    $reportPath
    [System.IO.Path]::ChangeExtension($reportPath, '.json')
}

$temporaryDirectory = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'Invoke-Pester'
$expectedPaths = @{
    'temporary configuration' = Join-Path -Path $temporaryDirectory -ChildPath 'Invoke-Pester.Configuration.ps1'
}

foreach ($path in (Get-ReportPath -Path $TestResultPath)) {
    $expectedPaths["test result report [$([System.IO.Path]::GetExtension($path))]"] = $path
}
foreach ($path in (Get-ReportPath -Path $CodeCoveragePath)) {
    $expectedPaths["code coverage report [$([System.IO.Path]::GetExtension($path))]"] = $path
}

foreach ($artifact in $expectedPaths.GetEnumerator()) {
    if (-not (Test-Path -Path $artifact.Value -PathType Leaf)) {
        throw "Expected $($artifact.Key) at [$($artifact.Value)]."
    }
}

$unexpectedPaths = @(
    $UnexpectedTestResultPath
    $UnexpectedCodeCoveragePath
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

foreach ($unexpectedPath in $unexpectedPaths) {
    foreach ($path in (Get-ReportPath -Path $unexpectedPath)) {
        if (Test-Path -Path $path) {
            throw "Did not expect a report at [$path]."
        }
    }
}
