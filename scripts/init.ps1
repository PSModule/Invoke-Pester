[CmdletBinding()]
param()

LogGroup 'Init - Setup prerequisites' {
    'Pester', 'Hashtable', 'TimeSpan', 'Markdown' | ForEach-Object {
        Install-PSResource -Name $_ -WarningAction SilentlyContinue -TrustRepository -Repository PSGallery
        Import-Module -Name $_
    }
    Import-Module "$PSScriptRoot/Helpers.psm1"
}

LogGroup 'Init - Get test kit versions' {
    $pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

    [PSCustomObject]@{
        PowerShell = $PSVersionTable.PSVersion.ToString()
        Pester     = $pesterModule.Version
    } | Format-List | Out-String
}

LogGroup 'Init - Load inputs' {
    $path = [string]::IsNullOrEmpty($env:PSMODULE_INVOKE_PESTER_INPUT_Path) ? '.' : $env:PSMODULE_INVOKE_PESTER_INPUT_Path

    $inputs = @{
        Path                               = $path

        Run_Path                           = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_Path
        Run_ExcludePath                    = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_ExcludePath
        Run_ScriptBlock                    = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_ScriptBlock
        Run_Container                      = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_Container
        Run_TestExtension                  = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_TestExtension
        Run_Exit                           = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_Exit
        Run_Throw                          = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_Throw
        Run_SkipRun                        = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_SkipRun
        Run_SkipRemainingOnFailure         = $env:PSMODULE_INVOKE_PESTER_INPUT_Run_SkipRemainingOnFailure

        Filter_Tag                         = $env:PSMODULE_INVOKE_PESTER_INPUT_Filter_Tag
        Filter_ExcludeTag                  = $env:PSMODULE_INVOKE_PESTER_INPUT_Filter_ExcludeTag
        Filter_Line                        = $env:PSMODULE_INVOKE_PESTER_INPUT_Filter_Line
        Filter_ExcludeLine                 = $env:PSMODULE_INVOKE_PESTER_INPUT_Filter_ExcludeLine
        Filter_FullName                    = $env:PSMODULE_INVOKE_PESTER_INPUT_Filter_FullName

        CodeCoverage_Enabled               = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_Enabled
        CodeCoverage_OutputFormat          = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_OutputFormat
        CodeCoverage_OutputPath            = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_OutputPath
        CodeCoverage_OutputEncoding        = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_OutputEncoding
        CodeCoverage_Path                  = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_Path
        CodeCoverage_ExcludeTests          = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_ExcludeTests
        CodeCoverage_RecursePaths          = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_RecursePaths
        CodeCoverage_CoveragePercentTarget = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_CoveragePercentTarget
        CodeCoverage_UseBreakpoints        = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_UseBreakpoints
        CodeCoverage_SingleHitBreakpoints  = $env:PSMODULE_INVOKE_PESTER_INPUT_CodeCoverage_SingleHitBreakpoints

        TestResult_Enabled                 = $env:PSMODULE_INVOKE_PESTER_INPUT_TestResult_Enabled
        TestResult_OutputFormat            = $env:PSMODULE_INVOKE_PESTER_INPUT_TestResult_OutputFormat
        TestResult_OutputPath              = $env:PSMODULE_INVOKE_PESTER_INPUT_TestResult_OutputPath
        TestResult_OutputEncoding          = $env:PSMODULE_INVOKE_PESTER_INPUT_TestResult_OutputEncoding
        TestResult_TestSuiteName           = $env:PSMODULE_INVOKE_PESTER_INPUT_TestResult_TestSuiteName

        Should_ErrorAction                 = $env:PSMODULE_INVOKE_PESTER_INPUT_Should_ErrorAction

        Debug_ShowFullErrors               = $env:PSMODULE_INVOKE_PESTER_INPUT_Debug_ShowFullErrors
        Debug_WriteDebugMessages           = $env:PSMODULE_INVOKE_PESTER_INPUT_Debug_WriteDebugMessages
        Debug_WriteDebugMessagesFrom       = $env:PSMODULE_INVOKE_PESTER_INPUT_Debug_WriteDebugMessagesFrom
        Debug_ShowNavigationMarkers        = $env:PSMODULE_INVOKE_PESTER_INPUT_Debug_ShowNavigationMarkers
        Debug_ReturnRawResultObject        = $env:PSMODULE_INVOKE_PESTER_INPUT_Debug_ReturnRawResultObject

        Output_Verbosity                   = $env:PSMODULE_INVOKE_PESTER_INPUT_Output_Verbosity
        Output_StackTraceVerbosity         = $env:PSMODULE_INVOKE_PESTER_INPUT_Output_StackTraceVerbosity
        Output_CIFormat                    = $env:PSMODULE_INVOKE_PESTER_INPUT_Output_CIFormat
        Output_CILogLevel                  = $env:PSMODULE_INVOKE_PESTER_INPUT_Output_CILogLevel
        Output_RenderMode                  = $env:PSMODULE_INVOKE_PESTER_INPUT_Output_RenderMode

        TestDrive_Enabled                  = $env:PSMODULE_INVOKE_PESTER_INPUT_TestDrive_Enabled
        TestRegistry_Enabled               = $env:PSMODULE_INVOKE_PESTER_INPUT_TestRegistry_Enabled
    }

    Show-Input -Inputs $inputs
}

LogGroup 'Init - Load configuration - Defaults' {
    New-PesterConfigurationHashtable -Default | Format-Hashtable | Out-String
}

LogGroup 'Init - Load configuration - Custom settings file' {
    $customConfig = Get-PesterConfiguration -Path $inputs.Path
    Write-Output ($customConfig | Format-Hashtable | Out-String)
}

LogGroup 'Init - Load configuration - Action overrides' {
    $customConfigInputMap = @{
        Run          = @{
            Path                   = $inputs.Run_Path
            ExcludePath            = $inputs.Run_ExcludePath
            ScriptBlock            = $inputs.Run_ScriptBlock
            Container              = $inputs.Run_Container
            TestExtension          = $inputs.Run_TestExtension
            Exit                   = $null -ne $inputs.Run_Exit ? $inputs.Run_Exit -eq 'true' : $null
            Throw                  = $null -ne $inputs.Run_Throw ? $inputs.Run_Throw -eq 'true' : $null
            SkipRun                = $null -ne $inputs.Run_SkipRun ? $inputs.Run_SkipRun -eq 'true' : $null
            SkipRemainingOnFailure = $inputs.Run_SkipRemainingOnFailure
        }
        Filter       = @{
            Tag         = $inputs.Filter_Tag
            ExcludeTag  = $inputs.Filter_ExcludeTag
            Line        = $inputs.Filter_Line
            ExcludeLine = $inputs.Filter_ExcludeLine
            FullName    = $inputs.Filter_FullName
        }
        CodeCoverage = @{
            Enabled               = $null -ne $inputs.CodeCoverage_Enabled ? $inputs.CodeCoverage_Enabled -eq 'true' : $null
            OutputFormat          = $inputs.CodeCoverage_OutputFormat
            OutputPath            = $inputs.CodeCoverage_OutputPath
            OutputEncoding        = $inputs.CodeCoverage_OutputEncoding
            Path                  = $inputs.CodeCoverage_Path
            ExcludeTests          = $null -ne $inputs.CodeCoverage_ExcludeTests ? $inputs.CodeCoverage_ExcludeTests -eq 'true' : $null
            RecursePaths          = $null -ne $inputs.CodeCoverage_RecursePaths ? $inputs.CodeCoverage_RecursePaths -eq 'true' : $null
            CoveragePercentTarget = [decimal]$inputs.CodeCoverage_CoveragePercentTarget
            UseBreakpoints        = $null -ne $inputs.CodeCoverage_UseBreakpoints ? $inputs.CodeCoverage_UseBreakpoints -eq 'true' : $null
            SingleHitBreakpoints  = $null -ne $inputs.CodeCoverage_SingleHitBreakpoints ? $inputs.CodeCoverage_SingleHitBreakpoints -eq 'true' : $null
        }
        TestResult   = @{
            Enabled        = $null -ne $inputs.TestResult_Enabled ? $inputs.TestResult_Enabled -eq 'true' : $null
            OutputFormat   = $inputs.TestResult_OutputFormat
            OutputPath     = $inputs.TestResult_OutputPath
            OutputEncoding = $inputs.TestResult_OutputEncoding
            TestSuiteName  = $inputs.TestResult_TestSuiteName
        }
        Should       = @{
            ErrorAction = $inputs.Should_ErrorAction
        }
        Debug        = @{
            ShowFullErrors         = $null -ne $inputs.Debug_ShowFullErrors ? $inputs.Debug_ShowFullErrors -eq 'true' : $null
            WriteDebugMessages     = $null -ne $inputs.Debug_WriteDebugMessages ? $inputs.Debug_WriteDebugMessages -eq 'true' : $null
            WriteDebugMessagesFrom = $inputs.Debug_WriteDebugMessagesFrom
            ShowNavigationMarkers  = $null -ne $inputs.Debug_ShowNavigationMarkers ? $inputs.Debug_ShowNavigationMarkers -eq 'true' : $null
            ReturnRawResultObject  = $null -ne $inputs.Debug_ReturnRawResultObject ? $inputs.Debug_ReturnRawResultObject -eq 'true' : $null
        }
        Output       = @{
            CIFormat            = $inputs.Output_CIFormat
            StackTraceVerbosity = $inputs.Output_StackTraceVerbosity
            Verbosity           = $inputs.Output_Verbosity
            CILogLevel          = $inputs.Output_CILogLevel
            RenderMode          = $inputs.Output_RenderMode
        }
        TestDrive    = @{
            Enabled = $null -ne $inputs.TestDrive_Enabled ? $inputs.TestDrive_Enabled -eq 'true' : $null
        }
        TestRegistry = @{
            Enabled = $null -ne $inputs.TestRegistry_Enabled ? $inputs.TestRegistry_Enabled -eq 'true' : $null
        }
    }

    $customInputs = $customConfigInputMap | Clear-PesterConfigurationEmptyValue
    Write-Output ($customInputs | Format-Hashtable | Out-String)
}

LogGroup 'Init - Load configuration' {
    $defaults = New-PesterConfigurationHashtable -Default
    $configuration = Merge-PesterConfiguration -BaseConfiguration $defaults -AdditionalConfiguration $customConfig, $customInputs

    if ([string]::IsNullOrEmpty($configuration.Run.Path)) {
        $configuration.Run.Path = $inputs.Path
    }
    $configuration | Format-Hashtable | Out-String
}

LogGroup 'Init - Export containers' {
    $containers = @()
    $existingContainers = $configuration.Run.Container
    if ($existingContainers.Count -gt 0) {
        Write-Output "Containers from configuration: [$($existingContainers.Count)]"
        foreach ($existingContainer in $existingContainers) {
            Write-Output "Processing container [$existingContainer]"
            $containers += $existingContainer | Convert-PesterConfigurationToHashtable
        }
    }
    Write-Output "Containers from configuration: [$($containers.Count)]"
    # Search for "*.Container.*" files in each Run.Path directory
    Write-Output 'Searching for containers in same location as config.'
    $path = New-Item -Path . -ItemType Directory -Name 'temp' -Force
    foreach ($testDir in $inputs.Path) {
        #If testDir is a file, get the directory
        $testItem = Get-Item -Path $testDir
        if ($testItem.PSIsContainer -eq $false) {
            $testDir = $testItem.DirectoryName
        }

        $containerFiles = Get-ChildItem -Path $testDir -Filter *.Container.* -Recurse
        Write-Output "Containers found in [$testDir]: [$($containerFiles.Count)]"
        if ($containerFiles.Count -eq 0) {
            # Look for test files and make a container for each test file.
            $testFiles = Get-ChildItem -Path $testDir -Filter *.Tests.ps1 -Recurse
            Write-Output "Test files found in [$testDir]: [$($testFiles.Count)]"
            foreach ($testFile in $testFiles) {
                $container = @{
                    Path = $testFile.FullName
                }
                LogGroup "Init - Export containers - Generated - $containerFileName" {
                    $containerFileName = ($testFile | Split-Path -Leaf).Replace('.Tests.ps1', '.Container.ps1')
                    Write-Output "Exporting container [$path/$containerFileName]"
                    Export-Hashtable -Hashtable $container -Path "$path/$containerFileName"
                }
                Write-Output "Containers created from test files: [$($containers.Count)]"
            }
        }
        foreach ($containerFile in $containerFiles) {
            $container = Import-Hashtable $containerFile
            $containerFileName = $containerFile | Split-Path -Leaf
            LogGroup "Init - Export containers - $containerFileName" {
                Format-Hashtable -Hashtable $container
                Write-Output "Exporting container [$path/$containerFileName]"
                Export-Hashtable -Hashtable $container -Path "$path/$containerFileName"
            }
        }
    }
    $configuration.Run.Container = @()
}

LogGroup 'Init - Export configuration' {
    $artifactName = $configuration.TestResult.TestSuiteName ?? 'Pester'
    $configuration.TestResult.OutputPath = "test_reports/$artifactName-TestResult-Report.xml"
    $configuration.CodeCoverage.OutputPath = "test_reports/$artifactName-CodeCoverage-Report.xml"
    $configuration.Run.PassThru = $true

    Format-Hashtable -Hashtable $configuration
    Write-Output "Exporting configuration [$path/Invoke-Pester.Configuration.ps1]"
    Export-Hashtable -Hashtable $configuration -Path "$path/Invoke-Pester.Configuration.ps1"
}
