# Invoke-Pester

This GitHub Action runs [Pester](https://pester.dev) tests in PowerShell, producing code coverage and test result artifacts. It automates many tasks to streamline continuous integration for PowerShell projects:

- Installation and import of required modules (Pester, PSScriptAnalyzer).
- Automatic merging of default, repo-level, and direct inputs into a final Pester configuration.
- Optional uploading of test results and coverage reports.
- Clear step summary in GitHub’s job logs.

## Introduction & Scope

**Invoke-Pester** is designed to:
- **Execute all Pester tests** in your repository, with optional container-based test organization.
- **Collect code coverage** metrics, if desired.
- **Summarize test results** with a neat table in the workflow’s step summary.
- **Upload artifacts** (e.g. coverage reports, test results) to GitHub for later inspection.
- **Allow flexible configuration** through a layered approach—defaults, repository-level config, and direct inputs.

By default, it tries to “just work” for the majority of scenarios. Advanced users can configure everything from coverage thresholds to skipping slow tests.

## Configuration Hierarchy

The action’s behavior is controlled by **layered configuration**:

1. **Default Config**
   Packaged with the action (in `Pester.Configuration.ps1` if provided). Sets base paths, coverage toggles, artifact names, etc.

2. **Repo-Level Config**
   If your repository contains a Pester config file (e.g., `MyTests.Configuration.psd1` or `Pester.Configuration.ps1`), the action loads and merges those settings on top of the defaults.

3. **Direct Inputs**
   Finally, any inputs specified under the `with:` clause in your GitHub Action workflow override both the default and repo-level config.
   > *Example:* If you specify `CodeCoverage_Enabled: true` here, it will enable coverage even if the repo config says otherwise.

This **“last-write-wins”** strategy means you can set global defaults while retaining the flexibility to override them at the action level.


## How This Action Processes Your Tests

1. **Prerequisite Setup**
   - Installs required PowerShell modules (Pester, PSScriptAnalyzer) if they’re not present.
   - Imports the modules so the testing framework is ready to use.

2. **Loading Inputs and Configuration**
   - Reads all GitHub Action inputs from `action.yml` environment variables.
   - (Optional) Loads a base config file included with the action (e.g., `Pester.Configuration.ps1` in the action folder).
   - If `Path` points to a location with a Pester configuration file, merges that config.
   - Finally, merges any direct inputs provided in your workflow.
   - The result is a **final Pester configuration** that determines what tests to run and how to run them.

3. **Building the Final Pester Configuration**
   - Collects all merged settings into a single configuration object.
   - If no “containers” (advanced Pester 5 grouping) are explicitly defined, it attempts to discover them automatically (files matching `*.Container.*`).

4. **Running the Tests**
   - Calls [`Invoke-Pester`](https://pester.dev/docs/commands/Invoke-Pester) using that final configuration.
   - **Discovery Phase**: Finds test files/containers.
   - **Execution Phase**: Runs tests, logs pass/fail/skipped/inconclusive.
   - **Results Gathering**: Aggregates outcomes into a final test object.

5. **Generating Reports (Optional)**
   - **Test Results** (e.g., NUnit/XML) if `TestResult_Enabled` is `true`. The file is saved to `TestResult_OutputPath`.
   - **Code Coverage** if `CodeCoverage_Enabled` is `true`. Saves coverage data (Cobertura, JaCoCo, etc.) to `CodeCoverage_OutputPath`.
   - These reports can automatically be uploaded as workflow artifacts.

6. **Summary in GitHub**
   - A step summary is generated, showing how many tests passed/failed/skipped, plus coverage info.
   - If containers are in use, each container’s results appear in a collapsible section.

7. **Publishing Outputs**
   - Key metrics (e.g., `Result`, `FailedCount`, `Duration`) are encoded in JSON and published as outputs.
   - Subsequent steps can parse these to decide whether to fail the build, open an issue, or notify a channel.

8. **Exit Code**
   - By default, returns a non-zero exit code if any tests fail (unless you override with `Run_Exit: false` or `Run_Throw: false`).
   - This ensures the GitHub job is marked as failed if your tests do not pass.


## Failure Handling

- **No Immediate Fail on First Test Error**:
  The entire suite runs, capturing all failures before deciding on pass/fail.
- **Allowed Failures / Coverage Threshold**:
  You can configure if any test failure leads to a fail, or whether certain coverage levels must be met.
- **Default Behavior**:
  If any test fails, the job fails at the end (exit code != 0). You can change this via `Run_Exit` or `Run_Throw`.


## Artifact Management

- **Test Result Artifacts**
  - By default, if `TestResult_Enabled` is true, the action saves a test result file (XML/JSON) to `TestResult_OutputPath` and uploads it with GitHub’s `actions/upload-artifact`.
- **Coverage Report Artifacts**
  - If `CodeCoverage_Enabled` is true, a coverage file (Cobertura, JaCoCo, etc.) is generated and uploaded similarly.
- **Naming & Paths**
  - You can override default filenames or directories in your config or direct inputs.
- **Logs & Extras**
  - Generally, the action only uploads essential coverage and test result files, though you can adapt it to collect additional logs if needed.

## Step Summary & Coverage Reporting

- **Detailed Markdown Summary**:
  Displays overall test results (passed, failed, skipped) and coverage in a table.
- **Collapsible Breakdown**:
  Each container or test file can be expanded for deeper inspection.
- **Always Visible**:
  Even if the action fails, the summary is posted so you can quickly see why.

## Potential Pitfalls

- If your tests are in a subfolder and `Path` or `Run_Path` isn’t updated, you might discover zero tests.
- Code coverage can differ between breakpoint-based (default) and profiler-based methods—choose which suits your environment (`CodeCoverage_UseBreakpoints`).
- Containers are optional in Pester 5. If you rely on them but name them incorrectly, Pester might skip them.

## Automation Notes

- **Threshold Enforcement**: You can parse `CoveragePercent` from the outputs in a subsequent step and fail the build if coverage is below X%.
- **Automatic Notifications**: Use the published JSON outputs (e.g., `Failed`) to highlight failing tests in Slack or Teams.
- **Versioning & Releases**: If `FailedCount` is zero, you could trigger a deployment or release pipeline automatically.


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
        uses: PSModule/Invoke-Pester@v1
        with:
          Path: './tests'
          CodeCoverage_Enabled: 'true'
          TestResult_Enabled: 'true'
          TestResult_TestSuiteName: 'IntegrationTests'
          # Configure additional inputs, e.g. Run_Throw, Run_Exit, etc.

      # If coverage & results are enabled, the action automatically uploads them as artifacts.
      # The step exit code will be non-zero if any tests fail, unless overridden.
```

### Inputs

All are **optional** unless otherwise noted.

| **Input**                            | **Description**                                                                                                                          | **Default**                     |
|--------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------|
| `Path`                               | Path to where tests are located or a configuration file.                                                                                 | `${{ github.workspace }}/tests` |
| `Run_Path`                           | Directories/files to be searched for tests.                                                                                              | *(none)*                        |
| `Run_ExcludePath`                    | Directories/files to exclude from the run.                                                                                               | *(none)*                        |
| `Run_ScriptBlock`                    | ScriptBlocks containing tests to be executed.                                                                                            | *(none)*                        |
| `Run_Container`                      | ContainerInfo objects containing tests to be executed. See [pester.dev/docs/usage/containers](https://pester.dev/docs/usage/containers). | *(none)*                        |
| `Run_TestExtension`                  | Filter used to identify test files (e.g. `.Tests.ps1`).                                                                                  | *(none)*                        |
| `Run_Exit`                           | Whether to exit with a non-zero exit code on failure.                                                                                    | *(none)*                        |
| `Run_Throw`                          | Whether to throw an exception on test failure.                                                                                           | *(none)*                        |
| `Run_PassThru`                       | Return result object to pipeline after finishing the test run.                                                                           | *(none)*                        |
| `Run_SkipRun`                        | Discovery only, skip actual test run.                                                                                                    | *(none)*                        |
| `Run_SkipRemainingOnFailure`         | Skips remaining tests after the first failure. Options: `None`, `Run`, `Container`, `Block`.                                             | *(none)*                        |
| `Filter_Tag`                         | Tags of Describe/Context/It blocks to run.                                                                                               | *(none)*                        |
| `Filter_ExcludeTag`                  | Tags of Describe/Context/It blocks to exclude.                                                                                           | *(none)*                        |
| `Filter_Line`                        | Filter by file + scriptblock start line (e.g. `C:\tests\file1.Tests.ps1:37`).                                                            | *(none)*                        |
| `Filter_ExcludeLine`                 | Exclude by file + scriptblock start line. Precedence over `Filter_Line`.                                                                 | *(none)*                        |
| `Filter_FullName`                    | Full name of a test with wildcards, joined by dot. E.g. `*.describe Get-Item.test1`                                                      | *(none)*                        |
| `CodeCoverage_Enabled`               | Enable code coverage.                                                                                                                    | *(none)*                        |
| `CodeCoverage_OutputFormat`          | Format for the coverage report. Possible values: `JaCoCo`, `CoverageGutters`, `Cobertura`.                                               | *(none)*                        |
| `CodeCoverage_OutputPath`            | Where to save the code coverage report (relative to the current dir).                                                                    | *(none)*                        |
| `CodeCoverage_OutputEncoding`        | Encoding of the coverage file.                                                                                                           | *(none)*                        |
| `CodeCoverage_Path`                  | Files/directories to measure coverage on (by default, reuses `Path` from the general settings).                                          | *(none)*                        |
| `CodeCoverage_ExcludeTests`          | Exclude tests themselves from coverage.                                                                                                  | *(none)*                        |
| `CodeCoverage_RecursePaths`          | Recurse through coverage directories.                                                                                                    | *(none)*                        |
| `CodeCoverage_CoveragePercentTarget` | Desired minimum coverage percentage.                                                                                                     | *(none)*                        |
| `CodeCoverage_UseBreakpoints`        | **Experimental**: When `false`, use a Profiler-based tracer instead of breakpoints.                                                      | *(none)*                        |
| `CodeCoverage_SingleHitBreakpoints`  | Remove breakpoints after first hit.                                                                                                      | *(none)*                        |
| `TestResult_Enabled`                 | Enable test-result output (e.g. NUnitXml, JUnitXml).                                                                                     | *(none)*                        |
| `TestResult_OutputFormat`            | Possible values: `NUnitXml`, `NUnit2.5`, `NUnit3`, `JUnitXml`.                                                                           | *(none)*                        |
| `TestResult_OutputPath`              | Where to save the test-result report (relative path).                                                                                    | *(none)*                        |
| `TestResult_OutputEncoding`          | Encoding of the test-result file.                                                                                                        | *(none)*                        |
| `TestResult_TestSuiteName`           | Name used for the root `test-suite` element in the result file.                                                                          | *(none)*                        |
| `Should_ErrorAction`                 | Controls if `Should` throws on error. Use `Stop` to throw, or `Continue` to fail at the end.                                             | *(none)*                        |
| `Debug_ShowFullErrors`               | Show Pester internal stack on errors. (Deprecated – overrides `Output.StackTraceVerbosity` to `Full`).                                   | *(none)*                        |
| `Debug_WriteDebugMessages`           | Write debug messages to screen.                                                                                                          | *(none)*                        |
| `Debug_WriteDebugMessagesFrom`       | Filter debug messages by source. Wildcards allowed.                                                                                      | *(none)*                        |
| `Debug_ShowNavigationMarkers`        | Write paths after every block/test for easy navigation in VSCode.                                                                        | *(none)*                        |
| `Debug_ReturnRawResultObject`        | Returns an unfiltered result object, for development only.                                                                               | *(none)*                        |
| `Output_Verbosity`                   | Verbosity: `None`, `Normal`, `Detailed`, `Diagnostic`.                                                                                   | *(none)*                        |
| `Output_StackTraceVerbosity`         | Stacktrace detail: `None`, `FirstLine`, `Filtered`, `Full`.                                                                              | *(none)*                        |
| `Output_CIFormat`                    | CI format of error output: `None`, `Auto`, `AzureDevops`, `GithubActions`.                                                               | *(none)*                        |
| `Output_CILogLevel`                  | CI log level: `Error` or `Warning`.                                                                                                      | *(none)*                        |
| `Output_RenderMode`                  | How to render console output: `Auto`, `Ansi`, `ConsoleColor`, `Plaintext`.                                                               | *(none)*                        |
| `TestDrive_Enabled`                  | Enable `TestDrive`.                                                                                                                      | *(none)*                        |
| `TestRegistry_Enabled`               | Enable `TestRegistry`.                                                                                                                   | *(none)*                        |
| `Debug`                              | Enable debug mode (`true`/`false`). When `true`, uses `PSModule/Debug@v0`.                                                               | `false`                         |

No secrets are directly required by this Action.

### Outputs

After the test run completes, these outputs become available. They are all JSON-encoded strings, so you can parse them in subsequent steps if needed:

| **Output**               | **Description**                                     |
|--------------------------|------------------------------------------------------|
| `Containers`             | Containers object used during the test.              |
| `Result`                 | Whether the tests passed (`Passed`, `Failed`, etc.). |
| `FailedCount`            | Number of failed tests.                              |
| `FailedBlocksCount`      | Number of failed blocks.                             |
| `FailedContainersCount`  | Number of failed containers.                         |
| `PassedCount`            | Number of passed tests.                              |
| `SkippedCount`           | Number of skipped tests.                             |
| `InconclusiveCount`      | Number of inconclusive tests.                        |
| `NotRunCount`            | Number of tests not run.                             |
| `TotalCount`             | Total number of tests.                               |
| `Duration`               | Duration of the test run.                            |
| `Executed`               | Number of tests actually executed.                   |
| `ExecutedAt`             | DateTime of the test run.                            |
| `Version`                | Pester version.                                      |
| `PSVersion`              | PowerShell version.                                  |
| `PSBoundParameters`      | The final set of parameters used to run the tests.   |
| `Plugins`                | Plugins used during the run.                         |
| `PluginConfiguration`    | Configuration for those plugins.                     |
| `PluginData`             | Data from those plugins.                             |
| `Configuration`          | The merged final Pester configuration used.          |
| `DiscoveryDuration`      | Discovery-phase duration.                            |
| `UserDuration`           | Duration of user code execution.                     |
| `FrameworkDuration`      | Duration of framework code execution.                |
| `Failed`                 | Info on failed tests.                                |
| `FailedBlocks`           | Info on failed blocks.                               |
| `FailedContainers`       | Info on failed containers.                           |
| `Passed`                 | Info on passed tests.                                |
| `Skipped`                | Info on skipped tests.                               |
| `Inconclusive`           | Info on inconclusive tests.                          |
| `NotRun`                 | Info on tests not run.                               |
| `Tests`                  | All discovered tests.                                |
| `CodeCoverage`           | Code coverage report object.                         |
| `TestResultEnabled`      | `true`/`false` based on `TestResult_Enabled`.        |
| `TestResultOutputPath`   | Path to the test result file.                        |
| `TestSuiteName`          | Name of the test suite.                              |
| `CodeCoverageEnabled`    | `true`/`false` based on `CodeCoverage_Enabled`.      |
| `CodeCoverageOutputPath` | Where the coverage report was saved.                 |


### Tips & Notes

- To **skip coverage** or **test result uploads**, set `CodeCoverage_Enabled: false` or `TestResult_Enabled: false`.
- If you do **not** want a failing test to cause the step to fail, set `Run_Exit: false` and `Run_Throw: false`.
- For deeper debug info, set `Debug: 'true'` (which uses the [PSModule/Debug@v0](https://github.com/PSModule/Debug) action).
- If your tests require a **custom Pester config**, place it in your repo and point `Path` or `Run_Path` to it. The action merges that file with defaults.

## Contributing

1. Open a pull request with your proposed changes (bug fixes, improvements, new features).
2. Test your branch in a real or mock workflow if possible to confirm it behaves as intended.
3. We welcome any ideas for streamlining test runs, coverage generation, or other enhancements.

## Conclusion

The **Invoke-Pester** GitHub Action streamlines automated PowerShell testing in CI/CD by merging multiple configuration layers, running Pester tests,
collecting coverage, generating artifacts, and neatly summarizing results. It helps maintain a robust CI environment for PowerShell projects of all
sizes. If you have questions or want to contribute, feel free to open an issue or pull request.

Happy pestering!
