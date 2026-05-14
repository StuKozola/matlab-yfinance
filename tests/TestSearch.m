classdef TestSearch < matlab.unittest.TestCase
    %TESTSEARCH Verify Yahoo Finance search handling.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function responseConvertsToTables(testCase)
            result = yfinance.internal.searchResponseToResult(searchFixture(), Query="apple");

            testCase.verifyEqual(result.Query, "apple");
            testCase.verifyClass(result.Quotes, "table");
            testCase.verifyClass(result.News, "table");
            testCase.verifyEqual(result.Quotes.Symbol, ["AAPL"; "APLE"]);
            testCase.verifyEqual(result.Quotes.ShortName(1), "Apple Inc.");
            testCase.verifyEqual(result.News.Title, "Apple headline");
            testCase.verifyClass(result.News.ProviderPublishTime, "datetime");
            testCase.verifyTrue(isfield(result, "Raw"));
        end

        function searchClassUsesSession(testCase)
            session = StaticChartSession(emptyChartFixture(), SearchResponse=searchFixture());

            result = yfinance.Search(" apple ", QuotesCount=2, NewsCount=1, Session=session);

            testCase.verifyEqual(result.Query, "apple");
            testCase.verifyEqual(session.LastSearchQuery, "apple");
            testCase.verifyEqual(session.LastSearchRequest.QuotesCount, 2);
            testCase.verifyEqual(session.LastSearchRequest.NewsCount, 1);
            testCase.verifyEqual(result.Quotes.Symbol, ["AAPL"; "APLE"]);
            testCase.verifyEqual(result.News.Title, "Apple headline");
        end

        function tickerNewsUsesSearchSession(testCase)
            session = StaticChartSession(emptyChartFixture(), SearchResponse=searchFixture());
            ticker = yfinance.Ticker(" aapl ", Session=session);

            data = ticker.news(Count=1);

            testCase.verifyEqual(session.LastSearchQuery, "AAPL");
            testCase.verifyEqual(session.LastSearchRequest.QuotesCount, 0);
            testCase.verifyEqual(session.LastSearchRequest.NewsCount, 1);
            testCase.verifyClass(data, "table");
            testCase.verifyEqual(data.Title, "Apple headline");
        end

        function emptySearchResponseReturnsEmptyTables(testCase)
            result = yfinance.internal.searchResponseToResult(struct(), Query="nothing");

            testCase.verifyEqual(height(result.Quotes), 0);
            testCase.verifyEqual(height(result.News), 0);
        end
    end
end

function response = searchFixture()
quotes(1) = struct( ...
    "symbol", "AAPL", ...
    "shortname", "Apple Inc.", ...
    "longname", "Apple Inc.", ...
    "quoteType", "EQUITY", ...
    "exchange", "NMS", ...
    "score", 100000, ...
    "typeDisp", "Equity");
quotes(2) = struct( ...
    "symbol", "APLE", ...
    "shortname", "Apple Hospitality REIT, Inc.", ...
    "longname", "Apple Hospitality REIT, Inc.", ...
    "quoteType", "EQUITY", ...
    "exchange", "NYQ", ...
    "score", 25000, ...
    "typeDisp", "Equity");
news = struct( ...
    "title", "Apple headline", ...
    "publisher", "Example News", ...
    "link", "https://example.com/apple", ...
    "providerPublishTime", 1704205800, ...
    "type", "STORY", ...
    "uuid", "news-1");
response = struct("quotes", quotes, "news", news);
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
