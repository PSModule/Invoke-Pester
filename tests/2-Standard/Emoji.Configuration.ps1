@{
    Run        = @{
        Path     = $PSScriptRoot
        PassThru = $true
    }
    TestResult = @{
        Enabled       = $true
        TestSuiteName = 'Standard'
    }
    Output     = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
