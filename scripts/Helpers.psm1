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
    Write-Host "Found $($containerFiles.Count) container files."

    foreach ($file in $containerFiles) {
        Write-Host "Loading container file: $($file.FullName)"
        $container = . $file.FullName
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

    #>
    [CmdletBinding()]
    param()

    # Prepare the output hashtable
    $result = @{}

    $schema = [PesterConfiguration]::new()

    # Iterate over each top-level category (Run, Filter, etc.)
    foreach ($category in $schema.PSObject.Properties.Name) {
        $categoryObj = $schema.$category
        $subHash = @{}

        # Iterate over each setting within the category
        foreach ($settingName in $categoryObj.PSObject.Properties.Name) {
            $subHash[$settingName] = $null
        }

        $result[$category] = $subHash
    }
    $result
}

filter Convert-PesterConfigurationToHashtable {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [PesterConfiguration] $PesterConfiguration
    )

    # Prepare the output hashtable
    $result = @{}

    # Iterate over each top-level category (Run, Filter, etc.)
    foreach ($category in $PesterConfiguration.PSObject.Properties.Name) {
        $categoryObj = $PesterConfiguration.$category
        $subHash = @{}

        # Iterate over each setting within the category
        foreach ($settingName in $categoryObj.PSObject.Properties.Name) {
            $setting = $categoryObj.$settingName

            # Only consider settings that have IsModified true
            if ($setting -and $setting.PSObject.Properties.Match('IsModified') -and $setting.IsModified) {

                # Ensure both Default and Value properties exist.
                if ($setting.PSObject.Properties.Match('Default') -and $setting.PSObject.Properties.Match('Value')) {

                    # Compare types (unless handling of nulls is desired differently).
                    if (($null -ne $setting.Value) -and ($null -ne $setting.Default)) {
                        if ($setting.Value.GetType().FullName -eq $setting.Default.GetType().FullName) {
                            $subHash[$settingName] = $setting.Value
                        }
                    } else {
                        # If both are null, include the key (adjust as needed).
                        if (($null -eq $setting.Value) -and ($null -eq $setting.Default)) {
                            $subHash[$settingName] = $null
                        }
                    }
                }
            }
        }

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
    [OutputType([Hashtable])]
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
                $testStatusIcon = $test.Result -eq 'Passed' ? '✅' : '❌'
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

$nbsp = [char]0x00A0
$indent = "$nbsp" * 4
