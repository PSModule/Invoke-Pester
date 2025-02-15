[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Path
)

Describe 'Emoji' {
    It 'Module is importable' {
        $null = Import-Module -Name $Path -PassThru | Should -Not -Throw
    }
}

Describe 'Get-Emoji' {
    Context 'Lookup by whole name' {
        It 'Returns 🌵 (cactus)' {
            Get-Emoji -Name cactus | Should -Be '🌵'
        }

        It 'Returns 🦒 (giraffe)' {
            Get-Emoji -Name giraffe | Should -Be '🦒'
        }
    }

    Context 'Lookup by wildcard' {
        Context 'by prefix' {
            BeforeAll {
                $emojis = Get-Emoji -Name pen*
            }

            It 'Returns ✏️ (pencil)' {
                $emojis | Should -Contain '✏️'
            }

            It 'Returns 🐧 (penguin)' {
                $emojis | Should -Contain '🐧'
            }

            It 'Returns 😔 (pensive)' {
                $emojis | Should -Contain '😔'
            }
        }

        Context 'by contains' {
            BeforeAll {
                $emojis = Get-Emoji -Name *smiling*
            }

            It 'Returns 🙂 (slightly smiling face)' {
                $emojis | Should -Contain '🙂'
            }

            It 'Returns 😁 (beaming face with smiling eyes)' {
                $emojis | Should -Contain '😁'
            }

            It 'Returns 😊 (smiling face with smiling eyes)' {
                $emojis | Should -Contain '😊'
            }
        }
    }
}
