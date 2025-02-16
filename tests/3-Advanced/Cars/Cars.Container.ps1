@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path    = Get-ChildItem -Path $PSScriptRoot -Filter *.Data.ps1 | Select-Object -ExpandProperty FullName
        Debug   = $false
        Verbose = $false
    }
}
