function data = quoteSummaryResponseToRecommendations(response, options)
%QUOTESUMMARYRESPONSETORECOMMENDATIONS Convert recommendation trend data to a table.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);

if ~isfield(result, "recommendationTrend") || isempty(result.recommendationTrend) || ...
        ~isfield(result.recommendationTrend, "trend") || isempty(result.recommendationTrend.trend)
    data = emptyRecommendationsTable();
    return
end

trend = result.recommendationTrend.trend;

if iscell(trend)
    trend = [trend{:}];
end

rowCount = numel(trend);
period = strings(rowCount, 1);
strongBuy = NaN(rowCount, 1);
buy = NaN(rowCount, 1);
hold = NaN(rowCount, 1);
sell = NaN(rowCount, 1);
strongSell = NaN(rowCount, 1);

for rowIndex = 1:rowCount
    item = trend(rowIndex);
    period(rowIndex) = stringField(item, "period");
    strongBuy(rowIndex) = numericField(item, "strongBuy");
    buy(rowIndex) = numericField(item, "buy");
    hold(rowIndex) = numericField(item, "hold");
    sell(rowIndex) = numericField(item, "sell");
    strongSell(rowIndex) = numericField(item, "strongSell");
end

data = table(period, strongBuy, buy, hold, sell, strongSell, VariableNames={ ...
    'Period', ...
    'StrongBuy', ...
    'Buy', ...
    'Hold', ...
    'Sell', ...
    'StrongSell'});
end

function data = emptyRecommendationsTable()
data = table( ...
    strings(0, 1), ...
    NaN(0, 1), ...
    NaN(0, 1), ...
    NaN(0, 1), ...
    NaN(0, 1), ...
    NaN(0, 1), ...
    VariableNames={'Period', 'StrongBuy', 'Buy', 'Hold', 'Sell', 'StrongSell'});
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(inputStruct.(fieldName));
else
    value = missing;
end
end

function value = numericField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = double(inputStruct.(fieldName));
else
    value = NaN;
end
end
