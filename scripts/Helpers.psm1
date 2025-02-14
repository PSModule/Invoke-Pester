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
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [TimeSpan] $TimeSpan
    )

    # If the TimeSpan is negative, handle sign and convert to a positive interval for breakdown
    $isNegative = $TimeSpan.Ticks -lt 0
    if ($isNegative) {
        $TimeSpan = New-TimeSpan -Ticks (-1 * $TimeSpan.Ticks)
    }

    # Total ticks in the TimeSpan
    [long]$ticks = $TimeSpan.Ticks

    # Define approximate conversion constants
    [long]$ticksInMillisecond = 10000              # 1 ms = 10,000 ticks
    [long]$ticksInSecond = 10000000           # 1 second = 10 million ticks
    [long]$ticksInMinute = $ticksInSecond * 60
    [long]$ticksInHour = $ticksInMinute * 60
    [long]$ticksInDay = $ticksInHour * 24
    [long]$ticksInWeek = $ticksInDay * 7

    # Approximate day-based constants for months/years:
    # ~30.436875 days in an average month, ~365.2425 days in an average year
    [double]$daysInMonth = 30.436875
    [double]$daysInYear = 365.2425

    [long]$ticksInMonth = [long]($daysInMonth * $ticksInDay)
    [long]$ticksInYear = [long]($daysInYear * $ticksInDay)

    # Extract each component (largest to smallest)
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

    # 1 tick = 100 nanoseconds.
    # Microseconds = leftover ticks * (100 ns) / 1000 => leftover ticks / 10
    $microseconds = [math]::Floor($ticks / 10)
    $ticks = $ticks % 10

    # Remaining ticks are in increments of 100 ns
    $nanoseconds = $ticks * 100

    # Build a list of non-zero components
    $parts = @()
    if ($years -ne 0) { $parts += "$years" + 'y' }
    if ($months -ne 0) { $parts += "$months" + 'mo' }
    if ($weeks -ne 0) { $parts += "$weeks" + 'w' }
    if ($days -ne 0) { $parts += "$days" + 'd' }
    if ($hours -ne 0) { $parts += "$hours" + 'h' }
    if ($minutes -ne 0) { $parts += "$minutes" + 'm' }
    if ($seconds -ne 0) { $parts += "$seconds" + 's' }
    if ($milliseconds -ne 0) { $parts += "$milliseconds" + 'ms' }
    if ($microseconds -ne 0) { $parts += "$microseconds" + 'us' }
    if ($nanoseconds -ne 0) { $parts += "$nanoseconds" + 'ns' }

    # If everything was 0, just show "0s"
    $formatted = if ($parts.Count -eq 0) {
        '0s'
    } else {
        # Join with spaces (or any desired separator)
        $parts -join ' '
    }

    # Add negative sign if original TimeSpan was negative
    if ($isNegative) {
        $formatted = "-$formatted"
    }

    return $formatted
}
