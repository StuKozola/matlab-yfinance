% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

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
trend = normalizeTrend(trend);

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

function records = normalizeTrend(records)
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
    if isstruct(recordCells{recordIndex})
        fieldNames = [fieldNames; string(fieldnames(recordCells{recordIndex}))]; %#ok<AGROW>
    end
end

fieldNames = unique(fieldNames, "stable");
template = cell2struct(cell(numel(fieldNames), 1), cellstr(fieldNames), 1);
records = repmat(template, numel(recordCells), 1);

for recordIndex = 1:numel(recordCells)
    record = recordCells{recordIndex};

    if ~isstruct(record)
        continue
    end

    names = fieldnames(record);

    for fieldIndex = 1:numel(names)
        records(recordIndex).(names{fieldIndex}) = record.(names{fieldIndex});
    end
end
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
    value = yfinance.internal.unwrapYahooValue(inputStruct.(fieldName));

    if isnumeric(value) || islogical(value)
        value = double(value);
    else
        value = str2double(string(value));
    end
else
    value = NaN;
end
end
