@{
    Run        = @{
        Path      = $PSScriptRoot
        Container = Get-ChildItem -Path $PSScriptRoot -Filter *.Container.ps* | ForEach-Object { . $_ }
    }
    TestResult = @{
        Enabled       = $true
        OutputPath    = 'outputs\AnotherPath.xml'
        TestSuiteName = 'Pester'
    }
    Output     = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
