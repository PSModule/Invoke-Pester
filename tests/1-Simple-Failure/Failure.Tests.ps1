﻿[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
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
        @{ Category = 'Get-PSModuleTest'; Expected = 'Hello, World!' }
        @{ Category = 'New-PSModuleTest'; Expected = 'Hello, World!' }
        @{ Category = 'Set-PSModuleTest'; Expected = 'Hello, World!' }
    )

    Context '<Category> should be <Expected>' {
        $Name = 'Get-PSModuleTest'
        $Expected = 'Hello, World!'

        It '<Name> should be <Expected>' {
            $Name | Should -Be $Expected
        }
    }

    $tests = @(
        @{ Name = 'Get-PSModuleTest'; Expected = 'Hello, World!' }
        @{ Name = 'New-PSModuleTest'; Expected = 'Hello, World!' }
        @{ Name = 'Set-PSModuleTest'; Expected = 'Hello, World!' }
    )

    It '<Name> should be <Expected>' -ForEach $tests {
        $Name | Should -Be $Expected
    }

    It 'True should be false' {
        $true | Should -Be $false
    }
}
