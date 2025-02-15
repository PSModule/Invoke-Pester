@{
    Run          = @{
        Path      = $PSScriptRoot
        Container = Get-ChildItem -Path $PSScriptRoot -Filter *.Container.* | ForEach-Object { . $_ } |
            ForEach-Object { New-PesterContainer @_ }
        PassThru  = $true
    }
    TestResult   = @{
        Enabled       = $true
        OutputPath    = 'outputs\AnotherPath.xml'
        TestSuiteName = 'Pester'
    }
    CodeCoverage = @{
        Path = 'Emoji.psm1'
    }
    Output       = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
