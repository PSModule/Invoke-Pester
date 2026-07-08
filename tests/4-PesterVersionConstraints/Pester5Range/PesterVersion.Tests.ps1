#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0'; MaximumVersion = '5.*' }

Describe 'Pester version constraint' {
    It 'uses a Pester 5.x version resolved from the configured range' {
        $module = Get-Module -Name Pester | Sort-Object Version -Descending | Select-Object -First 1

        $module | Should -Not -Be $null
        $module.Version.Major | Should -Be 5
        $module.Version | Should -BeGreaterOrEqual ([version]'5.0.0')
        $module.Version | Should -BeLessThan ([version]'6.0.0')
    }
}