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

        # If set to $true, do a rounding pass from nanoseconds -> microseconds -> milliseconds -> seconds, etc.
        # so that e.g. 999ms + leftover microseconds could become 1s, dropping microseconds/nanoseconds.
        [switch] $AdaptiveRounding
    )

    #----- 1) Handle negative TimeSpan -----
    $isNegative = $TimeSpan.Ticks -lt 0
    if ($isNegative) {
        $TimeSpan = New-TimeSpan -Ticks (-1 * $TimeSpan.Ticks)
    }

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

    #----- 4) If requested, do an adaptive "rounding up" pass -----
    if ($AdaptiveRounding) {
        # Round nanoseconds -> microseconds
        # e.g. if nano >= 500, round up microseconds by 1
        if ($nanoseconds -ge 500) {
            $microseconds++
        }
        $nanoseconds = 0

        # Carry microseconds -> milliseconds
        if ($microseconds -ge 1000) {
            $milliseconds += [math]::Floor($microseconds / 1000)
            $microseconds = $microseconds % 1000
        }

        # Carry milliseconds -> seconds
        if ($milliseconds -ge 1000) {
            $seconds += [math]::Floor($milliseconds / 1000)
            $milliseconds = $milliseconds % 1000
        }

        # Carry seconds -> minutes
        if ($seconds -ge 60) {
            $minutes += [math]::Floor($seconds / 60)
            $seconds = $seconds % 60
        }

        # Carry minutes -> hours
        if ($minutes -ge 60) {
            $hours += [math]::Floor($minutes / 60)
            $minutes = $minutes % 60
        }

        # Carry hours -> days
        if ($hours -ge 24) {
            $days += [math]::Floor($hours / 24)
            $hours = $hours % 24
        }

        # Carry days -> weeks
        if ($days -ge 7) {
            $weeks += [math]::Floor($days / 7)
            $days = $days % 7
        }

        # Approx: 4 weeks = 1 month
        if ($weeks -ge 4) {
            $months += [math]::Floor($weeks / 4)
            $weeks = $weeks % 4
        }

        # 12 months = 1 year
        if ($months -ge 12) {
            $years += [math]::Floor($months / 12)
            $months = $months % 12
        }
    }

    #----- 5) Apply Precision Filtering -----
    # Map each unit to a numeric rank
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

    # Gather all units in descending order
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

    # Filter out units that rank below the chosen precision or have zero value
    $parts = foreach ($item in $components) {
        $name = $item[0]
        $value = $item[1]
        $abbr = $item[2]
        if ($unitRank[$name] -le $lowestUnitAllowed -and $value -ne 0) {
            "$value$abbr"
        }
    }

    # If no parts remain, it means everything was 0 => "0s"
    if ($parts.Count -eq 0) {
        $parts = @('0s')
    }

    $formatted = $parts -join ' '

    #----- 6) Reapply sign if negative -----
    if ($isNegative) {
        $formatted = "-$formatted"
    }

    return $formatted
}
