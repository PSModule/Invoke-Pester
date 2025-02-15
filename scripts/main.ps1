[CmdletBinding()]
param()

LogGroup 'Setup prerequisites' {
    'Pester', 'PSScriptAnalyzer' | ForEach-Object {
        Install-PSResource -Name $_ -Verbose:$false -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
        Import-Module -Name $_ -Verbose:$false
    }
    Import-Module "$PSScriptRoot/Helpers.psm1"
}

LogGroup 'Get test kit versions' {
    $PSSAModule = Get-PSResource -Name PSScriptAnalyzer -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1
    $pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

    [PSCustomObject]@{
        PowerShell       = $PSVersionTable.PSVersion.ToString()
        Pester           = $pesterModule.Version
        PSScriptAnalyzer = $PSSAModule.Version
    } | Format-List
}

LogGroup 'Load inputs' {
    $inputs = @{
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

    [pscustomobject]($inputs.GetEnumerator() | Where-Object { -not [string]::IsNullOrEmpty($_.Value) }) | Format-List
}

$customConfig = @{}
$customInputs = @{}

LogGroup 'Load configuration - Defaults' {
    $defaultConfigPath = (Join-Path $PSScriptRoot -ChildPath 'Pester.Configuration.ps1')
    if (Test-Path -Path $defaultConfigPath) {
        $tmpDefault = . $defaultConfigPath
    }
    $defaultConfig = @{
        Run          = $tmpDefault.Run ?? @{}
        Filter       = $tmpDefault.Filter ?? @{}
        CodeCoverage = $tmpDefault.CodeCoverage ?? @{}
        TestResult   = $tmpDefault.TestResult ?? @{}
        Should       = $tmpDefault.Should ?? @{}
        Debug        = $tmpDefault.Debug ?? @{}
        Output       = $tmpDefault.Output ?? @{}
        TestDrive    = $tmpDefault.TestDrive ?? @{}
        TestRegistry = $tmpDefault.TestRegistry ?? @{}
    }
    Write-Output ($defaultConfig | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
}

LogGroup 'Load configuration - Custom settings file' {
    $customConfigFilePath = $inputs.ConfigurationFilePath
    Write-Output "Custom configuration file path: [$customConfigFilePath]"
    if ($customConfigFilePath) {
        $fileExists = Test-Path -Path $customConfigFilePath
        Write-Output "File exists: [$fileExists]"
        if ($fileExists) {
            $tmpCustom = . $customConfigFilePath
        }
    }
    $tmpCustomConfiguration = @{
        Run          = $tmpCustom.Run ?? @{}
        Filter       = $tmpCustom.Filter ?? @{}
        CodeCoverage = $tmpCustom.CodeCoverage ?? @{}
        TestResult   = $tmpCustom.TestResult ?? @{}
        Should       = $tmpCustom.Should ?? @{}
        Debug        = $tmpCustom.Debug ?? @{}
        Output       = $tmpCustom.Output ?? @{}
        TestDrive    = $tmpCustom.TestDrive ?? @{}
        TestRegistry = $tmpCustom.TestRegistry ?? @{}
    }

    foreach ($section in $tmpCustomConfiguration.Keys) {
        $filteredProperties = @{}
        foreach ($property in $tmpCustomConfiguration[$section].Keys) {
            $value = $tmpCustomConfiguration[$section][$property]
            if (-not [string]::IsNullOrEmpty($Value)) {
                $filteredProperties[$property] = $Value
            }
        }
        $customConfig[$section] = $filteredProperties
    }

    Write-Output ($customConfig | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
}

LogGroup 'Load configuration - Action overrides' {
    $customConfigInputMap = @{
        Run          = @{
            Path                   = $inputs.Run_Path
            ExcludePath            = $inputs.Run_ExcludePath
            ScriptBlock            = $inputs.Run_ScriptBlock
            Container              = $inputs.Run_Container
            TestExtension          = $inputs.Run_TestExtension
            Exit                   = $inputs.Run_Exit
            Throw                  = $inputs.Run_Throw
            PassThru               = $inputs.Run_PassThru
            SkipRun                = $inputs.Run_SkipRun
            SkipRemainingOnFailure = $inputs.Run_SkipRemainingOnFailure
        }
        Filter       = @{
            Tag         = $inputs.Filter_Tag
            ExcludeTag  = $inputs.Filter_ExcludeTag
            Line        = $inputs.Filter_Line
            ExcludeLine = $inputs.Filter_ExcludeLine
            FullName    = $inputs.Filter_FullName
        }
        CodeCoverage = @{
            Enabled               = $inputs.CodeCoverage_Enabled
            OutputFormat          = $inputs.CodeCoverage_OutputFormat
            OutputPath            = $inputs.CodeCoverage_OutputPath
            OutputEncoding        = $inputs.CodeCoverage_OutputEncoding
            Path                  = $inputs.CodeCoverage_Path
            ExcludeTests          = $inputs.CodeCoverage_ExcludeTests
            RecursePaths          = $inputs.CodeCoverage_RecursePaths
            CoveragePercentTarget = $inputs.CodeCoverage_CoveragePercentTarget
            UseBreakpoints        = $inputs.CodeCoverage_UseBreakpoints
            SingleHitBreakpoints  = $inputs.CodeCoverage_SingleHitBreakpoints
        }
        TestResult   = @{
            Enabled        = $inputs.TestResult_Enabled
            OutputFormat   = $inputs.TestResult_OutputFormat
            OutputPath     = $inputs.TestResult_OutputPath
            OutputEncoding = $inputs.TestResult_OutputEncoding
            TestSuiteName  = $inputs.TestResult_TestSuiteName
        }
        Should       = @{
            ErrorAction = $inputs.Should_ErrorAction
        }
        Debug        = @{
            ShowFullErrors         = $inputs.Debug_ShowFullErrors
            WriteDebugMessages     = $inputs.Debug_WriteDebugMessages
            WriteDebugMessagesFrom = $inputs.Debug_WriteDebugMessagesFrom
            ShowNavigationMarkers  = $inputs.Debug_ShowNavigationMarkers
            ReturnRawResultObject  = $inputs.Debug_ReturnRawResultObject
        }
        Output       = @{
            CIFormat            = $inputs.Output_CIFormat
            StackTraceVerbosity = $inputs.Output_StackTraceVerbosity
            Verbosity           = $inputs.Output_Verbosity
            CILogLevel          = $inputs.Output_CILogLevel
            RenderMode          = $inputs.Output_RenderMode
        }
        TestDrive    = @{
            Enabled = $inputs.TestDrive_Enabled
        }
        TestRegistry = @{
            Enabled = $inputs.TestRegistry_Enabled
        }
    }

    foreach ($section in $customConfigInputMap.Keys) {
        $filteredProperties = @{}
        foreach ($property in $customConfigInputMap[$section].Keys) {
            $value = $customConfigInputMap[$section][$property]
            if (-not [string]::IsNullOrEmpty($Value)) {
                $filteredProperties[$property] = $Value
            }
        }
        $customInputs[$section] = $filteredProperties
    }

    Write-Output ($customInputs | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
}

$run = Merge-Hashtable -Main $defaultConfig.Run -Overrides $customConfig.Run, $customInputs.Run
$filter = Merge-Hashtable -Main $defaultConfig.Filter -Overrides $customConfig.Filter, $customInputs.Filter
$codeCoverage = Merge-Hashtable -Main $defaultConfig.CodeCoverage -Overrides $customConfig.CodeCoverage, $customInputs.CodeCoverage
$testResult = Merge-Hashtable -Main $defaultConfig.TestResult -Overrides $customConfig.TestResult, $customInputs.TestResult
$should = Merge-Hashtable -Main $defaultConfig.Should -Overrides $customConfig.Should, $customInputs.Should
$debug = Merge-Hashtable -Main $defaultConfig.Debug -Overrides $customConfig.Debug, $customInputs.Debug
$output = Merge-Hashtable -Main $defaultConfig.Output -Overrides $customConfig.Output, $customInputs.Output
$testDrive = Merge-Hashtable -Main $defaultConfig.TestDrive -Overrides $customConfig.TestDrive, $customInputs.TestDrive
$testRegistry = Merge-Hashtable -Main $defaultConfig.TestRegistry -Overrides $customConfig.TestRegistry, $customInputs.TestRegistry

$configuration = @{
    Run          = $run
    Filter       = $filter
    CodeCoverage = $codeCoverage
    TestResult   = $testResult
    Should       = $should
    Debug        = $debug
    Output       = $output
    TestDrive    = $testDrive
    TestRegistry = $testRegistry
}

LogGroup 'Load configuration - Add containers' {
    $containers = Get-PesterContainer -Path $configuration.Run.Path
    Write-Output ($containers | ConvertTo-Json -Depth 2 -WarningAction SilentlyContinue)
}

LogGroup 'Load configuration - Result' {
    $configuration.Run.Container += $containers | ForEach-Object { New-PesterContainer @_ }
    Write-Output ($configuration | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
}

$testResults = Invoke-Pester -Configuration $configuration

LogGroup 'Test results' {
    $testResults | Format-List

    $failedTests = [int]$testResults.FailedCount

    if (($failedTests -gt 0) -or ($testResults.Result -ne 'Passed')) {
        Write-GitHubError "❌ Some [$failedTests] tests failed."
    }
    if ($failedTests -eq 0) {
        Write-GitHubNotice '✅ All tests passed.'
    }

    $results = $testResults | ConvertTo-Json -Depth 2

    # Provide structured JSON as an output for potential downstream steps
    Set-GitHubOutput -Name 'results' -Value $results
}

$totalTests = $testResults.TotalCount
$passedTests = $testResults.PassedCount
$failedTests = $testResults.FailedCount
$skippedTests = $testResults.SkippedCount
$inconclusiveTests = $testResults.InconclusiveCount
$notRunTests = $testResults.NotRunCount

$coverageString = 'N/A'
if ($configuration.CodeCoverage.Enabled) {
    $coverage = [System.Math]::Round(($testResults.CodeCoverage.CoveragePercent), 2)
    $coverageString = "$coverage%"
}

$statusIcon = if ($failedTests -gt 0) { '❌' } else { '✅' }

$summaryMarkdown = @"
### $statusIcon - Test Results

| Total | Passed | Failed | Skipped | Inconclusive | NotRun | Coverage |
| ----- | ------ | ------ | ------- | ------------ | ------ | -------- |
| $($totalTests) | $($passedTests) | $($failedTests) | $($skippedTests) | $($inconclusiveTests) | $($notRunTests) | $coverageString |


<details><summary>Details</summary>
<p>

``````

"@

$testResults.Tests | ForEach-Object {
    $test = $_
    $statusIcon = $test.Result -eq 'Passed' ? '✅' : '❌'
    $formattedDuration = $test.Duration | Format-TimeSpan -Precision Milliseconds -AdaptiveRounding
    $summaryMarkdown += @"
- $statusIcon $($test.Name) - $formattedDuration

"@
    if ($test.Result -eq 'Failed' -and $test.ErrorRecord.Exception.Message) {
        $summaryMarkdown += @"
  $($test.ErrorRecord.Exception.Message)

"@
    }
}
$summaryMarkdown += @"
``````

</p>
</details>
"@

Set-GitHubStepSummary -Summary $summaryMarkdown

# Output paths for artifacts upload
$codeCoverageOutputPath = $testResults.Configuration.CodeCoverage.OutputPath
if ($codeCoverageOutputPath) {
    Set-GitHubOutput -Name 'CodeCoverageOutputPath' -Value $codeCoverageOutputPath
} else {
    Write-GitHubWarning 'No code coverage output path found.'
}

$testResultOutputPath = $testResults.Configuration.TestResult.OutputPath
if ($testResultOutputPath) {
    Set-GitHubOutput -Name 'TestResultOutputPath' -Value $testResultOutputPath
} else {
    Write-GitHubWarning 'No test result output path found.'
}

exit $failedTests
