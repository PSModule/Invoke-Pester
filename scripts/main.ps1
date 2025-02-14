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
    $configInputs = @{
        Run          = @{
            Path                   = $env:GITHUB_ACTION_INPUT_Run_Path
            ExcludePath            = $env:GITHUB_ACTION_INPUT_Run_ExcludePath
            ScriptBlock            = $env:GITHUB_ACTION_INPUT_Run_ScriptBlock
            Container              = $env:GITHUB_ACTION_INPUT_Run_Container
            TestExtension          = $env:GITHUB_ACTION_INPUT_Run_TestExtension
            Exit                   = $env:GITHUB_ACTION_INPUT_Run_Exit
            Throw                  = $env:GITHUB_ACTION_INPUT_Run_Throw
            PassThru               = $env:GITHUB_ACTION_INPUT_Run_PassThru
            SkipRun                = $env:GITHUB_ACTION_INPUT_Run_SkipRun
            SkipRemainingOnFailure = $env:GITHUB_ACTION_INPUT_Run_SkipRemainingOnFailure
        }
        Filter       = @{
            Tag         = $env:GITHUB_ACTION_INPUT_Filter_Tag
            ExcludeTag  = $env:GITHUB_ACTION_INPUT_Filter_ExcludeTag
            Line        = $env:GITHUB_ACTION_INPUT_Filter_Line
            ExcludeLine = $env:GITHUB_ACTION_INPUT_Filter_ExcludeLine
            FullName    = $env:GITHUB_ACTION_INPUT_Filter_FullName
        }
        CodeCoverage = @{
            Enabled               = $env:GITHUB_ACTION_INPUT_CodeCoverage_Enabled
            OutputFormat          = $env:GITHUB_ACTION_INPUT_CodeCoverage_OutputFormat
            OutputPath            = $env:GITHUB_ACTION_INPUT_CodeCoverage_OutputPath
            OutputEncoding        = $env:GITHUB_ACTION_INPUT_CodeCoverage_OutputEncoding
            Path                  = $env:GITHUB_ACTION_INPUT_CodeCoverage_Path
            ExcludeTests          = $env:GITHUB_ACTION_INPUT_CodeCoverage_ExcludeTests
            RecursePaths          = $env:GITHUB_ACTION_INPUT_CodeCoverage_RecursePaths
            CoveragePercentTarget = $env:GITHUB_ACTION_INPUT_CodeCoverage_CoveragePercentTarget
            UseBreakpoints        = $env:GITHUB_ACTION_INPUT_CodeCoverage_UseBreakpoints
            SingleHitBreakpoints  = $env:GITHUB_ACTION_INPUT_CodeCoverage_SingleHitBreakpoints
        }
        TestResult   = @{
            Enabled        = $env:GITHUB_ACTION_INPUT_TestResult_Enabled
            OutputFormat   = $env:GITHUB_ACTION_INPUT_TestResult_OutputFormat
            OutputPath     = $env:GITHUB_ACTION_INPUT_TestResult_OutputPath
            OutputEncoding = $env:GITHUB_ACTION_INPUT_TestResult_OutputEncoding
            TestSuiteName  = $env:GITHUB_ACTION_INPUT_TestResult_TestSuiteName
        }
        Should       = @{
            ErrorAction = $env:GITHUB_ACTION_INPUT_Should_ErrorAction
        }
        Debug        = @{
            ShowFullErrors         = $env:GITHUB_ACTION_INPUT_Debug_ShowFullErrors
            WriteDebugMessages     = $env:GITHUB_ACTION_INPUT_Debug_WriteDebugMessages
            WriteDebugMessagesFrom = $env:GITHUB_ACTION_INPUT_Debug_WriteDebugMessagesFrom
            ShowNavigationMarkers  = $env:GITHUB_ACTION_INPUT_Debug_ShowNavigationMarkers
            ReturnRawResultObject  = $env:GITHUB_ACTION_INPUT_Debug_ReturnRawResultObject
        }
        Output       = @{
            Verbosity           = $env:GITHUB_ACTION_INPUT_Output_Verbosity
            StackTraceVerbosity = $env:GITHUB_ACTION_INPUT_Output_StackTraceVerbosity
            CIFormat            = $env:GITHUB_ACTION_INPUT_Output_CIFormat
            CILogLevel          = $env:GITHUB_ACTION_INPUT_Output_CILogLevel
            RenderMode          = $env:GITHUB_ACTION_INPUT_Output_RenderMode
        }
        TestDrive    = @{
            Enabled = $env:GITHUB_ACTION_INPUT_TestDrive_Enabled
        }
        TestRegistry = @{
            Enabled = $env:GITHUB_ACTION_INPUT_TestRegistry_Enabled
        }
    }
    $otherInputs = @{
        ConfigurationFilePath = $env:GITHUB_ACTION_INPUT_ConfigurationFilePath
    }

    $inputs = $configInputs + $otherInputs

    [pscustomobject]($inputs.GetEnumerator() | Where-Object { $_.Value }) | Format-List
}

LogGroup 'Load configuration - Defaults' {
    $defaultConfigurationPath = (Join-Path $PSScriptRoot -ChildPath 'Pester.Configuration.ps1')
    if (Test-Path -Path $defaultConfigurationPath) {
        $defaultConfiguration = . $defaultConfigurationPath
        [pscustomobject]$defaultConfiguration | Format-List
    }
}

LogGroup 'Load configuration - Custom settings file' {
    $customConfigurationFilePath = $otherInputs.ConfigurationFilePath
    $fileExists = Test-Path -Path $customConfigurationFilePath
    Write-Host "Custom configuration file path: $customConfigurationFilePath"
    Write-Host "File exists: $fileExists"
    if ($customConfigurationFilePath -and $fileExists) {
        $customConfiguration = . $customConfigurationFilePath
        [pscustomobject]$customConfiguration | Format-List
    }
}

LogGroup 'Load configuration - Action overrides' {
    $customConfigurationInputs = ($configInputs.GetEnumerator() | Where-Object { $_.Value })
    [pscustomobject]$customConfigurationInputs | Format-List
}

LogGroup 'Load configuration - Result' {
    $configuration = Merge-Hashtable -Main $defaultConfiguration -Overrides $customConfiguration, $customConfigurationInputs
    [pscustomobject]$configuration | Format-List
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
