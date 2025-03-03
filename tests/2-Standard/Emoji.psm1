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
        [string] $Name = '*',
        [string] $Property
    )
    if ($Property) {
        $script:emojis | Where-Object Name -Like $Name | ForEach-Object $Property
    } else {
        $script:emojis | Where-Object Name -Like $Name
    }
}

function Get-EmojiByKind {
    <#
            .SYNOPSIS
            Get emoji by kind.
        #>
    [CmdletBinding()]
    param(
        [string] $Kind
    )
    $script:emojis | Where-Object Kind -EQ $Kind
}
