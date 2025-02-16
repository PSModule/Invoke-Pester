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

    Get-ChildItem -Path $Path -Recurse -Filter *.Container.ps* | ForEach-Object {
        $file = $_
        switch ($file.Extension) {
            '.ps1' {
                . $file
            }
            '.psd1' {
                Import-PowerShellDataFile -Path $file
            }
        }
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

    Write-Output "Path: [$Path]"
    $pathExists = Test-Path -Path $Path
    if (-not $pathExists) {
        throw "Test path does not exist: [$Path]"
    }
    $item = $Path | Get-Item

    if ($item.PSIsContainer) {
        $file = Get-ChildItem -Path $Path -Filter *.Configuration.*
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

    switch ($file.Extension) {
        '.ps1' {
            . $file
        }
        '.psd1' {
            Import-PowerShellDataFile -Path $file
        }
    }
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

function Merge-Hashtable {
    <#
        .SYNOPSIS
        Merges two or more hashtables, with later hashtables overriding earlier ones.

        .DESCRIPTION
        This function merges multiple hashtables by applying overrides in order.
        The values from later hashtables in the `Overrides` parameter replace values
        from earlier hashtables, following a "last write wins" strategy.
        The function returns a new hashtable without modifying the original inputs.

        .EXAMPLE
        $Main = [ordered]@{
            Action   = ''
            Location = 'Main'
            Name     = 'Main'
            Mode     = 'Main'
        }
        $Override1 = [ordered]@{
            Action   = ''
            Location = ''
            Name     = 'Override1'
            Mode     = 'Override1'
        }
        $Override2 = [ordered]@{
            Action   = ''
            Location = ''
            Name     = 'Override1'
            Mode     = 'Override2'
        }
        Merge-Hashtables -Main $Main -Overrides $Override1, $Override2

        Output:
        ```powershell
        Name     : Override1
        Mode     : Override2
        Location : Main
        Action   :
        ```

        This example demonstrates merging multiple hashtables where values in later
        overrides replace earlier values while preserving keys from the main hashtable.

        .OUTPUTS
        Hashtable

        .NOTES
        Returns a merged hashtable where values from later overrides replace earlier ones.
    #>
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param (
        # Main hashtable
        [Parameter(Mandatory)]
        [Hashtable] $Main,

        # Hashtable with overrides.
        # Providing a list of overrides will apply them in order.
        # Last write wins.
        [Parameter(Mandatory)]
        [Hashtable[]] $Overrides
    )

    $Output = $Main.Clone()
    foreach ($Override in $Overrides) {
        foreach ($Key in $Override.Keys) {
            if (($Output.Keys) -notcontains $Key) {
                $Output.$Key = $Override.$Key
            }
            if (-not [string]::IsNullOrEmpty($Override[$Key])) {
                $Output.$Key = $Override.$Key
            }
        }
    }
    return $Output
}

filter Format-TimeSpan {
    <#
        .SYNOPSIS
        Formats a TimeSpan object into a human-readable string with the most appropriate unit.

        .DESCRIPTION
        The Format-TimeSpan function takes a TimeSpan object and returns a string representation of the duration
        using the most significant unit (e.g., years, months, weeks, days, hours, minutes, etc.).

        The function adapts dynamically to the scale of the input and ensures an appropriate level of rounding.
        Negative TimeSpan values are handled properly by converting to absolute values for formatting
        and appending a negative sign to the output.

        .EXAMPLE
        [TimeSpan]::FromDays(45) | Format-TimeSpan

        Output:
        ```powershell
        1mo
        ```

        Formats a TimeSpan of 45 days into the closest unit, which is 1 month.

        .EXAMPLE
        [TimeSpan]::FromSeconds(90) | Format-TimeSpan

        Output:
        ```powershell
        1m
        ```

        Converts 90 seconds into the most significant unit, which is 1 minute.

        .EXAMPLE
        [TimeSpan]::FromMilliseconds(500) | Format-TimeSpan

        Output:
        ```powershell
        500ms
        ```

        Converts 500 milliseconds directly into milliseconds as it's the most appropriate unit.

        .OUTPUTS
        System.String

        .NOTES
        Returns a string representing the formatted TimeSpan using the most significant unit.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The TimeSpan object to be formatted into a human-readable string.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [TimeSpan] $TimeSpan
    )

    #----- 1) Handle negative TimeSpan -----
    $isNegative = $TimeSpan.Ticks -lt 0
    if ($isNegative) {
        $TimeSpan = New-TimeSpan -Ticks (-1 * $TimeSpan.Ticks)
    }

    # Save original ticks for fractional math.
    $originalTicks = $TimeSpan.Ticks

    #----- 2) Define constants -----
    [long] $ticks = $TimeSpan.Ticks
    [long] $ticksInMillisecond = 10000       # 1 ms = 10,000 ticks
    [long] $ticksInSecond = 10000000          # 1 s  = 10,000,000 ticks
    [long] $ticksInMinute = $ticksInSecond * 60
    [long] $ticksInHour = $ticksInMinute * 60
    [long] $ticksInDay = $ticksInHour * 24
    [long] $ticksInWeek = $ticksInDay * 7

    # Approximate day-based constants for months & years
    [double] $daysInMonth = 30.436875
    [double] $daysInYear = 365.2425
    [long] $ticksInMonth = [long]($daysInMonth * $ticksInDay)
    [long] $ticksInYear = [long]($daysInYear * $ticksInDay)

    #----- 3) Extract units from largest to smallest -----
    $years = [math]::Floor($ticks / $ticksInYear)
    $ticks %= $ticksInYear
    $months = [math]::Floor($ticks / $ticksInMonth)
    $ticks %= $ticksInMonth
    $weeks = [math]::Floor($ticks / $ticksInWeek)
    $ticks %= $ticksInWeek
    $days = [math]::Floor($ticks / $ticksInDay)
    $ticks %= $ticksInDay
    $hours = [math]::Floor($ticks / $ticksInHour)
    $ticks %= $ticksInHour
    $minutes = [math]::Floor($ticks / $ticksInMinute)
    $ticks %= $ticksInMinute
    $seconds = [math]::Floor($ticks / $ticksInSecond)
    $ticks %= $ticksInSecond
    $milliseconds = [math]::Floor($ticks / $ticksInMillisecond)
    $ticks %= $ticksInMillisecond
    $microseconds = [math]::Floor($ticks / 10)
    $ticks %= 10
    $nanoseconds = $ticks * 100

    #----- 4) Build a list of components -----
    $components = [System.Collections.Generic.List[object]]::new()
    $components.Add(@('Years', $years, 'y'))
    $components.Add(@('Months', $months, 'mo'))
    $components.Add(@('Weeks', $weeks, 'w'))
    $components.Add(@('Days', $days, 'd'))
    $components.Add(@('Hours', $hours, 'h'))
    $components.Add(@('Minutes', $minutes, 'm'))
    $components.Add(@('Seconds', $seconds, 's'))
    $components.Add(@('Milliseconds', $milliseconds, 'ms'))
    $components.Add(@('Microseconds', $microseconds, 'us'))
    $components.Add(@('Nanoseconds', $nanoseconds, 'ns'))

    # Map each unit to a numeric rank (lower = more significant)
    $unitRank = @{
        'Years'        = 1
        'Months'       = 2
        'Weeks'        = 3
        'Days'         = 4
        'Hours'        = 5
        'Minutes'      = 6
        'Seconds'      = 7
        'Milliseconds' = 8
        'Microseconds' = 9
        'Nanoseconds'  = 10
    }
    # With no Precision parameter, allow all units (Nanoseconds rank is 10)
    [int] $lowestUnitAllowed = 10

    #----- 5) Adaptive rounding: Pick the first (highest) nonzero unit -----
    $highestUnitComponent = $null
    foreach ($comp in $components) {
        $unitName = $comp[0]
        $value = $comp[1]
        if ($unitRank[$unitName] -le $lowestUnitAllowed -and $value -ne 0) {
            $highestUnitComponent = $comp
            break
        }
    }
    if (-not $highestUnitComponent) {
        # If all components are zero, fall back to Nanoseconds.
        $highestUnitComponent = $components[-1]
    }
    $unitName = $highestUnitComponent[0]
    $unitAbbr = $highestUnitComponent[2]

    # Compute the full timespan in the chosen unit.
    switch ($unitName) {
        'Years' { $fractionalValue = $originalTicks / $ticksInYear }
        'Months' { $fractionalValue = $originalTicks / $ticksInMonth }
        'Weeks' { $fractionalValue = $originalTicks / $ticksInWeek }
        'Days' { $fractionalValue = $originalTicks / $ticksInDay }
        'Hours' { $fractionalValue = $originalTicks / $ticksInHour }
        'Minutes' { $fractionalValue = $originalTicks / $ticksInMinute }
        'Seconds' { $fractionalValue = $originalTicks / $ticksInSecond }
        'Milliseconds' { $fractionalValue = $originalTicks / $ticksInMillisecond }
        'Microseconds' { $fractionalValue = $originalTicks / 10 }
        'Nanoseconds' { $fractionalValue = $originalTicks * 100 }
    }

    # Round to the nearest integer.
    $roundedValue = [math]::Round($fractionalValue, 0, [System.MidpointRounding]::AwayFromZero)
    $formatted = "$roundedValue$unitAbbr"
    if ($isNegative) {
        $formatted = "-$formatted"
    }
    return $formatted
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
