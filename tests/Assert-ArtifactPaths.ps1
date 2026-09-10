[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $TestResultPath,

    [Parameter(Mandatory)]
    [string] $CodeCoveragePath,

    [Parameter(Mandatory)]
    [string] $TempPath,

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

$tempRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'Invoke-Pester'
$resolvedTempRoot = [System.IO.Path]::GetFullPath($tempRoot).TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar
$resolvedTempPath = [System.IO.Path]::GetFullPath($TempPath)
if (-not $resolvedTempPath.StartsWith($resolvedTempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Expected invocation temporary path beneath [$resolvedTempRoot], but found [$resolvedTempPath]."
}

$expectedPaths = @{
    'temporary configuration' = Join-Path -Path $resolvedTempPath -ChildPath 'Invoke-Pester.Configuration.ps1'
}

$testResultPaths = @(Get-ReportPath -Path $TestResultPath)
$codeCoveragePaths = @(Get-ReportPath -Path $CodeCoveragePath)

foreach ($path in $testResultPaths) {
    $expectedPaths["test result report [$([System.IO.Path]::GetExtension($path))]"] = $path
}
foreach ($path in $codeCoveragePaths) {
    $expectedPaths["code coverage report [$([System.IO.Path]::GetExtension($path))]"] = $path
}

foreach ($artifact in $expectedPaths.GetEnumerator()) {
    if (-not (Test-Path -Path $artifact.Value -PathType Leaf)) {
        throw "Expected $($artifact.Key) at [$($artifact.Value)]."
    }
}

foreach ($xmlReportPath in @($testResultPaths[0], $codeCoveragePaths[0])) {
    try {
        $null = [xml](Get-Content -Path $xmlReportPath -Raw)
    } catch {
        throw "Expected an XML report at [$xmlReportPath], but it did not contain valid XML."
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
