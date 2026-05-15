classdef TestAliasesAndIsin < matlab.unittest.TestCase
    %TESTALIASESANDISIN Verify compatibility aliases and ISIN lookup.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function businessInsiderSearchResponseExtractsIsin(testCase)
            text = ['mmSuggestDeliver(0, new Array(), new Array(new Array("Apple Inc.", "Stocks", ' ...
                '"AAPL|US0378331005|AAPL||AAPL", "75", "", "aapl|AAPL|1|869")))'];

            isinValue = yfinance.internal.businessInsiderSearchResponseToIsin(text, Symbol="AAPL", Query="Apple Inc.");

            testCase.verifyEqual(isinValue, "US0378331005");
        end

        function missingBusinessInsiderSearchReturnsDash(testCase)
            isinValue = yfinance.internal.businessInsiderSearchResponseToIsin("no match", Symbol="AAPL", Query="Apple Inc.");

            testCase.verifyEqual(isinValue, "-");
        end

        function tickerIsinUsesShortNameAndSearchSession(testCase)
            session = StaticChartSession( ...
                emptyChartFixture(), ...
                QuoteSummaryResponse=infoFixture(), ...
                IsinSearchResponse=isinSearchFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            isinValue = ticker.isin();

            testCase.verifyEqual(session.LastQuoteSummarySymbol, "AAPL");
            testCase.verifyEqual(session.LastIsinSearchQuery, "Apple Inc.");
            testCase.verifyEqual(isinValue, "US0378331005");
        end

        function tickerGetIsinAliasesIsin(testCase)
            session = StaticChartSession( ...
                emptyChartFixture(), ...
                QuoteSummaryResponse=infoFixture(), ...
                IsinSearchResponse=isinSearchFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            isinValue = ticker.getIsin();

            testCase.verifyEqual(isinValue, "US0378331005");
        end

        function tickerIsinSkipsUnsupportedSymbols(testCase)
            ticker = yfinance.Ticker("^GSPC", Session=StaticChartSession(emptyChartFixture()));

            isinValue = ticker.isin();

            testCase.verifyEqual(isinValue, "-");
        end

        function financialStatementAliasesDelegate(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=cashFlowFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.cashflow();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "cashflowStatementHistory");
            testCase.verifyEqual(data.FreeCashFlow, 700);
        end

        function getOptionsAliasDelegates(testCase)
            session = StaticChartSession(emptyChartFixture(), OptionsResponse=optionFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            expirations = ticker.getOptions();

            testCase.verifyEqual(session.LastOptionsSymbol, "AAPL");
            testCase.verifyEqual(expirations, datetime(1709856000, ConvertFrom="posixtime", TimeZone="UTC"));
        end

        function getRecommendationsAliasDelegates(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=recommendationsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.getRecommendations();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "recommendationTrend");
            testCase.verifyEqual(data.Period, "0m");
        end
    end
end

function response = infoFixture()
price = struct("shortName", "Apple Inc.");
response = struct("quoteSummary", struct("result", struct("price", price), "error", []));
end

function text = isinSearchFixture()
text = ['mmSuggestDeliver(0, new Array(), new Array(new Array("Apple Inc.", "Stocks", ' ...
    '"AAPL|US0378331005|AAPL||AAPL", "75", "", "aapl|AAPL|1|869")))'];
end

function response = cashFlowFixture()
statements = struct( ...
    "maxAge", 1, ...
    "endDate", struct("raw", 1703980800, "fmt", "2023-12-31"), ...
    "freeCashFlow", struct("raw", 700, "fmt", "700"));
module = struct("cashflowStatements", statements);
result = struct("cashflowStatementHistory", module);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = optionFixture()
result = struct("expirationDates", 1709856000, "options", struct.empty(0, 1));
response = struct("optionChain", struct("result", result, "error", []));
end

function response = recommendationsFixture()
trend = struct("period", "0m", "strongBuy", 1, "buy", 2, "hold", 3, "sell", 4, "strongSell", 5);
response = struct("quoteSummary", struct("result", struct("recommendationTrend", struct("trend", trend)), "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
