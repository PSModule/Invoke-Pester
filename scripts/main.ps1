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

$defaultConfiguration = @{}
$customConfiguration = @{}

LogGroup 'Load configuration - Defaults' {
    $defaultConfigurationPath = (Join-Path $PSScriptRoot -ChildPath 'Pester.Configuration.ps1')
    if (Test-Path -Path $defaultConfigurationPath) {
        $defaultConfiguration = . $defaultConfigurationPath
        Write-Host ($defaultConfiguration | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
    }
}

LogGroup 'Load configuration - Custom settings file' {
    $customConfigurationFilePath = $otherInputs.ConfigurationFilePath
    $fileExists = Test-Path -Path $customConfigurationFilePath
    Write-Host "Custom configuration file path: $customConfigurationFilePath"
    Write-Host "File exists: $fileExists"
    if ($customConfigurationFilePath -and $fileExists) {
        $customConfiguration = . $customConfigurationFilePath
        Write-Host ($customConfiguration | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
    }
}

LogGroup 'Load configuration - Action overrides' {
    $customConfigurationInputs = ($configInputs.GetEnumerator() | Where-Object { $_.Value })
    Write-Host ($customConfigurationInputs | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
}

LogGroup 'Load configuration - Result' {
    $configuration = Merge-Hashtable -Main $defaultConfiguration -Overrides $customConfiguration, $customConfigurationInputs
    Write-Host ($configuration | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
}

LogGroup 'Load containers' {
    $containers = Get-PesterContainer -Path $configuration.Run.Path
    Write-Host ($containers | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
}

$configuration.Run.Container = $containers

LogGroup 'Run tests' {
    $testResults = Invoke-Pester -Configuration $configuration
}

# Invoke-Pester -Configuration $Configuration


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
