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

# Build an array of objects for each job using environment variables
$ActionTest1SimpleOutcome = $env:ACTIONTEST1SIMPLE_OUTCOME
$ActionTest1SimpleOutcomeExpected = 'success'
$ActionTest1SimpleOutcomeResult = $ActionTest1SimpleOutcome -eq $ActionTest1SimpleOutcomeExpected
$ActionTest1SimpleConclusion = $env:ACTIONTEST1SIMPLE_CONCLUSION
$ActionTest1SimpleConclusionExpected = 'success'
$ActionTest1SimpleConclusionResult = $ActionTest1SimpleConclusion -eq $ActionTest1SimpleConclusionExpected
$ActionTest1SimpleExecuted = $env:ACTIONTEST1SIMPLE_EXECUTED
$ActionTest1SimpleExecutedExpected = 'True'
$ActionTest1SimpleExecutedResult = $ActionTest1SimpleExecuted -eq $ActionTest1SimpleExecutedExpected
$ActionTest1SimpleResult = $env:ACTIONTEST1SIMPLE_RESULT
$ActionTest1SimpleResultExpected = 'Passed'
$ActionTest1SimpleResultResult = $ActionTest1SimpleResult -eq $ActionTest1SimpleResultExpected

$ActionTest1SimpleFileOutcome = $env:ACTIONTEST1SIMPLEFILE_OUTCOME
$ActionTest1SimpleFileOutcomeExpected = 'success'
$ActionTest1SimpleFileOutcomeResult = $ActionTest1SimpleFileOutcome -eq $ActionTest1SimpleFileOutcomeExpected
$ActionTest1SimpleFileConclusion = $env:ACTIONTEST1SIMPLEFILE_CONCLUSION
$ActionTest1SimpleFileConclusionExpected = 'success'
$ActionTest1SimpleFileConclusionResult = $ActionTest1SimpleFileConclusion -eq $ActionTest1SimpleFileConclusionExpected
$ActionTest1SimpleFileExecuted = $env:ACTIONTEST1SIMPLEFILE_EXECUTED
$ActionTest1SimpleFileExecutedExpected = 'True'
$ActionTest1SimpleFileExecutedResult = $ActionTest1SimpleFileExecuted -eq $ActionTest1SimpleFileExecutedExpected
$ActionTest1SimpleFileResult = $env:ACTIONTEST1SIMPLEFILE_RESULT
$ActionTest1SimpleFileResultExpected = 'Passed'
$ActionTest1SimpleFileResultResult = $ActionTest1SimpleFileResult -eq $ActionTest1SimpleFileResultExpected

$ActionTest1SimpleFailureOutcome = $env:ACTIONTEST1SIMPLEFAILURE_OUTCOME
$ActionTest1SimpleFailureOutcomeExpected = 'failure'
$ActionTest1SimpleFailureOutcomeResult = $ActionTest1SimpleFailureOutcome -eq $ActionTest1SimpleFailureOutcomeExpected
$ActionTest1SimpleFailureConclusion = $env:ACTIONTEST1SIMPLEFAILURE_CONCLUSION
$ActionTest1SimpleFailureConclusionExpected = 'success'
$ActionTest1SimpleFailureConclusionResult = $ActionTest1SimpleFailureConclusion -eq $ActionTest1SimpleFailureConclusionExpected
$ActionTest1SimpleFailureExecuted = $env:ACTIONTEST1SIMPLEFAILURE_EXECUTED
$ActionTest1SimpleFailureExecutedExpected = 'True'
$ActionTest1SimpleFailureExecutedResult = $ActionTest1SimpleFailureExecuted -eq $ActionTest1SimpleFailureExecutedExpected
$ActionTest1SimpleFailureResult = $env:ACTIONTEST1SIMPLEFAILURE_RESULT
$ActionTest1SimpleFailureResultExpected = 'Failed'
$ActionTest1SimpleFailureResultResult = $ActionTest1SimpleFailureResult -eq $ActionTest1SimpleFailureResultExpected

$ActionTest1SimpleFailureOnlyFailedSummaryOutcome = $env:ACTIONTEST1SIMPLEFAILUREONLYFAILEDSUMMARY_OUTCOME
$ActionTest1SimpleFailureOnlyFailedSummaryOutcomeExpected = 'failure'
$ActionTest1SimpleFailureOnlyFailedSummaryOutcomeResult = $ActionTest1SimpleFailureOnlyFailedSummaryOutcome -eq $ActionTest1SimpleFailureOnlyFailedSummaryOutcomeExpected
$ActionTest1SimpleFailureOnlyFailedSummaryConclusion = $env:ACTIONTEST1SIMPLEFAILUREONLYFAILEDSUMMARY_CONCLUSION
$ActionTest1SimpleFailureOnlyFailedSummaryonclusionExpected = 'success'
$ActionTest1SimpleFailureOnlyFailedSummaryonclusionResult = $ActionTest1SimpleFailureOnlyFailedSummaryConclusion -eq $ActionTest1SimpleFailureOnlyFailedSummaryonclusionExpected
$ActionTest1SimpleFailureOnlyFailedSummaryExecuted = $env:ACTIONTEST1SIMPLEFAILUREONLYFAILEDSUMMARY_EXECUTED
$ActionTest1SimpleFailureOnlyFailedSummaryExecutedExpected = 'True'
$ActionTest1SimpleFailureOnlyFailedSummaryExecutedResult = $ActionTest1SimpleFailureOnlyFailedSummaryExecuted -eq $ActionTest1SimpleFailureOnlyFailedSummaryExecutedExpected
$ActionTest1SimpleFailureOnlyFailedSummaryResult = $env:ACTIONTEST1SIMPLEFAILUREONLYFAILEDSUMMARY_RESULT
$ActionTest1SimpleFailureOnlyFailedSummaryResultExpected = 'Failed'
$ActionTest1SimpleFailureOnlyFailedSummaryResultResult = $ActionTest1SimpleFailureOnlyFailedSummaryResult -eq $ActionTest1SimpleFailureOnlyFailedSummaryResultExpected

$ActionTest1SimpleExecutionFailureOutcome = $env:ACTIONTEST1SIMPLEEXECUTIONFAILURE_OUTCOME
$ActionTest1SimpleExecutionFailureOutcomeExpected = 'failure'
$ActionTest1SimpleExecutionFailureOutcomeResult = $ActionTest1SimpleExecutionFailureOutcome -eq $ActionTest1SimpleExecutionFailureOutcomeExpected
$ActionTest1SimpleExecutionFailureConclusion = $env:ACTIONTEST1SIMPLEEXECUTIONFAILURE_CONCLUSION
$ActionTest1SimpleExecutionFailureConclusionExpected = 'success'
$ActionTest1SimpleExecutionFailureConclusionResult = $ActionTest1SimpleExecutionFailureConclusion -eq $ActionTest1SimpleExecutionFailureConclusionExpected
$ActionTest1SimpleExecutionFailureExecuted = $env:ACTIONTEST1SIMPLEEXECUTIONFAILURE_EXECUTED
$ActionTest1SimpleExecutionFailureExecutedExpected = 'False'
$ActionTest1SimpleExecutionFailureExecutedResult = $ActionTest1SimpleExecutionFailureExecuted -eq $ActionTest1SimpleExecutionFailureExecutedExpected
$ActionTest1SimpleExecutionFailureResult = $env:ACTIONTEST1SIMPLEEXECUTIONFAILURE_RESULT
$ActionTest1SimpleExecutionFailureResultExpected = ''
$ActionTest1SimpleExecutionFailureResultResult = $ActionTest1SimpleExecutionFailureResult -eq $ActionTest1SimpleExecutionFailureResultExpected

$ActionTest2StandardOutcome = $env:ACTIONTEST2STANDARD_OUTCOME
$ActionTest2StandardOutcomeExpected = 'success'
$ActionTest2StandardOutcomeResult = $ActionTest2StandardOutcome -eq $ActionTest2StandardOutcomeExpected
$ActionTest2StandardConclusion = $env:ACTIONTEST2STANDARD_CONCLUSION
$ActionTest2StandardConclusionExpected = 'success'
$ActionTest2StandardConclusionResult = $ActionTest2StandardConclusion -eq $ActionTest2StandardConclusionExpected
$ActionTest2StandardExecuted = $env:ACTIONTEST2STANDARD_EXECUTED
$ActionTest2StandardExecutedExpected = 'True'
$ActionTest2StandardExecutedResult = $ActionTest2StandardExecuted -eq $ActionTest2StandardExecutedExpected
$ActionTest2StandardResult = $env:ACTIONTEST2STANDARD_RESULT
$ActionTest2StandardResultExpected = 'Passed'
$ActionTest2StandardResultResult = $ActionTest2StandardResult -eq $ActionTest2StandardResultExpected

$ActionTest2StandardPrescriptFileOutcome = $env:ACTIONTEST2STANDARDPRESCRIPTFILE_OUTCOME
$ActionTest2StandardPrescriptFileOutcomeExpected = 'success'
$ActionTest2StandardPrescriptFileOutcomeResult = $ActionTest2StandardPrescriptFileOutcome -eq $ActionTest2StandardPrescriptFileOutcomeExpected
$ActionTest2StandardPrescriptFileConclusion = $env:ACTIONTEST2STANDARDPRESCRIPTFILE_CONCLUSION
$ActionTest2StandardPrescriptFileConclusionExpected = 'success'
$ActionTest2StandardPrescriptFileConclusionResult = $ActionTest2StandardPrescriptFileConclusion -eq $ActionTest2StandardPrescriptFileConclusionExpected
$ActionTest2StandardPrescriptFileExecuted = $env:ACTIONTEST2STANDARDPRESCRIPTFILE_EXECUTED
$ActionTest2StandardPrescriptFileExecutedExpected = 'True'
$ActionTest2StandardPrescriptFileExecutedResult = $ActionTest2StandardPrescriptFileExecuted -eq $ActionTest2StandardPrescriptFileExecutedExpected
$ActionTest2StandardPrescriptFileResult = $env:ACTIONTEST2STANDARDPRESCRIPTFILE_RESULT
$ActionTest2StandardPrescriptFileResultExpected = 'Passed'
$ActionTest2StandardPrescriptFileResultResult = $ActionTest2StandardPrescriptFileResult -eq $ActionTest2StandardPrescriptFileResultExpected

$ActionTest2StandardNoSummaryOutcome = $env:ACTIONTEST2STANDARDNOSUMMARY_OUTCOME
$ActionTest2StandardNoSummaryOutcomeExpected = 'success'
$ActionTest2StandardNoSummaryOutcomeResult = $ActionTest2StandardNoSummaryOutcome -eq $ActionTest2StandardNoSummaryOutcomeExpected
$ActionTest2StandardNoSummaryConclusion = $env:ACTIONTEST2STANDARDNOSUMMARY_CONCLUSION
$ActionTest2StandardNoSummaryConclusionExpected = 'success'
$ActionTest2StandardNoSummaryConclusionResult = $ActionTest2StandardNoSummaryConclusion -eq $ActionTest2StandardNoSummaryConclusionExpected
$ActionTest2StandardNoSummaryExecuted = $env:ACTIONTEST2STANDARDNOSUMMARY_EXECUTED
$ActionTest2StandardNoSummaryExecutedExpected = 'True'
$ActionTest2StandardNoSummaryExecutedResult = $ActionTest2StandardNoSummaryExecuted -eq $ActionTest2StandardNoSummaryExecutedExpected
$ActionTest2StandardNoSummaryResult = $env:ACTIONTEST2STANDARDNOSUMMARY_RESULT
$ActionTest2StandardNoSummaryResultExpected = 'Passed'
$ActionTest2StandardNoSummaryResultResult = $ActionTest2StandardNoSummaryResult -eq $ActionTest2StandardNoSummaryResultExpected

$ActionTest3AdvancedOutcome = $env:ACTIONTEST3ADVANCED_OUTCOME
$ActionTest3AdvancedOutcomeExpected = 'success'
$ActionTest3AdvancedOutcomeResult = $ActionTest3AdvancedOutcome -eq $ActionTest3AdvancedOutcomeExpected
$ActionTest3AdvancedConclusion = $env:ACTIONTEST3ADVANCED_CONCLUSION
$ActionTest3AdvancedConclusionExpected = 'success'
$ActionTest3AdvancedConclusionResult = $ActionTest3AdvancedConclusion -eq $ActionTest3AdvancedConclusionExpected
$ActionTest3AdvancedExecuted = $env:ACTIONTEST3ADVANCED_EXECUTED
$ActionTest3AdvancedExecutedExpected = 'True'
$ActionTest3AdvancedExecutedResult = $ActionTest3AdvancedExecuted -eq $ActionTest3AdvancedExecutedExpected
$ActionTest3AdvancedResult = $env:ACTIONTEST3ADVANCED_RESULT
$ActionTest3AdvancedResultExpected = 'Passed'
$ActionTest3AdvancedResultResult = $ActionTest3AdvancedResult -eq $ActionTest3AdvancedResultExpected

$jobs = @(
    [PSCustomObject]@{
        Name               = 'Action-Test - [1-Simple]'
        Outcome            = $ActionTest1SimpleOutcome
        OutcomeExpected    = $ActionTest1SimpleOutcomeExpected
        OutcomeResult      = $ActionTest1SimpleOutcomeResult
        Conclusion         = $ActionTest1SimpleConclusion
        ConclusionExpected = $ActionTest1SimpleConclusionExpected
        ConclusionResult   = $ActionTest1SimpleConclusionResult
        Executed           = $ActionTest1SimpleExecuted
        ExecutedExpected   = $ActionTest1SimpleExecutedExpected
        ExecutedResult     = $ActionTest1SimpleExecutedResult
        Result             = $ActionTest1SimpleResult
        ResultExpected     = $ActionTest1SimpleResultExpected
        ResultResult       = $ActionTest1SimpleResultResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [1-Simple-File]'
        Outcome            = $ActionTest1SimpleFileOutcome
        OutcomeExpected    = $ActionTest1SimpleFileOutcomeExpected
        OutcomeResult      = $ActionTest1SimpleFileOutcomeResult
        Conclusion         = $ActionTest1SimpleFileConclusion
        ConclusionExpected = $ActionTest1SimpleFileConclusionExpected
        ConclusionResult   = $ActionTest1SimpleFileConclusionResult
        Executed           = $ActionTest1SimpleFileExecuted
        ExecutedExpected   = $ActionTest1SimpleFileExecutedExpected
        ExecutedResult     = $ActionTest1SimpleFileExecutedResult
        Result             = $ActionTest1SimpleFileResult
        ResultExpected     = $ActionTest1SimpleFileResultExpected
        ResultResult       = $ActionTest1SimpleFileResultResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [1-Simple-Failure]'
        Outcome            = $ActionTest1SimpleFailureOutcome
        OutcomeExpected    = $ActionTest1SimpleFailureOutcomeExpected
        OutcomeResult      = $ActionTest1SimpleFailureOutcomeResult
        Conclusion         = $ActionTest1SimpleFailureConclusion
        ConclusionExpected = $ActionTest1SimpleFailureConclusionExpected
        ConclusionResult   = $ActionTest1SimpleFailureConclusionResult
        Executed           = $ActionTest1SimpleFailureExecuted
        ExecutedExpected   = $ActionTest1SimpleFailureExecutedExpected
        ExecutedResult     = $ActionTest1SimpleFailureExecutedResult
        Result             = $ActionTest1SimpleFailureResult
        ResultExpected     = $ActionTest1SimpleFailureResultExpected
        ResultResult       = $ActionTest1SimpleFailureResultResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [1-Simple-Failure-OnlyFailedSummary]'
        Outcome            = $ActionTest1SimpleFailureOnlyFailedSummaryOutcome
        OutcomeExpected    = $ActionTest1SimpleFailureOnlyFailedSummaryOutcomeExpected
        OutcomeResult      = $ActionTest1SimpleFailureOnlyFailedSummaryOutcomeResult
        Conclusion         = $ActionTest1SimpleFailureOnlyFailedSummaryConclusion
        ConclusionExpected = $ActionTest1SimpleFailureOnlyFailedSummaryonclusionExpected
        ConclusionResult   = $ActionTest1SimpleFailureOnlyFailedSummaryonclusionResult
        Executed           = $ActionTest1SimpleFailureOnlyFailedSummaryExecuted
        ExecutedExpected   = $ActionTest1SimpleFailureOnlyFailedSummaryExecutedExpected
        ExecutedResult     = $ActionTest1SimpleFailureOnlyFailedSummaryExecutedResult
        Result             = $ActionTest1SimpleFailureOnlyFailedSummaryResult
        ResultExpected     = $ActionTest1SimpleFailureOnlyFailedSummaryResultExpected
        ResultResult       = $ActionTest1SimpleFailureOnlyFailedSummaryResultResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [1-Simple-ExecutionFailure]'
        Outcome            = $ActionTest1SimpleExecutionFailureOutcome
        OutcomeExpected    = $ActionTest1SimpleExecutionFailureOutcomeExpected
        OutcomeResult      = $ActionTest1SimpleExecutionFailureOutcomeResult
        Conclusion         = $ActionTest1SimpleExecutionFailureConclusion
        ConclusionExpected = $ActionTest1SimpleExecutionFailureConclusionExpected
        ConclusionResult   = $ActionTest1SimpleExecutionFailureConclusionResult
        Executed           = $ActionTest1SimpleExecutionFailureExecuted
        ExecutedExpected   = $ActionTest1SimpleExecutionFailureExecutedExpected
        ExecutedResult     = $ActionTest1SimpleExecutionFailureExecutedResult
        Result             = $ActionTest1SimpleExecutionFailureResult
        ResultExpected     = $ActionTest1SimpleExecutionFailureResultExpected
        ResultResult       = $ActionTest1SimpleExecutionFailureResultResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [2-Standard]'
        Outcome            = $ActionTest2StandardOutcome
        OutcomeExpected    = $ActionTest2StandardOutcomeExpected
        OutcomeResult      = $ActionTest2StandardOutcomeResult
        Conclusion         = $ActionTest2StandardConclusion
        ConclusionExpected = $ActionTest2StandardConclusionExpected
        ConclusionResult   = $ActionTest2StandardConclusionResult
        Executed           = $ActionTest2StandardExecuted
        ExecutedExpected   = $ActionTest2StandardExecutedExpected
        ExecutedResult     = $ActionTest2StandardExecutedResult
        Result             = $ActionTest2StandardResult
        ResultExpected     = $ActionTest2StandardResultExpected
        ResultResult       = $ActionTest2StandardResultResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [2-Standard-PrescriptFile]'
        Outcome            = $ActionTest2StandardPrescriptFileOutcome
        OutcomeExpected    = $ActionTest2StandardPrescriptFileOutcomeExpected
        OutcomeResult      = $ActionTest2StandardPrescriptFileOutcomeResult
        Conclusion         = $ActionTest2StandardPrescriptFileConclusion
        ConclusionExpected = $ActionTest2StandardPrescriptFileConclusionExpected
        ConclusionResult   = $ActionTest2StandardPrescriptFileConclusionResult
        Executed           = $ActionTest2StandardPrescriptFileExecuted
        ExecutedExpected   = $ActionTest2StandardPrescriptFileExecutedExpected
        ExecutedResult     = $ActionTest2StandardPrescriptFileExecutedResult
        Result             = $ActionTest2StandardPrescriptFileResult
        ResultExpected     = $ActionTest2StandardPrescriptFileResultExpected
        ResultResult       = $ActionTest2StandardPrescriptFileResultResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [2-Standard-NoSummary]'
        Outcome            = $ActionTest2StandardNoSummaryOutcome
        OutcomeExpected    = $ActionTest2StandardNoSummaryOutcomeExpected
        OutcomeResult      = $ActionTest2StandardNoSummaryOutcomeResult
        Conclusion         = $ActionTest2StandardNoSummaryConclusion
        ConclusionExpected = $ActionTest2StandardNoSummaryConclusionExpected
        ConclusionResult   = $ActionTest2StandardNoSummaryConclusionResult
        Executed           = $ActionTest2StandardNoSummaryExecuted
        ExecutedExpected   = $ActionTest2StandardNoSummaryExecutedExpected
        ExecutedResult     = $ActionTest2StandardNoSummaryExecutedResult
        Result             = $ActionTest2StandardNoSummaryResult
        ResultExpected     = $ActionTest2StandardNoSummaryResultExpected
        ResultResult       = $ActionTest2StandardNoSummaryResultResult
    },
    [PSCustomObject]@{
        Name               = 'Action-Test - [3-Advanced]'
        Outcome            = $ActionTest3AdvancedOutcome
        OutcomeExpected    = $ActionTest3AdvancedOutcomeExpected
        OutcomeResult      = $ActionTest3AdvancedOutcomeResult
        Conclusion         = $ActionTest3AdvancedConclusion
        ConclusionExpected = $ActionTest3AdvancedConclusionExpected
        ConclusionResult   = $ActionTest3AdvancedConclusionResult
        Executed           = $ActionTest3AdvancedExecuted
        ExecutedExpected   = $ActionTest3AdvancedExecutedExpected
        ExecutedResult     = $ActionTest3AdvancedExecutedResult
        Result             = $ActionTest3AdvancedResult
        ResultExpected     = $ActionTest3AdvancedResultExpected
        ResultResult       = $ActionTest3AdvancedResultResult
    }
)

# Display the table in the workflow logs
$jobs | Format-List | Out-String

$passed = $true
$jobs | ForEach-Object {
    if (-not $_.OutcomeResult) {
        Write-Error "Job $($_.Name) failed with Outcome $($_.Outcome) and Expected Outcome $($_.OutcomeExpected)"
        $passed = $false
    }

    if (-not $_.ConclusionResult) {
        Write-Error "Job $($_.Name) failed with Conclusion $($_.Conclusion) and Expected Conclusion $($_.ConclusionExpected)"
        $passed = $false
    }

    if (-not $_.ExecutedResult) {
        Write-Error "Job $($_.Name) not executed as expected. (Actual: $($_.Executed), Expected: $($_.ExecutedExpected))"
        $passed = $false
    }

    if (-not $_.ResultResult) {
        Write-Error "Job $($_.Name) tests did not pass as expected. (Actual: $($_.Result), Expected: $($_.ResultExpected))"
        $passed = $false
    }
}

$icon = if ($passed) { '✅' } else { '❌' }
$status = Heading 1 "$icon - GitHub Actions Status" {
    Table {
        $jobs
    }
}

Set-GitHubStepSummary -Summary $status

if (-not $passed) {
    Write-GitHubError 'One or more jobs failed'
    exit 1
}
