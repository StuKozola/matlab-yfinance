classdef TestChartHistory < matlab.unittest.TestCase
    %TESTCHARTHISTORY Verify Yahoo chart response handling.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function responseConvertsToTimetable(testCase)
            data = yfinance.internal.chartResponseToTimetable( ...
                chartFixture(), ...
                Symbol="AAPL", ...
                AutoAdjust=false);

            testCase.verifyClass(data, "timetable");
            testCase.verifyEqual(string(data.Properties.DimensionNames{1}), "Time");
            testCase.verifyEqual(data.Open, [100; 102]);
            testCase.verifyEqual(data.Close, [104; 105]);
            testCase.verifyEqual(data.AdjClose, [52; 52.5]);
            testCase.verifyEqual(data.Volume, [1000; 1100]);
        end

        function autoAdjustsOhlcPrices(testCase)
            data = yfinance.internal.chartResponseToTimetable( ...
                chartFixture(), ...
                Symbol="AAPL", ...
                AutoAdjust=true);

            testCase.verifyEqual(data.Open, [50; 51]);
            testCase.verifyEqual(data.High, [52.5; 53]);
            testCase.verifyEqual(data.Low, [49.5; 50.5]);
            testCase.verifyEqual(data.Close, [52; 52.5]);
        end

        function tickerHistoryUsesSession(testCase)
            session = StaticChartSession(chartFixture());
            ticker = yfinance.Ticker(" aapl ", Session=session);

            data = ticker.history(Period="5d", Interval="1d", AutoAdjust=false);

            testCase.verifyEqual(session.LastSymbol, "AAPL");
            testCase.verifyEqual(session.LastOptions.Period, "5d");
            testCase.verifyEqual(session.LastOptions.Interval, "1d");
            testCase.verifyEqual(data.Close, [104; 105]);
        end

        function downloadSingleSymbolReturnsTimetable(testCase)
            session = StaticChartSession(chartFixture());

            data = yfinance.download("aapl", Session=session, AutoAdjust=false);

            testCase.verifyClass(data, "timetable");
            testCase.verifyEqual(session.LastSymbol, "AAPL");
            testCase.verifyEqual(data.Close, [104; 105]);
        end

        function downloadMultipleSymbolsReturnsStruct(testCase)
            session = StaticChartSession(chartFixture());

            data = yfinance.download(["aapl", "msft"], Session=session, AutoAdjust=false);

            testCase.verifyTrue(isstruct(data));
            testCase.verifyTrue(isfield(data, "AAPL"));
            testCase.verifyTrue(isfield(data, "MSFT"));
            testCase.verifyClass(data.AAPL, "timetable");
            testCase.verifyClass(data.MSFT, "timetable");
        end

        function invalidPeriodReportsError(testCase)
            testCase.verifyError( ...
                @() yfinance.internal.chartQueryParameters(Period="bad"), ...
                "yfinance:InvalidPeriod");
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
