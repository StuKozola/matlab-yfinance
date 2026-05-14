classdef TestTickers < matlab.unittest.TestCase
    %TESTTICKERS Verify multi-ticker container behavior.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function constructorNormalizesSymbols(testCase)
            tickers = yfinance.Tickers([" aapl ", "", "msft"]);

            testCase.verifyEqual(tickers.Symbols, ["AAPL"; "MSFT"]);
            testCase.verifySize(tickers.Items, [2 1]);
        end

        function historyReturnsDownloadedData(testCase)
            session = StaticChartSession(chartFixture());
            tickers = yfinance.Tickers(["aapl", "msft"], Session=session);

            data = tickers.history(Period="5d", Interval="1d", AutoAdjust=false);

            testCase.verifyTrue(isstruct(data));
            testCase.verifyTrue(isfield(data, "AAPL"));
            testCase.verifyTrue(isfield(data, "MSFT"));
            testCase.verifyEqual(data.AAPL.Close, [104; 105]);
            testCase.verifyEqual(data.MSFT.Close, [104; 105]);
        end

        function downloadAliasesHistory(testCase)
            session = StaticChartSession(chartFixture());
            tickers = yfinance.Tickers(["aapl", "msft"], Session=session);

            data = tickers.download(Period="5d", AutoAdjust=false);

            testCase.verifyTrue(isfield(data, "AAPL"));
            testCase.verifyEqual(data.AAPL.Close, [104; 105]);
        end

        function fastInfoReturnsStructBySymbol(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteResponse=quoteFixture());
            tickers = yfinance.Tickers(["aapl", "msft"], Session=session);

            data = tickers.fastInfo();

            testCase.verifyTrue(isstruct(data));
            testCase.verifyEqual(data.AAPL.Symbol, "AAPL");
            testCase.verifyEqual(data.MSFT.Symbol, "MSFT");
            testCase.verifyEqual(data.AAPL.LastPrice, 123.45);
            testCase.verifyEqual(data.MSFT.LastPrice, 456.78);
        end
    end
end

function response = chartFixture()
timestamps = [1704119400; 1704205800];
quote = struct( ...
    "open", [100; 102], ...
    "high", [105; 106], ...
    "low", [99; 101], ...
    "close", [104; 105], ...
    "volume", [1000; 1100]);
adjClose = struct("adjclose", [52; 52.5]);
indicators = struct("quote", quote, "adjclose", adjClose);
meta = struct( ...
    "currency", "USD", ...
    "symbol", "AAPL", ...
    "exchangeTimezoneName", "America/New_York");
result = struct("meta", meta, "timestamp", timestamps, "indicators", indicators);
response = struct("chart", struct("result", result, "error", []));
end

function response = quoteFixture()
quotes(1) = struct( ...
    "symbol", "AAPL", ...
    "currency", "USD", ...
    "regularMarketPrice", 123.45, ...
    "regularMarketPreviousClose", 120.25);
quotes(2) = struct( ...
    "symbol", "MSFT", ...
    "currency", "USD", ...
    "regularMarketPrice", 456.78, ...
    "regularMarketPreviousClose", 450.00);
response = struct("quoteResponse", struct("result", quotes, "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
