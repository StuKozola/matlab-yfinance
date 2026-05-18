% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestFinancialStatements < matlab.unittest.TestCase
    %TESTFINANCIALSTATEMENTS Verify financial statement APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function incomeStatementConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                incomeFixture(), ...
                Symbol="AAPL", ...
                Module="incomeStatementHistory");

            testCase.verifyClass(data, "table");
            testCase.verifyEqual(height(data), 2);
            testCase.verifyEqual(data.TotalRevenue, [1000; 900]);
            testCase.verifyEqual(data.NetIncome, [250; 200]);
            testCase.verifyClass(data.EndDate, "datetime");
            testCase.verifyEqual(data.Properties.UserData.Symbol, "AAPL");
        end

        function balanceSheetConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                balanceFixture(), ...
                Symbol="AAPL", ...
                Module="balanceSheetHistory");

            testCase.verifyEqual(data.TotalAssets, [5000; 4500]);
            testCase.verifyEqual(data.TotalLiab, [2000; 1800]);
        end

        function cashFlowConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                cashFlowFixture(), ...
                Symbol="AAPL", ...
                Module="cashflowStatementHistory");

            testCase.verifyEqual(data.TotalCashFromOperatingActivities, [800; 700]);
            testCase.verifyEqual(data.CapitalExpenditures, [-100; -90]);
        end

        function fundamentalsTimeSeriesConvertsToTtmStatement(testCase)
            data = yfinance.internal.fundamentalsTimeSeriesResponseToFinancialStatement( ...
                ttmFixture(), ...
                Symbol="AAPL", ...
                StatementType="income", ...
                Frequency="trailing", ...
                Types=["trailingTotalRevenue", "trailingNetIncome", "trailingOperatingCashFlow"]);

            testCase.verifyEqual(height(data), 2);
            testCase.verifyEqual(data.EndDate, [ ...
                datetime("2026-03-31", TimeZone="UTC"); ...
                datetime("2025-06-30", TimeZone="UTC")]);
            testCase.verifyEqual(data.Properties.VariableNames, ...
                {'EndDate', 'TotalRevenue', 'NetIncome', 'OperatingCashFlow'});
            testCase.verifyEqual(data.TotalRevenue, [1200; 1000]);
            testCase.verifyEqual(data.NetIncome, [300; 250]);
            testCase.verifyEqual(data.OperatingCashFlow, [350; 310]);
            testCase.verifyEqual(data.Properties.UserData.Frequency, "trailing");
        end

        function tickerIncomeStmtUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=incomeFixture());
            ticker = yfinance.Ticker(" aapl ", Session=session);

            data = ticker.incomeStmt();

            testCase.verifyEqual(session.LastQuoteSummarySymbol, "AAPL");
            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "incomeStatementHistory");
            testCase.verifyEqual(data.TotalRevenue(1), 1000);
        end

        function tickerQuarterlyIncomeStmtUsesQuarterlyModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=quarterlyIncomeFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.incomeStmt(Quarterly=true);

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "incomeStatementHistoryQuarterly");
            testCase.verifyEqual(data.TotalRevenue, 300);
        end

        function tickerFinancialsAliasUsesIncomeStatement(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=incomeFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.financials();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "incomeStatementHistory");
            testCase.verifyEqual(data.NetIncome(1), 250);
        end

        function tickerFinancialsAcceptsQuarterlyOption(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=quarterlyIncomeFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.financials(Quarterly=true);

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "incomeStatementHistoryQuarterly");
            testCase.verifyEqual(data.TotalRevenue, 300);
        end

        function tickerFinancialsAcceptsTrailingOption(testCase)
            session = StaticChartSession(emptyChartFixture(), FundamentalsTimeSeriesResponse=ttmFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.financials(Trailing=true);

            testCase.verifyEqual(session.LastFundamentalsTimeSeriesSymbol, "AAPL");
            testCase.verifyTrue(ismember("trailingTotalRevenue", session.LastFundamentalsTimeSeriesRequest.Types));
            testCase.verifyTrue(ismember("trailingNetIncome", session.LastFundamentalsTimeSeriesRequest.Types));
            testCase.verifyEqual(data.TotalRevenue(1), 1200);
        end

        function tickerQuarterlyIncomeStmtAliasUsesQuarterlyModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=quarterlyIncomeFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.quarterlyIncomeStmt();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "incomeStatementHistoryQuarterly");
            testCase.verifyEqual(data.NetIncome, 75);
        end

        function tickerTtmIncomeStmtAliasUsesFundamentalsTimeSeries(testCase)
            session = StaticChartSession(emptyChartFixture(), FundamentalsTimeSeriesResponse=ttmFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.ttmIncomeStmt();

            testCase.verifyEqual(session.LastFundamentalsTimeSeriesSymbol, "AAPL");
            testCase.verifyTrue(ismember("trailingTotalRevenue", session.LastFundamentalsTimeSeriesRequest.Types));
            testCase.verifyEqual(session.LastFundamentalsTimeSeriesRequest.Start, datetime(2016, 12, 31, TimeZone="UTC"));
            testCase.verifyEqual(data.NetIncome(1), 300);
        end

        function tickerQuarterlyFinancialsAliasUsesQuarterlyModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=quarterlyIncomeFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.quarterlyFinancials();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "incomeStatementHistoryQuarterly");
            testCase.verifyEqual(data.GrossProfit, 120);
        end

        function tickerTtmFinancialsAliasUsesTtmIncomeStatement(testCase)
            session = StaticChartSession(emptyChartFixture(), FundamentalsTimeSeriesResponse=ttmFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.ttmFinancials();

            testCase.verifyTrue(ismember("trailingNetIncome", session.LastFundamentalsTimeSeriesRequest.Types));
            testCase.verifyEqual(data.NetIncome(1), 300);
        end

        function tickerBalanceSheetUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=balanceFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.balanceSheet();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "balanceSheetHistory");
            testCase.verifyEqual(data.TotalAssets(1), 5000);
        end

        function tickerQuarterlyBalanceSheetAliasUsesQuarterlyModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=quarterlyBalanceFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.quarterlyBalanceSheet();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "balanceSheetHistoryQuarterly");
            testCase.verifyEqual(data.TotalAssets, 5100);
        end

        function tickerCashFlowUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=cashFlowFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.cashFlow();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "cashflowStatementHistory");
            testCase.verifyEqual(data.TotalCashFromOperatingActivities(1), 800);
        end

        function tickerQuarterlyCashFlowAliasUsesQuarterlyModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=quarterlyCashFlowFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.quarterlyCashFlow();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "cashflowStatementHistoryQuarterly");
            testCase.verifyEqual(data.TotalCashFromOperatingActivities, 210);
        end

        function tickerTtmCashFlowAliasUsesFundamentalsTimeSeries(testCase)
            session = StaticChartSession(emptyChartFixture(), FundamentalsTimeSeriesResponse=ttmFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.ttmCashFlow();

            testCase.verifyTrue(ismember("trailingOperatingCashFlow", session.LastFundamentalsTimeSeriesRequest.Types));
            testCase.verifyTrue(ismember("trailingFreeCashFlow", session.LastFundamentalsTimeSeriesRequest.Types));
            testCase.verifyEqual(data.OperatingCashFlow(1), 350);
        end

        function tickerCashFlowAcceptsTrailingOption(testCase)
            session = StaticChartSession(emptyChartFixture(), FundamentalsTimeSeriesResponse=ttmFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.cashFlow(Trailing=true);

            testCase.verifyTrue(ismember("trailingOperatingCashFlow", session.LastFundamentalsTimeSeriesRequest.Types));
            testCase.verifyEqual(data.OperatingCashFlow(1), 350);
        end

        function tickerQuarterlyEarningsAliasUsesEarningsModule(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=earningsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.quarterlyEarnings();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "earnings");
            testCase.verifyEqual(data.Period, "1Q2024");
            testCase.verifyEqual(data.Revenue, 910);
        end

        function quarterlyTrailingIncomeStmtErrors(testCase)
            ticker = yfinance.Ticker("AAPL", Session=StaticChartSession(emptyChartFixture()));

            testCase.verifyError( ...
                @() ticker.incomeStmt(Quarterly=true, Trailing=true), ...
                "yfinance:InvalidFrequency");
        end

        function missingStatementModuleReturnsEmptyTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                struct("quoteSummary", struct("result", struct(), "error", [])), ...
                Symbol="AAPL", ...
                Module="incomeStatementHistory");

            testCase.verifyEqual(height(data), 0);
            testCase.verifyTrue(ismember("EndDate", string(data.Properties.VariableNames)));
        end
    end
end

function response = incomeFixture()
statements(1) = struct( ...
    "maxAge", 1, ...
    "endDate", formattedValue(1703980800, "2023-12-31"), ...
    "totalRevenue", formattedValue(1000, "1,000"), ...
    "grossProfit", formattedValue(400, "400"), ...
    "netIncome", formattedValue(250, "250"));
statements(2) = struct( ...
    "maxAge", 1, ...
    "endDate", formattedValue(1672444800, "2022-12-31"), ...
    "totalRevenue", formattedValue(900, "900"), ...
    "grossProfit", formattedValue(350, "350"), ...
    "netIncome", formattedValue(200, "200"));
module = struct("incomeStatementHistory", statements);
result = struct("incomeStatementHistory", module);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = quarterlyIncomeFixture()
statements = struct( ...
    "maxAge", 1, ...
    "endDate", formattedValue(1703980800, "2023-12-31"), ...
    "totalRevenue", formattedValue(300, "300"), ...
    "grossProfit", formattedValue(120, "120"), ...
    "netIncome", formattedValue(75, "75"));
module = struct("incomeStatementHistory", statements);
result = struct("incomeStatementHistoryQuarterly", module);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = balanceFixture()
statements(1) = struct( ...
    "maxAge", 1, ...
    "endDate", formattedValue(1703980800, "2023-12-31"), ...
    "totalAssets", formattedValue(5000, "5,000"), ...
    "totalLiab", formattedValue(2000, "2,000"), ...
    "totalStockholderEquity", formattedValue(3000, "3,000"));
statements(2) = struct( ...
    "maxAge", 1, ...
    "endDate", formattedValue(1672444800, "2022-12-31"), ...
    "totalAssets", formattedValue(4500, "4,500"), ...
    "totalLiab", formattedValue(1800, "1,800"), ...
    "totalStockholderEquity", formattedValue(2700, "2,700"));
module = struct("balanceSheetStatements", statements);
result = struct("balanceSheetHistory", module);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = quarterlyBalanceFixture()
statements = struct( ...
    "maxAge", 1, ...
    "endDate", formattedValue(1703980800, "2023-12-31"), ...
    "totalAssets", formattedValue(5100, "5,100"), ...
    "totalLiab", formattedValue(2050, "2,050"), ...
    "totalStockholderEquity", formattedValue(3050, "3,050"));
module = struct("balanceSheetStatements", statements);
result = struct("balanceSheetHistoryQuarterly", module);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = cashFlowFixture()
statements(1) = struct( ...
    "maxAge", 1, ...
    "endDate", formattedValue(1703980800, "2023-12-31"), ...
    "totalCashFromOperatingActivities", formattedValue(800, "800"), ...
    "capitalExpenditures", formattedValue(-100, "-100"), ...
    "freeCashFlow", formattedValue(700, "700"));
statements(2) = struct( ...
    "maxAge", 1, ...
    "endDate", formattedValue(1672444800, "2022-12-31"), ...
    "totalCashFromOperatingActivities", formattedValue(700, "700"), ...
    "capitalExpenditures", formattedValue(-90, "-90"), ...
    "freeCashFlow", formattedValue(610, "610"));
module = struct("cashflowStatements", statements);
result = struct("cashflowStatementHistory", module);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = quarterlyCashFlowFixture()
statements = struct( ...
    "maxAge", 1, ...
    "endDate", formattedValue(1703980800, "2023-12-31"), ...
    "totalCashFromOperatingActivities", formattedValue(210, "210"), ...
    "capitalExpenditures", formattedValue(-25, "-25"), ...
    "freeCashFlow", formattedValue(185, "185"));
module = struct("cashflowStatements", statements);
result = struct("cashflowStatementHistoryQuarterly", module);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = earningsFixture()
quarterly = struct( ...
    "date", "1Q2024", ...
    "revenue", struct("raw", 910, "fmt", "910"), ...
    "earnings", struct("raw", 240, "fmt", "240"));
earnings = struct( ...
    "financialCurrency", "USD", ...
    "financialsChart", struct("quarterly", quarterly));
result = struct("earnings", earnings);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = ttmFixture()
totalRevenue = struct( ...
    "asOfDate", {"2025-06-30"; "2026-03-31"}, ...
    "periodType", {"TTM"; "TTM"}, ...
    "currencyCode", {"USD"; "USD"}, ...
    "reportedValue", {formattedValue(1000, "1,000"); formattedValue(1200, "1,200")});
netIncome = struct( ...
    "asOfDate", {"2025-06-30"; "2026-03-31"}, ...
    "periodType", {"TTM"; "TTM"}, ...
    "currencyCode", {"USD"; "USD"}, ...
    "reportedValue", {formattedValue(250, "250"); formattedValue(300, "300")});
operatingCashFlow = struct( ...
    "asOfDate", {"2025-06-30"; "2026-03-31"}, ...
    "periodType", {"TTM"; "TTM"}, ...
    "currencyCode", {"USD"; "USD"}, ...
    "reportedValue", {formattedValue(310, "310"); formattedValue(350, "350")});
result = { ...
    struct("meta", struct("symbol", "AAPL", "type", "trailingNetIncome"), "trailingNetIncome", netIncome); ...
    struct("meta", struct("symbol", "AAPL", "type", "trailingOperatingCashFlow"), "trailingOperatingCashFlow", operatingCashFlow); ...
    struct("meta", struct("symbol", "AAPL", "type", "trailingTotalRevenue"), "trailingTotalRevenue", totalRevenue)};
response = struct("timeseries", struct("result", {result}, "error", []));
end

function value = formattedValue(rawValue, formattedText)
value = struct("raw", rawValue, "fmt", formattedText);
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
