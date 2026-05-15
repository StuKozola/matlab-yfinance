classdef TestMetadataAndFilings < matlab.unittest.TestCase
    %TESTMETADATAANDFILINGS Verify metadata, SEC filings, and shares APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function chartResponseConvertsToHistoryMetadata(testCase)
            metadata = yfinance.internal.chartResponseToHistoryMetadata(chartFixture(), Symbol="AAPL");

            testCase.verifyEqual(metadata.Symbol, "AAPL");
            testCase.verifyEqual(metadata.currency, "USD");
            testCase.verifyEqual(metadata.exchangeName, "NMS");
            testCase.verifyClass(metadata.RegularMarketTime, "datetime");
            testCase.verifyTrue(isfield(metadata, "Raw"));
        end

        function secFilingsResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToSecFilings(secFilingsFixture(), Symbol="AAPL");

            testCase.verifyClass(data, "table");
            testCase.verifyEqual(height(data), 2);
            testCase.verifyEqual(data.Type, ["10-Q"; "8-K"]);
            testCase.verifyEqual(data.Date(1), datetime("2024-10-31", TimeZone="UTC"));
            testCase.verifyEqual(data.EpochDate(1), datetime(1730332800, ConvertFrom="posixtime", TimeZone="UTC"));
            testCase.verifyEqual(data.EdgarUrl(1), "https://www.sec.gov/example-10q");
            testCase.verifyEqual(data.Exhibits{1}.Type, ["EX-101.SCH"; "EX-101.CAL"]);
        end

        function sharesResponseConvertsToMetricTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToShares(sharesFixture(), Symbol="AAPL");

            testCase.verifyClass(data, "table");
            testCase.verifyEqual(data.Metric, [ ...
                "sharesOutstanding"; ...
                "floatShares"; ...
                "impliedSharesOutstanding"; ...
                "heldPercentInsiders"; ...
                "heldPercentInstitutions"; ...
                "marketCap"]);
            testCase.verifyEqual(data.Value, [15000000000; 14800000000; 15100000000; 0.001; 0.62; 3000000000000]);
            testCase.verifyEqual(data.Properties.UserData.Symbol, "AAPL");
        end

        function sharesFullResponseConvertsToTimetable(testCase)
            data = yfinance.internal.fundamentalsTimeSeriesResponseToShares(sharesFullFixture(), Symbol="AAPL");

            testCase.verifyClass(data, "timetable");
            testCase.verifyEqual(height(data), 2);
            testCase.verifyEqual(data.Time(1), datetime(1704067200, ConvertFrom="posixtime", TimeZone="UTC"));
            testCase.verifyEqual(data.SharesOutstanding, [15000000000; 15100000000]);
            testCase.verifyEqual(data.Properties.UserData.Symbol, "AAPL");
            testCase.verifyEqual(data.Properties.UserData.Type, "shares_out");
        end

        function tickerHistoryMetadataUsesChartSession(testCase)
            session = StaticChartSession(chartFixture());
            ticker = yfinance.Ticker(" aapl ", Session=session);

            metadata = ticker.historyMetadata();

            testCase.verifyEqual(session.LastSymbol, "AAPL");
            testCase.verifyEqual(session.LastOptions.Period, "5d");
            testCase.verifyEqual(session.LastOptions.Interval, "1d");
            testCase.verifyEqual(metadata.exchangeName, "NMS");
        end

        function tickerSecFilingsUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=secFilingsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.secFilings();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "secFilings");
            testCase.verifyEqual(data.Type(1), "10-Q");
        end

        function tickerSharesUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=sharesFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.shares();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, ["defaultKeyStatistics", "price"]);
            testCase.verifyEqual(data.Value(1), 15000000000);
        end

        function tickerSharesFullUsesFundamentalsTimeSeriesSession(testCase)
            session = StaticChartSession(emptyChartFixture(), FundamentalsTimeSeriesResponse=sharesFullFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);
            startTime = datetime("2024-01-01", TimeZone="UTC");
            endTime = datetime("2024-04-01", TimeZone="UTC");

            data = ticker.sharesFull(Start=startTime, End=endTime);

            testCase.verifyEqual(session.LastFundamentalsTimeSeriesSymbol, "AAPL");
            testCase.verifyEqual(session.LastFundamentalsTimeSeriesRequest.Types, "shares_out");
            testCase.verifyEqual(session.LastFundamentalsTimeSeriesRequest.Start, startTime);
            testCase.verifyEqual(session.LastFundamentalsTimeSeriesRequest.End, endTime);
            testCase.verifyEqual(data.SharesOutstanding(2), 15100000000);
        end

        function emptySecFilingsReturnsEmptyTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToSecFilings(emptySecFilingsFixture(), Symbol="AAPL");

            testCase.verifyEqual(height(data), 0);
            testCase.verifyEqual(data.Properties.VariableNames, ...
                {'Date', 'EpochDate', 'Type', 'Title', 'EdgarUrl', 'Exhibits'});
        end

        function emptySharesFullReturnsEmptyTimetable(testCase)
            data = yfinance.internal.fundamentalsTimeSeriesResponseToShares(emptySharesFullFixture(), Symbol="AAPL");

            testCase.verifyClass(data, "timetable");
            testCase.verifyEqual(height(data), 0);
            testCase.verifyEqual(data.Properties.VariableNames, {'SharesOutstanding'});
            testCase.verifyEqual(data.Properties.UserData.Symbol, "AAPL");
        end
    end
end

function response = chartFixture()
meta = struct( ...
    "currency", "USD", ...
    "symbol", "AAPL", ...
    "exchangeName", "NMS", ...
    "fullExchangeName", "NasdaqGS", ...
    "exchangeTimezoneName", "America/New_York", ...
    "instrumentType", "EQUITY", ...
    "regularMarketTime", 1704205800, ...
    "regularMarketPrice", 222.5);
result = struct("meta", meta, "timestamp", 1704205800, "indicators", struct());
response = struct("chart", struct("result", result, "error", []));
end

function response = secFilingsFixture()
filing1 = struct( ...
    "date", "2024-10-31", ...
    "epochDate", 1730332800, ...
    "type", "10-Q", ...
    "title", "Quarterly report", ...
    "edgarUrl", "https://www.sec.gov/example-10q", ...
    "exhibits", exhibitsFixture());
filing2 = struct( ...
    "date", "2024-09-09", ...
    "epochDate", 1725840000, ...
    "type", "8-K", ...
    "title", "Current report", ...
    "edgarUrl", "https://www.sec.gov/example-8k", ...
    "exhibits", struct.empty(0, 1));
result = struct("secFilings", struct("filings", [filing1; filing2]));
response = struct("quoteSummary", struct("result", result, "error", []));
end

function exhibits = exhibitsFixture()
exhibits(1) = struct("type", "EX-101.SCH", "url", "https://www.sec.gov/example-sch");
exhibits(2) = struct("type", "EX-101.CAL", "url", "https://www.sec.gov/example-cal");
exhibits = exhibits(:);
end

function response = sharesFixture()
defaultKeyStatistics = struct( ...
    "sharesOutstanding", struct("raw", 15000000000, "fmt", "15B"), ...
    "floatShares", struct("raw", 14800000000, "fmt", "14.8B"), ...
    "impliedSharesOutstanding", struct("raw", 15100000000, "fmt", "15.1B"), ...
    "heldPercentInsiders", struct("raw", 0.001, "fmt", "0.10%"), ...
    "heldPercentInstitutions", struct("raw", 0.62, "fmt", "62.00%"));
price = struct("marketCap", struct("raw", 3000000000000, "fmt", "3T"));
result = struct("defaultKeyStatistics", defaultKeyStatistics, "price", price);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = sharesFullFixture()
result = struct( ...
    "meta", struct("symbol", "AAPL", "type", "shares_out"), ...
    "timestamp", [1704067200; 1711929600], ...
    "shares_out", [15000000000; 15100000000]);
response = struct("timeseries", struct("result", result, "error", []));
end

function response = emptySecFilingsFixture()
result = struct("secFilings", struct("filings", []));
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = emptySharesFullFixture()
result = struct("meta", struct("symbol", "AAPL", "type", "shares_out"));
response = struct("timeseries", struct("result", result, "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
