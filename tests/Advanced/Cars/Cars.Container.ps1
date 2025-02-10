@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1
    Data = @{
        Path    = Get-ChildItem -Path $PSScriptRoot -Filter *.Data.ps1
        Debug   = $false
        Verbose = $false
    }
}
