classdef TestScreener < matlab.unittest.TestCase
    %TESTSCREENER Verify predefined screener APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function screenerResponseConvertsToResult(testCase)
            result = yfinance.internal.screenerResponseToResult(screenerFixture(), Query="day_gainers");

            testCase.verifyEqual(result.Query, "day_gainers");
            testCase.verifyEqual(result.Title, "Day Gainers");
            testCase.verifyEqual(result.Count, 2);
            testCase.verifyEqual(result.Total, 42);
            testCase.verifyEqual(result.Quotes.Symbol, ["AAPL"; "MSFT"]);
            testCase.verifyEqual(result.Quotes.RegularMarketPrice, [200; 300]);
        end

        function emptyScreenerResponseReturnsEmptyQuotes(testCase)
            result = yfinance.internal.screenerResponseToResult(emptyScreenerFixture(), Query="empty");

            testCase.verifyEqual(result.Query, "empty");
            testCase.verifyEqual(height(result.Quotes), 0);
        end

        function screenFunctionUsesSession(testCase)
            session = StaticChartSession(emptyChartFixture(), ScreenerResponse=screenerFixture());

            result = yfinance.screen("day_gainers", Count=2, Offset=5, Session=session);

            testCase.verifyEqual(session.LastScreenerQuery, "day_gainers");
            testCase.verifyEqual(session.LastScreenerRequest.Count, 2);
            testCase.verifyEqual(session.LastScreenerRequest.Offset, 5);
            testCase.verifyEqual(result.Quotes.Symbol(1), "AAPL");
        end

        function screenerClassStoresResult(testCase)
            session = StaticChartSession(emptyChartFixture(), ScreenerResponse=screenerFixture());

            screener = yfinance.Screener("day_gainers", Count=2, Session=session);

            testCase.verifyEqual(screener.Query, "day_gainers");
            testCase.verifyEqual(screener.Quotes.Symbol(2), "MSFT");
            testCase.verifyTrue(isfield(screener.Raw, "quotes"));
        end

        function countAboveYahooLimitErrors(testCase)
            session = yfinance.internal.Session();

            testCase.verifyError( ...
                @() session.getScreener("day_gainers", Count=251), ...
                "yfinance:InvalidCount");
        end
    end
end

function response = screenerFixture()
quote1 = struct( ...
    "symbol", "AAPL", ...
    "shortName", "Apple Inc.", ...
    "regularMarketPrice", 200, ...
    "regularMarketChangePercent", 3.1);
quote2 = struct( ...
    "symbol", "MSFT", ...
    "shortName", "Microsoft Corporation", ...
    "regularMarketPrice", 300, ...
    "marketCap", 3500000000000);
quotes = cell(2, 1);
quotes{1} = quote1;
quotes{2} = quote2;
result = struct( ...
    "id", "day_gainers", ...
    "title", "Day Gainers", ...
    "description", "Stocks with the highest gains today.", ...
    "start", 0, ...
    "count", 2, ...
    "total", 42);
result.quotes = quotes;
response = struct("finance", struct("result", result, "error", []));
end

function response = emptyScreenerFixture()
response = struct("finance", struct("result", [], "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
