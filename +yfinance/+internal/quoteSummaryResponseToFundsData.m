function data = quoteSummaryResponseToFundsData(response, options)
%QUOTESUMMARYRESPONSETOFUNDSDATA Convert Yahoo fund quoteSummary modules.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
quoteType = moduleOrEmpty(result, "quoteType");
summaryProfile = moduleOrEmpty(result, "summaryProfile");
fundProfile = moduleOrEmpty(result, "fundProfile");
topHoldings = moduleOrEmpty(result, "topHoldings");

data = struct( ...
    "Symbol", options.Symbol, ...
    "QuoteType", stringField(quoteType, "quoteType"), ...
    "Description", stringField(summaryProfile, "longBusinessSummary"), ...
    "FundOverview", fundOverview(fundProfile), ...
    "FundOperations", fundOperationsTable(fundProfile, options.Symbol), ...
    "AssetClasses", assetClasses(topHoldings), ...
    "TopHoldings", topHoldingsTable(fieldOrEmpty(topHoldings, "holdings")), ...
    "EquityHoldings", equityHoldingsTable(fieldOrEmpty(topHoldings, "equityHoldings")), ...
    "BondHoldings", bondHoldingsTable(fieldOrEmpty(topHoldings, "bondHoldings")), ...
    "BondRatings", weightingsTable(fieldOrEmpty(topHoldings, "bondRatings")), ...
    "SectorWeightings", weightingsTable(fieldOrEmpty(topHoldings, "sectorWeightings")), ...
    "Raw", result);
end

function value = moduleOrEmpty(result, moduleName)
if isfield(result, moduleName) && ~isempty(result.(moduleName))
    value = result.(moduleName);
else
    value = struct();
end
end

function value = fundOverview(fundProfile)
value = struct( ...
    "CategoryName", stringField(fundProfile, "categoryName"), ...
    "Family", stringField(fundProfile, "family"), ...
    "LegalType", stringField(fundProfile, "legalType"));
end

function data = fundOperationsTable(fundProfile, symbol)
operations = fieldOrEmpty(fundProfile, "feesExpensesInvestment");
categoryOperations = fieldOrEmpty(fundProfile, "feesExpensesInvestmentCat");
attributes = [ ...
    "Annual Report Expense Ratio"; ...
    "Annual Holdings Turnover"; ...
    "Total Net Assets"];
values = [ ...
    rawField(operations, "annualReportExpenseRatio"); ...
    rawField(operations, "annualHoldingsTurnover"); ...
    rawField(operations, "totalNetAssets")];
categoryAverages = [ ...
    rawField(categoryOperations, "annualReportExpenseRatio"); ...
    rawField(categoryOperations, "annualHoldingsTurnover"); ...
    rawField(categoryOperations, "totalNetAssets")];
data = table(attributes, values, categoryAverages, VariableNames=["Attribute", "Value", "CategoryAverage"]);
data.Properties.UserData = struct("Symbol", symbol);
end

function value = assetClasses(topHoldings)
value = struct( ...
    "CashPosition", rawField(topHoldings, "cashPosition"), ...
    "StockPosition", rawField(topHoldings, "stockPosition"), ...
    "BondPosition", rawField(topHoldings, "bondPosition"), ...
    "PreferredPosition", rawField(topHoldings, "preferredPosition"), ...
    "ConvertiblePosition", rawField(topHoldings, "convertiblePosition"), ...
    "OtherPosition", rawField(topHoldings, "otherPosition"));
end

function data = topHoldingsTable(records)
records = normalizeRecords(records);
symbols = strings(numel(records), 1);
names = strings(numel(records), 1);
holdingPercents = NaN(numel(records), 1);

for recordIndex = 1:numel(records)
    symbols(recordIndex) = stringField(records(recordIndex), "symbol");
    names(recordIndex) = firstStringField(records(recordIndex), ["holdingName", "name"]);
    holdingPercents(recordIndex) = rawField(records(recordIndex), "holdingPercent");
end

data = table(symbols, names, holdingPercents, VariableNames=["Symbol", "Name", "HoldingPercent"]);
end

function data = equityHoldingsTable(equityHoldings)
metrics = [ ...
    "Price/Earnings"; ...
    "Price/Book"; ...
    "Price/Sales"; ...
    "Price/Cashflow"; ...
    "Median Market Cap"; ...
    "3 Year Earnings Growth"];
values = [ ...
    rawField(equityHoldings, "priceToEarnings"); ...
    rawField(equityHoldings, "priceToBook"); ...
    rawField(equityHoldings, "priceToSales"); ...
    rawField(equityHoldings, "priceToCashflow"); ...
    rawField(equityHoldings, "medianMarketCap"); ...
    rawField(equityHoldings, "threeYearEarningsGrowth")];
categoryAverages = [ ...
    rawField(equityHoldings, "priceToEarningsCat"); ...
    rawField(equityHoldings, "priceToBookCat"); ...
    rawField(equityHoldings, "priceToSalesCat"); ...
    rawField(equityHoldings, "priceToCashflowCat"); ...
    rawField(equityHoldings, "medianMarketCapCat"); ...
    rawField(equityHoldings, "threeYearEarningsGrowthCat")];
data = table(metrics, values, categoryAverages, VariableNames=["Metric", "Value", "CategoryAverage"]);
end

function data = bondHoldingsTable(bondHoldings)
metrics = [ ...
    "Duration"; ...
    "Maturity"; ...
    "Credit Quality"];
values = [ ...
    rawField(bondHoldings, "duration"); ...
    rawField(bondHoldings, "maturity"); ...
    rawField(bondHoldings, "creditQuality")];
categoryAverages = [ ...
    rawField(bondHoldings, "durationCat"); ...
    rawField(bondHoldings, "maturityCat"); ...
    rawField(bondHoldings, "creditQualityCat")];
data = table(metrics, values, categoryAverages, VariableNames=["Metric", "Value", "CategoryAverage"]);
end

function data = weightingsTable(records)
records = normalizeRecords(records);
categories = strings(0, 1);
weights = zeros(0, 1);

for recordIndex = 1:numel(records)
    names = string(fieldnames(records(recordIndex)));

    for fieldIndex = 1:numel(names)
        rawValue = records(recordIndex).(names(fieldIndex));

        if isempty(rawValue)
            continue
        end

        categories(end + 1, 1) = names(fieldIndex); %#ok<AGROW>
        weights(end + 1, 1) = double(yfinance.internal.unwrapYahooValue(rawValue)); %#ok<AGROW>
    end
end

data = table(categories, weights, VariableNames=["Category", "Weight"]);
end

function records = normalizeRecords(records)
if iscell(records)
    if isempty(records)
        records = struct.empty(0, 1);
    else
        records = normalizeRecordCells(records);
    end
end

records = records(:);
end

function records = normalizeRecordCells(recordCells)
recordCells = recordCells(:);
fieldNames = strings(0, 1);

for recordIndex = 1:numel(recordCells)
    fieldNames = [fieldNames; string(fieldnames(recordCells{recordIndex}))]; %#ok<AGROW>
end

fieldNames = unique(fieldNames, "stable");
template = cell2struct(cell(numel(fieldNames), 1), cellstr(fieldNames), 1);
records = repmat(template, numel(recordCells), 1);

for recordIndex = 1:numel(recordCells)
    record = recordCells{recordIndex};
    names = fieldnames(record);

    for fieldIndex = 1:numel(names)
        records(recordIndex).(names{fieldIndex}) = record.(names{fieldIndex});
    end
end
end

function value = fieldOrEmpty(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = inputStruct.(fieldName);
else
    value = struct.empty(0, 1);
end
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(inputStruct.(fieldName));
else
    value = "";
end
end

function value = firstStringField(inputStruct, fieldNames)
value = "";

for fieldIndex = 1:numel(fieldNames)
    value = stringField(inputStruct, fieldNames(fieldIndex));

    if value ~= ""
        return
    end
end
end

function value = rawField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = yfinance.internal.unwrapYahooValue(inputStruct.(fieldName));
else
    value = NaN;
end
end
