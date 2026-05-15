classdef TestEstimatesAndEarnings < matlab.unittest.TestCase
    %TESTESTIMATESANDEARNINGS Verify earnings and estimate APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function earningsEstimateResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToEarningsTrendTable( ...
                estimatesFixture(), ...
                Symbol="AAPL", ...
                Key="earningsEstimate", ...
                CurrencyKey="earningsCurrency");

            testCase.verifyEqual(height(data), 4);
            testCase.verifyEqual(data.Period(1:2), ["0q"; "+1q"]);
            testCase.verifyEqual(data.NumberOfAnalysts(1:2), [32; 31]);
            testCase.verifyEqual(data.Avg(1:2), [2.1; 2.4]);
            testCase.verifyEqual(data.YearAgoEps(1:2), [1.9; 2.0]);
            testCase.verifyEqual(data.Currency(1:2), ["USD"; "USD"]);
        end

        function revenueEstimateResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToEarningsTrendTable( ...
                estimatesFixture(), ...
                Symbol="AAPL", ...
                Key="revenueEstimate", ...
                CurrencyKey="revenueCurrency");

            testCase.verifyEqual(height(data), 4);
            testCase.verifyEqual(data.Period(1:2), ["0q"; "+1q"]);
            testCase.verifyEqual(data.Avg(1:2), [90000000000; 96000000000]);
            testCase.verifyEqual(data.YearAgoRevenue(1:2), [83000000000; 88000000000]);
            testCase.verifyEqual(data.Currency(1:2), ["USD"; "USD"]);
        end

        function epsTrendResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToEarningsTrendTable( ...
                estimatesFixture(), ...
                Symbol="AAPL", ...
                Key="epsTrend");

            testCase.verifyEqual(data.Current(1:2), [2.1; 2.4]);
            testCase.verifyEqual(data.X7daysAgo(1:2), [2.0; 2.3]);
            testCase.verifyEqual(data.X90daysAgo(1:2), [1.8; 2.1]);
        end

        function epsRevisionsResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToEarningsTrendTable( ...
                estimatesFixture(), ...
                Symbol="AAPL", ...
                Key="epsRevisions");

            testCase.verifyEqual(data.UpLast7days(1:2), [3; 2]);
            testCase.verifyEqual(data.DownLast30days(1:2), [1; 0]);
        end

        function earningsHistoryResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToEarningsHistory(estimatesFixture(), Symbol="AAPL");

            testCase.verifyEqual(height(data), 2);
            testCase.verifyEqual(data.Quarter(1), datetime("2024-03-31", TimeZone="UTC"));
            testCase.verifyEqual(data.EpsActual, [2.2; 2.45]);
            testCase.verifyEqual(data.SurprisePercent, [0.0476; 0.0208]);
        end

        function growthEstimatesResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToGrowthEstimates(estimatesFixture(), Symbol="AAPL");

            testCase.verifyEqual(data.Period, ["0q"; "+1q"; "0y"; "+1y"; "+5y"]);
            testCase.verifyEqual(data.Stock, [0.07; 0.09; 0.11; 0.13; 0.15]);
            testCase.verifyEqual(data.Industry, [0.05; 0.06; 0.07; 0.08; 0.1]);
            testCase.verifyEqual(data.Sector, [0.04; 0.05; 0.06; 0.07; 0.08]);
            testCase.verifyEqual(data.Index, [0.03; 0.04; 0.05; 0.055; 0.06]);
        end

        function earningsResponseConvertsToYearlyTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToEarnings(estimatesFixture(), Symbol="AAPL");

            testCase.verifyEqual(data.Period, ["2023"; "2024"]);
            testCase.verifyEqual(data.Revenue, [383000000000; 391000000000]);
            testCase.verifyEqual(data.Earnings, [97000000000; 102000000000]);
            testCase.verifyEqual(data.Properties.UserData.Currency, "USD");
        end

        function earningsResponseConvertsToQuarterlyTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToEarnings( ...
                estimatesFixture(), ...
                Symbol="AAPL", ...
                Quarterly=true);

            testCase.verifyEqual(data.Period, ["1Q2024"; "2Q2024"]);
            testCase.verifyEqual(data.Revenue, [91000000000; 94000000000]);
            testCase.verifyEqual(data.Properties.UserData.Frequency, "quarterly");
        end

        function tickerEstimateMethodsUseQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=estimatesFixture());
            ticker = yfinance.Ticker(" aapl ", Session=session);

            data = ticker.earningsEstimate();

            testCase.verifyEqual(session.LastQuoteSummarySymbol, "AAPL");
            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "earningsTrend");
            testCase.verifyEqual(data.NumberOfAnalysts(1:2), [32; 31]);
        end

        function tickerGrowthEstimatesUseQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=estimatesFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.growthEstimates();

            testCase.verifyEqual( ...
                session.LastQuoteSummaryRequest.Modules, ...
                ["earningsTrend", "industryTrend", "sectorTrend", "indexTrend"]);
            testCase.verifyEqual(data.Stock(5), 0.15);
        end

        function tickerEarningsHistoryUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=estimatesFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.earningsHistory();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "earningsHistory");
            testCase.verifyEqual(data.EpsEstimate, [2.1; 2.4]);
        end

        function tickerEarningsUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=estimatesFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.earnings(Quarterly=true);

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "earnings");
            testCase.verifyEqual(data.Period, ["1Q2024"; "2Q2024"]);
        end

        function recommendationsSummaryUsesRecommendationTrend(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=recommendationsFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.recommendationsSummary();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, "recommendationTrend");
            testCase.verifyEqual(data.StrongBuy, 10);
        end

        function emptyEarningsTrendReturnsEmptyTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToEarningsTrendTable( ...
                emptyTrendFixture(), ...
                Symbol="AAPL", ...
                Key="earningsEstimate");

            testCase.verifyEqual(height(data), 0);
            testCase.verifyEqual(data.Properties.VariableNames, {'Period'});
        end
    end
end

function response = estimatesFixture()
result = struct( ...
    "earningsTrend", struct("trend", earningsTrendFixture()), ...
    "earningsHistory", struct("history", earningsHistoryFixture()), ...
    "industryTrend", struct("estimates", peerTrendFixture([0.05, 0.06, 0.07, 0.08, 0.1])), ...
    "sectorTrend", struct("estimates", peerTrendFixture([0.04, 0.05, 0.06, 0.07, 0.08])), ...
    "indexTrend", struct("estimates", peerTrendFixture([0.03, 0.04, 0.05, 0.055, 0.06])), ...
    "earnings", earningsFixture());
response = struct("quoteSummary", struct("result", result, "error", []));
end

function trend = earningsTrendFixture()
trend(1) = trendItem("0q", 32, 2.1, 1.9, 0.07, 90000000000, 83000000000, 3, 1);
trend(2) = trendItem("+1q", 31, 2.4, 2.0, 0.09, 96000000000, 88000000000, 2, 0);
trend(3) = trendItem("0y", 35, 8.4, 7.8, 0.11, 370000000000, 340000000000, 4, 1);
trend(4) = trendItem("+1y", 34, 9.0, 8.4, 0.13, 395000000000, 370000000000, 3, 0);
trend(5) = trendItem("+5y", 20, 12.0, 10.5, 0.15, 500000000000, 430000000000, 1, 0);
end

function item = trendItem(period, analysts, eps, yearAgoEps, growth, revenue, yearAgoRevenue, upLast7days, downLast30days)
item = struct( ...
    "period", period, ...
    "earningsEstimate", struct( ...
        "numberOfAnalysts", struct("raw", analysts, "fmt", string(analysts)), ...
        "avg", struct("raw", eps, "fmt", string(eps)), ...
        "low", struct("raw", eps - 0.2, "fmt", string(eps - 0.2)), ...
        "high", struct("raw", eps + 0.2, "fmt", string(eps + 0.2)), ...
        "yearAgoEps", struct("raw", yearAgoEps, "fmt", string(yearAgoEps)), ...
        "growth", struct("raw", growth, "fmt", string(growth)), ...
        "earningsCurrency", "USD"), ...
    "revenueEstimate", struct( ...
        "numberOfAnalysts", struct("raw", analysts, "fmt", string(analysts)), ...
        "avg", struct("raw", revenue, "fmt", string(revenue)), ...
        "low", struct("raw", revenue - 1000000000, "fmt", string(revenue - 1000000000)), ...
        "high", struct("raw", revenue + 1000000000, "fmt", string(revenue + 1000000000)), ...
        "yearAgoRevenue", struct("raw", yearAgoRevenue, "fmt", string(yearAgoRevenue)), ...
        "growth", struct("raw", growth, "fmt", string(growth)), ...
        "revenueCurrency", "USD"), ...
    "epsTrend", struct( ...
        "current", struct("raw", eps, "fmt", string(eps)), ...
        "x7daysAgo", struct("raw", eps - 0.1, "fmt", string(eps - 0.1)), ...
        "x30daysAgo", struct("raw", eps - 0.2, "fmt", string(eps - 0.2)), ...
        "x60daysAgo", struct("raw", eps - 0.25, "fmt", string(eps - 0.25)), ...
        "x90daysAgo", struct("raw", eps - 0.3, "fmt", string(eps - 0.3))), ...
    "epsRevisions", struct( ...
        "upLast7days", struct("raw", upLast7days, "fmt", string(upLast7days)), ...
        "upLast30days", struct("raw", upLast7days + 1, "fmt", string(upLast7days + 1)), ...
        "downLast7days", struct("raw", 0, "fmt", "0"), ...
        "downLast30days", struct("raw", downLast30days, "fmt", string(downLast30days))), ...
    "growth", struct("raw", growth, "fmt", string(growth)));
end

function history = earningsHistoryFixture()
history(1) = struct( ...
    "quarter", struct("fmt", "2024-03-31"), ...
    "epsEstimate", struct("raw", 2.1, "fmt", "2.10"), ...
    "epsActual", struct("raw", 2.2, "fmt", "2.20"), ...
    "epsDifference", struct("raw", 0.1, "fmt", "0.10"), ...
    "surprisePercent", struct("raw", 0.0476, "fmt", "4.76%"));
history(2) = struct( ...
    "quarter", struct("fmt", "2024-06-30"), ...
    "epsEstimate", struct("raw", 2.4, "fmt", "2.40"), ...
    "epsActual", struct("raw", 2.45, "fmt", "2.45"), ...
    "epsDifference", struct("raw", 0.05, "fmt", "0.05"), ...
    "surprisePercent", struct("raw", 0.0208, "fmt", "2.08%"));
end

function estimates = peerTrendFixture(values)
periods = ["0q", "+1q", "0y", "+1y", "+5y"];
estimates(1) = struct("period", periods(1), "growth", struct("raw", values(1), "fmt", string(values(1))));
estimates(2) = struct("period", periods(2), "growth", struct("raw", values(2), "fmt", string(values(2))));
estimates(3) = struct("period", periods(3), "growth", struct("raw", values(3), "fmt", string(values(3))));
estimates(4) = struct("period", periods(4), "growth", struct("raw", values(4), "fmt", string(values(4))));
estimates(5) = struct("period", periods(5), "growth", struct("raw", values(5), "fmt", string(values(5))));
end

function earnings = earningsFixture()
yearly(1) = struct( ...
    "date", 2023, ...
    "revenue", struct("raw", 383000000000, "fmt", "383B"), ...
    "earnings", struct("raw", 97000000000, "fmt", "97B"));
yearly(2) = struct( ...
    "date", 2024, ...
    "revenue", struct("raw", 391000000000, "fmt", "391B"), ...
    "earnings", struct("raw", 102000000000, "fmt", "102B"));
quarterly(1) = struct( ...
    "date", "1Q2024", ...
    "revenue", struct("raw", 91000000000, "fmt", "91B"), ...
    "earnings", struct("raw", 24000000000, "fmt", "24B"));
quarterly(2) = struct( ...
    "date", "2Q2024", ...
    "revenue", struct("raw", 94000000000, "fmt", "94B"), ...
    "earnings", struct("raw", 25000000000, "fmt", "25B"));
earnings = struct( ...
    "financialCurrency", "USD", ...
    "financialsChart", struct("yearly", yearly, "quarterly", quarterly));
end

function response = recommendationsFixture()
trend = struct("period", "0m", "strongBuy", 10, "buy", 20, "hold", 5, "sell", 1, "strongSell", 0);
result = struct("recommendationTrend", struct("trend", trend));
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = emptyTrendFixture()
result = struct("earningsTrend", struct("trend", []));
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
