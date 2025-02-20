@{
    Run        = @{
        Path     = $PSScriptRoot
        PassThru = $true
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
