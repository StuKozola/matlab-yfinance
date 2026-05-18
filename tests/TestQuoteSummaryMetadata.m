% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestQuoteSummaryMetadata < matlab.unittest.TestCase
    %TESTQUOTESUMMARYMETADATA Verify quoteSummary metadata APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function calendarResponseConvertsToStruct(testCase)
            data = yfinance.internal.quoteSummaryResponseToCalendar(calendarFixture(), Symbol="AAPL");

            testCase.verifyEqual(data.Symbol, "AAPL");
            testCase.verifyClass(data.EarningsDate, "datetime");
            testCase.verifyEqual(numel(data.EarningsDate), 2);
            testCase.verifyEqual(data.ExDividendDate, datetime(1705622400, ConvertFrom="posixtime", TimeZone="UTC"));
        end

        function analystTargetsResponseConvertsToStruct(testCase)
            data = yfinance.internal.quoteSummaryResponseToAnalystPriceTargets(targetsFixture(), Symbol="AAPL");

            testCase.verifyEqual(data.Symbol, "AAPL");
            testCase.verifyEqual(data.TargetHighPrice, 250);
            testCase.verifyEqual(data.TargetLowPrice, 180);
            testCase.verifyEqual(data.TargetMeanPrice, 220);
            testCase.verifyEqual(data.RecommendationKey, "buy");
            testCase.verifyEqual(data.NumberOfAnalystOpinions, 42);
        end

        function recommendationsResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToRecommendations(recommendationsFixture(), Symbol="AAPL");

            testCase.verifyClass(data, "table");
            testCase.verifyEqual(height(data), 2);
            testCase.verifyEqual(data.Period, ["0m"; "-1m"]);
            testCase.verifyEqual(data.StrongBuy, [10; 9]);
            testCase.verifyEqual(data.Hold, [5; 6]);
        end

        function tickerCalendarUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=calendarFixture());
            ticker = yfinance.Ticker(" aapl ", Session=session);

            data = ticker.calendar();

            testCase.verifyEqual(session.LastQuoteSummarySymbol, "AAPL");
            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "calendarEvents");
            testCase.verifyEqual(data.Symbol, "AAPL");
        end

        function tickerAnalystTargetsUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=targetsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.analystPriceTargets();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "financialData");
            testCase.verifyEqual(data.TargetMedianPrice, 215);
        end

        function tickerRecommendationsUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=recommendationsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.recommendations();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "recommendationTrend");
            testCase.verifyEqual(height(data), 2);
        end
    end
end

function response = calendarFixture()
earnings = struct("earningsDate", [1705622400; 1706227200]);
calendarEvents = struct( ...
    "earnings", earnings, ...
    "exDividendDate", struct("raw", 1705622400, "fmt", "2024-01-19"), ...
    "dividendDate", struct("raw", 1706227200, "fmt", "2024-01-26"));
result = struct("calendarEvents", calendarEvents);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = targetsFixture()
financialData = struct( ...
    "targetHighPrice", struct("raw", 250, "fmt", "250.00"), ...
    "targetLowPrice", struct("raw", 180, "fmt", "180.00"), ...
    "targetMeanPrice", struct("raw", 220, "fmt", "220.00"), ...
    "targetMedianPrice", struct("raw", 215, "fmt", "215.00"), ...
    "recommendationMean", struct("raw", 1.8, "fmt", "1.80"), ...
    "recommendationKey", "buy", ...
    "numberOfAnalystOpinions", struct("raw", 42, "fmt", "42"));
result = struct("financialData", financialData);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = recommendationsFixture()
trend(1) = struct("period", "0m", "strongBuy", 10, "buy", 20, "hold", 5, "sell", 1, "strongSell", 0);
trend(2) = struct("period", "-1m", "strongBuy", 9, "buy", 19, "hold", 6, "sell", 1, "strongSell", 0);
recommendationTrend = struct("trend", trend);
result = struct("recommendationTrend", recommendationTrend);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
