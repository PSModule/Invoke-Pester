filter Get-PesterTestTree {
    <#
        .SYNOPSIS
        Processes Pester test results and returns a structured test tree.

        .DESCRIPTION
        This function processes Pester test results and organizes them into a structured
        test tree. It categorizes objects as Runs, Containers, Blocks, or Tests,
        adding relevant properties such as depth and item type. This allows for better
        visualization and analysis of Pester test results.

        .EXAMPLE
        $testResults = Invoke-Pester -Path 'C:\Repos\GitHub\PSModule\Action\Invoke-Pester\tests\1-Simple-Failure\Failure.Tests.ps1' -PassThru
        $testResults | Get-PesterTestTree | Format-Table -AutoSize -Property Depth, Name, ItemType, Result, Duration, ErrorRecord

        Output:
        ```powershell
        Depth Name              ItemType   Result   Duration ErrorRecord
        ----- ----              --------   ------   -------- -----------
            0 Failure.Tests     Container Passed   0.012s
            1 Describe Block 1  Block     Failed   0.003s    System.Exception: Failure message
        ```

        Retrieves and formats Pester test results into a hierarchical tree structure.

        .OUTPUTS
        PSCustomObject

        .NOTES
        Returns an object representing the hierarchical structure of
        Pester test results, including depth, name, item type, and result status.
    #>

    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param (
        # Specifies the input object, which is expected to be an object in the Pester test result hierarchy.
        # Run, Container, Block, or Test objects are supported.
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [object] $InputObject
    )

    $inputObject = [pscustomobject]$InputObject

    Write-Verbose "Processing object of type: $($InputObject.GetType().Name)"
    switch ($InputObject.GetType().Name) {
        'Run' {
            $inputObject | Add-Member -MemberType NoteProperty -Name Depth -Value 0
            $inputObject | Add-Member -MemberType NoteProperty -Name ItemType -Value 'TestSuite'
            $inputObject | Add-Member -MemberType NoteProperty -Name Name -Value $($testResults.Configuration.TestResult.TestSuiteName.Value) -Force
            $inputObject
            $inputObject.Containers | Get-PesterTestTree
        }
        'Container' {
            $inputObject | Add-Member -MemberType NoteProperty -Name Depth -Value 1
            $inputObject | Add-Member -MemberType NoteProperty -Name ItemType -Value 'Container'
            $inputObject | Add-Member -MemberType NoteProperty -Name Name -Value ((Split-Path $InputObject.Name -Leaf) -replace '.Tests.ps1') -Force
            $inputObject
            $InputObject.Blocks | Get-PesterTestTree
        }
        'Block' {
            $inputObject | Add-Member -MemberType NoteProperty -Name Depth -Value ($InputObject.Path.Count + 1)
            $inputObject | Add-Member -MemberType NoteProperty -Name Name -Value ($InputObject.ExpandedName) -Force
            $inputObject
            $InputObject.Order | Get-PesterTestTree
        }
        'Test' {
            $inputObject | Add-Member -MemberType NoteProperty -Name Depth -Value ($InputObject.Path.Count + 1)
            $inputObject | Add-Member -MemberType NoteProperty -Name Name -Value ($InputObject.ExpandedName) -Force
            $inputObject
        }
        default {
            Write-Error "Unknown object type: [$($InputObject.GetType().Name)]"
        }
    }
}
