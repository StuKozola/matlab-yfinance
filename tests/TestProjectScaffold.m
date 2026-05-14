classdef TestProjectScaffold < matlab.unittest.TestCase
    %TESTPROJECTSCAFFOLD Verify the initial project scaffold.

    methods (TestClassSetup)
        function addProjectRootToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
        end
    end

    methods (Test)
        function versionReturnsString(testCase)
            value = yfinance.version;

            testCase.verifyClass(value, "string");
            testCase.verifyEqual(value, "0.0.0");
        end

        function tickerStoresNormalizedSymbol(testCase)
            ticker = yfinance.Ticker(" aapl ");

            testCase.verifyEqual(ticker.Symbol, "AAPL");
        end

        function downloadReportsNotImplemented(testCase)
            testCase.verifyError(@() yfinance.download("AAPL"), "yfinance:NotImplemented");
        end
    end
end
