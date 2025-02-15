function Get-PesterContainer {
    param(
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
    param(
        [string] $Path
    )

    Get-ChildItem -Path $Path -Filter *.Configuration.ps* | ForEach-Object {
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

function Merge-Hashtable {
    <#
        .SYNOPSIS
        Merge two hashtables, with the second hashtable overriding the first

        .DESCRIPTION
        Merge two hashtables, with the second hashtable overriding the first

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
    #>
    [OutputType([Hashtable])]
    [Alias('Merge-Hashtables')]
    [CmdletBinding()]
    param (
        # Main hashtable
        [Parameter(Mandatory)]
        [object] $Main,

        # Hashtable with overrides.
        # Providing a list of overrides will apply them in order.
        # Last write wins.
        [Parameter(Mandatory)]
        [object[]] $Overrides
    )
    $Output = $Main.Clone()
    foreach ($Override in $Overrides) {
        foreach ($Key in $Override.Keys) {
            if (($Output.Keys) -notcontains $Key) {
                $Output.$Key = $Override.$Key
            }
            if (-not [string]::IsNullOrEmpty($Override.item($Key))) {
                $Output.$Key = $Override.$Key
            }
        }
    }
    return $Output
}

filter Format-TimeSpan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [TimeSpan] $TimeSpan,

        [ValidateSet('Years', 'Months', 'Weeks', 'Days', 'Hours', 'Minutes', 'Seconds', 'Milliseconds', 'Microseconds', 'Nanoseconds')]
        [string] $Precision = 'Nanoseconds',

        # If set, round the entire timespan to the nearest integer in the highest allowed unit.
        [switch] $AdaptivePrecission
    )

    #----- 1) Handle negative TimeSpan -----
    $isNegative = $TimeSpan.Ticks -lt 0
    if ($isNegative) {
        $TimeSpan = New-TimeSpan -Ticks (-1 * $TimeSpan.Ticks)
    }

    # Save original ticks for later fractional math.
    $originalTicks = $TimeSpan.Ticks

    #----- 2) Define constants -----
    [long] $ticks = $TimeSpan.Ticks

    # 1 tick = 100 ns
    [long] $ticksInMillisecond = 10000       # 1 ms = 10,000 ticks
    [long] $ticksInSecond = 10000000    # 1 s  = 10,000,000 ticks
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
    $ticks = $ticks % $ticksInYear

    $months = [math]::Floor($ticks / $ticksInMonth)
    $ticks = $ticks % $ticksInMonth

    $weeks = [math]::Floor($ticks / $ticksInWeek)
    $ticks = $ticks % $ticksInWeek

    $days = [math]::Floor($ticks / $ticksInDay)
    $ticks = $ticks % $ticksInDay

    $hours = [math]::Floor($ticks / $ticksInHour)
    $ticks = $ticks % $ticksInHour

    $minutes = [math]::Floor($ticks / $ticksInMinute)
    $ticks = $ticks % $ticksInMinute

    $seconds = [math]::Floor($ticks / $ticksInSecond)
    $ticks = $ticks % $ticksInSecond

    $milliseconds = [math]::Floor($ticks / $ticksInMillisecond)
    $ticks = $ticks % $ticksInMillisecond

    # 1 tick = 100 ns, so microseconds = leftover ticks / 10
    $microseconds = [math]::Floor($ticks / 10)
    $ticks = $ticks % 10

    # leftover ticks * 100 ns = nanoseconds
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
    [int] $lowestUnitAllowed = $unitRank[$Precision]

    #----- 5) Adaptive rounding (if switch set) -----
    if ($AdaptivePrecission) {

        # Find the first (highest) allowed unit that is nonzero.
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
            # If none of the allowed components are nonzero, use the one matching $Precision.
            $highestUnitComponent = $components | Where-Object { $_[0] -eq $Precision } | Select-Object -First 1
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

        # Round to the nearest integer (i.e. if at least half the next unit, round up)
        $roundedValue = [math]::Round($fractionalValue, 0, [System.MidpointRounding]::AwayFromZero)
        $formatted = "$roundedValue$unitAbbr"

        if ($isNegative) {
            $formatted = "-$formatted"
        }
        return $formatted
    } else {
        #----- 6) Normal behavior: filter and output multiple components -----
        $parts = foreach ($item in $components) {
            $name = $item[0]
            $value = $item[1]
            $abbr = $item[2]
            if ($unitRank[$name] -le $lowestUnitAllowed -and $value -ne 0) {
                "$value$abbr"
            }
        }

        if ($parts.Count -eq 0) {
            $parts = @('0s')
        }
        $formatted = $parts -join ' '

        if ($isNegative) {
            $formatted = "-$formatted"
        }
        return $formatted
    }
}

function Get-GroupedTestMarkdown {
    param(
        [Parameter(Mandatory)]
        [array]$Tests,
        [int]$Depth
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
        $formattedGroupDuration = $groupDuration | Format-TimeSpan -AdaptivePrecission

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
                $formattedDuration = $test.Duration | Format-TimeSpan -AdaptivePrecission
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
