[CmdletBinding()]
param()

Import-Module "$PSScriptRoot/Helpers.psm1"

LogGroup 'Get test kit versions' {
    $PSSAModule = Get-PSResource -Name PSScriptAnalyzer -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1
    $pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

    [PSCustomObject]@{
        PowerShell       = $PSVersionTable.PSVersion.ToString()
        Pester           = $pesterModule.version
        PSScriptAnalyzer = $PSSAModule.version
    } | Format-List
}

$Path = '\tests\Advanced'
$containers = Get-PesterContainer -Path $Path

$Configuration = Get-PesterConfiguration -Path $Path
$Configuration.Run.Container = $containers

$Configuration.Run.Container.Value


$Configuration | ConvertTo-Json -Depth 100 | Clip
$Configuration.Container | ConvertTo-Json -Depth 100 | Clip

Invoke-Pester -Configuration $Configuration



# LogGroup 'Pester config' {
#     $pesterParams = @{
#         Configuration = @{
#             Run          = @{
#                 Path      = $Path
#                 Container = $containers
#                 PassThru  = $true
#             }
#             TestResult   = @{
#                 Enabled       = $testModule
#                 OutputFormat  = 'NUnitXml'
#                 OutputPath    = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'outputs\Test-Report.xml'
#                 TestSuiteName = 'Unit tests'
#             }
#             CodeCoverage = @{
#                 Enabled               = $testModule
#                 OutputPath            = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'outputs\CodeCoverage-Report.xml'
#                 OutputFormat          = 'JaCoCo'
#                 OutputEncoding        = 'UTF8'
#                 CoveragePercentTarget = 75
#             }
#             Output       = @{
#                 CIFormat            = 'Auto'
#                 StackTraceVerbosity = $StackTraceVerbosity
#                 Verbosity           = $Verbosity
#             }
#         }
#     }
#     Write-Host ($pesterParams | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
# }

# $testResults = Invoke-Pester @pesterParams

# LogGroup 'Test results' {
#     $testResults | Format-List
#     $failedTests = [int]$testResults.FailedCount

#     if (($failedTests -gt 0) -or ($testResults.Result -ne 'Passed')) {
#         Write-GitHubError "❌ Some [$failedTests] tests failed."
#     }
#     if ($failedTests -eq 0) {
#         Write-GitHubNotice '✅ All tests passed.'
#     }

#     Set-GitHubOutput -Name 'results' -Value $testResults
# }

# exit $failedTests
