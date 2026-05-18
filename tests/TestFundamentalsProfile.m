% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestFundamentalsProfile < matlab.unittest.TestCase
    %TESTFUNDAMENTALSPROFILE Verify quoteSummary profile and fundamentals APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function tickerQuoteSummaryUsesRequestedModules(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=fundamentalsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.quoteSummary(Modules=["summaryDetail", "financialData"]);

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, ["summaryDetail", "financialData"]);
            testCase.verifyEqual(data.trailingPE, 30);
            testCase.verifyEqual(data.currentPrice, 200);
        end

        function tickerSummaryDetailUsesSummaryDetailModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=fundamentalsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.summaryDetail();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "summaryDetail");
            testCase.verifyEqual(data.trailingPE, 30);
        end

        function tickerDefaultKeyStatisticsUsesStatisticsModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=fundamentalsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.defaultKeyStatistics();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "defaultKeyStatistics");
            testCase.verifyEqual(data.enterpriseValue, 3200000000000);
        end

        function tickerFinancialDataUsesFinancialDataModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=fundamentalsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.financialData();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "financialData");
            testCase.verifyEqual(data.grossMargins, 0.46);
        end

        function tickerProfileAndQuoteTypeMethodsUseExpectedModules(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=fundamentalsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            profile = ticker.assetProfile();
            quoteType = ticker.quoteType();

            testCase.verifyEqual(profile.sector, "Technology");
            testCase.verifyEqual(quoteType.quoteType.quoteType, "EQUITY");
            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "quoteType");
        end

        function tickerFundProfileUsesFundProfileModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=fundProfileFixture());
            ticker = yfinance.Ticker("SPY", Session=session);

            data = ticker.fundProfile();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "fundProfile");
            testCase.verifyEqual(data.categoryName, "Large Blend");
        end

        function tickerFundamentalsUsesCommonModules(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=fundamentalsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.fundamentals();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, ...
                ["summaryDetail", "defaultKeyStatistics", "financialData", "assetProfile", "quoteType"]);
            testCase.verifyEqual(data.enterpriseValue, 3200000000000);
            testCase.verifyEqual(data.sector, "Technology");
        end
    end
end

function response = fundamentalsFixture()
summaryDetail = struct( ...
    "trailingPE", struct("raw", 30, "fmt", "30.00"), ...
    "forwardPE", struct("raw", 25, "fmt", "25.00"));
defaultKeyStatistics = struct( ...
    "enterpriseValue", struct("raw", 3200000000000, "fmt", "3.2T"), ...
    "priceToBook", struct("raw", 45, "fmt", "45.00"));
financialData = struct( ...
    "currentPrice", struct("raw", 200, "fmt", "200.00"), ...
    "grossMargins", struct("raw", 0.46, "fmt", "46.00%"));
assetProfile = struct( ...
    "sector", "Technology", ...
    "industry", "Consumer Electronics");
quoteType = struct( ...
    "quoteType", "EQUITY", ...
    "longName", "Apple Inc.");
result = struct( ...
    "summaryDetail", summaryDetail, ...
    "defaultKeyStatistics", defaultKeyStatistics, ...
    "financialData", financialData, ...
    "assetProfile", assetProfile, ...
    "quoteType", quoteType);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = fundProfileFixture()
fundProfile = struct( ...
    "categoryName", "Large Blend", ...
    "legalType", "Exchange Traded Fund");
response = struct("quoteSummary", struct("result", struct("fundProfile", fundProfile), "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
