[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Path
)

BeforeAll {
    . $Path
}

Describe 'Cars Module Tests' {

    Context 'Car Count' {
        It 'Should return the expected number of car models' {
            $expectedCount = $CarsSettings.CarCount
            $actualCount = $CarsSettings.CarModels.Count
            $actualCount | Should -Be $expectedCount
        }
    }

    Context 'Car Models' {
        It 'Should return the expected list of car models' {
            $expectedModels = $CarsSettings.CarModels
            $actualModels = $CarsSettings.CarModels
            $actualModels | Should -BeExactly $expectedModels
        }
    }
}
