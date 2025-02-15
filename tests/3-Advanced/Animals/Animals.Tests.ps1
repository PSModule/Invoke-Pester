[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Path
)

BeforeAll {
    . $Path
}

Describe 'Animals Module Tests' {
    Context 'Animal Count' {
        It 'Should return the expected number of animals' {
            $expectedCount = $AnimalsSettings.AnimalCount
            $actualCount = $AnimalsSettings.AnimalNames.Count
            $actualCount | Should -Be $expectedCount
        }
    }
    Context 'Animal Names' {
        It 'Should return the expected list of animal names' {
            $expectedNames = $AnimalsSettings.AnimalNames
            $actualNames = $AnimalsSettings.AnimalNames
            $actualNames | Should -BeExactly $expectedNames
        }
    }
}
