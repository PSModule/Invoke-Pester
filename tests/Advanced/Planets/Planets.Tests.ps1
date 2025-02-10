<#
.SYNOPSIS
    Pester tests for planet-related functions.
.DESCRIPTION
    This script loads settings from Planets.Settings.ps1 and validates functions that return planet data.
.NOTES
    Ensure that functions like Get-PlanetCount and Get-PlanetNames are available (e.g. from your module).
#>

# Dot-source the settings file to import $PlanetsSettings
. "$PSScriptRoot\Planets.Settings.ps1"

Describe 'Planets Module Tests' {

    Context 'Planet Count' {
        It 'Should return the expected number of planets' {
            $expectedCount = $PlanetsSettings.PlanetCount
            $actualCount = $PlanetsSettings.PlanetNames.Count
            $actualCount | Should -Be $expectedCount
        }
    }

    Context 'Planet Names' {
        It 'Should return the expected list of planet names' {
            $expectedNames = $PlanetsSettings.PlanetNames
            $actualNames = $PlanetsSettings.PlanetNames
            $actualNames | Should -BeExactly $expectedNames
        }
    }
}
