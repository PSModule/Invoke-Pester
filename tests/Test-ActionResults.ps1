<#
    .DESCRIPTION
    Aggregates and validates test results from all Action-Test workflow jobs.
    Compares actual outcomes against expected values and generates a summary report.
#>

[CmdletBinding()]
param()

# Install and import the Markdown module for generating summary tables
'Markdown' | ForEach-Object {
    $name = $_
    Write-Output "Installing module: $name"
    $retryCount = 5
    $retryDelay = 10
    for ($i = 0; $i -lt $retryCount; $i++) {
        try {
            Install-PSResource -Name $name -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
            break
        } catch {
            Write-Warning "Installation of $name failed with error: $_"
            if ($i -eq $retryCount - 1) {
                throw
            }
            Write-Warning "Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
        }
    }
    Import-Module -Name $name
}

# Build test job objects with expected vs actual values
$jobs = @(
    @{
        Name       = 'Action-Test - [1-Simple]'
        Outcome    = @{ Actual = $env:ACTIONTEST1SIMPLE_OUTCOME; Expected = 'success' }
        Conclusion = @{ Actual = $env:ACTIONTEST1SIMPLE_CONCLUSION; Expected = 'success' }
        Executed   = @{ Actual = $env:ACTIONTEST1SIMPLE_EXECUTED; Expected = 'True' }
        Result     = @{ Actual = $env:ACTIONTEST1SIMPLE_RESULT; Expected = 'Passed' }
    }
    @{
        Name       = 'Action-Test - [1-Simple-File]'
        Outcome    = @{ Actual = $env:ACTIONTEST1SIMPLEFILE_OUTCOME; Expected = 'success' }
        Conclusion = @{ Actual = $env:ACTIONTEST1SIMPLEFILE_CONCLUSION; Expected = 'success' }
        Executed   = @{ Actual = $env:ACTIONTEST1SIMPLEFILE_EXECUTED; Expected = 'True' }
        Result     = @{ Actual = $env:ACTIONTEST1SIMPLEFILE_RESULT; Expected = 'Passed' }
    }
    @{
        Name       = 'Action-Test - [1-Simple-Failure]'
        Outcome    = @{ Actual = $env:ACTIONTEST1SIMPLEFAILURE_OUTCOME; Expected = 'failure' }
        Conclusion = @{ Actual = $env:ACTIONTEST1SIMPLEFAILURE_CONCLUSION; Expected = 'success' }
        Executed   = @{ Actual = $env:ACTIONTEST1SIMPLEFAILURE_EXECUTED; Expected = 'True' }
        Result     = @{ Actual = $env:ACTIONTEST1SIMPLEFAILURE_RESULT; Expected = 'Failed' }
    }
    @{
        Name       = 'Action-Test - [1-Simple-Failure-OnlyFailedSummary]'
        Outcome    = @{ Actual = $env:ACTIONTEST1SIMPLEFAILUREONLYFAILEDSUMMARY_OUTCOME; Expected = 'failure' }
        Conclusion = @{ Actual = $env:ACTIONTEST1SIMPLEFAILUREONLYFAILEDSUMMARY_CONCLUSION; Expected = 'success' }
        Executed   = @{ Actual = $env:ACTIONTEST1SIMPLEFAILUREONLYFAILEDSUMMARY_EXECUTED; Expected = 'True' }
        Result     = @{ Actual = $env:ACTIONTEST1SIMPLEFAILUREONLYFAILEDSUMMARY_RESULT; Expected = 'Failed' }
    }
    @{
        Name       = 'Action-Test - [1-Simple-ExecutionFailure]'
        Outcome    = @{ Actual = $env:ACTIONTEST1SIMPLEEXECUTIONFAILURE_OUTCOME; Expected = 'failure' }
        Conclusion = @{ Actual = $env:ACTIONTEST1SIMPLEEXECUTIONFAILURE_CONCLUSION; Expected = 'success' }
        Executed   = @{ Actual = $env:ACTIONTEST1SIMPLEEXECUTIONFAILURE_EXECUTED; Expected = 'False' }
        Result     = @{ Actual = $env:ACTIONTEST1SIMPLEEXECUTIONFAILURE_RESULT; Expected = '' }
    }
    @{
        Name       = 'Action-Test - [2-Standard]'
        Outcome    = @{ Actual = $env:ACTIONTEST2STANDARD_OUTCOME; Expected = 'success' }
        Conclusion = @{ Actual = $env:ACTIONTEST2STANDARD_CONCLUSION; Expected = 'success' }
        Executed   = @{ Actual = $env:ACTIONTEST2STANDARD_EXECUTED; Expected = 'True' }
        Result     = @{ Actual = $env:ACTIONTEST2STANDARD_RESULT; Expected = 'Passed' }
    }
    @{
        Name       = 'Action-Test - [2-Standard-PrescriptFile]'
        Outcome    = @{ Actual = $env:ACTIONTEST2STANDARDPRESCRIPTFILE_OUTCOME; Expected = 'success' }
        Conclusion = @{ Actual = $env:ACTIONTEST2STANDARDPRESCRIPTFILE_CONCLUSION; Expected = 'success' }
        Executed   = @{ Actual = $env:ACTIONTEST2STANDARDPRESCRIPTFILE_EXECUTED; Expected = 'True' }
        Result     = @{ Actual = $env:ACTIONTEST2STANDARDPRESCRIPTFILE_RESULT; Expected = 'Passed' }
    }
    @{
        Name       = 'Action-Test - [2-Standard-NoSummary]'
        Outcome    = @{ Actual = $env:ACTIONTEST2STANDARDNOSUMMARY_OUTCOME; Expected = 'success' }
        Conclusion = @{ Actual = $env:ACTIONTEST2STANDARDNOSUMMARY_CONCLUSION; Expected = 'success' }
        Executed   = @{ Actual = $env:ACTIONTEST2STANDARDNOSUMMARY_EXECUTED; Expected = 'True' }
        Result     = @{ Actual = $env:ACTIONTEST2STANDARDNOSUMMARY_RESULT; Expected = 'Passed' }
    }
    @{
        Name       = 'Action-Test - [3-Advanced]'
        Outcome    = @{ Actual = $env:ACTIONTEST3ADVANCED_OUTCOME; Expected = 'success' }
        Conclusion = @{ Actual = $env:ACTIONTEST3ADVANCED_CONCLUSION; Expected = 'success' }
        Executed   = @{ Actual = $env:ACTIONTEST3ADVANCED_EXECUTED; Expected = 'True' }
        Result     = @{ Actual = $env:ACTIONTEST3ADVANCED_RESULT; Expected = 'Passed' }
    }
)

# Add Pass property to each check and convert to PSCustomObject for table output
$results = $jobs | ForEach-Object {
    [PSCustomObject]@{
        Name               = $_.Name
        Outcome            = $_.Outcome.Actual
        OutcomeExpected    = $_.Outcome.Expected
        OutcomePass        = $_.Outcome.Actual -eq $_.Outcome.Expected
        Conclusion         = $_.Conclusion.Actual
        ConclusionExpected = $_.Conclusion.Expected
        ConclusionPass     = $_.Conclusion.Actual -eq $_.Conclusion.Expected
        Executed           = $_.Executed.Actual
        ExecutedExpected   = $_.Executed.Expected
        ExecutedPass       = $_.Executed.Actual -eq $_.Executed.Expected
        Result             = $_.Result.Actual
        ResultExpected     = $_.Result.Expected
        ResultPass         = $_.Result.Actual -eq $_.Result.Expected
    }
}

# Display the table in the workflow logs
$results | Format-List | Out-String

$passed = $true
foreach ($job in $results) {
    if (-not $job.OutcomePass) {
        Write-Error "Job $($job.Name) failed with Outcome $($job.Outcome) and Expected Outcome $($job.OutcomeExpected)"
        $passed = $false
    }

    if (-not $job.ConclusionPass) {
        Write-Error "Job $($job.Name) failed with Conclusion $($job.Conclusion) and Expected Conclusion $($job.ConclusionExpected)"
        $passed = $false
    }

    if (-not $job.ExecutedPass) {
        Write-Error "Job $($job.Name) not executed as expected. (Actual: $($job.Executed), Expected: $($job.ExecutedExpected))"
        $passed = $false
    }

    if (-not $job.ResultPass) {
        Write-Error "Job $($job.Name) tests did not pass as expected. (Actual: $($job.Result), Expected: $($job.ResultExpected))"
        $passed = $false
    }
}

$icon = if ($passed) { '✅' } else { '❌' }
$status = Heading 1 "$icon - GitHub Actions Status" {
    Table {
        $results
    }
}

Set-GitHubStepSummary -Summary $status

if (-not $passed) {
    Write-GitHubError 'One or more jobs failed'
    exit 1
}
