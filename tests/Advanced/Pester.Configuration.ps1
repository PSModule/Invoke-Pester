@{
    Run          = @{
        Path = $PSScriptRoot
    }
    CodeCoverage = @{
        Enabled = $false
    }
    TestResult   = @{
        Enabled       = $true
        OutputPath    = 'outputs\AnotherPath.xml'
        TestSuiteName = 'Pester'
    }
    Output       = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
