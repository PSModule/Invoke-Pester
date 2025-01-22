[CmdletBinding()]
param()

LogGroup 'Loading inputs' {
    $codeToTest = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $env:GITHUB_ACTION_INPUT_Path
    if (-not (Test-Path -Path $codeToTest)) {
        throw "Path [$codeToTest] does not exist."
    }

    if (-not (Test-Path -Path $env:GITHUB_ACTION_INPUT_TestsPath)) {
        throw "Path [$env:GITHUB_ACTION_INPUT_TestsPath] does not exist."
    }

    [pscustomobject]@{
        CodeToTest          = $codeToTest
        TestsPath           = $env:GITHUB_ACTION_INPUT_TestsPath
        StackTraceVerbosity = $env:GITHUB_ACTION_INPUT_StackTraceVerbosity
        Verbosity           = $env:GITHUB_ACTION_INPUT_Verbosity
    } | Format-List
}

############################################################################################

$moduleName = Split-Path -Path $Path -Leaf
$testSourceCode = $TestType -eq 'SourceCode'
$testModule = $TestType -eq 'Module'
$moduleTestsPath = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $TestsPath

LogGroup 'Get test kit versions' {
    $PSSAModule = Get-PSResource -Name PSScriptAnalyzer -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1
    $pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

    [PSCustomObject]@{
        PowerShell       = $PSVersionTable.PSVersion.ToString()
        Pester           = $pesterModule.version
        PSScriptAnalyzer = $PSSAModule.version
    } | Format-List
}

LogGroup 'Add test - Common - PSScriptAnalyzer' {
    $containers = @()
    $PSSATestsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\tests\PSScriptAnalyzer'
    $settingsFileName = if ($testModule) { 'Settings.Module.psd1' } else { 'Settings.SourceCode.psd1' }
    $settingsFilePath = Join-Path -Path $PSSATestsPath -ChildPath $settingsFileName
    $containerParams = @{
        Path = Join-Path $PSSATestsPath 'PSScriptAnalyzer.Tests.ps1'
        Data = @{
            Path             = $Path
            SettingsFilePath = $settingsFilePath
            Debug            = $false
            Verbose          = $false
        }
    }
    Write-Host ($containerParams | ConvertTo-Json)
    $containers += New-PesterContainer @containerParams
}

LogGroup 'Add test - Common - PSModule' {
    $containerParams = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath '..\tests\PSModule\Common.Tests.ps1'
        Data = @{
            Path    = $Path
            Debug   = $false
            Verbose = $false
        }
    }
    Write-Host ($containerParams | ConvertTo-Json)
    $containers += New-PesterContainer @containerParams
}

if ($testModule) {
    LogGroup 'Add test - Module - PSModule' {
        $containerParams = @{
            Path = Join-Path -Path $PSScriptRoot -ChildPath '..\tests\PSModule\Module.Tests.ps1'
            Data = @{
                Path    = $Path
                Debug   = $false
                Verbose = $false
            }
        }
        Write-Host ($containerParams | ConvertTo-Json)
        $containers += New-PesterContainer @containerParams
    }
}

if ($testSourceCode) {
    LogGroup 'Add test - SourceCode - PSModule' {
        $containerParams = @{
            Path = Join-Path -Path $PSScriptRoot -ChildPath '..\tests\PSModule\SourceCode.Tests.ps1'
            Data = @{
                Path      = $Path
                TestsPath = $moduleTestsPath
                Debug     = $false
                Verbose   = $false
            }
        }
        Write-Host ($containerParams | ConvertTo-Json)
        $containers += New-PesterContainer @containerParams
    }
}

if ($testModule) {
    if (Test-Path -Path $moduleTestsPath) {
        LogGroup "Add test - Module - $moduleName" {
            $containerParams = @{
                Path = $moduleTestsPath
            }
            Write-Host ($containerParams | ConvertTo-Json)
            $containers += New-PesterContainer @containerParams
        }
    } else {
        Write-GitHubWarning "⚠️ No tests found - [$moduleTestsPath]"
    }
}

LogGroup 'Pester config' {
    $pesterParams = @{
        Configuration = @{
            Run          = @{
                Path      = $Path
                Container = $containers
                PassThru  = $true
            }
            TestResult   = @{
                Enabled       = $testModule
                OutputFormat  = 'NUnitXml'
                OutputPath    = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'outputs\Test-Report.xml'
                TestSuiteName = 'Unit tests'
            }
            CodeCoverage = @{
                Enabled               = $testModule
                OutputPath            = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'outputs\CodeCoverage-Report.xml'
                OutputFormat          = 'JaCoCo'
                OutputEncoding        = 'UTF8'
                CoveragePercentTarget = 75
            }
            Output       = @{
                CIFormat            = 'Auto'
                StackTraceVerbosity = $StackTraceVerbosity
                Verbosity           = $Verbosity
            }
        }
    }
    Write-Host ($pesterParams | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue)
}

$testResults = Invoke-Pester @pesterParams

LogGroup 'Test results' {
    $testResults | Format-List
    $failedTests = [int]$testResults.FailedCount

    if (($failedTests -gt 0) -or ($testResults.Result -ne 'Passed')) {
        Write-GitHubError "❌ Some [$failedTests] tests failed."
    }
    if ($failedTests -eq 0) {
        Write-GitHubNotice '✅ All tests passed.'
    }

    Set-GitHubOutput -Name 'results' -Value $testResults
}

exit $failedTests
