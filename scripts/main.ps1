[CmdletBinding()]
param()

'Pester', 'PSScriptAnalyzer' | ForEach-Object {
    Install-PSResource -Name $_ -Verbose:$false -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
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
    $params = @{
        Run_Path                           = $env:GITHUB_ACTION_INPUT_Run_Path
        Run_ExcludePath                    = $env:GITHUB_ACTION_INPUT_Run_ExcludePath
        Run_ScriptBlock                    = $env:GITHUB_ACTION_INPUT_Run_ScriptBlock
        Run_Container                      = $env:GITHUB_ACTION_INPUT_Run_Container
        Run_TestExtension                  = $env:GITHUB_ACTION_INPUT_Run_TestExtension
        Run_Exit                           = $env:GITHUB_ACTION_INPUT_Run_Exit
        Run_Throw                          = $env:GITHUB_ACTION_INPUT_Run_Throw
        Run_PassThru                       = $env:GITHUB_ACTION_INPUT_Run_PassThru
        Run_SkipRun                        = $env:GITHUB_ACTION_INPUT_Run_SkipRun
        Run_SkipRemainingOnFailure         = $env:GITHUB_ACTION_INPUT_Run_SkipRemainingOnFailure
        Filter_Tag                         = $env:GITHUB_ACTION_INPUT_Filter_Tag
        Filter_ExcludeTag                  = $env:GITHUB_ACTION_INPUT_Filter_ExcludeTag
        Filter_Line                        = $env:GITHUB_ACTION_INPUT_Filter_Line
        Filter_ExcludeLine                 = $env:GITHUB_ACTION_INPUT_Filter_ExcludeLine
        Filter_FullName                    = $env:GITHUB_ACTION_INPUT_Filter_FullName
        CodeCoverage_Enabled               = $env:GITHUB_ACTION_INPUT_CodeCoverage_Enabled
        CodeCoverage_OutputFormat          = $env:GITHUB_ACTION_INPUT_CodeCoverage_OutputFormat
        CodeCoverage_OutputPath            = $env:GITHUB_ACTION_INPUT_CodeCoverage_OutputPath
        CodeCoverage_OutputEncoding        = $env:GITHUB_ACTION_INPUT_CodeCoverage_OutputEncoding
        CodeCoverage_Path                  = $env:GITHUB_ACTION_INPUT_CodeCoverage_Path
        CodeCoverage_ExcludeTests          = $env:GITHUB_ACTION_INPUT_CodeCoverage_ExcludeTests
        CodeCoverage_RecursePaths          = $env:GITHUB_ACTION_INPUT_CodeCoverage_RecursePaths
        CodeCoverage_CoveragePercentTarget = $env:GITHUB_ACTION_INPUT_CodeCoverage_CoveragePercentTarget
        CodeCoverage_UseBreakpoints        = $env:GITHUB_ACTION_INPUT_CodeCoverage_UseBreakpoints
        CodeCoverage_SingleHitBreakpoints  = $env:GITHUB_ACTION_INPUT_CodeCoverage_SingleHitBreakpoints
        TestResult_Enabled                 = $env:GITHUB_ACTION_INPUT_TestResult_Enabled
        TestResult_OutputFormat            = $env:GITHUB_ACTION_INPUT_TestResult_OutputFormat
        TestResult_OutputPath              = $env:GITHUB_ACTION_INPUT_TestResult_OutputPath
        TestResult_OutputEncoding          = $env:GITHUB_ACTION_INPUT_TestResult_OutputEncoding
        TestResult_TestSuiteName           = $env:GITHUB_ACTION_INPUT_TestResult_TestSuiteName
        Should_ErrorAction                 = $env:GITHUB_ACTION_INPUT_Should_ErrorAction
        Debug_ShowFullErrors               = $env:GITHUB_ACTION_INPUT_Debug_ShowFullErrors
        Debug_WriteDebugMessages           = $env:GITHUB_ACTION_INPUT_Debug_WriteDebugMessages
        Debug_WriteDebugMessagesFrom       = $env:GITHUB_ACTION_INPUT_Debug_WriteDebugMessagesFrom
        Debug_ShowNavigationMarkers        = $env:GITHUB_ACTION_INPUT_Debug_ShowNavigationMarkers
        Debug_ReturnRawResultObject        = $env:GITHUB_ACTION_INPUT_Debug_ReturnRawResultObject
        Output_Verbosity                   = $env:GITHUB_ACTION_INPUT_Output_Verbosity
        Output_StackTraceVerbosity         = $env:GITHUB_ACTION_INPUT_Output_StackTraceVerbosity
        Output_CIFormat                    = $env:GITHUB_ACTION_INPUT_Output_CIFormat
        Output_CILogLevel                  = $env:GITHUB_ACTION_INPUT_Output_CILogLevel
        Output_RenderMode                  = $env:GITHUB_ACTION_INPUT_Output_RenderMode
        TestDrive_Enabled                  = $env:GITHUB_ACTION_INPUT_TestDrive_Enabled
        TestRegistry_Enabled               = $env:GITHUB_ACTION_INPUT_TestRegistry_Enabled
        ConfigurationFilePath              = $env:GITHUB_ACTION_INPUT_ConfigurationFilePath
    }

    [pscustomobject]($params.GetEnumerator() | Where-Object { $_.Value }) | Format-List
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
