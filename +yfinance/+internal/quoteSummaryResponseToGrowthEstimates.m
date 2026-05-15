function data = quoteSummaryResponseToGrowthEstimates(response, options)
%QUOTESUMMARYRESPONSETOGROWTHESTIMATES Convert growth estimate trends.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
period = strings(0, 1);
stock = NaN(0, 1);
industry = NaN(0, 1);
sector = NaN(0, 1);
index = NaN(0, 1);

[period, stock, industry, sector, index] = addStockGrowth(result, period, stock, industry, sector, index);
[period, stock, industry, sector, index] = addPeerGrowth(result, "industryTrend", period, stock, industry, sector, index);
[period, stock, industry, sector, index] = addPeerGrowth(result, "sectorTrend", period, stock, industry, sector, index);
[period, stock, industry, sector, index] = addPeerGrowth(result, "indexTrend", period, stock, industry, sector, index);

data = table(period, stock, industry, sector, index, VariableNames={ ...
    'Period', ...
    'Stock', ...
    'Industry', ...
    'Sector', ...
    'Index'});
data.Properties.UserData = struct("Symbol", options.Symbol, "Module", "growthEstimates");
end

function [period, stock, industry, sector, index] = addStockGrowth(result, period, stock, industry, sector, index)
if ~isfield(result, "earningsTrend") || isempty(result.earningsTrend) || ...
        ~isfield(result.earningsTrend, "trend") || isempty(result.earningsTrend.trend)
    return
end

trend = normalizeRecords(result.earningsTrend.trend);

for trendIndex = 1:numel(trend)
    item = trend(trendIndex);

    if ~isfield(item, "period") || isempty(item.period)
        continue
    end

    periodValue = string(item.period);
    rowIndex = findOrAppendPeriod(periodValue, period);
    [period, stock, industry, sector, index] = ensureRow(rowIndex, period, stock, industry, sector, index);
    period(rowIndex) = periodValue;
    stock(rowIndex) = growthField(item);
end
end

function [period, stock, industry, sector, index] = addPeerGrowth( ...
        result, moduleName, period, stock, industry, sector, index)
if ~isfield(result, moduleName) || isempty(result.(moduleName)) || ...
        ~isfield(result.(moduleName), "estimates") || isempty(result.(moduleName).estimates)
    return
end

estimates = normalizeRecords(result.(moduleName).estimates);

for estimateIndex = 1:numel(estimates)
    estimate = estimates(estimateIndex);

    if ~isfield(estimate, "period") || isempty(estimate.period)
        continue
    end

    periodValue = string(estimate.period);
    rowIndex = findOrAppendPeriod(periodValue, period);
    [period, stock, industry, sector, index] = ensureRow(rowIndex, period, stock, industry, sector, index);
    period(rowIndex) = periodValue;
    value = growthField(estimate);

    if moduleName == "industryTrend"
        industry(rowIndex) = value;
    elseif moduleName == "sectorTrend"
        sector(rowIndex) = value;
    else
        index(rowIndex) = value;
    end
end
end

function records = normalizeRecords(records)
if iscell(records)
    records = [records{:}];
end

records = records(:);
end

function rowIndex = findOrAppendPeriod(value, period)
rowIndex = find(period == value, 1);

if isempty(rowIndex)
    rowIndex = numel(period) + 1;
end
end

function [period, stock, industry, sector, index] = ensureRow(rowIndex, period, stock, industry, sector, index)
if rowIndex <= numel(period)
    return
end

period(rowIndex, 1) = missing;
stock(rowIndex, 1) = NaN;
industry(rowIndex, 1) = NaN;
sector(rowIndex, 1) = NaN;
index(rowIndex, 1) = NaN;
end

function value = growthField(inputStruct)
value = NaN;

if isfield(inputStruct, "growth") && ~isempty(inputStruct.growth)
    rawValue = yfinance.internal.unwrapYahooValue(inputStruct.growth);

    if isnumeric(rawValue) && ~isempty(rawValue)
        value = double(rawValue);
    end
end
end
