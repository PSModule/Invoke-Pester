@{
    Run          = @{
        Path     = $Path
        PassThru = $true
    }
    TestResult   = @{
        Enabled       = $true
        OutputFormat  = 'NUnitXml'
        OutputPath    = 'outputs\Test-Report.xml'
        TestSuiteName = 'Unit tests'
    }
    CodeCoverage = @{
        Enabled               = $true
        OutputPath            = 'outputs\CodeCoverage-Report.xml'
        OutputFormat          = 'JaCoCo'
        OutputEncoding        = 'UTF8'
        CoveragePercentTarget = 75
    }
    Output       = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Normal'
        Verbosity           = 'Detailed'
    }
}
