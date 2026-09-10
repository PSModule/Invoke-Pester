[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Default', 'PSModule')]
    [string] $Layout,

    [Parameter(Mandatory)]
    [string] $TestResultOutputPath,

    [Parameter(Mandatory)]
    [string] $CodeCoverageOutputPath
)

$outputDirectory = switch ($Layout) {
    'Default' {
        Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'tests/2-Standard'
    }
    'PSModule' {
        Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath '.PSModule'
    }
}

$expectedPaths = @{
    '.temp configuration' = Join-Path -Path $outputDirectory -ChildPath '.temp/Invoke-Pester.Configuration.ps1'
    'code coverage report' = Join-Path -Path $outputDirectory -ChildPath 'CodeCoverage/Standard-CodeCoverage-Report.xml'
    'code coverage JSON report' = Join-Path -Path $outputDirectory -ChildPath 'CodeCoverage/Standard-CodeCoverage-Report.json'
    'test result report' = Join-Path -Path $outputDirectory -ChildPath 'TestResult/Standard-TestResult-Report.xml'
    'test result JSON report' = Join-Path -Path $outputDirectory -ChildPath 'TestResult/Standard-TestResult-Report.json'
}

$expectedTestResultOutputPath = Join-Path -Path $outputDirectory -ChildPath 'TestResult'
$expectedCodeCoverageOutputPath = Join-Path -Path $outputDirectory -ChildPath 'CodeCoverage'

if ($TestResultOutputPath -ne $expectedTestResultOutputPath) {
    throw "Expected TestResultOutputPath [$expectedTestResultOutputPath], but received [$TestResultOutputPath]."
}

if ($CodeCoverageOutputPath -ne $expectedCodeCoverageOutputPath) {
    throw "Expected CodeCoverageOutputPath [$expectedCodeCoverageOutputPath], but received [$CodeCoverageOutputPath]."
}

foreach ($artifact in $expectedPaths.GetEnumerator()) {
    if (-not (Test-Path -Path $artifact.Value -PathType Leaf)) {
        throw "Expected $($artifact.Key) at [$($artifact.Value)]."
    }
}
