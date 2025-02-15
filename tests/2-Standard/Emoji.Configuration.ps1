@{
    Run        = @{
        Path      = $PSScriptRoot
        Container = Get-ChildItem -Path $PSScriptRoot -Filter *.Container.* | ForEach-Object { . $_ }
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
