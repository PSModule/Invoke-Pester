$nbsp = [char]0x00A0
$indent = "$nbsp" * 4

function Get-PesterContainer {
    <#
        .SYNOPSIS
        Loads Pester container files from the specified path.

        .DESCRIPTION
        This function searches the given directory recursively for Pester container files with extensions
        '.ps1' and '.psd1'. It then loads '.ps1' files using dot-sourcing and imports '.psd1' files
        as PowerShell data files.

        .EXAMPLE
        Get-PesterContainer -Path "C:\Tests"

        Output:
        ```powershell
        # No direct output, but scripts and data files are loaded into the session.
        ```

        Recursively loads all Pester container files from the 'C:\Tests' directory.

        .OUTPUTS
        hashtable

        .NOTES
        The hashtable representation from what was contained in the Container file.
    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        # The path to search for Pester container files.
        [string] $Path
    )

    $containerFiles = Get-ChildItem -Path $Path -Recurse -Filter *.Container.*
    Write-Verbose "Found $($containerFiles.Count) container files."

    foreach ($file in $containerFiles) {
        Write-Verbose "Loading container file: [$file]"
        $container = . $file
        Write-Verbose ($container | Format-Hashtable | Out-String)
        $container
    }
}

function Get-PesterConfiguration {
    <#
        .SYNOPSIS
        Retrieves a Pester configuration file from the specified path.

        .DESCRIPTION
        This function checks the specified path for a Pester configuration file. If the path is a directory,
        it searches for files matching the pattern `*.Configuration.*`. If multiple configuration files
        are found, an error is thrown. The function supports `.ps1` and `.psd1` files, executing or importing them
        accordingly.

        .EXAMPLE
        Get-PesterConfiguration -Path "C:\\Pester\\Config"

        Output:
        ```powershell
        Path: [C:\Pester\Config]
        @{Setting1 = 'Value1'; Setting2 = 'Value2'}
        ```

        Retrieves the Pester configuration from the specified directory.

        .OUTPUTS
        hashtable

        .NOTES
        The function returns a hashtable containing the Pester configuration if found.
        If no configuration file is found, an empty hashtable is returned.
    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        # Specifies the path where the Pester configuration file is located.
        [Parameter(Mandatory)]
        [string] $Path
    )

    Write-Verbose "Path: [$Path]"
    $pathExists = Test-Path -Path $Path
    if (-not $pathExists) {
        throw "Test path does not exist: [$Path]"
    }
    $item = $Path | Get-Item

    if ($item.PSIsContainer) {
        Write-Verbose 'Path is a directory. Searching for configuration files...'
        $file = Get-ChildItem -Path $Path -Filter *.Configuration.*
        Write-Verbose "Found $($file.Count) configuration files."
        if ($file.Count -eq 0) {
            Write-Verbose "No configuration files found in path: [$Path]"
            return @{}
        }
        if ($file.Count -gt 1) {
            throw "Multiple configuration files found in path: [$Path]"
        }
    } else {
        $file = $item
    }

    Write-Verbose "Importing configuration data file: $($file.FullName)"
    Import-Hashtable -Path $($file.FullName)
}

function Merge-PesterConfiguration {
    <#
        .SYNOPSIS
        Merges a base Pester configuration with additional settings.

        .DESCRIPTION
        The `Merge-PesterConfiguration` function takes a base Pester configuration hashtable and merges it with
        additional configuration settings. The function processes each additional configuration hashtable and
        merges it into the base configuration. If multiple additional configurations are provided, the function
        merges them sequentially, with each subsequent configuration overwriting the previous one.

        .EXAMPLE
        $baseConfig = @{
            Run = @{
                PassThru = $false
            }
        }
        $additionalConfig1 = @{
            Run = @{
                PassThru = $true
            }
        }
        $additionalConfig2 = @{
            Run = @{
                PassThru    = $false
                ExcludePath = "Test-Exclude"
            }
        }
        Merge-PesterConfiguration -BaseConfiguration $baseConfig -AdditionalConfiguration $additionalConfig1, $additionalConfig2

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        # The base configuration hashtable to merge into.
        [Parameter(Mandatory)]
        [hashtable] $BaseConfiguration,

        # The additional configuration hashtable to merge into the base.
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [hashtable[]] $AdditionalConfiguration
    )


    begin {
        $mergedConfiguration = $BaseConfiguration.Clone()
    }

    process {
        foreach ($config in $AdditionalConfiguration) {
            foreach ($category in $config.Keys) {
                Write-Verbose "Merging category: [$category]"
                $mergedConfiguration[$category] = Merge-Hashtable -Main $mergedConfiguration[$category] -Overrides $config[$category]
            }
        }
    }

    end {
        return $mergedConfiguration
    }
}

function New-PesterConfigurationHashtable {
    <#
        .SYNOPSIS
        Generates a hashtable representing the structure of a Pester configuration.

        .DESCRIPTION
        This function creates a hashtable that mirrors the structure of a Pester configuration object.
        Each top-level category (e.g., Run, Filter) is represented as a key in the hashtable, with subkeys
        corresponding to individual settings. The values for these settings are initialized as `$null`.

        This function is useful for creating configuration templates or inspecting the available settings
        in a structured manner.

        .EXAMPLE
        New-PesterConfigurationHashtable | Format-Hashtable

        Output:
        ```powershell
        @{
            Should       = @{
                ErrorAction = $null
            }
            CodeCoverage = @{
                ExcludeTests          = $null
                UseBreakpoints        = $null
                SingleHitBreakpoints  = $null
                RecursePaths          = $null
                OutputEncoding        = $null
                CoveragePercentTarget = $null
                Path                  = $null
                Enabled               = $null
                OutputPath            = $null
                OutputFormat          = $null
            }
            TestRegistry = @{
                Enabled = $null
            }
            Output       = @{
                StackTraceVerbosity = $null
                CILogLevel          = $null
                Verbosity           = $null
                CIFormat            = $null
                RenderMode          = $null
            }
            Filter       = @{
                ExcludeLine = $null
                ExcludeTag  = $null
                Line        = $null
                FullName    = $null
                Tag         = $null
            }
            Debug        = @{
                ShowFullErrors         = $null
                WriteDebugMessagesFrom = $null
                ReturnRawResultObject  = $null
                WriteDebugMessages     = $null
                ShowNavigationMarkers  = $null
            }
            Run          = @{
                Exit                   = $null
                Path                   = $null
                PassThru               = $null
                Container              = $null
                ScriptBlock            = $null
                Throw                  = $null
                SkipRemainingOnFailure = $null
                SkipRun                = $null
                ExcludePath            = $null
                TestExtension          = $null
            }
            TestDrive    = @{
                Enabled = $null
            }
            TestResult   = @{
                OutputFormat   = $null
                OutputPath     = $null
                Enabled        = $null
                OutputEncoding = $null
                TestSuiteName  = $null
            }
        }
        ```

        Generates a hashtable representing the Pester configuration structure with `$null` values.

        .EXAMPLE
        New-PesterConfigurationHashtable -Default | Format-Hashtable

        Output:
        ```powershell
        @{
            Should       = @{
                ErrorAction = 'Stop'
            }
            CodeCoverage = @{
                ExcludeTests          = $true
                UseBreakpoints        = $true
                SingleHitBreakpoints  = $true
                RecursePaths          = $true
                OutputEncoding        = 'UTF8'
                CoveragePercentTarget = '75'
                Path                  = @()
                Enabled               = $false
                OutputPath            = 'coverage.xml'
                OutputFormat          = 'JaCoCo'
            }
            TestRegistry = @{
                Enabled = $true
            }
            Output       = @{
                StackTraceVerbosity = 'Filtered'
                CILogLevel          = 'Error'
                Verbosity           = 'Normal'
                CIFormat            = 'Auto'
                RenderMode          = 'Auto'
            }
            Filter       = @{
                ExcludeLine = @()
                ExcludeTag  = @()
                Line        = @()
                FullName    = @()
                Tag         = @()
            }
            Debug        = @{
                ShowFullErrors         = $false
                WriteDebugMessagesFrom = @(
                    'Discovery'
                    'Skip'
                    'Mock'
                    'CodeCoverage'
                )
                ReturnRawResultObject  = $false
                WriteDebugMessages     = $false
                ShowNavigationMarkers  = $false
            }
            Run          = @{
                Exit                   = $false
                Path                   = @(
                    '.'
                )
                PassThru               = $false
                Container              = @()
                ScriptBlock            = @()
                Throw                  = $false
                SkipRemainingOnFailure = 'None'
                SkipRun                = $false
                ExcludePath            = @()
                TestExtension          = '.Tests.ps1'
            }
            TestDrive    = @{
                Enabled = $true
            }
            TestResult   = @{
                OutputFormat   = 'NUnitXml'
                OutputPath     = 'testResults.xml'
                Enabled        = $false
                OutputEncoding = 'UTF8'
                TestSuiteName  = 'Pester'
            }
        }
        ```

        Generates a hashtable representing the Pester configuration structure with default values.

        .OUTPUTS
        hashtable

        .NOTES
        Returns a hashtable containing the structure of a Pester configuration with `$null` values.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Creates an in-memory resource'
    )]
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [switch] $Default
    )

    # Prepare the output hashtable
    $result = @{}

    $schema = [PesterConfiguration]::new()

    # Iterate over each top-level category (Run, Filter, etc.)
    foreach ($category in $schema.PSObject.Properties.Name) {
        $categoryObj = $schema.$category
        $subHash = @{}

        # Iterate over each setting within the category
        foreach ($settingName in $categoryObj.PSObject.Properties.Name) {
            if ($Default) {
                $subHash[$settingName] = $schema.$category.$settingName.Value
            } else {
                $subHash[$settingName] = $null
            }
        }

        $result[$category] = $subHash
    }
    $result
}

filter Convert-PesterConfigurationToHashtable {
    <#
        .SYNOPSIS
        Converts a PesterConfiguration object into a hashtable containing only modified settings.

        .DESCRIPTION
        This function iterates over a given PesterConfiguration object and extracts only the settings that have been modified.
        It ensures that only properties with an `IsModified` flag set to `$true` are included in the output hashtable.
        The function maintains the category structure of the configuration and retains type consistency when assigning values.
        When the -IncludeDefaults switch is provided, it includes settings that have not been modified, outputting their default values.

        .EXAMPLE
        New-PesterConfiguration | Convert-PesterConfigurationToHashtable | Format-Hashtable

        Output:
        ```powershell
        @{
            TestDrive    = @{
                Enabled = $true
            }
            TestResult   = @{
                TestSuiteName  = 'Pester'
                OutputFormat   = 'NUnitXml'
                OutputEncoding = 'UTF8'
                OutputPath     = 'testResults.xml'
                Enabled        = $false
            }
            Run          = @{
                ExcludePath            = $null
                Exit                   = $false
                SkipRun                = $false
                Path                   = '.'
                Throw                  = $false
                PassThru               = $false
                SkipRemainingOnFailure = 'None'
                ScriptBlock            = $null
                Container              = $null
                TestExtension          = '.Tests.ps1'
            }
            Output       = @{
                CILogLevel          = 'Error'
                StackTraceVerbosity = 'Filtered'
                RenderMode          = 'Auto'
                CIFormat            = 'Auto'
                Verbosity           = 'Normal'
            }
            Debug        = @{
                ShowNavigationMarkers  = $false
                ShowFullErrors         = $false
                WriteDebugMessagesFrom = @(
                    'Discovery'
                    'Skip'
                    'Mock'
                    'CodeCoverage'
                )
                WriteDebugMessages     = $false
                ReturnRawResultObject  = $false
            }
            TestRegistry = @{
                Enabled = $true
            }
            CodeCoverage = @{
                Path                  = $null
                OutputEncoding        = 'UTF8'
                CoveragePercentTarget = '75'
                UseBreakpoints        = $true
                ExcludeTests          = $true
                RecursePaths          = $true
                OutputPath            = 'coverage.xml'
                SingleHitBreakpoints  = $true
                Enabled               = $false
                OutputFormat          = 'JaCoCo'
            }
            Should       = @{
                ErrorAction = 'Stop'
            }
            Filter       = @{
                Line        = $null
                Tag         = $null
                ExcludeLine = $null
                FullName    = $null
                ExcludeTag  = $null
            }
        }
        ```

        The complete hashtable with all settings including both modified and defaults.

        .EXAMPLE
        $config = New-PesterConfiguration
        $config.Run.PassThru = $true
        Convert-PesterConfigurationToHashtable -PesterConfiguration $config -OnlyModified | Format-Hashtable

        Output:
        ```powershell
        @{
            Run = @{
                PassThru = $true
            }
        }
        ```

        .OUTPUTS
        hashtable

        .NOTES
        A hashtable containing only modified settings (or all settings if -IncludeDefaults is used) from the provided PesterConfiguration object.
    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        # The PesterConfiguration object to convert into a hashtable.
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [PesterConfiguration] $PesterConfiguration,

        # Include default values in the output hashtable.
        [Parameter()]
        [switch] $OnlyModified
    )

    # Prepare the output hashtable
    $result = @{}

    # Iterate over each top-level category (Run, Filter, etc.)
    foreach ($category in $PesterConfiguration.PSObject.Properties.Name) {
        $categoryObj = $PesterConfiguration.$category
        $subHash = @{}

        # Iterate over each setting within the category
        foreach ($settingName in $categoryObj.PSObject.Properties.Name) {
            if ($OnlyModified) {
                if ($setting.IsModified) {
                    $subHash[$settingName] = $setting.Value
                }
            } else {
                $subHash[$settingName] = if ($setting.IsModified) { $setting.Value } else { $setting.Default }
            }
        }

        # Add the category sub-hashtable to the result even if empty, to preserve structure.
        $result[$category] = $subHash
    }

    return $result
}

filter Clear-PesterConfigurationEmptyValue {
    <#
        .SYNOPSIS
        Filters out empty or null values from a Pester configuration hashtable.

        .DESCRIPTION
        The `Clear-PesterConfigurationEmptyValue` filter removes any keys in a Pester configuration hashtable
        that contain empty strings or null values. It processes each section within the hashtable and ensures
        that only properties with valid values remain. The function is useful for cleaning up configurations
        before passing them to Pester to avoid unnecessary or invalid settings.

        .EXAMPLE
        @{Run=@{PassThru=$true; Exclude=""; Timeout=$null}} | Clear-PesterConfigurationEmptyValue

        Output:
        ```powershell
        @{
            Run = @{
                PassThru = $true
            }
        }
        ```

        Removes empty and null values from the provided Pester configuration hashtable.

        .OUTPUTS
        Hashtable

        .NOTES
        A cleaned hashtable with empty or null values removed.
    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        # The hashtable containing Pester configuration settings to filter.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [hashtable] $Hashtable
    )

    $return = @{}

    foreach ($section in $Hashtable.Keys) {
        $filteredProperties = @{}

        foreach ($property in $Hashtable[$section].Keys) {
            $value = $Hashtable[$section][$property]

            # If the value isn't null or empty string, keep it.
            if (-not [string]::IsNullOrEmpty($value)) {
                $filteredProperties[$property] = $value
            }
        }

        $return[$section] = $filteredProperties
    }

    return $return
}

filter Get-PesterTestTree {
    <#
        .SYNOPSIS
        Processes Pester test results and returns a structured test tree.

        .DESCRIPTION
        This function processes Pester test results and organizes them into a structured
        test tree. It categorizes objects as Runs, Containers, Blocks, or Tests,
        adding relevant properties such as depth and item type. This allows for better
        visualization and analysis of Pester test results.

        .EXAMPLE
        $testResults = Invoke-Pester -Path 'C:\Repos\GitHub\PSModule\Action\Invoke-Pester\tests\1-Simple-Failure\Failure.Tests.ps1' -PassThru
        $testResults | Get-PesterTestTree | Format-Table -AutoSize -Property Depth, Name, ItemType, Result, Duration, ErrorRecord

        Output:
        ```powershell
        Depth Name              ItemType   Result   Duration ErrorRecord
        ----- ----              --------   ------   -------- -----------
            0 Failure.Tests     TestSuite Passed   0.015s
            1 Failure.Tests     Container Passed   0.012s
            2 Describe Block 1  Block     Failed   0.003s    System.Exception: Failure message
        ```

        Retrieves and formats Pester test results into a hierarchical tree structure.

        .OUTPUTS
        PSCustomObject

        .NOTES
        Returns an object representing the hierarchical structure of
        Pester test results, including depth, name, item type, and result status.
    #>

    [OutputType([object])]
    [CmdletBinding()]
    param (
        # Specifies the input object, which is expected to be an object in the Pester test result hierarchy.
        # Run, Container, Block, or Test objects are supported.
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [object] $InputObject
    )

    Write-Verbose "Processing object of type: $($InputObject.GetType().Name)"
    switch ($InputObject.GetType().Name) {
        'Run' {
            $inputObject | Add-Member -MemberType NoteProperty -Name Depth -Value 0
            $inputObject | Add-Member -MemberType NoteProperty -Name ItemType -Value 'TestSuite'
            $inputObject | Add-Member -MemberType NoteProperty -Name Name -Value $($testResults.Configuration.TestResult.TestSuiteName.Value) -Force
            $inputObject | Add-Member -MemberType NoteProperty -Name Children -Value $inputObject.Containers
            $inputObject
            $inputObject.Containers | Get-PesterTestTree
        }
        'Container' {
            $inputObject | Add-Member -MemberType NoteProperty -Name Depth -Value 1
            $inputObject | Add-Member -MemberType NoteProperty -Name ItemType -Value 'Container'
            $inputObject | Add-Member -MemberType NoteProperty -Name Name -Value ((Split-Path $InputObject.Name -Leaf) -replace '.Tests.ps1') -Force
            $inputObject | Add-Member -MemberType NoteProperty -Name Children -Value $InputObject.Blocks
            $inputObject
            $InputObject.Blocks | Get-PesterTestTree
        }
        'Block' {
            $inputObject | Add-Member -MemberType NoteProperty -Name Depth -Value ($InputObject.Path.Count + 1)
            $inputObject | Add-Member -MemberType NoteProperty -Name Name -Value ($InputObject.ExpandedName) -Force
            $inputObject | Add-Member -MemberType NoteProperty -Name Children -Value $InputObject.Order
            $inputObject
            $InputObject.Order | Get-PesterTestTree
        }
        'Test' {
            $inputObject | Add-Member -MemberType NoteProperty -Name Depth -Value ($InputObject.Path.Count + 1)
            $inputObject | Add-Member -MemberType NoteProperty -Name Name -Value ($InputObject.ExpandedName) -Force
            $inputObject
        }
        default {
            Write-Error "Unknown object type: [$($InputObject.GetType().Name)]"
        }
    }
}

function Set-PesterReportSummary {
    <#

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The Pester result object.
        [Parameter(Mandatory)]
        [Pester.Run] $TestResults
    )

    $testSuitName = $TestResults.Configuration.TestResult.TestSuiteName.Value
    $testSuitStatusIcon = if ($failedTests -gt 0) { '❌' } else { '✅' }
    $formattedTestDuration = $testResults.Duration | Format-TimeSpan

    Details "$testSuitStatusIcon - $testSuitName ($formattedTestDuration)" {
        $testResults | Set-PesterReportSummaryTable

        # $testResults | Set-PesterReportTestsSummary

        # $testResults | Set-PesterReportConfigurationSummary

        # $testResults | Set-PesterReportRunSummary -Sections 'Containers'
    }
}

filter Set-PesterReportSummaryTable {
    <#

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The Pester result object.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Pester.Run] $TestResults
    )

    $statusTable = [pscustomobject]@{
        Total        = $testResults.TotalCount
        Passed       = $testResults.PassedCount
        Failed       = $testResults.FailedCount
        Skipped      = $testResults.SkippedCount
        Inconclusive = $testResults.InconclusiveCount
        NotRun       = $testResults.NotRunCount
    }

    if ($testResults.Configuration.CodeCoverage.Enabled) {
        $coverage = [System.Math]::Round(($testResults.CodeCoverage.CoveragePercent), 2)
        $coverageString = "$coverage%"
        $statusTable | Add-Member -MemberType NoteProperty -Name 'Coverage' -Value $coverageString
    }

    Table {
        $statusTable
    }
}

filter Set-PesterReportTestsSummary {
    <#

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [OutputType([string])]
    [CmdletBinding()]
    param (
        # Specifies the input object, which is expected to be an object in the Pester test result hierarchy.
        # Run, Container, Block, or Test objects are supported.
        [Parameter(Mandatory, ValueFromPipeline)]
        [object] $InputObject,

        # The indentation level for the current item.
        [Parameter()]
        [int] $Depth = 0
    )

    $formattedTestDuration = $inputObject.Duration | Format-TimeSpan
    $testStatusIcon = switch ($Item.Result) {
        'Passed' { '✅' }
        'Failed' { '❌' }
        'Skipped' { '⚠️' }
        default { $Item.Result }
    }

    Write-Verbose "Processing object of type: $($InputObject.GetType().Name)"
    switch ($InputObject.GetType().Name) {
        'Run' {
            $itemIndent = $Indent * $Depth
            $testName = $testResults.Configuration.TestResult.TestSuiteName.Value

            Details "$itemIndent$testStatusIcon - $testName ($formattedTestDuration)" {
                $inputObject.Containers | Set-PesterReportTestsSummary -Depth ($Depth++)
            }
        }
        'Container' {
            $itemIndent = $Indent * $Depth
            $testName = (Split-Path $InputObject.Name -Leaf) -replace '.Tests.ps1'

            Details "$itemIndent$testStatusIcon - $testName ($formattedTestDuration)" {
                $inputObject.Blocks | Set-PesterReportTestsSummary -Depth ($Depth++)
            }
        }
        'Block' {
            $itemIndent = $Indent * $Depth
            $testName = $InputObject.ExpandedName

            Details "$itemIndent$testStatusIcon - $testName ($formattedTestDuration)" {
                $inputObject.Order | Set-PesterReportTestsSummary -Depth ($Depth++)
            }
        }
        'Test' {
            $itemIndent = $Indent * $Depth
            $testName = $InputObject.ExpandedName

            if ($Item.ErrorRecord) {
                Details "$itemIndent$testStatusIcon - $testName ($formattedTestDuration)" {
                    CodeBlock 'pwsh' {
                        $Item.ErrorRecord
                    }
                }
            } else {
                "$itemIndent$testStatusIcon - $testName ($formattedTestDuration)"
            }
        }
        default {
            Write-Error "Unknown object type: [$($InputObject.GetType().Name)]"
        }
    }
}

filter Set-PesterReportConfigurationSummary {
    <#

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The Pester result object.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Pester.Run] $TestResults
    )

    $configurationHashtable = $testResults.Configuration | Convert-PesterConfigurationToHashtable | Format-Hashtable

    Details 'Configuration' {
        CodeBlock 'pwsh' {
            $configurationHashtable
        }
    }
}

filter Set-PesterReportRunSummary {
    <#

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The Pester result object.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Pester.Run] $TestResults,

        [Parameter(Mandatory)]
        [string[]] $Sections
    )

    foreach ($property in ($testResults.PSObject.Properties | Where-Object { $_.Name -notin $Sections })) {
        Write-Verbose "Setting output for [$($property.Name)]"
        $name = $property.Name
        $value = -not [string]::IsNullOrEmpty($property.Value) ? ($property.Value | ConvertTo-Json -Depth 2 -WarningAction SilentlyContinue) : ''

        Details "$indent - $name" {
            CodeBlock 'json' {
                $value
            }
        }
    }
}
