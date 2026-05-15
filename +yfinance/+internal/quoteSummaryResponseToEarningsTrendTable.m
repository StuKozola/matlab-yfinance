function data = quoteSummaryResponseToEarningsTrendTable(response, options)
%QUOTESUMMARYRESPONSETOEARNINGSTRENDTABLE Convert earningsTrend metrics to a table.

arguments
    response struct
    options.Symbol (1,1) string = ""
    options.Key (1,1) string
    options.CurrencyKey (1,1) string = ""
    options.MaxRows (1,1) double {mustBeNonnegative, mustBeInteger} = 4
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
moduleName = "earningsTrend." + options.Key;

if ~isfield(result, "earningsTrend") || isempty(result.earningsTrend) || ...
        ~isfield(result.earningsTrend, "trend") || isempty(result.earningsTrend.trend)
    data = emptyTrendTable(options.Symbol, moduleName);
    return
end

trend = normalizeTrend(result.earningsTrend.trend, options.MaxRows);
records = recordsFromTrend(trend, options.Key, options.CurrencyKey);

if isempty(records)
    data = emptyTrendTable(options.Symbol, moduleName);
    return
end

data = yfinance.internal.yahooStructArrayToTable( ...
    records, ...
    Symbol=options.Symbol, ...
    Module=moduleName);
end

function trend = normalizeTrend(trend, maxRows)
if iscell(trend)
    trend = [trend{:}];
end

trend = trend(:);

if maxRows > 0
    trend = trend(1:min(maxRows, numel(trend)));
end
end

function records = recordsFromTrend(trend, key, currencyKey)
fieldNames = trendFieldNames(trend, key, currencyKey);

if isempty(fieldNames)
    records = struct.empty(0, 1);
    return
end

emptyRecord = emptyRecordForFields(["period"; fieldNames]);
records = repmat(emptyRecord, numel(trend), 1);

for rowIndex = 1:numel(trend)
    item = trend(rowIndex);
    records(rowIndex).period = stringField(item, "period");

    if ~isfield(item, key) || isempty(item.(key))
        continue
    end

    values = yfinance.internal.unwrapYahooValue(item.(key));

    for fieldIndex = 1:numel(fieldNames)
        sourceName = fieldNames(fieldIndex);
        recordFieldName = trendRecordFieldName(sourceName, currencyKey);

        if isfield(values, sourceName) && ~isempty(values.(sourceName))
            records(rowIndex).(recordFieldName) = values.(sourceName);
        end
    end
end
end

function fieldNames = trendFieldNames(trend, key, currencyKey)
fieldNames = strings(0, 1);

for rowIndex = 1:numel(trend)
    item = trend(rowIndex);

    if ~isfield(item, key) || isempty(item.(key))
        continue
    end

    values = yfinance.internal.unwrapYahooValue(item.(key));
    fieldNames = [fieldNames; string(fieldnames(values))]; %#ok<AGROW>
end

fieldNames = unique(fieldNames, "stable");
fieldNames(fieldNames == "maxAge") = [];

if currencyKey ~= ""
    fieldNames = [fieldNames(fieldNames ~= currencyKey); fieldNames(fieldNames == currencyKey)];
end
end

function record = emptyRecordForFields(fieldNames)
record = struct();

for fieldIndex = 1:numel(fieldNames)
    record.(trendRecordFieldName(fieldNames(fieldIndex), "")) = [];
end
end

function fieldName = trendRecordFieldName(sourceName, currencyKey)
if currencyKey ~= "" && sourceName == currencyKey
    fieldName = "currency";
else
    fieldName = matlab.lang.makeValidName(sourceName);
end
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(yfinance.internal.unwrapYahooValue(inputStruct.(fieldName)));
else
    value = missing;
end
end

function data = emptyTrendTable(symbol, moduleName)
data = table(strings(0, 1), VariableNames={'Period'});
data.Properties.UserData = struct("Symbol", symbol, "Module", moduleName);
end
