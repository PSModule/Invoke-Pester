# Classes

## TestResults

```plaintext
Containers            : {[-] C:\Repos\GitHub\PSModule\Action\Invoke-Pester\tests\1-Simple-Failure\Failure.Tests.ps1}
Result                : Failed
FailedCount           : 7
FailedBlocksCount     : 0
FailedContainersCount : 0
PassedCount           : 0
SkippedCount          : 0
InconclusiveCount     : 0
NotRunCount           : 0
TotalCount            : 7
Duration              : 00:00:00.0657533
Executed              : True
ExecutedAt            : 2/22/2025 7:35:53 PM
Version               : 5.7.1
PSVersion             : 7.5.0
PSBoundParameters     : {[Path, System.String[]], [PassThru, True]}
Plugins               :
PluginConfiguration   :
PluginData            :
Configuration         : PesterConfiguration
DiscoveryDuration     : 00:00:00.0097464
UserDuration          : 00:00:00.0081193
FrameworkDuration     : 00:00:00.0478876
Failed                : {[-] Get-PSModuleTest should be Hello, World!, [-] New-PSModuleTest should be Hello, World!, [-] Set-PSModuleTest should be Hello, World!, [-] True should be false…}
FailedBlocks          : {}
FailedContainers      : {}
Passed                : {}
Skipped               : {}
Inconclusive          : {}
NotRun                : {}
Tests                 : {[-] Get-PSModuleTest should be Hello, World!, [-] New-PSModuleTest should be Hello, World!, [-] Set-PSModuleTest should be Hello, World!, [-] True should be false…}
CodeCoverage          :
```

## Container

```plaintext
Name              : C:\Repos\GitHub\PSModule\Action\Invoke-Pester\tests\1-Simple-Failure\Failure.Tests.ps1
Type              : File
Item              : C:\Repos\GitHub\PSModule\Action\Invoke-Pester\tests\1-Simple-Failure\Failure.Tests.ps1
Data              : {}
Blocks            : {[-] Failure}
Result            : Failed
Duration          : 00:00:00.0657533
FailedCount       : 7
PassedCount       : 0
SkippedCount      : 0
InconclusiveCount : 0
NotRunCount       : 0
TotalCount        : 7
ErrorRecord       : {}
Passed            : False
OwnPassed         : True
Skip              : False
ShouldRun         : True
Executed          : True
ExecutedAt        : 2/22/2025 7:35:53 PM
DiscoveryDuration : 00:00:00.0097464
UserDuration      : 00:00:00.0081193
FrameworkDuration : 00:00:00.0478876
StandardOutput    :
```

## Block

```plaintext
Name                 : Failure
Path                 : {Failure}
Data                 :
ExpandedName         : Failure
ExpandedPath         : Failure
Blocks               : {[-] Cat: <Category> should be <Expected>, [-] Cat: <Category> should be <Expected>, [-] Cat: <Category> should be <Expected>}
Tests                : {[-] Get-PSModuleTest should be Hello, World!, [-] New-PSModuleTest should be Hello, World!, [-] Set-PSModuleTest should be Hello, World!, [-] True should be false}
Result               : Failed
FailedCount          : 7
PassedCount          : 0
SkippedCount         : 0
NotRunCount          : 0
TotalCount           : 7
ErrorRecord          : {}
Duration             : 00:00:00.0359926
Id                   :
GroupId              :
Tag                  : {}
Focus                : False
Skip                 : False
ItemType             : Block
BlockContainer       : C:\Repos\GitHub\PSModule\Action\Invoke-Pester\tests\1-Simple-Failure\Failure.Tests.ps1
Root                 : [ ] Root
IsRoot               : False
Parent               : [ ] Root
EachTestSetup        :
OneTimeTestSetup     :
EachTestTeardown     :
OneTimeTestTeardown  :
EachBlockSetup       :
OneTimeBlockSetup    :
EachBlockTeardown    :
OneTimeBlockTeardown :
Order                : {[-] Cat: <Category> should be <Expected>, [-] Cat: <Category> should be <Expected>, [-] Cat: <Category> should be <Expected>, [-] Get-PSModuleTest should be Hello, World!…}
Passed               : False
First                : True
Last                 : True
StandardOutput       :
ShouldRun            : True
Executed             : True
ExecutedAt           : 2/22/2025 7:35:53 PM
Exclude              : False
Include              : False
Explicit             : False
DiscoveryDuration    : 00:00:00
FrameworkDuration    : 00:00:00.0280245
UserDuration         : 00:00:00.0079681
OwnDuration          : -00:00:00.0141096
ScriptBlock          :

                           $categories = @(
                               @{ Category = 'Get-PSModuleTest'; Expected = 'Hello, World!' }
                               @{ Category = 'New-PSModuleTest'; Expected = 'Hello, World!' }
                               @{ Category = 'Set-PSModuleTest'; Expected = 'Hello, World!' }
                           )

                           Context 'Cat: <Category> should be <Expected>' -ForEach $categories {
                               It 'ItCat: <Category> should be <Expected>' {
                                   $Category | Should -Be $Expected
                               }
                           }

                           $tests = @(
                               @{ Name = 'Get-PSModuleTest'; Expected = 'Hello, World!' }
                               @{ Name = 'New-PSModuleTest'; Expected = 'Hello, World!' }
                               @{ Name = 'Set-PSModuleTest'; Expected = 'Hello, World!' }
                           )

                           It '<Name> should be <Expected>' -ForEach $tests {
                               $Name | Should -Be $Expected
                           }

                           It 'True should be false' {
                               $true | Should -Be $false
                           }

StartLine            : 13
FrameworkData        :
PluginData           :
PendingCount         : 0
InconclusiveCount    : 0
OwnPassed            : True
OwnTotalCount        : 4
OwnPassedCount       : 0
OwnFailedCount       : 4
OwnSkippedCount      : 0
OwnPendingCount      : 0
OwnNotRunCount       : 0
OwnInconclusiveCount : 0

```

## Test

```plaintext
Name              : True should be false
Path              : {Failure, True should be false}
Data              :
ExpandedName      : True should be false
ExpandedPath      : Failure.True should be false
Result            : Failed
ErrorRecord       : {Expected $false, but got $true.}
StandardOutput    :
Duration          : 00:00:00.0032736
ItemType          : Test
Id                :
GroupId           :
ScriptBlock       :
                            $true | Should -Be $false

Tag               :
Focus             : False
Skip              : False
Block             : [-] Failure
First             : False
Last              : True
Include           : False
Exclude           : False
Explicit          : False
ShouldRun         : True
StartLine         : 37
Executed          : True
ExecutedAt        : 2/22/2025 7:35:53 PM
Passed            : False
Skipped           : False
Inconclusive      : False
UserDuration      : 00:00:00.0010710
FrameworkDuration : 00:00:00.0022026
PluginData        :
FrameworkData     :
```
