﻿@{
    Run        = @{
        Path      = $PSScriptRoot
        PassThru  = $true
        Container = Get-ChildItem -Path $PSScriptRoot -Filter *.Container.* -Recurse |
            ForEach-Object { . $_ } | ForEach-Object { New-PesterContainer @_ }
    }
    TestResult = @{
        Enabled       = $true
        OutputPath    = 'outputs\AnotherPath.xml'
        TestSuiteName = 'Pester'
    }
    Output     = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
