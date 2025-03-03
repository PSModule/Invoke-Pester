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
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

Describe 'Get-Emoji' {
    Context 'Lookup by whole name' {
        It 'Returns 🌵 (cactus)' {
            (Get-Emoji -Name cactus).Symbol | Should -Be '🌵'
        }

        It 'Returns 🦒 (giraffe)' {
            Get-Emoji -Name giraffe -Property Symbol | Should -Be '🦒'
        }
    }

    Context 'Lookup by wildcard' {
        Context 'by prefix' {
            BeforeAll {
                $penEmojis = Get-Emoji -Name pen*
            }
            It 'Returns ✏️ (pencil)' {
                $penEmojis.Symbol | Should -Contain '✏️'
            }

            It 'Returns 🐧 (penguin)' {
                $penEmojis.Kind | Should -Contain 'Animal'
            }

            It 'Returns 😔 (pensive)' {
                $penEmojis.Name | Should -Contain 'pensive'
            }
        }

        Context 'by contains' {
            BeforeAll {
                $smilingEmojis = Get-Emoji -Name *smiling*
            }

            It 'Returns 🙂 (slightly smiling face)' {
                $smilingEmojis.Symbol | Should -Contain '🙂'
            }

            It 'Returns 😁 (beaming face with smiling eyes)' {
                $smilingEmojis.Kind | Should -Contain 'Face'
            }

            It 'Returns 😊 (smiling face with smiling eyes)' {
                $smilingEmojis.Name | Should -Contain 'smiling face with smiling eyes'
            }
        }
    }
}
