classdef TestValuation < matlab.unittest.TestCase
    %TESTVALUATION Verify valuation quoteSummary APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function valuationResponseConvertsToTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToValuation(valuationFixture(), Symbol="AAPL");

            testCase.verifyClass(data, "table");
            testCase.verifyEqual(data.Metric(1:8), [ ...
                "MarketCap"; ...
                "RegularMarketPrice"; ...
                "Beta"; ...
                "TrailingPE"; ...
                "ForwardPE"; ...
                "PriceToSalesTrailing12Months"; ...
                "EnterpriseValue"; ...
                "PegRatio"]);
            testCase.verifyEqual(data.Field(1), "marketCap");
            testCase.verifyEqual(data.Value(1:8), [3000000000000; 200; 1.25; 30; 25; 7.1; 3200000000000; 2.4]);
            testCase.verifyEqual(data.Formatted(1), "3T");
            testCase.verifyEqual(data.Module(1), "price");
            testCase.verifyEqual(data.Properties.UserData.Symbol, "AAPL");
            testCase.verifyEqual(data.Properties.UserData.Module, "valuation");
        end

        function duplicateFieldsUseFirstConfiguredModule(testCase)
            data = yfinance.internal.quoteSummaryResponseToValuation(valuationFixture(), Symbol="AAPL");

            marketCapRows = data(data.Field == "marketCap", :);

            testCase.verifyEqual(height(marketCapRows), 1);
            testCase.verifyEqual(marketCapRows.Module, "price");
            testCase.verifyEqual(marketCapRows.Value, 3000000000000);
        end

        function emptyValuationResponseReturnsEmptyTable(testCase)
            data = yfinance.internal.quoteSummaryResponseToValuation(emptyValuationFixture(), Symbol="AAPL");

            testCase.verifyEqual(height(data), 0);
            testCase.verifyEqual(data.Properties.VariableNames, {'Metric', 'Field', 'Value', 'Formatted', 'Module'});
            testCase.verifyEqual(data.Properties.UserData.Symbol, "AAPL");
        end

        function tickerValuationUsesQuoteSummarySession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=valuationFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.valuation();

            testCase.verifyEqual(session.LastQuoteSummarySymbol, "AAPL");
            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, ...
                ["price", "summaryDetail", "defaultKeyStatistics", "financialData"]);
            testCase.verifyEqual(data.Value(data.Field == "enterpriseValue"), 3200000000000);
        end

        function tickerValuationMeasuresAliasesValuation(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteSummaryResponse=valuationFixture());
            ticker = yfinance.Ticker("AAPL", Session=session);

            data = ticker.valuationMeasures();

            testCase.verifyEqual(session.LastQuoteSummaryRequest.Modules, ...
                ["price", "summaryDetail", "defaultKeyStatistics", "financialData"]);
            testCase.verifyEqual(data.Value(data.Field == "trailingPE"), 30);
        end
    end
end

function response = valuationFixture()
price = struct( ...
    "marketCap", formattedValue(3000000000000, "3T"), ...
    "regularMarketPrice", formattedValue(200, "200.00"));
summaryDetail = struct( ...
    "marketCap", formattedValue(2900000000000, "2.9T"), ...
    "beta", formattedValue(1.25, "1.25"), ...
    "trailingPE", formattedValue(30, "30.00"), ...
    "forwardPE", formattedValue(25, "25.00"), ...
    "priceToSalesTrailing12Months", formattedValue(7.1, "7.10"));
defaultKeyStatistics = struct( ...
    "enterpriseValue", formattedValue(3200000000000, "3.2T"), ...
    "pegRatio", formattedValue(2.4, "2.40"), ...
    "priceToBook", formattedValue(45, "45.00"), ...
    "enterpriseToRevenue", formattedValue(8.2, "8.20"), ...
    "enterpriseToEbitda", formattedValue(22, "22.00"));
financialData = struct( ...
    "currentPrice", formattedValue(201, "201.00"), ...
    "profitMargins", formattedValue(0.24, "24.00%"), ...
    "grossMargins", formattedValue(0.46, "46.00%"), ...
    "ebitdaMargins", formattedValue(0.33, "33.00%"), ...
    "operatingMargins", formattedValue(0.31, "31.00%"), ...
    "ebitda", formattedValue(130000000000, "130B"));
result = struct( ...
    "price", price, ...
    "summaryDetail", summaryDetail, ...
    "defaultKeyStatistics", defaultKeyStatistics, ...
    "financialData", financialData);
response = struct("quoteSummary", struct("result", result, "error", []));
end

function response = emptyValuationFixture()
response = struct("quoteSummary", struct("result", struct(), "error", []));
end

function value = formattedValue(rawValue, formattedText)
value = struct("raw", rawValue, "fmt", formattedText);
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
