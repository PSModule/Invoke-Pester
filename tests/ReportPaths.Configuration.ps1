@{
    Run          = @{
        Path     = "$PSScriptRoot/2-Standard"
        PassThru = $true
    }
    TestResult   = @{
        Enabled       = $true
        TestSuiteName = 'Standard'
        OutputPath    = '.PSModule/Configuration/TestResult/Configured-TestResult-Report.xml'
    }
    CodeCoverage = @{
        Enabled    = $true
        Path       = "$PSScriptRoot/2-Standard/Emoji.psm1"
        OutputPath = '.PSModule/Configuration/CodeCoverage/Configured-CodeCoverage-Report.xml'
    }
    Output       = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
