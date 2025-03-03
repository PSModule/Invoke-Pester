@{
    Run          = @{
        Path     = $PSScriptRoot
        PassThru = $true
    }
    TestResult   = @{
        Enabled       = $true
        TestSuiteName = 'Standard'
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
