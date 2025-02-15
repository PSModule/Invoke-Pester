@{
    Run          = @{
        Path     = $PSScriptRoot
        PassThru = $true
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
