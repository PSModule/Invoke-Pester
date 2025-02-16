[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Required for Pester tests'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Required for Pester tests'
)]
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Path
)

Describe 'Emoji' {
    It 'Module is importable' {
        { Import-Module -Name $Path } | Should -Not -Throw
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
                $script:emojis = Get-Emoji -Name pen*
            }

            It 'Returns ✏️ (pencil)' {
                $script:emojis | Should -Contain '✏️'
            }

            It 'Returns 🐧 (penguin)' {
                $script:emojis | Should -Contain '🐧'
            }

            It 'Returns 😔 (pensive)' {
                $script:emojis | Should -Contain '😔'
            }
        }

        Context 'by contains' {
            BeforeAll {
                $script:emojis = Get-Emoji -Name *smiling*
            }

            It 'Returns 🙂 (slightly smiling face)' {
                $script:emojis | Should -Contain '🙂'
            }

            It 'Returns 😁 (beaming face with smiling eyes)' {
                $script:emojis | Should -Contain '😁'
            }

            It 'Returns 😊 (smiling face with smiling eyes)' {
                $script:emojis | Should -Contain '😊'
            }
        }
    }
}
