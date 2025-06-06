﻿[CmdletBinding()]
param()

LogGroup 'Init - Setup prerequisites' {
    Import-Module "$PSScriptRoot/Helpers.psm1"
    'Pester', 'Hashtable', 'TimeSpan', 'Markdown' | Install-PSResourceWithRetry
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
            Exit                   = [string]::IsNullOrEmpty($inputs.Run_Exit) ? $null : $inputs.Run_Exit -eq 'true'
            Throw                  = [string]::IsNullOrEmpty($inputs.Run_Throw) ? $null : $inputs.Run_Throw -eq 'true'
            SkipRun                = [string]::IsNullOrEmpty($inputs.Run_SkipRun) ? $null : $inputs.Run_SkipRun -eq 'true'
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
            Enabled               = [string]::IsNullOrEmpty($inputs.CodeCoverage_Enabled) ? $null : $inputs.CodeCoverage_Enabled -eq 'true'
            OutputFormat          = $inputs.CodeCoverage_OutputFormat
            OutputPath            = $inputs.CodeCoverage_OutputPath
            OutputEncoding        = $inputs.CodeCoverage_OutputEncoding
            Path                  = $inputs.CodeCoverage_Path
            ExcludeTests          = [string]::IsNullOrEmpty($inputs.CodeCoverage_ExcludeTests) ? $null : $inputs.CodeCoverage_ExcludeTests -eq 'true'
            RecursePaths          = [string]::IsNullOrEmpty($inputs.CodeCoverage_RecursePaths) ? $null : $inputs.CodeCoverage_RecursePaths -eq 'true'
            CoveragePercentTarget = [string]::IsNullOrEmpty($inputs.CodeCoverage_CoveragePercentTarget) ?
            $null : [decimal]$inputs.CodeCoverage_CoveragePercentTarget
            UseBreakpoints        = [string]::IsNullOrEmpty($inputs.CodeCoverage_UseBreakpoints) ?
            $null : $inputs.CodeCoverage_UseBreakpoints -eq 'true'
            SingleHitBreakpoints  = [string]::IsNullOrEmpty($inputs.CodeCoverage_SingleHitBreakpoints) ?
            $null : $inputs.CodeCoverage_SingleHitBreakpoints -eq 'true'
        }
        TestResult   = @{
            Enabled        = [string]::IsNullOrEmpty($inputs.TestResult_Enabled) ? $null : $inputs.TestResult_Enabled -eq 'true'
            OutputFormat   = $inputs.TestResult_OutputFormat
            OutputPath     = $inputs.TestResult_OutputPath
            OutputEncoding = $inputs.TestResult_OutputEncoding
            TestSuiteName  = $inputs.TestResult_TestSuiteName
        }
        Should       = @{
            ErrorAction = $inputs.Should_ErrorAction
        }
        Debug        = @{
            ShowFullErrors         = [string]::IsNullOrEmpty($inputs.Debug_ShowFullErrors) ? $null : $inputs.Debug_ShowFullErrors -eq 'true'
            WriteDebugMessages     = [string]::IsNullOrEmpty($inputs.Debug_WriteDebugMessages) ? $null : $inputs.Debug_WriteDebugMessages -eq 'true'
            WriteDebugMessagesFrom = $inputs.Debug_WriteDebugMessagesFrom
            ShowNavigationMarkers  = [string]::IsNullOrEmpty($inputs.Debug_ShowNavigationMarkers) ?
            $null : $inputs.Debug_ShowNavigationMarkers -eq 'true'
            ReturnRawResultObject  = [string]::IsNullOrEmpty($inputs.Debug_ReturnRawResultObject) ?
            $null : $inputs.Debug_ReturnRawResultObject -eq 'true'
        }
        Output       = @{
            CIFormat            = $inputs.Output_CIFormat
            StackTraceVerbosity = $inputs.Output_StackTraceVerbosity
            Verbosity           = $inputs.Output_Verbosity
            CILogLevel          = $inputs.Output_CILogLevel
            RenderMode          = $inputs.Output_RenderMode
        }
        TestDrive    = @{
            Enabled = [string]::IsNullOrEmpty($inputs.TestDrive_Enabled) ? $null : $inputs.TestDrive_Enabled -eq 'true'
        }
        TestRegistry = @{
            Enabled = [string]::IsNullOrEmpty($inputs.TestRegistry_Enabled) ? $null : $inputs.TestRegistry_Enabled -eq 'true'
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
            $containers += $existingContainer | ConvertTo-Hashtable
        }
    }
    Write-Output "Containers from configuration: [$($containers.Count)]"

    # Create temp directory for container output
    $path = New-Item -Path . -ItemType Directory -Name '.temp' -Force

    # Process each input path
    foreach ($testDir in $inputs.Path) {
        # Check if testDir is a file or directory
        $testItem = Get-Item -Path $testDir -ErrorAction SilentlyContinue
        if ($null -eq $testItem) {
            Write-Output "Path not found: [$testDir]"
            continue
        }

        if ($testItem.PSIsContainer -eq $false) {
            # Handle single file
            $fileName = $testItem.Name

            if ($fileName -like '*.Container.ps1') {
                # If it's a container file, use it directly
                Write-Output "Processing container file: [$fileName]"
                $containerFile = $testItem.FullName
                $container = Import-Hashtable -Path $containerFile
                $containerFileName = $fileName
                Write-Output 'Container configuration from file:'
                Write-Output (Format-Hashtable -Hashtable $container | Out-String)
                Write-Output "Exporting container [$path/$containerFileName]"
                Export-Hashtable -Hashtable $container -Path "$path/$containerFileName"
                $containers += $container
            } elseif ($fileName -like '*.Tests.ps1') {
                # If it's a test file, create a container for it
                Write-Output "Creating container for test file: [$fileName]"
                $container = @{
                    Path = $testItem.FullName
                }
                $containerFileName = $fileName.Replace('.Tests.ps1', '.Container.ps1')
                Write-Output 'Generated container configuration:'
                Write-Output (Format-Hashtable -Hashtable $container | Out-String)
                Write-Output "Exporting container [$path/$containerFileName]"
                Export-Hashtable -Hashtable $container -Path "$path/$containerFileName"
                $containers += $container
            } else {
                Write-Output "File [$fileName] is not a .Container.ps1 or .Tests.ps1 file. Processing parent directory."
                $testDir = $testItem.DirectoryName
                Write-Output "Processing test directory: [$testDir]"
                # Process the directory recursively
                $containers += Invoke-ProcessTestDirectory -Directory $testDir -OutputPath $path
            }
        } else {
            Write-Output "Processing test directory: [$testDir]"
            # Process the directory recursively
            $containers += Invoke-ProcessTestDirectory -Directory $testDir -OutputPath $path
        }

        Write-Output "Total containers after processing [$testDir]: [$($containers.Count)]"
    }
    $configuration.Run.Container = @()
}

LogGroup 'Init - Export configuration' {
    $artifactName = $configuration.TestResult.TestSuiteName ?? 'Pester'
    $configuration.TestResult.OutputPath = "$pwd/TestResult/$artifactName-TestResult-Report.xml"
    $configuration.CodeCoverage.OutputPath = "$pwd/CodeCoverage/$artifactName-CodeCoverage-Report.xml"
    $configuration.Run.PassThru = $true

    Format-Hashtable -Hashtable $configuration
    Write-Output "Exporting configuration [$path/Invoke-Pester.Configuration.ps1]"
    Export-Hashtable -Hashtable $configuration -Path "$path/Invoke-Pester.Configuration.ps1"
}
