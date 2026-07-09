#Requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '6.0.0' }

Describe 'Pester GUID input (match)' {
    It 'runs when the Guid input matches the installed Pester identity' {
        # The GUID is pinned through the action's Guid input (validated at install), not via #Requires here,
        # so reaching and passing this test proves the matching Guid input let the run proceed.
        $module = Get-Module -Name Pester | Sort-Object Version -Descending | Select-Object -First 1

        $module | Should -Not -Be $null
        $module.Version | Should -Be ([version]'6.0.0')
        $module.Guid | Should -Be ([guid]'a699dea5-2c73-4616-a270-1f7abb777e71')
    }
}
