@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path    = Join-Path $PSScriptRoot -ChildPath 'Emoji.psm1'
        Debug   = $false
        Verbose = $false
    }
}
