% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestLiveYahoo < matlab.unittest.TestCase
    %TESTLIVEYAHOO Optional live Yahoo Finance integration smoke tests.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
        end
    end

    methods (Test)
        function downloadReturnsRecentRows(testCase)
            data = yfinance.download("AAPL", Period="5d", Interval="1d");

            testCase.verifyGreaterThan(height(data), 0);
            testCase.verifyTrue(ismember("Close", string(data.Properties.VariableNames)));
        end

        function searchReturnsQuoteMatches(testCase)
            results = yfinance.Search("AAPL", NewsCount=0);

            testCase.verifyGreaterThan(height(results.Quotes), 0);
            testCase.verifyTrue(ismember("Symbol", string(results.Quotes.Properties.VariableNames)));
        end

        function screenerReturnsQuotes(testCase)
            result = yfinance.screen("most_actives", Count=1);

            testCase.verifyGreaterThan(height(result.Quotes), 0);
            testCase.verifyTrue(ismember("Symbol", string(result.Quotes.Properties.VariableNames)));
        end

        function calendarEndpointReturnsTable(testCase)
            calendars = yfinance.Calendars( ...
                Start=datetime("today", TimeZone="UTC"), ...
                End=datetime("today", TimeZone="UTC") + days(7));

            data = calendars.getEconomicEventsCalendar(Limit=5);

            testCase.verifyTrue(istable(data));
        end
    end
end
