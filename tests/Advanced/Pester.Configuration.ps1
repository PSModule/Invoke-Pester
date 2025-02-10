@{
    # Define run settings for Pester
    Run          = @{
        # Include specific test tags. For example, you might tag tests with "Planets", "Animals", or "Cars"
        Include  = @('Planets', 'Animals', 'Cars')

        # Exclude tests with certain tags (e.g., integration tests that are not run on every build)
        Exclude  = @('Integration')

        # Configure parallel test execution to speed up test runs.
        Parallel = @{
            Enabled          = $true
            MaxRunspaceCount = 4  # Adjust based on your system's capabilities.
        }
    }

    # Output configuration: adjust verbosity, colors, and format.
    Output       = @{
        # Toggle verbose output for more details during test runs.
        Verbose = $true

        # Define color output for test results (if your terminal supports color).
        Color   = @{
            Success = 'Green'
            Failure = 'Red'
            Error   = 'Yellow'
        }

        # Choose an output format; "Detailed" shows more information than "Short".
        Format  = 'Detailed'
    }

    # Test-specific settings.
    Test         = @{
        # Timeout for individual tests, in milliseconds.
        Timeout = 60000
    }

    # Code coverage settings.
    CodeCoverage = @{
        Enabled      = $true

        # Specify what files to include in code coverage calculations.
        Include      = @('*.ps1', '*.psm1')

        # Exclude test files to prevent them from skewing coverage results.
        Exclude      = @('*.Tests.ps1', '*Tests.ps1')

        # Output format can be "Cobertura", "Html", etc.
        OutputFormat = 'Cobertura'

        # Define where the code coverage report should be saved.
        OutputPath   = "$PSScriptRoot\coverage.xml"
    }
}
