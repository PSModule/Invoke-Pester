[CmdletBinding()]
param()

$PSStyle.OutputRendering = 'Ansi'

'::group::Exec - Setup prerequisites'
'Pester' | ForEach-Object {
    Install-PSResource -Name $_ -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
    Import-Module -Name $_
}
Import-Module "$PSScriptRoot/Helpers.psm1"
'::endgroup::'

'::group::Exec - Get test kit versions'
$pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

[PSCustomObject]@{
    PowerShell = $PSVersionTable.PSVersion.ToString()
    Pester     = $pesterModule.Version
} | Format-List
'::endgroup::'

'::group::Exec - Info about environment'
$path = Join-Path -Path $pwd.Path -ChildPath 'temp'
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
    'Pester', 'Hashtable', 'TimeSpan', 'Markdown' | ForEach-Object {
        Install-PSResource -Name $_ -Verbose:$false -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
        Import-Module -Name $_ -Verbose:$false
    }
    Import-Module "$PSScriptRoot/Helpers.psm1"
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
    Set-GitHubStepSummary -Summary ($testResults | Set-PesterReportSummary)
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

    if ($env:PSMODULE_INVOKE_PESTER_INPUT_ReportAsJson -eq 'true' -and $testResults.Configuration.TestResult.Enabled.Value) {
        $jsonOutputPath = $testResults.Configuration.TestResult.OutputPath.Value -Replace '\.xml$', '.json'
        Write-Output "Exporting test results to [$jsonOutputPath]"
        $testResults | Get-PesterTestTree | ConvertTo-Json -Depth 2 | Out-File -FilePath $jsonOutputPath
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
