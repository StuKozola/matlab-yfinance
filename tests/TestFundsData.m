% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestFundsData < matlab.unittest.TestCase
    %TESTFUNDSDATA Verify ETF and mutual fund data APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function fundsDataParsesQuoteSummaryModules(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=fundsFixture());

            funds = yfinance.FundsData("SPY", Session=session);
            quoteType = funds.QuoteType;

            testCase.verifyEqual(session.LastQuoteSummarySymbol, "SPY");
            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, ...
                ["quoteType", "summaryProfile", "fundProfile", "topHoldings"]);
            testCase.verifyEqual(quoteType, "ETF");
            testCase.verifyEqual(funds.Description, "Tracks the S&P 500.");
            testCase.verifyEqual(funds.FundOverview.CategoryName, "Large Blend");
            testCase.verifyEqual(funds.FundOperations.Value(1), 0.0009);
            testCase.verifyEqual(funds.AssetClasses.StockPosition, 0.98);
            testCase.verifyEqual(funds.TopHoldings.Symbol, ["AAPL"; "MSFT"]);
            testCase.verifyEqual(funds.TopHoldings.HoldingPercent, [0.07; 0.06]);
            testCase.verifyEqual(funds.EquityHoldings.Value(1), 20);
            testCase.verifyEqual(funds.BondHoldings.CategoryAverage(2), 7);
            testCase.verifyEqual(funds.BondRatings.Category, ["aaa"; "bb"]);
            testCase.verifyEqual(funds.SectorWeightings.Weight, [0.35; 0.12]);
            testCase.verifyTrue(isfield(funds.Raw, "topHoldings"));
        end

        function tickerFundsDataReturnsFundsDataObject(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=fundsFixture());
            ticker = yfinance.Ticker("SPY", Session=session);

            funds = ticker.fundsData();
            quoteType = funds.QuoteType;

            testCase.verifyClass(funds, "yfinance.FundsData");
            testCase.verifyEqual(quoteType, "ETF");
            testCase.verifyEqual(session.LastQuoteSummarySymbol, "SPY");
        end

        function missingFundModulesReturnEmptyDefaults(testCase)
            funds = yfinance.internal.quoteSummaryResponseToFundsData(emptyFundsFixture(), Symbol="ABC");

            testCase.verifyEqual(funds.Symbol, "ABC");
            testCase.verifyEqual(funds.QuoteType, "");
            testCase.verifyEqual(funds.FundOverview.CategoryName, "");
            testCase.verifyEqual(height(funds.TopHoldings), 0);
            testCase.verifyEqual(height(funds.BondRatings), 0);
        end
    end
end

function response = fundsFixture()
quoteType = struct("quoteType", "ETF");
summaryProfile = struct("longBusinessSummary", "Tracks the S&P 500.");
fundProfile = fundProfileFixture();
topHoldings = topHoldingsFixture();
result = struct( ...
    "quoteType", quoteType, ...
    "summaryProfile", summaryProfile, ...
    "fundProfile", fundProfile, ...
    "topHoldings", topHoldings);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function fundProfile = fundProfileFixture()
fundProfile = struct( ...
    "categoryName", "Large Blend", ...
    "family", "SPDR State Street Global Advisors", ...
    "legalType", "Exchange Traded Fund");
fundProfile.feesExpensesInvestment = struct( ...
    "annualReportExpenseRatio", formattedValue(0.0009), ...
    "annualHoldingsTurnover", formattedValue(0.02), ...
    "totalNetAssets", formattedValue(500000000000));
fundProfile.feesExpensesInvestmentCat = struct( ...
    "annualReportExpenseRatio", formattedValue(0.001), ...
    "annualHoldingsTurnover", formattedValue(0.15), ...
    "totalNetAssets", formattedValue(12000000000));
end

function topHoldings = topHoldingsFixture()
topHoldings = struct( ...
    "cashPosition", formattedValue(0.01), ...
    "stockPosition", formattedValue(0.98), ...
    "bondPosition", formattedValue(0.00), ...
    "preferredPosition", formattedValue(0.00), ...
    "convertiblePosition", formattedValue(0.00), ...
    "otherPosition", formattedValue(0.01));
topHoldings.holdings = { ...
    struct("symbol", "AAPL", "holdingName", "Apple Inc.", "holdingPercent", formattedValue(0.07)), ...
    struct("symbol", "MSFT", "holdingName", "Microsoft Corporation", "holdingPercent", formattedValue(0.06))};
topHoldings.equityHoldings = struct( ...
    "priceToEarnings", formattedValue(20), ...
    "priceToBook", formattedValue(4), ...
    "priceToSales", formattedValue(3), ...
    "priceToCashflow", formattedValue(15), ...
    "medianMarketCap", formattedValue(100000000000), ...
    "threeYearEarningsGrowth", formattedValue(0.1), ...
    "priceToEarningsCat", formattedValue(18), ...
    "priceToBookCat", formattedValue(3), ...
    "priceToSalesCat", formattedValue(2), ...
    "priceToCashflowCat", formattedValue(13), ...
    "medianMarketCapCat", formattedValue(90000000000), ...
    "threeYearEarningsGrowthCat", formattedValue(0.08));
topHoldings.bondHoldings = struct( ...
    "duration", formattedValue(5), ...
    "maturity", formattedValue(6), ...
    "creditQuality", formattedValue(8), ...
    "durationCat", formattedValue(4), ...
    "maturityCat", formattedValue(7), ...
    "creditQualityCat", formattedValue(9));
topHoldings.bondRatings = {struct("aaa", 0.5), struct("bb", 0.2)};
topHoldings.sectorWeightings = {struct("technology", 0.35), struct("financial_services", 0.12)};
end

function response = emptyFundsFixture()
response = struct("quoteSummary", struct("result", struct(), "error", []));
end

function value = formattedValue(raw)
value = struct("raw", raw, "fmt", string(raw));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
