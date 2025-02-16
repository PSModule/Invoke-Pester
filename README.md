# Invoke-Pester

This GitHub Action runs [Pester](https://pester.dev) tests in PowerShell, producing code coverage and test result artifacts.

The action handles many tedious tasks so that you only have to focus on designing the tests. Here are some key features:

- Installation and import of Pester (and PSScriptAnalyzer) modules.
- Automatic merging of default Pester configuration, custom test configuration, and direct GitHub Action inputs.
- Support for uploading test results and code coverage reports as workflow artifacts based on provided Pester configuration.
- Detailed step summary in GitHub’s job logs.

## Details

1. **Prerequisite Setup**
   - The action installs the required PowerShell modules — namely Pester (for testing) and PSScriptAnalyzer (for static analysis).
   - It then imports those modules to make sure all test commands and analysis functions are available.

2. **Loading Inputs and Configuration**
   - The script collects settings using a hierarchicallooks for a default configuration (`Pester.Configuration.ps1`) in the Action’s folder. If it finds one, it loads that into memory as the “base” config.
   - All Action inputs are read from the environment (these come from your `action.yml` definitions).
   - Next, the script runs `Get-PesterConfiguration -Path` on the `Path` you specified. If a Pester configuration file is found there, it merges that into the base config.
   - Finally, any Action-level overrides (the actual GitHub Action inputs) are merged on top. This layered approach ensures you can define defaults in multiple places and still be able to override them easily from the GitHub Workflow.

3. **Building the Final Pester Configuration**
   - After merging all those sources, the script constructs a final Pester configuration hash table. This tells Pester exactly which tests to run, how to filter them, whether to enable code coverage, etc.
   - If no test “containers” are defined in the config, the script also attempts to discover any container files (`*.Container.*` patterns) inside the path(s) given. In Pester 5, containers are used to organize or group tests, but if you aren’t explicitly using them, Pester falls back to normal test discovery.

4. **Running the Tests**
   - The script invokes `Invoke-Pester` with the merged configuration. This is where the actual tests are run:
     - **Discovery Phase**: Pester looks for tests in the paths and/or containers defined.
     - **Execution Phase**: Each discovered test is executed. If containers are defined, they are run in the order and grouping Pester sees fit.
     - **Results Gathering**: Pester aggregates pass/fail/skipped/inconclusive results into a final test result object.

5. **Generating Reports (Optional)**
   - **Test Results** (e.g., NUnit/JUnit) are generated if `TestResult_Enabled` is `true`. The result file location is defined by `TestResult_OutputPath`. The Action can then automatically upload this file as an artifact if the run succeeds or fails.
   - **Code Coverage** can also be enabled by setting `CodeCoverage_Enabled` to `true`. This generates a coverage report in the format you select (e.g., Cobertura, JaCoCo) and saves it to `CodeCoverage_OutputPath`. That file is also automatically uploaded as an artifact, if enabled.

6. **Summary in GitHub**
   - A summary block is added to the GitHub Actions logs, detailing how many tests passed, failed, or were skipped, along with total coverage.
   - If you are using containers, each container’s results are displayed in a collapsible section. This helps you see exactly which tests failed and why.

7. **Publishing Outputs**
   - The Action then extracts key pieces of information—like `Result`, `FailedCount`, `Duration`, etc.—from the final Pester run object.
   - Each piece of data is converted to JSON and set as a GitHub Action output. This means subsequent steps or workflows can read those values to make decisions (for instance, fail the build if coverage is below a certain threshold).

8. **Exit Code**
   - The Action returns a non-zero exit code if any tests fail (or if you configured `Run_Throw`, it can throw an exception). This ensures GitHub will mark the job as a failure when tests do not pass.

---

### Why the Configurations Are Layered
- **Default Config**: A built-in Pester configuration (in `Pester.Configuration.ps1` if provided) holds fallback defaults.
- **Repo Config**: Your repository may include a Pester config file that further tailors defaults.
- **Action Inputs**: Finally, everything can be overridden by GitHub Actions inputs. This layering is especially helpful if you want a single set of “global” defaults but occasionally need to tweak the test-run behavior (e.g., skipping slow tests in some branches).

### Potential Pitfalls
- If your code is in a subfolder and you forget to update `Path` or `Run_Path`, the tests might not be found.
- When code coverage is enabled, make sure the coverage tool you choose is compatible with your environment (e.g., breakpoints vs. profiler-based coverage).
- If you rely on containers but forgot to add them to your config or name them correctly, tests may be skipped (or discovered in an unintended way).

### Automation Notes
Because all the output is published as JSON, you can chain additional actions or scripts to automatically parse the results. For instance, you could:
- Use a script to compare `CoveragePercent` against a required threshold and automatically open an issue if coverage decreases.
- Parse `Failed` tests in a subsequent step to highlight them in your Slack or Teams notifications.
- Automatically tag or release a build only if `FailedCount` is zero.

Overall, the Action’s approach is meant to be flexible and extensible, giving you control via the Pester configuration system without making you rewrite existing test logic.

## Usage

### Inputs

Below is a comprehensive list of inputs pulled directly from `action.yml`. All are **optional** unless otherwise noted.

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

### Example

Below is a complete example of using this Action in a workflow. It:

- Checks out the repo
- Runs Pester tests in the `tests` folder
- Produces coverage and test results
- Uploads each report as an artifact if applicable

```yaml
name: Pester Tests

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  test-pester:
    runs-on: ubuntu-latest

    steps:
      - name: Check out
        uses: actions/checkout@v3

      - name: Run Pester Tests
        uses: PSModule/Invoke-Pester@v1
        with:
          Path: './tests'
          CodeCoverage_Enabled: 'true'
          TestResult_Enabled: 'true'
          TestResult_TestSuiteName: 'IntegrationTests'
          Debug: 'false'

      # Note: The action already includes artifact uploads if coverage & results are enabled.
      # The final pass/fail status is determined by the test results. If any test fails,
      # the step exit code will be non-zero (assuming Run_Exit and/or Run_Throw is true).
```

### Tips & Notes

- If you want to **skip** the coverage or test results upload, set `TestResult_Enabled` or `CodeCoverage_Enabled` to `false`.
- If you prefer the step *never fails*, set `Run_Exit: false` and `Run_Throw: false`. (Not recommended, but possible.)
- The final test run’s pass/fail is also reflected in the step exit code by default if `Run_Exit` is `true`.
- Use `Debug: 'true'` to show extra logs from the action (via `PSModule/Debug@v0`).
- If your tests rely on a custom Pester configuration file, place that file in your repo (for example, `MyTests.Configuration.psd1`) and point `Path` or `Run_Path` to that. This action merges your config with the defaults.

## Contributing

1. Open a pull request with your changes.
2. Ensure you’ve tested your updated action in a real or test workflow.
3. We welcome bug reports, feature requests, and suggestions for improvement.
