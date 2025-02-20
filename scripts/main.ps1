
[CmdletBinding()]
param()

LogGroup 'Setup prerequisites' {
    'Pester', 'PSScriptAnalyzer', 'Hashtable', 'TimeSpan' | ForEach-Object {
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
    $providedItem = Resolve-Path -Path $env:GITHUB_ACTION_INPUT_Path | Select-Object -ExpandProperty Path | Get-Item
    if ($providedItem -is [System.IO.DirectoryInfo]) {
        $providedPath = $providedItem.FullName
    } elseif ($providedItem -is [System.IO.FileInfo]) {
        $providedPath = $providedItem.Directory.FullName
    } else {
        Write-GitHubError "❌ Provided path [$providedItem] is not a valid directory or file."
        exit 1
    }

    $inputs = @{
        Path                               = $providedPath

        Run_Path                           = $env:GITHUB_ACTION_INPUT_Run_Path
        Run_ExcludePath                    = $env:GITHUB_ACTION_INPUT_Run_ExcludePath
        Run_ScriptBlock                    = $env:GITHUB_ACTION_INPUT_Run_ScriptBlock
        Run_Container                      = $env:GITHUB_ACTION_INPUT_Run_Container
        Run_TestExtension                  = $env:GITHUB_ACTION_INPUT_Run_TestExtension
        Run_Exit                           = $env:GITHUB_ACTION_INPUT_Run_Exit
        Run_Throw                          = $env:GITHUB_ACTION_INPUT_Run_Throw
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
    }

    [pscustomobject]($inputs.GetEnumerator() | Where-Object { -not [string]::IsNullOrEmpty($_.Value) }) | Format-List
}

LogGroup 'Load configuration - Defaults' {
    $defaultConfig = New-PesterConfiguration | Convert-PesterConfigurationToHashtable
    Write-Output ($defaultConfig | Format-Hashtable | Out-String)
}

LogGroup 'Load configuration - Custom settings file' {
    $customConfig = Get-PesterConfiguration -Path $inputs.Path
    Write-Output ($customConfig | Format-Hashtable | Out-String)
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

    $customInputs = $customConfigInputMap | Clear-PesterConfigurationEmptyValue
    Write-Output ($customInputs | Format-Hashtable | Out-String)
}

LogGroup 'Merge configuration' {
    $configuration = Merge-PesterConfiguration -BaseConfiguration $defaultConfig -AdditionalConfiguration $customConfig, $customInputs

    if ([string]::IsNullOrEmpty($configuration.Run.Path)) {
        $configuration.Run.Path = $inputs.Path
    }
    Write-Output ($configuration | Format-Hashtable | Out-String)
}

LogGroup 'Find containers' {
    $containers = @()
    $existingContainers = $configuration.Run.Container
    if ($existingContainers.Count -gt 0) {
        Write-Output "Containers from configuration: [$($existingContainers.Count)]"
        foreach ($existingContainer in $existingContainers) {
            Write-Output "Processing container [$existingContainer]"
            $containers += $existingContainer | Convert-PesterConfigurationToHashtable
        }
    }
    Write-Output "Containers from configuration: [$($containers.Count)]"
    if ($containers.Count -eq 0) {
        # If no containers are specified, search for "*.Container.*" files in each Run.Path directory
        Write-Output 'Searching for containers in same location as config.'
        foreach ($testDir in $inputs.Path) {
            $containerFiles = Get-ChildItem -Path $testDir -Filter *.Container.* -Recurse
            Write-Output "Containers found in [$testDir]: [$($containerFiles.Count)]"
            foreach ($containerFile in $containerFiles) {
                Write-Output "Processing container file [$containerFile]"
                $containers += Import-Hashtable $containerFile
            }
        }
    }
    Write-Output "Containers found: [$($containers.Count)]"
    Write-Output ($containers | ConvertTo-Json -Depth 2 -WarningAction SilentlyContinue)
}

LogGroup 'Set Configuration - Result' {
    $artifactName = $configuration.TestResult.TestSuiteName ?? 'Pester'
    $configuration.TestResult.OutputPath = "test_reports/$artifactName-TestResult-Report.xml"
    $configuration.CodeCoverage.OutputPath = "test_reports/$artifactName-CodeCoverage-Report.xml"
    $configuration.Run.PassThru = $true

    # If any containers are defined as hashtables, convert them to PesterContainer objects
    $configuration.Run.Container = @()
    foreach ($container in $containers) {
        Write-Verbose "Processing container [$container]" -Verbose
        Write-Verbose 'Converting hashtable to PesterContainer' -Verbose
        $configuration.Run.Container += New-PesterContainer @container
    }

    $configuration = New-PesterConfiguration -Hashtable $configuration
    $configurationHashtable = $configuration | Convert-PesterConfigurationToHashtable | Format-Hashtable | Out-String
    Write-Output $configurationHashtable
}

$testResults = Invoke-Pester -Configuration $configuration

if ($null -eq $testResults) {
    Write-GitHubError '❌ No test results were returned.'
    exit 1
}

LogGroup 'Test results' {
    $testResults | Format-List

    $failedTests = [int]$testResults.FailedCount

    if ($failedTests -eq 0 -and $testResults.Result -eq 'Passed') {
        Write-GitHubNotice '✅ All tests passed.'
        Set-GitHubOutput -Name 'passed' -Value $true
    } else {
        Write-GitHubError "❌ Some [$failedTests] tests failed."
        Set-GitHubOutput -Name 'passed' -Value $false
    }
}

LogGroup 'Test results summary' {

    $nbsp = [char]0x00A0
    $indent = "$nbsp" * 4

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

    $testSuitName = $($configuration.TestResult.TestSuiteName.Value)
    $testSuitStatusIcon = if ($failedTests -gt 0) { '❌' } else { '✅' }
    $formattedTestDuration = $testResults.Duration | Format-TimeSpan
    $summaryMarkdown = @"

<details><summary>$testSuitStatusIcon - $testSuitName ($formattedTestDuration)</summary>
<p>

<details><summary>Configuration</summary>
<p>

``````pwsh
$configurationHashtable
``````

</p>
</details>


| Total | Passed | Failed | Skipped | Inconclusive | NotRun | Coverage |
| ----- | ------ | ------ | ------- | ------------ | ------ | -------- |
| $($totalTests) | $($passedTests) | $($failedTests) | $($skippedTests) | $($inconclusiveTests) | $($notRunTests) | $coverageString |

"@

    Write-Verbose "Processing containers [$($testResults.Containers.Count)]" -Verbose
    # For each container, group tests by their test path parts
    foreach ($container in $testResults.Containers) {
        $containerPath = $container.Item.FullName
        Write-Verbose "Processing container [$containerPath]" -Verbose
        $containerName = (Split-Path $container.Name -Leaf) -replace '.Tests.ps1'
        Write-Verbose "Container name: [$containerName]" -Verbose
        $containerStatusIcon = $container.Result -eq 'Passed' ? '✅' : '❌'
        $formattedContainerDuration = $container.Duration | Format-TimeSpan
        $summaryMarkdown += @"
<details><summary>$Indent$containerStatusIcon - $containerName ($formattedContainerDuration)</summary>
<p>

"@
        $containerTests = $testResults.Tests | Where-Object { $_.Block.BlockContainer.Item.FullName -eq $containerPath } | Sort-Object -Property Path
        Write-Verbose "Processing tests [$($containerTests.Count)]" -Verbose

        # Build the nested details markdown grouping tests by their test path parts
        $groupedMarkdown = Get-GroupedTestMarkdown -Tests $containerTests -Depth 0
        $summaryMarkdown += $groupedMarkdown

        $summaryMarkdown += @'

</p>
</details>

'@
    }

    $summaryMarkdown += @'

</p>
</details>

'@
    Set-GitHubStepSummary -Summary $summaryMarkdown
}

# For each property of testresults, output the value as a JSON object
# foreach ($property in $testResults.PSObject.Properties) {
#     Write-Verbose "Setting output for [$($property.Name)]"
#     $name = $property.Name
#     $value = -not [string]::IsNullOrEmpty($property.Value) ? ($property.Value | ConvertTo-Json -Depth 2 -WarningAction SilentlyContinue) : ''
#     Set-GitHubOutput -Name $name -Value $value
# }

Set-GitHubOutput -Name 'TestResultEnabled' -Value $testResults.Configuration.TestResult.Enabled.Value
Set-GitHubOutput -Name 'TestResultOutputPath' -Value $testResults.Configuration.TestResult.OutputPath.Value
Set-GitHubOutput -Name 'TestSuiteName' -Value $testResults.Configuration.TestResult.TestSuiteName.Value
Set-GitHubOutput -Name 'CodeCoverageEnabled' -Value $testResults.Configuration.CodeCoverage.Enabled.Value
Set-GitHubOutput -Name 'CodeCoverageOutputPath' -Value $testResults.Configuration.CodeCoverage.OutputPath.Value

exit $failedTests
