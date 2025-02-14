[CmdletBinding()]
param()

'Pester', 'PSScriptAnalyzer' | ForEach-Object {
    Install-PSResource -Name $_ -Verbose:$false -WarningAction SilentlyContinue
    Import-Module -Name $_ -Verbose:$false
}

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

LogGroup 'Load inputs' {
    Get-ChildItem -Path env: | Where-Object { $_.Name -like 'GITHUB_ACTION_INPUT_*' } | ForEach-Object {
        $name = $_.Name -replace '^GITHUB_ACTION_INPUT_'
        $value = $_.Value
        New-Variable -Name $name -Value $value -Force -Scope Script -PassThru
    } | Format-Table -AutoSize
}

# $Path = '\tests\Advanced'
# $containers = Get-PesterContainer -Path $Path

# $Configuration = Get-PesterConfiguration -Path $Path
# $Configuration.Run.Container = $containers

# $Configuration.Run.Container.Value
# @{
#     Run_Path                           = $Path
#     Run_ExcludePath                    = @()
#     Run_ScriptBlock                    = @()
#     Run_Container                      = @()
#     Run_TestExtension                  = @(
#         '.Tests.ps1'
#     )
#     Run_Exit                           = $false
#     Run_Throw                          = $false
#     Run_PassThru                       = $true
#     Run_SkipRun                        = $false
#     Run_SkipRemainingOnFailure         = 'None'

#     Filter_Tag                         = @()
#     Filter_ExcludeTag                  = @()
#     Filter_Line                        = @()
#     Filter_ExcludeLine                 = @()
#     Filter_FullName                    = @()

#     CodeCoverage_Enabled               = $true
#     CodeCoverage_OutputFormat          = 'JaCoCo'
#     CodeCoverage_OutputPath            = 'CodeCoverage-Report.xml'
#     CodeCoverage_OutputEncoding        = 'UTF8'
#     CodeCoverage_Path                  = @()
#     CodeCoverage_ExcludeTests          = $true
#     CodeCoverage_RecursePaths          = $true
#     CodeCoverage_CoveragePercentTarget = 75.0
#     CodeCoverage_UseBreakpoints        = $true
#     CodeCoverage_SingleHitBreakpoints  = $true

#     TestResult_Enabled                 = $true
#     TestResult_OutputFormat            = 'NUnitXml'
#     TestResult_OutputPath              = 'outputs\Test-Report.xml'
#     TestResult_OutputEncoding          = 'UTF8'
#     TestResult_TestSuiteName           = 'Unit tests'
#     Should_ErrorAction                 = 'Stop'
#     Debug_ShowFullErrors               = $false
#     Debug_WriteDebugMessages           = $false
#     Debug_WriteDebugMessagesFrom       = @(
#         'Discovery',
#         'Skip',
#         'Mock',
#         'CodeCoverage'
#     )
#     Debug_ShowNavigationMarkers        = $false
#     Debug_ReturnRawResultObject        = $false

#     Output_CIFormat                    = 'Auto'
#     Output_StackTraceVerbosity         = 'Filtered'
#     Output_Verbosity                   = 'Detailed'
#     Output_CILogLevel                  = 'Error'
#     Output_RenderMode                  = 'Auto'
#     TestDrive_Enabled                  = $true
#     TestRegistry_Enabled               = $true
# }


# $Configuration | ConvertTo-Json -Depth 100 | Clip
# $Configuration.Container | ConvertTo-Json -Depth 100 | Clip

# Invoke-Pester -Configuration $Configuration



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
