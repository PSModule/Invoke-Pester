$PSStyle.OutputRendering = 'Ansi'
$executed = $env:PSMODULE_INVOKE_PESTER_INTERNAL_Executed -eq 'true'
$outcome = $env:PSMODULE_INVOKE_PESTER_INTERNAL_Outcome
$conclusion = $env:PSMODULE_INVOKE_PESTER_INTERNAL_Conclusion

"Executed=$executed" >> $env:GITHUB_OUTPUT

[PSCustomObject]@{
    Executed   = $executed
    Outcome    = $outcome
    Conclusion = $conclusion
} | Format-List | Out-String

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
