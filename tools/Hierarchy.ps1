filter Get-Result {
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        $Item
    )

    switch ($Item.GetType().Name) {
        'Container' {
            [pscustomobject]@{
                Depth       = 0
                Result      = $Item.Result
                ItemType    = $Item.ItemType
                Name        = (Split-Path $Item.Name -Leaf) -replace '.Tests.ps1'
                Duration    = $Item.Duration
                ErrorRecord = $Item.ErrorRecord
            }
            $Item.Blocks | ForEach-Object {
                $_ | Get-Result
            }
        }
        'Block' {
            [pscustomobject]@{
                Depth       = $Item.Path.Count
                Result      = $Item.Result
                ItemType    = $Item.ItemType
                Name        = $Item.ExpandedName
                Duration    = $Item.Duration
                ErrorRecord = $Item.ErrorRecord
            }
            $Item.Order | ForEach-Object {
                $_ | Get-Result
            }
        }
        'Test' {
            [pscustomobject]@{
                Depth    = $Item.Path.Count
                Result   = $Item.Result
                ItemType = $Item.ItemType
                Name     = $Item.ExpandedName
                Duration = $Item.Duration
            }
        }
    }
}
$testResults = Invoke-Pester -Path 'C:\Repos\GitHub\PSModule\Action\Invoke-Pester\tests\1-Simple-Failure\Failure.Tests.ps1' -PassThru

$testResults.Containers | ForEach-Object {
    Get-Result -Item $_
} | Format-Table -AutoSize

