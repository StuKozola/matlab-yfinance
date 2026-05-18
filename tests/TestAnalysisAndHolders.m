% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestAnalysisAndHolders < matlab.unittest.TestCase
    %TESTANALYSISANDHOLDERS Verify analysis and holder quoteSummary APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function sustainabilityResponseConvertsToStruct(testCase)
            data = yfinance.internal.quoteSummaryResponseToSustainability(analysisHoldersFixture(), Symbol="AAPL");

            testCase.verifyEqual(data.Symbol, "AAPL");
            testCase.verifyEqual(data.TotalEsg, 16.3);
            testCase.verifyEqual(data.EnvironmentScore, 1.2);
            testCase.verifyEqual(data.PeerGroup, "Technology Hardware");
            testCase.verifyTrue(isfield(data, "Raw"));
        end

        function upgradesDowngradesResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToUpgradesDowngrades(analysisHoldersFixture(), Symbol="AAPL");

            testCase.verifyClass(data, "table");
            testCase.verifyEqual(height(data), 2);
            testCase.verifyEqual(data.Firm, ["Example Bank"; "Example Research"]);
            testCase.verifyEqual(data.ToGrade, ["Buy"; "Neutral"]);
            testCase.verifyEqual(data.Action, ["up"; "down"]);
            testCase.verifyClass(data.GradeDate, "datetime");
        end

        function majorHoldersResponseConvertsToMetricTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToMetricTable( ...
                analysisHoldersFixture(), ...
                Symbol="AAPL", ...
                Module="majorHoldersBreakdown");

            testCase.verifyClass(data, "table");
            testCase.verifyEqual(data.Metric, ["insidersPercentHeld"; "institutionsPercentHeld"]);
            testCase.verifyEqual(data.Value{1}, 0.001);
            testCase.verifyEqual(data.Properties.UserData.Symbol, "AAPL");
        end

        function institutionalHolderResponseConvertsToTypedTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToHolderTable( ...
                analysisHoldersFixture(), ...
                Symbol="AAPL", ...
                Module="institutionOwnership", ...
                RecordField="ownershipList");

            testCase.verifyClass(data, "table");
            testCase.verifyEqual(height(data), 1);
            testCase.verifyEqual(data.Organization, "Example Capital");
            testCase.verifyEqual(data.PctHeld, 0.05);
            testCase.verifyClass(data.ReportDate, "datetime");
        end

        function tickerSustainabilityUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=analysisHoldersFixture());
            ticker = yfinance.Ticker(" aapl ", Session=session);

            data = ticker.sustainability();

            testCase.verifyEqual(session.LastQuoteSummarySymbol, "AAPL");
            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "esgScores");
            testCase.verifyEqual(data.TotalEsg, 16.3);
        end

        function tickerUpgradesDowngradesUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=analysisHoldersFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.upgradesDowngrades();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "upgradeDowngradeHistory");
            testCase.verifyEqual(height(data), 2);
        end

        function tickerMajorHoldersUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=analysisHoldersFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.majorHolders();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "majorHoldersBreakdown");
            testCase.verifyEqual(height(data), 2);
        end

        function tickerInstitutionalHoldersUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=analysisHoldersFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.institutionalHolders();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "institutionOwnership");
            testCase.verifyEqual(data.Organization, "Example Capital");
        end

        function tickerMutualFundHoldersUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=analysisHoldersFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.mutualFundHolders();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "fundOwnership");
            testCase.verifyEqual(data.Organization, "Example Index Fund");
        end

        function tickerInsiderTransactionsUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=analysisHoldersFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.insiderTransactions();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "insiderTransactions");
            testCase.verifyEqual(data.FilerName, "Example Officer");
        end

        function tickerInsiderPurchasesUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=analysisHoldersFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.insiderPurchases();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "insiderTransactions");
            testCase.verifyEqual(data.Period, "6m");
        end

        function tickerInsiderRosterHoldersUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=analysisHoldersFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.insiderRosterHolders();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "insiderHolders");
            testCase.verifyEqual(data.Name, "Example Director");
        end
    end
end

function response = analysisHoldersFixture()
esgScores = struct( ...
    "totalEsg", struct("raw", 16.3, "fmt", "16.30"), ...
    "environmentScore", struct("raw", 1.2, "fmt", "1.20"), ...
    "peerGroup", "Technology Hardware");
upgradeDowngradeHistory = struct("history", upgradeDowngradeHistoryFixture());
majorHoldersBreakdown = struct( ...
    "insidersPercentHeld", struct("raw", 0.001, "fmt", "0.10%"), ...
    "institutionsPercentHeld", struct("raw", 0.62, "fmt", "62.00%"));
institutionOwnership = struct("ownershipList", struct( ...
    "organization", "Example Capital", ...
    "pctHeld", struct("raw", 0.05, "fmt", "5.00%"), ...
    "position", struct("raw", 1000000, "fmt", "1M"), ...
    "reportDate", struct("raw", 1704067200, "fmt", "2024-01-01")));
fundOwnership = struct("ownershipList", struct( ...
    "organization", "Example Index Fund", ...
    "pctHeld", struct("raw", 0.03, "fmt", "3.00%"), ...
    "position", struct("raw", 600000, "fmt", "600k"), ...
    "reportDate", struct("raw", 1704067200, "fmt", "2024-01-01")));
insiderTransactions = struct( ...
    "transactions", struct( ...
        "filerName", "Example Officer", ...
        "transactionText", "Sale", ...
        "shares", struct("raw", 1000, "fmt", "1,000"), ...
        "value", struct("raw", 200000, "fmt", "200k"), ...
        "startDate", struct("raw", 1704153600, "fmt", "2024-01-02")), ...
    "purchases", struct( ...
        "period", "6m", ...
        "buyInfoShares", struct("raw", 2000, "fmt", "2,000"), ...
        "sellInfoShares", struct("raw", 1000, "fmt", "1,000")));
insiderHolders = struct("holders", struct( ...
    "name", "Example Director", ...
    "relation", "Director", ...
    "positionDirect", struct("raw", 12000, "fmt", "12,000"), ...
    "latestTransDate", struct("raw", 1704240000, "fmt", "2024-01-03")));
result = struct( ...
    "esgScores", esgScores, ...
    "upgradeDowngradeHistory", upgradeDowngradeHistory, ...
    "majorHoldersBreakdown", majorHoldersBreakdown, ...
    "institutionOwnership", institutionOwnership, ...
    "fundOwnership", fundOwnership, ...
    "insiderTransactions", insiderTransactions, ...
    "insiderHolders", insiderHolders);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function history = upgradeDowngradeHistoryFixture()
history(1) = struct( ...
    "epochGradeDate", 1704067200, ...
    "firm", "Example Bank", ...
    "toGrade", "Buy", ...
    "fromGrade", "Neutral", ...
    "action", "up");
history(2) = struct( ...
    "epochGradeDate", 1704153600, ...
    "firm", "Example Research", ...
    "toGrade", "Neutral", ...
    "fromGrade", "Buy", ...
    "action", "down");
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
