# Invoke-Pester

This GitHub Action runs [Pester](https://pester.dev) tests in PowerShell, producing code coverage and test result artifacts. It automates many tasks
to streamline continuous integration for PowerShell projects:

- Installation and import of required modules.
- Automatic merging of default configuration, test suite configuration, and direct inputs into a final Pester configuration.
- Uploading of test results and coverage reports.
- Clear step summary in GitHub's job logs.

## Dependencies

- This action.
- [`Pester` module](https://github.com/Pester/Pester)
- [`GitHub-Script` action](https://github.com/PSModule/GitHub-Script)
- [`GitHub` module](https://github.com/PSModule/GitHub)

## Configuration Hierarchy

The action's behavior is controlled by a **layered configuration** system, which merges settings from multiple sources in a specific order. The
highest-priority settings override lower-priority ones. The order of precedence is as follows:

| Setting    | Default | Test Suite | Direct Inputs | Result |
|------------|---------|------------|---------------|--------|
| `SettingA` | `X`     |            |               | `X`    |
| `SettingB` | `X`     | `Y`        |               | `Y`    |
| `SettingC` | `X`     | `Y`        | `Z`           | `Z`    |

This **last-write-wins** strategy means you can set global defaults while retaining the flexibility to override them at the action level.

### 1. Default Configuration

The action defaults use the `PesterConfiguration` defaults.

<details>
<summary>Default Configuration</summary>

```powershell
@{
    TestDrive    = @{
        Enabled = $true
    }
    TestResult   = @{
        TestSuiteName  = 'Pester'
        OutputFormat   = 'NUnitXml'
        OutputEncoding = 'UTF8'
        OutputPath     = 'testResults.xml'
        Enabled        = $false
    }
    Run          = @{
        ExcludePath            = $null
        Exit                   = $false
        SkipRun                = $false
        Path                   = '.'
        Throw                  = $false
        PassThru               = $false
        SkipRemainingOnFailure = 'None'
        ScriptBlock            = $null
        Container              = $null
        TestExtension          = '.Tests.ps1'
    }
    Output       = @{
        CILogLevel          = 'Error'
        StackTraceVerbosity = 'Filtered'
        RenderMode          = 'Auto'
        CIFormat            = 'Auto'
        Verbosity           = 'Normal'
    }
    Debug        = @{
        ShowNavigationMarkers  = $false
        ShowFullErrors         = $false
        WriteDebugMessagesFrom = @(
            'Discovery'
            'Skip'
            'Mock'
            'CodeCoverage'
        )
        WriteDebugMessages     = $false
        ReturnRawResultObject  = $false
    }
    TestRegistry = @{
        Enabled = $true
    }
    CodeCoverage = @{
        Path                  = $null
        OutputEncoding        = 'UTF8'
        CoveragePercentTarget = '75'
        UseBreakpoints        = $true
        ExcludeTests          = $true
        RecursePaths          = $true
        OutputPath            = 'coverage.xml'
        SingleHitBreakpoints  = $true
        Enabled               = $false
        OutputFormat          = 'JaCoCo'
    }
    Should       = @{
        ErrorAction = 'Stop'
    }
    Filter       = @{
        Line        = $null
        Tag         = $null
        ExcludeLine = $null
        FullName    = $null
        ExcludeTag  = $null
    }
}
```

</details>

### 2. Test Suite Configuration

If your test suite contains a Pester config file (e.g., `MyTests.Configuration.psd1` or `Pester.Configuration.ps1`), the action loads and merges
those settings on top of the defaults.

### 3. Direct Action Inputs

Finally, any inputs specified under the `with:` clause in your GitHub Action workflow override both the default and test suite config.
If you specify `CodeCoverage_Enabled: true` here, it will enable coverage even if the test suite config says otherwise.

## How This Action Processes Your Tests

1. **Prerequisite Setup**
   - Installs required PowerShell modules if they're not present.
   - Imports the modules so the testing framework is ready to use.
2. **Loading Inputs and Configuration**
   - Loads a default Pester configuration.
   - If `Path` points to a location with a Pester configuration file, merges that config.
   - Finally, merges any direct inputs provided in your workflow.
   - The result is a **final Pester configuration** that determines what tests to run and how to run them.
3. **Add Containers**
   - If no containers are explicitly defined, it attempts to discover them automatically (files matching `*.Container.*`).
   - Adds these containers to the final configuration.
4. **Running the Tests**
   - Calls [`Invoke-Pester`](https://pester.dev/docs/commands/Invoke-Pester) using that final configuration.
   - Finds test files/containers.
   - Runs tests, logging pass/fail/skipped/inconclusive.
   - Aggregates outcomes into a final test object.
5. **Generating Reports**
   - **Test Results** (e.g., NUnit/XML) if `TestResult_Enabled` is `true`. The file is saved to `TestResult_OutputPath`.
   - **Code Coverage** if `CodeCoverage_Enabled` is `true`. Saves coverage data (Cobertura, JaCoCo, etc.) to `CodeCoverage_OutputPath`.
   - These reports are automatically uploaded as workflow artifacts. The artifact names are:
     - `<TestSuiteName>-TestResults`
     - `<TestSuiteName>-CodeCoverage`

    > [!TIP]
    > Use the `TestResult_TestSuiteName` input to change the variable name of the artifact.
6. **Summary in GitHub**
   - A step summary is generated, showing how many tests passed/failed/skipped along with coverage information.
   - If containers are in use, each container's results appear in a collapsible section.
7. **Publishing Outputs**
   - The action sets several outputs for internal usage:
     - `TestSuiteName`: Name assigned to the test suite.
     - `TestResultEnabled`: Indicates if test-result output is enabled.
     - `TestResultOutputPath`: Path to the test result report.
     - `CodeCoverageEnabled`: Indicates if code coverage is enabled.
     - `CodeCoverageOutputPath`: Path to the code coverage report.

## How to Determine a Test's Outcome

After running your tests, you can assess the overall result by checking:

- **Outcome:**
  The step's outcome will be `success` if all tests passed or `failure` if one or more tests failed.

- **Conclusion:**
  This value provides an overall summary (typically `success` or `failure`) of the test run.
  Use this with the `continue-on-error` flag to run a separate step to gather results of parallel tests.

These values are accessible in your workflow using the step's outputs, for example:

```yaml
- name: Status
  shell: pwsh
  env:
    OUTCOME: ${{ steps.action-test.outcome }}
    CONCLUSION: ${{ steps.action-test.conclusion }}
  run: |
    Write-Host "Outcome: [$env:OUTCOME]"
    Write-Host "Conclusion: [$env:CONCLUSION]"
```

## Controlling Workflow Execution Based on Test Outcome/Conclusion

You can use the test outcome and conclusion to control the flow of your GitHub workflow. For example:

- **Using a Shell Step:**
  You might include a step that checks the outcome and exits with a non-zero code if the tests did not pass:

  ```yaml
  - name: Status Check
    shell: pwsh
    run: |
      $outcome = '${{ steps.action-test.outcome }}'
      Write-Host "Outcome: [$outcome]"
      if ($outcome -ne 'success') {
        Write-Error "Tests did not pass. Aborting workflow."
        exit 1
      }
  ```

- **Conditional Steps in Workflow YAML:**
  You can conditionally run steps based on the outcome and conclusion:
  ```yaml
  - name: Deploy
    if: ${{ steps.action-test.outcome == 'success' && steps.action-test.conclusion == 'success' }}
    run: |
      # Deployment commands here
  ```

This approach provides full control over the execution flow of your workflow, ensuring that subsequent actions (like deployment) only run if the tests meet your success criteria.

## Usage

Below is a typical usage example. (Subsequent sections list *all* available inputs and outputs.)

```yaml
name: Pester Tests

on:
  push:

jobs:
  test-pester:
    runs-on: ubuntu-latest

    steps:
      - name: Check out
        uses: actions/checkout@v4

      - name: Run Pester Tests
        uses: PSModule/Invoke-Pester@v2
        id: action-test
        continue-on-error: true
        with:
          TestResult_TestSuiteName: IntegrationTests
          Path: ./tests
          Run_Path: ./src

      - name: Status
        shell: pwsh
        env:
          OUTCOME: ${{ steps.action-test.outcome }}
          CONCLUSION: ${{ steps.action-test.conclusion }}
        run: |
          Write-Host "Outcome: [$env:OUTCOME]"
          Write-Host "Conclusion: [$env:CONCLUSION]"
```

### Inputs

_All inputs are optional unless noted otherwise. For more details, refer to the [Pester Configuration documentation](https://pester.dev/docs/usage/configuration)._
`Run.PassThru` is forced to `$true` to ensure the action can capture test results.

| **Input**                            | **Description**                                                                                        | **Default**                     |
|--------------------------------------|--------------------------------------------------------------------------------------------------------|---------------------------------|
| `Path`                               | Path to where tests are located or a configuration file.                                               | `${{ github.workspace }}/tests` |
| `Run_Path`                           | Directories/files to be searched for tests.                                                            | *(none)*                        |
| `Run_ExcludePath`                    | Directories/files to exclude from the run.                                                             | *(none)*                        |
| `Run_ScriptBlock`                    | ScriptBlocks containing tests to be executed.                                                          | *(none)*                        |
| `Run_Container`                      | ContainerInfo objects containing tests to be executed.                                                 | *(none)*                        |
| `Run_TestExtension`                  | Filter used to identify test files (e.g. `.Tests.ps1`).                                                | *(none)*                        |
| `Run_Exit`                           | Whether to exit with a non-zero exit code on failure.                                                  | *(none)*                        |
| `Run_Throw`                          | Whether to throw an exception on test failure.                                                         | *(none)*                        |
| `Run_SkipRun`                        | Discovery only, skip actual test run.                                                                  | *(none)*                        |
| `Run_SkipRemainingOnFailure`         | Skips remaining tests after the first failure. Options: `None`, `Run`, `Container`, `Block`.           | *(none)*                        |
| `Filter_Tag`                         | Tags of Describe/Context/It blocks to run.                                                             | *(none)*                        |
| `Filter_ExcludeTag`                  | Tags of Describe/Context/It blocks to exclude.                                                         | *(none)*                        |
| `Filter_Line`                        | Filter by file + scriptblock start line (e.g. `C:\tests\file1.Tests.ps1:37`).                          | *(none)*                        |
| `Filter_ExcludeLine`                 | Exclude by file + scriptblock start line. Precedence over `Filter_Line`.                               | *(none)*                        |
| `Filter_FullName`                    | Full name of a test with wildcards, joined by dot. E.g. `*.describe Get-Item.test1`                    | *(none)*                        |
| `CodeCoverage_Enabled`               | Enable code coverage.                                                                                  | *(none)*                        |
| `CodeCoverage_OutputFormat`          | Format for the coverage report. Possible values: `JaCoCo`, `CoverageGutters`, `Cobertura`.             | *(none)*                        |
| `CodeCoverage_OutputPath`            | Where to save the code coverage report (relative to the current dir).                                  | *(none)*                        |
| `CodeCoverage_OutputEncoding`        | Encoding of the coverage file.                                                                         | *(none)*                        |
| `CodeCoverage_Path`                  | Files/directories to measure coverage on (by default, reuses `Path` from the general settings).        | *(none)*                        |
| `CodeCoverage_ExcludeTests`          | Exclude tests themselves from coverage.                                                                | *(none)*                        |
| `CodeCoverage_RecursePaths`          | Recurse through coverage directories.                                                                  | *(none)*                        |
| `CodeCoverage_CoveragePercentTarget` | Desired minimum coverage percentage.                                                                   | *(none)*                        |
| `CodeCoverage_UseBreakpoints`        | **Experimental**: When `false`, use a Profiler-based tracer instead of breakpoints.                    | *(none)*                        |
| `CodeCoverage_SingleHitBreakpoints`  | Remove breakpoints after first hit.                                                                    | *(none)*                        |
| `TestResult_Enabled`                 | Enable test-result output (e.g. NUnitXml, JUnitXml).                                                   | *(none)*                        |
| `TestResult_OutputFormat`            | Possible values: `NUnitXml`, `NUnit2.5`, `NUnit3`, `JUnitXml`.                                         | *(none)*                        |
| `TestResult_OutputPath`              | Where to save the test-result report (relative path).                                                  | *(none)*                        |
| `TestResult_OutputEncoding`          | Encoding of the test-result file.                                                                      | *(none)*                        |
| `TestResult_TestSuiteName`           | Name used for the root `test-suite` element in the result file.                                        | *(none)*                        |
| `Should_ErrorAction`                 | Controls if `Should` throws on error. Use `Stop` to throw, or `Continue` to fail at the end.           | *(none)*                        |
| `Debug_ShowFullErrors`               | Show Pester internal stack on errors. (Deprecated – overrides `Output.StackTraceVerbosity` to `Full`). | *(none)*                        |
| `Debug_WriteDebugMessages`           | Write debug messages to screen.                                                                        | *(none)*                        |
| `Debug_WriteDebugMessagesFrom`       | Filter debug messages by source. Wildcards allowed.                                                    | *(none)*                        |
| `Debug_ShowNavigationMarkers`        | Write paths after every block/test for easy navigation in Visual Studio Code.                          | *(none)*                        |
| `Debug_ReturnRawResultObject`        | Returns an unfiltered result object, for development only.                                             | *(none)*                        |
| `Output_Verbosity`                   | Verbosity: `None`, `Normal`, `Detailed`, `Diagnostic`.                                                 | *(none)*                        |
| `Output_StackTraceVerbosity`         | Stacktrace detail: `None`, `FirstLine`, `Filtered`, `Full`.                                            | *(none)*                        |
| `Output_CIFormat`                    | CI format of error output: `None`, `Auto`, `AzureDevops`, `GithubActions`.                             | *(none)*                        |
| `Output_CILogLevel`                  | CI log level: `Error` or `Warning`.                                                                    | *(none)*                        |
| `Output_RenderMode`                  | How to render console output: `Auto`, `Ansi`, `ConsoleColor`, `Plaintext`.                             | *(none)*                        |
| `TestDrive_Enabled`                  | Enable `TestDrive`.                                                                                    | *(none)*                        |
| `TestRegistry_Enabled`               | Enable `TestRegistry`.                                                                                 | *(none)*                        |
| `Debug`                              | Enable debug mode (`true`/`false`). When `true`, uses `PSModule/Debug@v0`.                             | `false`                         |

### Outputs

No outputs are provided directly by this action. Instead, use the step's **outcome** and **conclusion** properties along with the published outputs
listed above to control the subsequent flow of your workflow.

The provided example workflows demonstrate how you can use these outputs to control the flow. For instance, the **Status** steps in the test
workflows print the `outcome` and `conclusion` values, and a later job aggregates these values to decide whether to continue or abort the workflow.
