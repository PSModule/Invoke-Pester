[CmdletBinding()]
param(
    [Parameter()]
    [string] $Subject = $env:GITHUB_ACTION_INPUT_subject
)

Write-Host "Hello, $subject!"
