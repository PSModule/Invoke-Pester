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
        Path    = "$PSScriptRoot/Emoji.psm1"
    }
    Output       = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
