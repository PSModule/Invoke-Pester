<#
    .DESCRIPTION
    Sample prescript file used for testing the file-based prescript execution.
#>

[CmdletBinding()]
param()

Write-Host 'This prescript was loaded from a file!'
Write-Host "Current working directory: $PWD"
