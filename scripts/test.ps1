# Run all files with the name like *.Containers.ps1 in the current directory recursively.

function Get-PesterContainer {
    param(
        [string] $Path
    )

    Get-ChildItem -Path $Path -Recurse -Filter *.Container.ps* | ForEach-Object {
        $file = $_
        $param = switch ($file.Extension) {
            '.ps1' {
                . $file
            }
            '.psd1' {
                Import-PowerShellDataFile -Path $file
            }
        }
        New-PesterContainer @param
    }
}

function Get-PesterConfiguration {
    param(
        [string] $Path
    )

    $config = Get-ChildItem -Path $Path -Filter *.Configuration.ps* | ForEach-Object {
        $file = $_
        switch ($file.Extension) {
            '.ps1' {
                . $file
            }
            '.psd1' {
                Import-PowerShellDataFile -Path $file
            }
        }
    }
    New-PesterConfiguration -Hashtable $config
}


$Path = 'C:\Repos\GitHub\PSModule\Action\Invoke-Pester\tests\Advanced'
$containers = Get-PesterContainer -Path $Path


$Configuration = Get-PesterConfiguration -Path $Path
$Configuration.Run.Container = $containers

$Configuration.Run.Container.Value


$Configuration | Convertto-Json -Depth 100 | Clip
$Configuration.Container | ConvertTo-Json -Depth 100 | Clip

Invoke-Pester -Configuration $Configuration
