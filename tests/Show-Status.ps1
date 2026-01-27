<#
    .DESCRIPTION
        Displays the outcome and conclusion of an action step.
        Used by workflow tests to verify action execution results.
#>

[CmdletBinding()]
param()

Write-Host "Outcome: $env:OUTCOME"
Write-Host "Conclusion: $env:CONCLUSION"
