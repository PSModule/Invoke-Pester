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


Describe 'Failure' {

    $categories = @(
        @{ Category = 'Get-PSModuleTest'; Expected = 'Get-PSModuleTest' }
        @{ Category = 'New-PSModuleTest'; Expected = 'Hello, World!' }
        @{ Category = 'Set-PSModuleTest'; Expected = 'Set-PSModuleTest' }
    )

    Context 'Cat: <Category> should be <Expected>' -ForEach $categories {
        It 'ItCat: <Category> should be <Expected>' {
            $Category | Should -Be $Expected
        }
    }

    $tests = @(
        @{ Name = 'Get-PSModuleTest'; Expected = 'Get-PSModuleTest' }
        @{ Name = 'New-PSModuleTest'; Expected = 'New-PSModuleTest' }
        @{ Name = 'Set-PSModuleTest'; Expected = 'Hello, World!' }
    )

    It '<Name> should be <Expected>' -ForEach $tests {
        $Name | Should -Be $Expected
    }

    Context 'Something' {
        Describe 'Another thing' {
            It 'True should be false' -Skip {
                $true | Should -Be $false
            }
        }
    }

    It 'True should be false' {
        $true | Should -Be $false
    }
}
