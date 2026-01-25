$PSStyle.OutputRendering = 'Ansi'
$outcome = $env:PSMODULE_INVOKE_PESTER_INTERNAL_Outcome
$conclusion = $env:PSMODULE_INVOKE_PESTER_INTERNAL_Conclusion
$executed = $env:PSMODULE_INVOKE_PESTER_INTERNAL_Executed -eq 'true'
$result = $env:PSMODULE_INVOKE_PESTER_INTERNAL_Result
$failedCount = $env:PSMODULE_INVOKE_PESTER_INTERNAL_FailedCount
$failedBlocksCount = $env:PSMODULE_INVOKE_PESTER_INTERNAL_FailedBlocksCount
$failedContainersCount = $env:PSMODULE_INVOKE_PESTER_INTERNAL_FailedContainersCount
$passedCount = $env:PSMODULE_INVOKE_PESTER_INTERNAL_PassedCount
$skippedCount = $env:PSMODULE_INVOKE_PESTER_INTERNAL_SkippedCount
$inconclusiveCount = $env:PSMODULE_INVOKE_PESTER_INTERNAL_InconclusiveCount
$notRunCount = $env:PSMODULE_INVOKE_PESTER_INTERNAL_NotRunCount
$totalCount = $env:PSMODULE_INVOKE_PESTER_INTERNAL_TotalCount

"Executed=$executed" >> $env:GITHUB_OUTPUT

LogGroup 'Outputs' {
    [PSCustomObject]@{
        Outcome               = $outcome
        Conclusion            = $conclusion
        Executed              = $executed
        Result                = $result
        FailedCount           = $failedCount
        FailedBlocksCount     = $failedBlocksCount
        FailedContainersCount = $failedContainersCount
        PassedCount           = $passedCount
        SkippedCount          = $skippedCount
        InconclusiveCount     = $inconclusiveCount
        NotRunCount           = $notRunCount
        TotalCount            = $totalCount
    } | Format-List | Out-String
}
# If the tests did not execute, exit with a failure code
if ($executed -ne 'true') {
    Write-Error 'Tests did not execute.'
    exit 1
}
# If the outcome is not success, exit with a failure code
if ($outcome -ne 'success') {
    Write-Error 'Tests did not pass.'
    exit 1
}
# If the conclusion is not success
if ($conclusion -ne 'success') {
    Write-Error 'Tests did not pass.'
    exit 1
}
