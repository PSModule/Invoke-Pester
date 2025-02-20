@{
    Run          = @{
        Path     = $PSScriptRoot
        PassThru = $true
    }
    TestResult   = @{
        Enabled       = $true
        TestSuiteName = 'Advanced'
    }
    CodeCoverage = @{
        Enabled = $true
    }
    Output       = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
