@{
    Run          = @{
        Path     = $PSScriptRoot
        PassThru = $true
    }
    TestResult   = @{
        Enabled       = $true
        TestSuiteName = 'Advanced'
    }
    CodeCoderage = @{
        Enabled = $true
    }
    Output       = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
