@{
    Run        = @{
        Path      = $PSScriptRoot
        PassThru  = $true
        Container = Get-ChildItem -Path $PSScriptRoot -Filter *.Container.* -Recurse | ForEach-Object {
            $ht = . $_
            New-PesterContainer @ht
        }
    }
    TestResult = @{
        Enabled       = $true
        TestSuiteName = 'Advanced'
    }
    Output     = @{
        CIFormat            = 'Auto'
        StackTraceVerbosity = 'Filtered'
        Verbosity           = 'Detailed'
    }
}
