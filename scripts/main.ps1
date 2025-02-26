[CmdletBinding()]
param()

'::group::Exec - Setup prerequisites'
'Pester' | ForEach-Object {
    Install-PSResource -Name $_ -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
    Import-Module -Name $_
}
Import-Module "$PSScriptRoot/Helpers.psm1"
Get-Module
'::endgroup::'

'::group::Exec - Get test kit versions'
$pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

[PSCustomObject]@{
    PowerShell = $PSVersionTable.PSVersion.ToString()
    Pester     = $pesterModule.Version
} | Format-List
'::endgroup::'

'::group::Exec - Import Configuration'
$configuration = & "$PSScriptRoot/Invoke-Pester.Configuration.ps1"
$configuration
$configuration.Run.Container = @()
$containerFiles = Get-ChildItem -Path $PSScriptRoot -Filter *.Container.* -Recurse
foreach ($containerFile in $containerFiles) {
    $container = & $($containerFile.FullName)
    Write-Verbose "Processing container [$container]" -Verbose
    Write-Verbose 'Converting hashtable to PesterContainer' -Verbose
    $configuration.Run.Container += New-PesterContainer @container
}
$configuration.Run.Container | ConvertTo-Json
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

    $testResults | Format-List
}

LogGroup 'Eval - Test results summary' {
    Set-GitHubStepSummary -Summary ($testResults | Set-PesterReportSummary)
}

LogGroup 'Eval - Set outputs' {
    Set-GitHubOutput -Name 'TestSuiteName' -Value $testResults.Configuration.TestResult.TestSuiteName.Value
    Set-GitHubOutput -Name 'TestResultEnabled' -Value $testResults.Configuration.TestResult.Enabled.Value
    Set-GitHubOutput -Name 'TestResultOutputPath' -Value $testResults.Configuration.TestResult.OutputPath.Value
    Set-GitHubOutput -Name 'CodeCoverageEnabled' -Value $testResults.Configuration.CodeCoverage.Enabled.Value
    Set-GitHubOutput -Name 'CodeCoverageOutputPath' -Value $testResults.Configuration.CodeCoverage.OutputPath.Value
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
