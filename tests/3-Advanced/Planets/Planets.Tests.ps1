[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Required for Pester tests'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Required for Pester tests'
)]
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Path
)

BeforeAll {
    . $Path
}

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
