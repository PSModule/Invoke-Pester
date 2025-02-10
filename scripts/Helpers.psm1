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
