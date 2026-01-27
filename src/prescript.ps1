<#
    .DESCRIPTION
    Executes a prescript that can be either an inline script or a path to a script file.
    Safely handles both cases by checking if the input is a valid file path first.
#>

[CmdletBinding()]
param()

$prescript = $env:PSMODULE_INVOKE_PESTER_INPUT_Prescript

# Exit early if prescript is null or empty
if ([string]::IsNullOrWhiteSpace($prescript)) {
    Write-Verbose 'No prescript provided, skipping execution.'
    return
}

Write-Host '::group::Prescript - Execution'

# Check if the prescript is a path to an existing file
if (Test-Path -Path $prescript -PathType Leaf) {
    $scriptPath = Resolve-Path -Path $prescript
    Write-Host "Executing prescript from file: [$scriptPath]"
    & $scriptPath
} else {
    Write-Host 'Executing inline prescript'
    # Use ScriptBlock::Create for safer execution than Invoke-Expression
    $scriptBlock = [scriptblock]::Create($prescript)
    & $scriptBlock
}

Write-Host '::endgroup::'
