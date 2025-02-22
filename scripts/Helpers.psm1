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

function Get-GroupedTestMarkdown {
    <#
        .SYNOPSIS
        Generates a grouped and formatted Markdown summary of test results.

        .DESCRIPTION
        This function takes a collection of test results and organizes them into a hierarchical
        Markdown format based on their path depth. It groups tests dynamically and represents their
        results using icons, displaying test failures and durations appropriately. If a group contains
        nested test results, the function calls itself recursively to generate a structured summary.

        .EXAMPLE
        Get-GroupedTestMarkdown -Tests $testResults -Depth 0

        Output:
        ```
        <details><summary>✅ - Group A (00:02:30)</summary>
        <p>
        <details><summary>❌ - Test 1 (00:00:45)</summary>
        <p>

        ``````
        Test failed due to timeout
        ``````

        </p>
        </details>
        </p>
        </details>
        ```

        Generates a Markdown summary of test results, grouping them by their hierarchical depth.

        .OUTPUTS
        string

        .NOTES
        A formatted Markdown string summarizing test results.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The collection of test results to be grouped and formatted.
        [Parameter(Mandatory)]
        [array] $Tests,

        # The depth at which to group tests. Defaults to 0.
        [Parameter()]
        [int] $Depth
    )

    $markdown = ''
    # Group tests by the element at position $Depth (or "Ungrouped" if not present)
    $groups = $Tests | Group-Object { if ($_.Path.Count -gt $Depth) { $_.Path[$Depth] } else { 'Ungrouped' } } | Sort-Object Name
    foreach ($group in $groups) {
        $groupName = $group.Name
        $groupTests = $group.Group
        $groupIndent = $Indent * ($Depth + 2)
        # Calculate aggregate status: if any test failed, mark the group as failed
        $groupStatusIcon = if ($groupTests | Where-Object { $_.Result -eq 'Failed' }) { '❌' } else { '✅' }
        # Calculate aggregate duration: sum all test durations
        $groupDuration = [System.TimeSpan]::Zero
        $groupTests.Duration | ForEach-Object { $groupDuration += $_ }
        $formattedGroupDuration = $groupDuration | Format-TimeSpan

        # If any test has further parts, create a nested details block...
        if ($groupTests | Where-Object { $_.Path.Count -gt ($Depth + 1) }) {
            $markdown += @"
<details><summary>$groupIndent$groupStatusIcon - $groupName ($formattedGroupDuration)</summary>
<p>
$(Get-GroupedTestMarkdown -Tests $groupTests -Depth ($Depth + 1))
</p>
</details>

"@
        } else {
            # Otherwise, list each test at this level
            foreach ($test in $groupTests) {
                $testName = $test.Path[$Depth]
                $testStatusIcon = switch ($test.Result) {
                    'Passed' { '✅' }
                    'Failed' { '❌' }
                    'Skipped' { '⚠️' }
                    default { $test.Result }
                }
                $formattedDuration = $test.Duration | Format-TimeSpan
                $markdown += @"
<details><summary>$groupIndent$testStatusIcon - $testName ($formattedDuration)</summary>
<p>

"@
                if ($test.Result -eq 'Failed' -and $test.ErrorRecord.Exception.Message) {
                    $markdown += @"

``````
$($test.ErrorRecord.Exception.Message)
``````

"@
                }
                $markdown += @'
</p>
</details>

'@
            }
        }
    }
    return $markdown
}
