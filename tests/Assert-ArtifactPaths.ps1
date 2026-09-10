[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Default', 'PSModule')]
    [string] $Layout
)

$outputDirectory = switch ($Layout) {
    'Default' {
        Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'tests/2-Standard'
    }
    'PSModule' {
        Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath '.PSModule'
    }
}

$temporaryDirectory = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'tests/2-Standard'

$expectedPaths = @{
    '.temp configuration'       = Join-Path -Path $temporaryDirectory -ChildPath '.temp/Invoke-Pester.Configuration.ps1'
    'code coverage report'      = Join-Path -Path $outputDirectory -ChildPath 'CodeCoverage/Standard-CodeCoverage-Report.xml'
    'code coverage JSON report' = Join-Path -Path $outputDirectory -ChildPath 'CodeCoverage/Standard-CodeCoverage-Report.json'
    'test result report'        = Join-Path -Path $outputDirectory -ChildPath 'TestResult/Standard-TestResult-Report.xml'
    'test result JSON report'   = Join-Path -Path $outputDirectory -ChildPath 'TestResult/Standard-TestResult-Report.json'
}

foreach ($artifact in $expectedPaths.GetEnumerator()) {
    if (-not (Test-Path -Path $artifact.Value -PathType Leaf)) {
        throw "Expected $($artifact.Key) at [$($artifact.Value)]."
    }
}
