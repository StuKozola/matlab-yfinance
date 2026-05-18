% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestFastInfo < matlab.unittest.TestCase
    %TESTFASTINFO Verify fast quote metadata handling.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function quoteResponseConvertsToFastInfo(testCase)
            info = yfinance.internal.quoteResponseToFastInfo(quoteFixture(), Symbol="AAPL");

            testCase.verifyEqual(info.Symbol, "AAPL");
            testCase.verifyEqual(info.Currency, "USD");
            testCase.verifyEqual(info.LastPrice, 123.45);
            testCase.verifyEqual(info.PreviousClose, 120.25);
            testCase.verifyEqual(info.Volume, 1000000);
            testCase.verifyClass(info.LastTradeTime, "datetime");
            testCase.verifyTrue(isfield(info, "Raw"));
        end

        function tickerFastInfoUsesQuoteSession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteResponse=quoteFixture());
            ticker = yfinance.Ticker(" aapl ", Session=session);

            info = ticker.fastInfo();

            testCase.verifyEqual(session.LastQuoteSymbols, "AAPL");
            testCase.verifyEqual(info.Symbol, "AAPL");
            testCase.verifyEqual(info.LastPrice, 123.45);
        end

        function tickerFastInfoFallsBackToChartMetadata(testCase)
            session = StaticChartSession(chartFastInfoFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            info = ticker.fastInfo();

            testCase.verifyEqual(session.LastSymbol, "AAPL");
            testCase.verifyEqual(info.Symbol, "AAPL");
            testCase.verifyEqual(info.LastPrice, 222.5);
            testCase.verifyEqual(info.PreviousClose, 220);
        end

        function emptyQuoteResponseReportsNoData(testCase)
            response = struct("quoteResponse", struct("result", [], "error", []));

            testCase.verifyError( ...
                @() yfinance.internal.quoteResponseToFastInfo(response, Symbol="AAPL"), ...
                "yfinance:NoData");
        end
    end
end

function response = quoteFixture()
quote = struct( ...
    "symbol", "AAPL", ...
    "currency", "USD", ...
    "exchange", "NMS", ...
    "exchangeTimezoneName", "America/New_York", ...
    "quoteType", "EQUITY", ...
    "shortName", "Apple Inc.", ...
    "longName", "Apple Inc.", ...
    "regularMarketPrice", 123.45, ...
    "regularMarketPreviousClose", 120.25, ...
    "regularMarketOpen", 121.5, ...
    "regularMarketDayHigh", 124.0, ...
    "regularMarketDayLow", 121.0, ...
    "regularMarketVolume", 1000000, ...
    "regularMarketTime", 1704205800, ...
    "marketCap", 3000000000000, ...
    "averageDailyVolume10Day", 50000000, ...
    "averageDailyVolume3Month", 60000000, ...
    "fiftyTwoWeekHigh", 199.62, ...
    "fiftyTwoWeekLow", 124.17);
response = struct("quoteResponse", struct("result", quote, "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end

function response = chartFastInfoFixture()
meta = struct( ...
    "currency", "USD", ...
    "symbol", "AAPL", ...
    "exchangeName", "NMS", ...
    "fullExchangeName", "NasdaqGS", ...
    "exchangeTimezoneName", "America/New_York", ...
    "instrumentType", "EQUITY", ...
    "regularMarketPrice", 222.5, ...
    "chartPreviousClose", 220, ...
    "regularMarketTime", 1704205800);
result = struct("meta", meta, "timestamp", 1704205800, "indicators", struct());
response = struct("chart", struct("result", result, "error", []));
end
