% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestScreener < matlab.unittest.TestCase
    %TESTSCREENER Verify screener APIs.

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

        function cellWrappedScreenerResponseHandlesSparseQuotes(testCase)
            result = yfinance.internal.screenerResponseToResult( ...
                sparseScreenerFixture(), ...
                Query="custom");

            testCase.verifyEqual(result.Query, "custom");
            testCase.verifyEqual(result.Title, "Sparse Quotes");
            testCase.verifyEqual(result.Quotes.Symbol, ["AAPL"; "MSFT"]);
            testCase.verifyEqual(result.Quotes.RegularMarketPrice, [200; NaN]);
            testCase.verifyTrue(ismissing(result.Quotes.ShortName(2)));
        end

        function screenFunctionUsesSession(testCase)
            session = StaticChartSession(emptyChartFixture(), ScreenerResponse=screenerFixture());

            result = yfinance.screen("day_gainers", Count=2, Session=session);

            testCase.verifyEqual(session.LastScreenerQuery, "day_gainers");
            testCase.verifyEqual(session.LastScreenerRequest.Count, 2);
            testCase.verifyEqual(session.LastScreenerRequest.Offset, 0);
            testCase.verifyEqual(result.Quotes.Symbol(1), "AAPL");
        end

        function predefinedScreenerQueriesReturnUpstreamNames(testCase)
            queries = yfinance.predefinedScreenerQueries();

            testCase.verifyClass(queries, "string");
            testCase.verifySize(queries, [19, 1]);
            testCase.verifyEqual(queries(1), "aggressive_small_caps");
            testCase.verifyEqual(queries(end), "bond_etfs");
            testCase.verifyTrue(ismember("top_performing_etfs", queries));
        end

        function uppercasePredefinedScreenerQueriesReturnsDefinitions(testCase)
            definitions = yfinance.PREDEFINED_SCREENER_QUERIES();

            testCase.verifyTrue(isfield(definitions, "day_gainers"));
            testCase.verifyTrue(isfield(definitions, "high_yield_bond"));
            testCase.verifyEqual(definitions.day_gainers.SortField, "percentchange");
            testCase.verifyEqual(definitions.day_gainers.SortType, "DESC");
            testCase.verifyFalse(definitions.day_gainers.SortAscending);
            testCase.verifyEqual(definitions.high_yield_bond.QuoteType, "MUTUALFUND");
            testCase.verifyEqual(definitions.top_performing_etfs.QuoteType, "ETF");
        end

        function predefinedScreenWithOffsetUsesCustomEndpoint(testCase)
            session = StaticChartSession(emptyChartFixture(), ScreenerResponse=screenerFixture());

            result = yfinance.screen("day_gainers", Count=2, Offset=5, Session=session);

            testCase.verifyEqual(session.LastCustomScreenerQuery.operator, "AND");
            testCase.verifyEqual(session.LastCustomScreenerRequest.Count, 2);
            testCase.verifyEqual(session.LastCustomScreenerRequest.Offset, 5);
            testCase.verifyEqual(session.LastCustomScreenerRequest.SortField, "percentchange");
            testCase.verifyFalse(session.LastCustomScreenerRequest.SortAscending);
            testCase.verifyEqual(session.LastCustomScreenerRequest.QuoteType, "EQUITY");
            testCase.verifyEqual(result.Query, "day_gainers");
        end

        function equityQueryConvertsToYahooStruct(testCase)
            query = yfinance.EquityQuery("and", { ...
                yfinance.EquityQuery("gt", {"percentchange", 3}), ...
                yfinance.EquityQuery("eq", {"region", "us"})});

            value = query.toStruct();

            testCase.verifyEqual(value.operator, "AND");
            testCase.verifyEqual(value.operands{1}.operator, "GT");
            testCase.verifyEqual(value.operands{1}.operands{1}, "percentchange");
            testCase.verifyEqual(value.operands{1}.operands{2}, 3);
            testCase.verifyEqual(value.operands{2}.operator, "EQ");
            testCase.verifyEqual(value.operands{2}.operands{2}, "us");
        end

        function isInQueryExpandsToOrOfEquals(testCase)
            query = yfinance.EquityQuery("is-in", {"exchange", "NMS", "NYQ"});

            value = query.toStruct();

            testCase.verifyEqual(value.operator, "OR");
            testCase.verifyEqual(numel(value.operands), 2);
            testCase.verifyEqual(value.operands{1}.operator, "EQ");
            testCase.verifyEqual(value.operands{1}.operands{2}, "NMS");
            testCase.verifyEqual(value.operands{2}.operator, "EQ");
            testCase.verifyEqual(value.operands{2}.operands{2}, "NYQ");
        end

        function screenFunctionPostsCustomQuery(testCase)
            query = yfinance.EquityQuery("gt", {"percentchange", 3});
            session = StaticChartSession(emptyChartFixture(), ScreenerResponse=screenerFixture());

            result = yfinance.screen( ...
                query, ...
                Size=2, ...
                Offset=5, ...
                SortField="percentchange", ...
                SortAscending=true, ...
                Session=session);

            testCase.verifyEqual(session.LastCustomScreenerQuery.operator, "GT");
            testCase.verifyEqual(session.LastCustomScreenerRequest.Count, 2);
            testCase.verifyEqual(session.LastCustomScreenerRequest.Offset, 5);
            testCase.verifyEqual(session.LastCustomScreenerRequest.SortField, "percentchange");
            testCase.verifyTrue(session.LastCustomScreenerRequest.SortAscending);
            testCase.verifyEqual(session.LastCustomScreenerRequest.QuoteType, "EQUITY");
            testCase.verifyEqual(result.Query, string(query));
            testCase.verifyEqual(result.Quotes.Symbol(1), "AAPL");
        end

        function fundAndEtfQueriesCarryQuoteTypes(testCase)
            fundQuery = yfinance.FundQuery("eq", {"categoryname", "Large Growth"});
            etfQuery = yfinance.ETFQuery("eq", {"region", "us"});

            testCase.verifyEqual(fundQuery.QuoteType, "MUTUALFUND");
            testCase.verifyEqual(etfQuery.QuoteType, "ETF");
        end

        function invalidQueryOperatorErrors(testCase)
            testCase.verifyError( ...
                @() yfinance.EquityQuery("near", {"region", "us"}), ...
                "yfinance:InvalidQueryOperator");
        end

        function invalidComparisonOperandErrors(testCase)
            testCase.verifyError( ...
                @() yfinance.EquityQuery("gt", {"percentchange", "high"}), ...
                "yfinance:InvalidQueryOperand");
        end

        function screenerClassStoresResult(testCase)
            session = StaticChartSession(emptyChartFixture(), ScreenerResponse=screenerFixture());

            screener = yfinance.Screener("day_gainers", Count=2, Session=session);

            testCase.verifyEqual(screener.Query, "day_gainers");
            testCase.verifyEqual(screener.Quotes.Symbol(2), "MSFT");
            testCase.verifyTrue(isfield(screener.Raw, "quotes"));
        end

        function screenerClassStoresCustomResult(testCase)
            session = StaticChartSession(emptyChartFixture(), ScreenerResponse=screenerFixture());
            query = yfinance.ETFQuery("eq", {"region", "us"});

            screener = yfinance.Screener(query, Size=2, Session=session);

            testCase.verifyEqual(screener.Query, string(query));
            testCase.verifyEqual(screener.Quotes.Symbol(2), "MSFT");
            testCase.verifyEqual(session.LastCustomScreenerRequest.QuoteType, "ETF");
        end

        function countAboveYahooLimitErrors(testCase)
            session = yfinance.internal.Session();

            testCase.verifyError( ...
                @() session.getScreener("day_gainers", Count=251), ...
                "yfinance:InvalidCount");
        end

        function customCountAboveYahooLimitErrors(testCase)
            session = StaticChartSession(emptyChartFixture(), ScreenerResponse=screenerFixture());
            query = yfinance.EquityQuery("eq", {"region", "us"});

            testCase.verifyError( ...
                @() yfinance.screen(query, Size=251, Session=session), ...
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

function response = sparseScreenerFixture()
quote1 = struct( ...
    "symbol", "AAPL", ...
    "shortName", "Apple Inc.", ...
    "regularMarketPrice", struct("raw", 200, "fmt", "200.00"));
quote2 = struct( ...
    "symbol", "MSFT", ...
    "regularMarketPrice", []);
result = struct( ...
    "id", "custom", ...
    "title", "Sparse Quotes", ...
    "description", "", ...
    "start", 0, ...
    "count", 2, ...
    "total", 2);
result.quotes = {quote1; quote2};
response = struct("finance", struct("result", {{result}}, "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
