[CmdletBinding()]
param()

LogGroup 'Exec - Setup prerequisites' {
    $PSModuleAutoLoadingPreference = 'None'
    'Pester' | ForEach-Object {
        Install-PSResource -Name $_ -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
        Import-Module -Name $_
    }
    Import-Module "$PSScriptRoot/Helpers.psm1"
}

LogGroup 'Exec - Get test kit versions' {
    $pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

    [PSCustomObject]@{
        PowerShell = $PSVersionTable.PSVersion.ToString()
        Pester     = $pesterModule.Version
    } | Format-List
}

LogGroup 'Exec - Import Configuration' {
    $configuration = & "$PSScriptRoot/Invoke-Pester.Configuration.ps1"
    $configuration
    $containerFiles = Get-ChildItem -Path $PSScriptRoot -Filter *.Container.* -Recurse
    $configuration.Run.Container = @()
    foreach ($containerFile in $containerFiles) {
        $container = & $containerFile.FullName
        Write-Verbose "Processing container [$container]" -Verbose
        Write-Verbose 'Converting hashtable to PesterContainer' -Verbose
        $configuration.Run.Container += New-PesterContainer @container
    }
    $configuration.Run.Container
}

$configuration = New-PesterConfiguration -Hashtable $configuration

$testResults = Invoke-Pester -Configuration $configuration

$testResults
