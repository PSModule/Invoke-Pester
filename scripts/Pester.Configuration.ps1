@{
    Run          = @{
        Path                   = $Path
        ExcludePath            = @()
        ScriptBlock            = @()
        Container              = @()
        TestExtension          = @(
            '.Tests.ps1'
        )
        Exit                   = $false
        Throw                  = $false
        PassThru               = $true
        SkipRun                = $false
        SkipRemainingOnFailure = 'None'
    }
    Filter       = @{
        Tag         = @()
        ExcludeTag  = @()
        Line        = @()
        ExcludeLine = @()
        FullName    = @()
    }
    CodeCoverage = @{
        Enabled               = $true
        OutputFormat          = 'JaCoCo'
        OutputPath            = 'CodeCoverage-Report.xml'
        OutputEncoding        = 'UTF8'
        Path                  = @()
        ExcludeTests          = $true
        RecursePaths          = $true
        CoveragePercentTarget = 75.0
        UseBreakpoints        = $true
        SingleHitBreakpoints  = $true
    }
    TestResult   = @{
        Enabled        = $true
        OutputFormat   = 'NUnitXml'
        OutputPath     = 'outputs\Test-Report.xml'
        OutputEncoding = 'UTF8'
        TestSuiteName  = 'Unit tests'
    }
    Should       = @{
        ErrorAction = 'Stop'
    }
    Debug        = @{
        ShowFullErrors         = $false
        WriteDebugMessages     = $false
        WriteDebugMessagesFrom = @(
            'Discovery',
            'Skip',
            'Mock',
            'CodeCoverage'
        )
        ShowNavigationMarkers  = $false
        ReturnRawResultObject  = $false
    }
    Output       = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
        CILogLevel          = 'Error'
        RenderMode          = 'Auto'
    }
    TestDrive    = @{
        Enabled = $true
    }
    TestRegistry = @{
        Enabled = $true
    }
}
