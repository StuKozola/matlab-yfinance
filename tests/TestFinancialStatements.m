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

        function tickerBalanceSheetUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=balanceFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.balanceSheet();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "balanceSheetHistory");
            testCase.verifyEqual(data.TotalAssets(1), 5000);
        end

        function tickerCashFlowUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=cashFlowFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.cashFlow();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "cashflowStatementHistory");
            testCase.verifyEqual(data.TotalCashFromOperatingActivities(1), 800);
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

function value = formattedValue(rawValue, formattedText)
value = struct("raw", rawValue, "fmt", formattedText);
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
