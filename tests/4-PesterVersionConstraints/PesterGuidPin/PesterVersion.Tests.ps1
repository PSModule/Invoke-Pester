#Requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '6.0.0'; GUID = 'a699dea5-2c73-4616-a270-1f7abb777e71' }

Describe 'Pester GUID pin' {
    It 'loads the Pester module identified by its GUID' {
        # The #Requires above pins Pester by module identity (GUID) in addition to version. PowerShell refuses to
        # run this file unless the loaded Pester matches both, so reaching this assertion already proves the pin held.
        # Select the pinned version explicitly so a side-by-side loaded version cannot make the assertion flaky.
        $module = Get-Module -Name Pester | Where-Object { $_.Version -eq [version]'6.0.0' } | Select-Object -First 1

        $module | Should -Not -BeNullOrEmpty
        $module.Guid | Should -Be ([guid]'a699dea5-2c73-4616-a270-1f7abb777e71')
    }
}
