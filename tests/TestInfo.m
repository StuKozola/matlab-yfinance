% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestInfo < matlab.unittest.TestCase
    %TESTINFO Verify ticker quote summary metadata handling.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function quoteSummaryResponseConvertsToInfo(testCase)
            info = yfinance.internal.quoteSummaryResponseToInfo(infoFixture(), Symbol="AAPL");

            testCase.verifyEqual(info.Symbol, "AAPL");
            testCase.verifyEqual(info.symbol, "AAPL");
            testCase.verifyEqual(info.shortName, "Apple Inc.");
            testCase.verifyEqual(info.marketCap, 3000000000000);
            testCase.verifyEqual(info.trailingPE, 28.5);
            testCase.verifyEqual(info.sector, "Technology");
            testCase.verifyTrue(isfield(info, "Raw"));
            testCase.verifyTrue(isfield(info, "price"));
        end

        function tickerInfoUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=infoFixture());
            ticker = yfinance.Ticker(" aapl ", Session=session);

            info = ticker.info(Modules=["price", "summaryProfile"]);

            testCase.verifyEqual(session.LastQuoteSummarySymbol, "AAPL");
            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, ["price", "summaryProfile"]);
            testCase.verifyEqual(info.shortName, "Apple Inc.");
        end

        function tickerInfoFallsBackToFastInfo(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteResponse=quoteFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            info = ticker.info();

            testCase.verifyEqual(info.Symbol, "AAPL");
            testCase.verifyEqual(info.LastPrice, 123.45);
            testCase.verifyEqual(info.InfoSource, "fastInfoFallback");
        end

        function emptyQuoteSummaryReportsNoData(testCase)
            response = struct("quoteSummary", struct("result", [], "error", []));

            testCase.verifyError( ...
                @() yfinance.internal.quoteSummaryResponseToInfo(response, Symbol="AAPL"), ...
                "yfinance:NoData");
        end

        function emptyModulesReportError(testCase)
            testCase.verifyError( ...
                @() yfinance.internal.normalizeModules(" "), ...
                "yfinance:InvalidModule");
        end
    end
end

function response = infoFixture()
price = struct( ...
    "symbol", "AAPL", ...
    "shortName", "Apple Inc.", ...
    "longName", "Apple Inc.", ...
    "regularMarketPrice", struct("raw", 123.45, "fmt", "123.45"), ...
    "marketCap", struct("raw", 3000000000000, "fmt", "3T", "longFmt", "3,000,000,000,000"));
summaryProfile = struct( ...
    "sector", "Technology", ...
    "industry", "Consumer Electronics", ...
    "website", "https://www.apple.com");
summaryDetail = struct( ...
    "trailingPE", struct("raw", 28.5, "fmt", "28.50"), ...
    "dividendRate", struct("raw", 1.04, "fmt", "1.04"));
result = struct( ...
    "price", price, ...
    "summaryProfile", summaryProfile, ...
    "summaryDetail", summaryDetail);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = quoteFixture()
quote = struct( ...
    "symbol", "AAPL", ...
    "currency", "USD", ...
    "regularMarketPrice", 123.45, ...
    "regularMarketPreviousClose", 120.25);
response = struct("quoteResponse", struct("result", quote, "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
