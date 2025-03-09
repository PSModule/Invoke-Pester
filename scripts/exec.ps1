[CmdletBinding()]
param()

$PSStyle.OutputRendering = 'Ansi'

'::group::Exec - Setup prerequisites'
Import-Module "$PSScriptRoot/Helpers.psm1"
'Pester' | Install-PSResourceWithRetry
'::endgroup::'

'::group::Exec - Get test kit versions'
$pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

[PSCustomObject]@{
    PowerShell = $PSVersionTable.PSVersion.ToString()
    Pester     = $pesterModule.Version
} | Format-List
'::endgroup::'

'::group::Exec - Info about environment'
$path = Join-Path -Path $pwd.Path -ChildPath '.temp'
Test-Path -Path $path
Get-ChildItem -Path $path -Recurse | Sort-Object FullName | Format-Table -AutoSize | Out-String

'::group::Exec - Import Configuration'
$configPath = (Join-Path -Path $path -ChildPath 'Invoke-Pester.Configuration.ps1')
Write-Output "Importing configuration from [$configPath]"
if (-not (Test-Path -Path $configPath)) {
    Write-Error "Configuration file [$configPath] not found."
    exit 1
}
Get-Content -Path $configPath -Raw
'::endgroup::'

'::group::Exec - PesterConfiguration'
$configuration = . $configPath
$configuration.Run.Container = @()
$containerFiles = Get-ChildItem -Path $path -Filter *.Container.* -Recurse | Sort-Object FullName
foreach ($containerFile in $containerFiles) {
    $container = & $($containerFile.FullName)
    Write-Verbose "Processing container [$container]"
    Write-Verbose 'Converting hashtable to PesterContainer'
    $configuration.Run.Container += New-PesterContainer @container
}

$configuration | ConvertTo-Json

'::endgroup::'

'::group::Exec - Available modules'
Get-Module | Format-Table -AutoSize | Out-String
'::endgroup::'

$configuration = New-PesterConfiguration -Hashtable $configuration
$testResults = Invoke-Pester -Configuration $configuration

LogGroup 'Eval - Setup prerequisites' {
    'Pester', 'Hashtable', 'TimeSpan', 'Markdown' | Install-PSResourceWithRetry
}

LogGroup 'Eval - Get test kit versions' {
    $pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

    [PSCustomObject]@{
        PowerShell = $PSVersionTable.PSVersion.ToString()
        Pester     = $pesterModule.Version
    } | Format-List
}

LogGroup 'Eval - Test results' {
    if ($null -eq $testResults) {
        Write-GitHubError '❌ No test results were returned.'
        exit 1
    }

    $testResults | Format-List | Out-String
}

LogGroup 'Eval - Test results summary' {
    $stepSummaryMode = $env:PSMODULE_INVOKE_PESTER_INPUT_StepSummary_Mode
    $showTestOverview = $env:PSMODULE_INVOKE_PESTER_INPUT_StepSummary_ShowTestOverview -eq 'true'
    $showConfiguration = $env:PSMODULE_INVOKE_PESTER_INPUT_StepSummary_ShowConfiguration -eq 'true'

    # Only generate a step summary if the StepSummary setting is not 'None'
    # AND at least one component is configured to be displayed
    $generateSummary = $showTestOverview -or $showConfiguration -or ($stepSummaryMode -in @('Failed', 'Full'))

    if ($generateSummary) {
        $PSStyle.OutputRendering = 'Host'

        $summaryParams = @{
            ShowTestOverview  = $showTestOverview
            ShowTestsMode     = $stepSummaryMode
            ShowConfiguration = $showConfiguration
        }
        [PSCustomObject]$summaryParams | Format-List | Out-String

        Set-GitHubStepSummary -Summary ($testResults | Set-PesterReportSummary @summaryParams)
        $PSStyle.OutputRendering = 'Ansi'
    } else {
        Write-Verbose 'Step summary has been disabled or no components are configured for display'
    }
}

LogGroup 'Eval - Set outputs' {
    $testResultOutputFolderPath = $testResults.Configuration.TestResult.OutputPath.Value | Split-Path -Parent
    $codeCoverageOutputFolderPath = $testResults.Configuration.CodeCoverage.OutputPath.Value | Split-Path -Parent
    [pscustomobject]@{
        TestSuiteName          = $testResults.Configuration.TestResult.TestSuiteName.Value
        TestResultEnabled      = $testResults.Configuration.TestResult.Enabled.Value
        TestResultOutputPath   = $testResultOutputFolderPath
        CodeCoverageEnabled    = $testResults.Configuration.CodeCoverage.Enabled.Value
        CodeCoverageOutputPath = $codeCoverageOutputFolderPath
    } | Format-List | Out-String
    Set-GitHubOutput -Name 'TestSuiteName' -Value $testResults.Configuration.TestResult.TestSuiteName.Value
    Set-GitHubOutput -Name 'TestResultEnabled' -Value $testResults.Configuration.TestResult.Enabled.Value
    Set-GitHubOutput -Name 'TestResultOutputPath' -Value $testResultOutputFolderPath
    Set-GitHubOutput -Name 'CodeCoverageEnabled' -Value $testResults.Configuration.CodeCoverage.Enabled.Value
    Set-GitHubOutput -Name 'CodeCoverageOutputPath' -Value $codeCoverageOutputFolderPath
    Set-GitHubOutput -Name 'Executed' -Value $testResults.Executed
    Set-GitHubOutput -Name 'Result' -Value $testResults.Result
    Set-GitHubOutput -Name 'FailedCount' -Value $testResults.FailedCount
    Set-GitHubOutput -Name 'FailedBlocksCount' -Value $testResults.FailedBlocksCount
    Set-GitHubOutput -Name 'FailedContainersCount' -Value $testResults.FailedContainersCount
    Set-GitHubOutput -Name 'PassedCount' -Value $testResults.PassedCount
    Set-GitHubOutput -Name 'SkippedCount' -Value $testResults.SkippedCount
    Set-GitHubOutput -Name 'InconclusiveCount' -Value $testResults.InconclusiveCount
    Set-GitHubOutput -Name 'NotRunCount' -Value $testResults.NotRunCount
    Set-GitHubOutput -Name 'TotalCount' -Value $testResults.TotalCount

    if ($env:PSMODULE_INVOKE_PESTER_INPUT_ReportAsJson -eq 'true' -and $testResults.Configuration.TestResult.Enabled.Value) {
        $jsonOutputPath = $testResults.Configuration.TestResult.OutputPath.Value -Replace '\.xml$', '.json'
        Write-Output "Exporting test results to [$jsonOutputPath]"
        $testResults | Get-PesterTestTree | ConvertTo-Json -Depth 100 -Compress | Out-File -FilePath $jsonOutputPath
    }

    if ($env:PSMODULE_INVOKE_PESTER_INPUT_ReportAsJson -eq 'true' -and $testResults.Configuration.CodeCoverage.Enabled.Value) {
        $jsonOutputPath = $testResults.Configuration.CodeCoverage.OutputPath.Value -Replace '\.xml$', '.json'
        Write-Output "Exporting code coverage results to [$jsonOutputPath]"
        $testResults.CodeCoverage | ConvertTo-Json -Depth 100 -Compress | Out-File -FilePath $jsonOutputPath
    }
}

LogGroup 'Exit' {
    if ($testResults.Result -eq 'Passed') {
        Write-GitHubNotice '✅ All tests passed.'
        $script:exit = 0
    } else {
        if ($failedTests -gt 0) {
            Write-GitHubError "❌ Some [$failedTests] tests failed."
            $script:exit = $failedTests
        } else {
            Write-GitHubError '❌ Some tests failed.'
            $script:exit = 1
        }
    }
}

exit $script:exit
