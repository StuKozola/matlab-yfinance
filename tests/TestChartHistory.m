% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

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
            testCase.verifyEqual(string(data.Time.TimeZone), "America/New_York");
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

            data = ticker.history( ...
                Period="5d", ...
                Interval="1d", ...
                AutoAdjust=false, ...
                IncludePrePost=true);

            testCase.verifyEqual(session.LastSymbol, "AAPL");
            testCase.verifyEqual(session.LastOptions.Period, "5d");
            testCase.verifyEqual(session.LastOptions.Interval, "1d");
            testCase.verifyTrue(session.LastOptions.IncludePrePost);
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

        function startEndDatesUsePeriodBounds(testCase)
            startTime = datetime(2024, 1, 1, TimeZone="UTC");
            endTime = datetime(2024, 1, 2, TimeZone="UTC");

            query = yfinance.internal.chartQueryParameters( ...
                Start=startTime, ...
                End=endTime, ...
                IncludePrePost=true);

            testCase.verifyEqual(queryValue(query, "period1"), string(floor(posixtime(startTime))));
            testCase.verifyEqual(queryValue(query, "period2"), string(floor(posixtime(endTime))));
            testCase.verifyEqual(queryValue(query, "includePrePost"), "true");
            testCase.verifyFalse(hasQueryName(query, "range"));
        end

        function endWithoutStartReportsError(testCase)
            endTime = datetime(2024, 1, 2, TimeZone="UTC");

            testCase.verifyError( ...
                @() yfinance.internal.chartQueryParameters(End=endTime), ...
                "yfinance:InvalidDateRange");
        end

        function actionsReturnsNonzeroActionRows(testCase)
            session = StaticChartSession(actionChartFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.actions();

            testCase.verifyEqual(height(data), 2);
            testCase.verifyEqual( ...
                string(data.Properties.VariableNames), ...
                ["Dividends", "StockSplits", "CapitalGains"]);
            testCase.verifyEqual(data.Dividends, [0.24; 0]);
            testCase.verifyEqual(data.StockSplits, [0; 4]);
            testCase.verifyEqual(data.CapitalGains, [0; 1.25]);
        end

        function dividendsReturnsDividendRows(testCase)
            session = StaticChartSession(actionChartFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.dividends();

            testCase.verifyEqual(height(data), 1);
            testCase.verifyEqual(data.Dividends, 0.24);
        end

        function splitsReturnsSplitRows(testCase)
            session = StaticChartSession(actionChartFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.splits();

            testCase.verifyEqual(height(data), 1);
            testCase.verifyEqual(data.StockSplits, 4);
        end

        function capitalGainsReturnsDistributionRows(testCase)
            session = StaticChartSession(actionChartFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.capitalGains();

            testCase.verifyEqual(height(data), 1);
            testCase.verifyEqual(data.CapitalGains, 1.25);
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

function response = actionChartFixture()
response = chartFixture();
timestamps = response.chart.result.timestamp;
events = struct();
events.dividends = struct( ...
    "event1", struct("date", timestamps(1), "amount", 0.24));
events.splits = struct( ...
    "event1", struct("date", timestamps(2), "numerator", 4, "denominator", 1));
events.capitalGains = struct( ...
    "event1", struct("date", timestamps(2), "amount", 1.25));
response.chart.result.events = events;
end

function value = queryValue(query, name)
names = string(query(1:2:end));
values = query(2:2:end);
valueIndex = find(names == name, 1);

if isempty(valueIndex)
    value = "";
else
    value = string(values{valueIndex});
end
end

function value = hasQueryName(query, name)
names = string(query(1:2:end));
value = any(names == name);
end
