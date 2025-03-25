[CmdletBinding()]
param()

$DebugPreference = $env:PSMODULE_INVOKE_PESTER_INPUT_Debug -eq 'true' ? 'Continue' : 'SilentlyContinue'
$VerbosePreference = $env:PSMODULE_INVOKE_PESTER_INPUT_Verbose -eq 'true' ? 'Continue' : 'SilentlyContinue'

$PSStyle.OutputRendering = 'Ansi'
$DebugPreference = $env:PSMODULE_INVOKE_PESTER_INPUT_Debug ? 'Continue' : 'SilentlyContinue'
$VerbosePreference = $env:PSMODULE_INVOKE_PESTER_INPUT_Verbose ? 'Continue' : 'SilentlyContinue'

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
$PSStyle.OutputRendering = 'Host' # Ensure propper XML rendering
$testResults = Invoke-Pester -Configuration $configuration
$PSStyle.OutputRendering = 'Ansi'

'::group::Eval - Setup prerequisites'
'Pester', 'Hashtable', 'TimeSpan', 'Markdown' | Install-PSResourceWithRetry
'::endgroup::'

'::group::Eval - Get test kit versions'
$pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

[PSCustomObject]@{
    PowerShell = $PSVersionTable.PSVersion.ToString()
    Pester     = $pesterModule.Version
} | Format-List
'::endgroup::'

'::group::Eval - Test results'
if ($null -eq $testResults) {
    '::error::❌ No test results were returned.'
    exit 1
}

$testResults | Format-List | Out-String
'::endgroup::'

'::group::Eval - Test results summary'
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
    $content = $testResults | Set-PesterReportSummary @summaryParams

    if ($content) {
        $content >> $env:GITHUB_STEP_SUMMARY
    } else {
        Write-Verbose 'No content to display in step summary'
    }
    $PSStyle.OutputRendering = 'Ansi'
} else {
    Write-Verbose 'Step summary has been disabled or no components are configured for display'
}
'::endgroup::'

'::group::Eval - Set outputs'
$testResultOutputFolderPath = $testResults.Configuration.TestResult.OutputPath.Value | Split-Path -Parent
$codeCoverageOutputFolderPath = $testResults.Configuration.CodeCoverage.OutputPath.Value | Split-Path -Parent
[pscustomobject]@{
    TestSuiteName          = $testResults.Configuration.TestResult.TestSuiteName.Value
    TestResultEnabled      = $testResults.Configuration.TestResult.Enabled.Value
    TestResultOutputPath   = $testResultOutputFolderPath
    CodeCoverageEnabled    = $testResults.Configuration.CodeCoverage.Enabled.Value
    CodeCoverageOutputPath = $codeCoverageOutputFolderPath
} | Format-List | Out-String
"TestSuiteName=$($testResults.Configuration.TestResult.TestSuiteName.Value)" >> $env:GITHUB_OUTPUT
"TestResultEnabled=$($testResults.Configuration.TestResult.Enabled.Value)" >> $env:GITHUB_OUTPUT
"TestResultOutputPath=$($testResultOutputFolderPath)" >> $env:GITHUB_OUTPUT
"CodeCoverageEnabled=$($testResults.Configuration.CodeCoverage.Enabled.Value)" >> $env:GITHUB_OUTPUT
"CodeCoverageOutputPath=$($codeCoverageOutputFolderPath)" >> $env:GITHUB_OUTPUT
"Executed=$($testResults.Executed)" >> $env:GITHUB_OUTPUT
"Result=$($testResults.Result)" >> $env:GITHUB_OUTPUT
"FailedCount=$($testResults.FailedCount)" >> $env:GITHUB_OUTPUT
"FailedBlocksCount=$($testResults.FailedBlocksCount)" >> $env:GITHUB_OUTPUT
"FailedContainersCount=$($testResults.FailedContainersCount)" >> $env:GITHUB_OUTPUT
"PassedCount=$($testResults.PassedCount)" >> $env:GITHUB_OUTPUT
"SkippedCount=$($testResults.SkippedCount)" >> $env:GITHUB_OUTPUT
"InconclusiveCount=$($testResults.InconclusiveCount)" >> $env:GITHUB_OUTPUT
"NotRunCount=$($testResults.NotRunCount)" >> $env:GITHUB_OUTPUT
"TotalCount=$($testResults.TotalCount)" >> $env:GITHUB_OUTPUT

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
'::endgroup::'

'::group::Exit'
if ($testResults.Result -eq 'Passed') {
    '::notice::✅ All tests passed.'
    $script:exit = 0
} else {
    if ($failedTests -gt 0) {
        "::error::❌ Some [$failedTests] tests failed."
        $script:exit = $failedTests
    } else {
        '::error::❌ Some tests failed.'
        $script:exit = 1
    }
}

exit $script:exit
