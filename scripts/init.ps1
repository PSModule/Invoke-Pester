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
    $providedItem = Resolve-Path -Path $path | Select-Object -ExpandProperty Path | Get-Item
    if ($providedItem -is [System.IO.DirectoryInfo]) {
        $providedPath = $providedItem.FullName
    } elseif ($providedItem -is [System.IO.FileInfo]) {
        $providedPath = $providedItem.Directory.FullName
    } else {
        Write-GitHubError "❌ Provided path [$providedItem] is not a valid directory or file."
        exit 1
    }

    $inputs = @{
        Path                               = $providedPath

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
            Exit                   = $inputs.Run_Exit
            Throw                  = $inputs.Run_Throw
            SkipRun                = $inputs.Run_SkipRun
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
            Enabled               = $inputs.CodeCoverage_Enabled
            OutputFormat          = $inputs.CodeCoverage_OutputFormat
            OutputPath            = $inputs.CodeCoverage_OutputPath
            OutputEncoding        = $inputs.CodeCoverage_OutputEncoding
            Path                  = $inputs.CodeCoverage_Path
            ExcludeTests          = $inputs.CodeCoverage_ExcludeTests
            RecursePaths          = $inputs.CodeCoverage_RecursePaths
            CoveragePercentTarget = $inputs.CodeCoverage_CoveragePercentTarget
            UseBreakpoints        = $inputs.CodeCoverage_UseBreakpoints
            SingleHitBreakpoints  = $inputs.CodeCoverage_SingleHitBreakpoints
        }
        TestResult   = @{
            Enabled        = $inputs.TestResult_Enabled
            OutputFormat   = $inputs.TestResult_OutputFormat
            OutputPath     = $inputs.TestResult_OutputPath
            OutputEncoding = $inputs.TestResult_OutputEncoding
            TestSuiteName  = $inputs.TestResult_TestSuiteName
        }
        Should       = @{
            ErrorAction = $inputs.Should_ErrorAction
        }
        Debug        = @{
            ShowFullErrors         = $inputs.Debug_ShowFullErrors
            WriteDebugMessages     = $inputs.Debug_WriteDebugMessages
            WriteDebugMessagesFrom = $inputs.Debug_WriteDebugMessagesFrom
            ShowNavigationMarkers  = $inputs.Debug_ShowNavigationMarkers
            ReturnRawResultObject  = $inputs.Debug_ReturnRawResultObject
        }
        Output       = @{
            CIFormat            = $inputs.Output_CIFormat
            StackTraceVerbosity = $inputs.Output_StackTraceVerbosity
            Verbosity           = $inputs.Output_Verbosity
            CILogLevel          = $inputs.Output_CILogLevel
            RenderMode          = $inputs.Output_RenderMode
        }
        TestDrive    = @{
            Enabled = $inputs.TestDrive_Enabled
        }
        TestRegistry = @{
            Enabled = $inputs.TestRegistry_Enabled
        }
    }

    $customInputs = $customConfigInputMap | Clear-PesterConfigurationEmptyValue
    Write-Output ($customInputs | Format-Hashtable | Out-String)
}

LogGroup 'Init - Load configuration' {
    $defaults = New-PesterConfigurationHashtable
    $configuration = Merge-PesterConfiguration -BaseConfiguration $defaults -AdditionalConfiguration $customConfig, $customInputs

    if ([string]::IsNullOrEmpty($configuration.Run.Path)) {
        $configuration.Run.Path = $inputs.Path
    }
    Write-Output ($configuration | Format-Hashtable | Out-String)
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
    foreach ($testDir in $inputs.Path) {
        $containerFiles = Get-ChildItem -Path $testDir -Filter *.Container.* -Recurse
        Write-Output "Containers found in [$testDir]: [$($containerFiles.Count)]"
        foreach ($containerFile in $containerFiles) {
            $container = Import-Hashtable $containerFile
            $containerFileName = $containerFile | Split-Path -Leaf
            LogGroup "Init - Export containers - $containerFileName" {
                Format-Hashtable -Hashtable $container
                Write-Verbose 'Converting hashtable to PesterContainer'
                Export-Hashtable -Hashtable $container -Path "$PSScriptRoot/$containerFileName"
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
    Export-Hashtable -Hashtable $configuration -Path "$PSScriptRoot/Invoke-Pester.Configuration.ps1"
}
