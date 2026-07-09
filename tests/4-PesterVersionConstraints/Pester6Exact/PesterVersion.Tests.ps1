#Requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '6.0.0' }

Describe 'Pester version constraint' {
    It 'uses the exact configured Pester version' {
        $module = Get-Module -Name Pester | Sort-Object Version -Descending | Select-Object -First 1

        $module | Should -Not -Be $null
        $module.Version | Should -Be ([version]'6.0.0')
    }
}