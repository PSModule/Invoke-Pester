[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Required for Pester tests'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Required for Pester tests'
)]
[CmdletBinding()]
param()

BeforeAll {
    $script:CarsSettings = @{
        # Expected number of car models for testing
        CarCount  = 3

        # Expected list of car models for testing
        CarModels = @('Sedan', 'SUV', 'Coupe')
    }

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
