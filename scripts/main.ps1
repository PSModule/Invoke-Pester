[CmdletBinding()]
param()

LogGroup 'Setup prerequisites' {
    $PSModuleAutoLoadingPreference = 'None'
    'Pester' | ForEach-Object {
        Install-PSResource -Name $_ -Verbose:$false -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
        Import-Module -Name $_ -Verbose:$false
    }
    Import-Module "$PSScriptRoot/Helpers.psm1"
}

LogGroup 'Get test kit versions' {
    $pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

    [PSCustomObject]@{
        PowerShell = $PSVersionTable.PSVersion.ToString()
        Pester     = $pesterModule.Version
    } | Format-List
}

$configuration = Import-Hashtable -Path "$PSScriptRoot/Invoke-Pester.Configuration.ps1"
$configuration = New-PesterConfiguration -Hashtable $configuration
$configurationHashtable = $configuration | Convert-PesterConfigurationToHashtable | Format-Hashtable | Out-String
Write-Output $configurationHashtable

$testResults = Invoke-Pester -Configuration $configuration
