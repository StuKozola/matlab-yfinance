% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestProjectScaffold < matlab.unittest.TestCase
    %TESTPROJECTSCAFFOLD Verify the initial project scaffold.

    methods (TestClassSetup)
        function addProjectRootToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function versionReturnsString(testCase)
            value = yfinance.version;

            testCase.verifyClass(value, "string");
            testCase.verifyEqual(value, "0.1.1");
        end

        function licenseAndNoticeFilesExist(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));

            testCase.verifyTrue(isfile(fullfile(projectRoot, "LICENSE")));
            testCase.verifyTrue(isfile(fullfile(projectRoot, "NOTICE")));
        end

        function tickerStoresNormalizedSymbol(testCase)
            ticker = yfinance.Ticker(" aapl ");

            testCase.verifyEqual(ticker.Symbol, "AAPL");
        end

        function downloadRejectsEmptySymbols(testCase)
            testCase.verifyError(@() yfinance.download(" "), "yfinance:InvalidSymbol");
        end
    end
end
