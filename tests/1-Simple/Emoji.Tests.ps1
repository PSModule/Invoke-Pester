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
    $script:emojis = @(
        @{ Name = 'apple'; Symbol = '🍎'; Kind = 'Fruit' }
        @{ Name = 'beaming face with smiling eyes'; Symbol = '😁'; Kind = 'Face' }
        @{ Name = 'cactus'; Symbol = '🌵'; Kind = 'Plant' }
        @{ Name = 'giraffe'; Symbol = '🦒'; Kind = 'Animal' }
        @{ Name = 'pencil'; Symbol = '✏️'; Kind = 'Item' }
        @{ Name = 'penguin'; Symbol = '🐧'; Kind = 'Animal' }
        @{ Name = 'pensive'; Symbol = '😔'; Kind = 'Face' }
        @{ Name = 'slightly smiling face'; Symbol = '🙂'; Kind = 'Face' }
        @{ Name = 'smiling face with smiling eyes'; Symbol = '😊'; Kind = 'Face' }
    ) | ForEach-Object { [PSCustomObject]$_ }

    function Get-Emoji {
        <#
            .SYNOPSIS
            Get emoji by name.
        #>
        [CmdletBinding()]
        param(
            [string]$Name = '*'
        )
        $script:emojis | Where-Object Name -Like $Name | ForEach-Object Symbol
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
                $penEmojis = Get-Emoji -Name pen*
            }
            It 'Returns ✏️ (pencil)' {
                $penEmojis | Should -Contain '✏️'
            }

            It 'Returns 🐧 (penguin)' {
                $penEmojis | Should -Contain '🐧'
            }

            It 'Returns 😔 (pensive)' {
                $penEmojis | Should -Contain '😔'
            }
        }

        Context 'by contains' {
            BeforeAll {
                $smilingEmojis = Get-Emoji -Name *smiling*
            }

            It 'Returns 🙂 (slightly smiling face)' {
                $smilingEmojis | Should -Contain '🙂'
            }

            It 'Returns 😁 (beaming face with smiling eyes)' {
                $smilingEmojis | Should -Contain '😁'
            }

            It 'Returns 😊 (smiling face with smiling eyes)' {
                $smilingEmojis | Should -Contain '😊'
            }
        }
    }
}
