@{
    Run        = @{
        Path      = $PSScriptRoot
        PassThru  = $true
        Container = Get-ChildItem -Path $PSScriptRoot -Filter *.Container.* -Recurse | ForEach-Object { . $_ }
    }
    TestResult = @{
        Enabled       = $true
        TestSuiteName = 'Advanced'
    }
    Output     = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
