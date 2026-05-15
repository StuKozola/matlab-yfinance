function data = fundamentalsTimeSeriesResponseToFinancialStatement(response, options)
%FUNDAMENTALSTIMESERIESRESPONSETOFINANCIALSTATEMENT Convert Yahoo TTM statements.

arguments
    response struct
    options.Symbol (1,1) string = ""
    options.StatementType (1,1) string = ""
    options.Frequency (1,1) string = "trailing"
    options.Types (1,:) string = strings(0, 1)
end

if ~isfield(response, "timeseries") || isempty(response.timeseries)
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a timeseries payload.");
end

timeseries = response.timeseries;

if isfield(timeseries, "error") && ~isempty(timeseries.error)
    error("yfinance:YahooError", "Yahoo Finance returned a timeseries error for %s.", options.Symbol);
end

if ~isfield(timeseries, "result") || isempty(timeseries.result)
    data = emptyStatementTable(options);
    return
end

metrics = metricSeries(timeseries.result, options.Frequency, options.Types);

if isempty(metrics)
    data = emptyStatementTable(options);
    return
end

data = statementTable(metrics);
data.Properties.UserData = struct( ...
    "Symbol", options.Symbol, ...
    "Source", "fundamentals-timeseries", ...
    "StatementType", options.StatementType, ...
    "Frequency", options.Frequency);
end

function metrics = metricSeries(result, frequency, requestedTypes)
resultItems = normalizeResultItems(result);
fieldNamesByItem = cell(numel(resultItems), 1);
metricCapacity = 0;

for resultIndex = 1:numel(resultItems)
    item = resultItems{resultIndex};
    fieldNames = string(fieldnames(item));
    fieldNames(ismember(fieldNames, ["meta", "timestamp"])) = [];
    fieldNamesByItem{resultIndex} = fieldNames;
    metricCapacity = metricCapacity + numel(fieldNames);
end

metrics = repmat(struct("Type", "", "VariableName", "", "Dates", NaT(0, 1), "Values", NaN(0, 1)), metricCapacity, 1);
metricCount = 0;

for resultIndex = 1:numel(resultItems)
    item = resultItems{resultIndex};
    fieldNames = fieldNamesByItem{resultIndex};

    for fieldIndex = 1:numel(fieldNames)
        typeName = fieldNames(fieldIndex);
        [dates, values] = recordsToSeries(item.(typeName));

        if isempty(dates)
            continue
        end

        metricCount = metricCount + 1;
        metrics(metricCount) = struct( ...
            "Type", typeName, ...
            "VariableName", typeToVariableName(typeName, frequency), ...
            "Dates", dates, ...
            "Values", values);
    end
end

metrics = metrics(1:metricCount);
metrics = reorderMetrics(metrics, requestedTypes);
end

function items = normalizeResultItems(result)
if iscell(result)
    items = result(:);
else
    result = result(:);
    items = cell(numel(result), 1);

    for resultIndex = 1:numel(result)
        items{resultIndex} = result(resultIndex);
    end
end
end

function [dates, values] = recordsToSeries(records)
records = normalizeRecords(records);
rowCount = numel(records);
dates = NaT(rowCount, 1, TimeZone="UTC");
values = NaN(rowCount, 1);

for rowIndex = 1:rowCount
    record = records(rowIndex);
    dates(rowIndex) = recordDate(record);
    values(rowIndex) = recordValue(record);
end

validRows = ~isnat(dates) & ~isnan(values);
dates = dates(validRows);
values = values(validRows);
end

function records = normalizeRecords(records)
if iscell(records)
    records = [records{:}];
end

records = records(:);
end

function value = recordDate(record)
value = NaT(1, 1, TimeZone="UTC");

if isfield(record, "asOfDate") && strlength(string(record.asOfDate)) > 0
    value = datetime(string(record.asOfDate), TimeZone="UTC");
elseif isfield(record, "timestamp") && isnumeric(record.timestamp) && ~isempty(record.timestamp)
    value = datetime(double(record.timestamp(1)), ConvertFrom="posixtime", TimeZone="UTC");
end
end

function value = recordValue(record)
value = NaN;

if isfield(record, "reportedValue")
    rawValue = yfinance.internal.unwrapYahooValue(record.reportedValue);
elseif isfield(record, "raw")
    rawValue = record.raw;
else
    rawValue = record;
end

if isnumeric(rawValue) && ~isempty(rawValue)
    value = double(rawValue(1));
end
end

function variableName = typeToVariableName(typeName, frequency)
typeName = string(typeName);
frequency = string(frequency);

if startsWith(typeName, frequency)
    typeName = extractAfter(typeName, strlength(frequency));
end

variableName = yfinance.internal.pascalFieldName(typeName);
end

function metrics = reorderMetrics(metrics, requestedTypes)
if isempty(requestedTypes) || isempty(metrics)
    return
end

metricTypes = [metrics.Type];
[~, order] = ismember(metricTypes, requestedTypes);
knownOrder = order > 0;
[~, sortIndex] = sort(order(knownOrder));
metrics = [metrics(knownOrder)];
metrics = metrics(sortIndex);
end

function data = statementTable(metrics)
endDate = NaT(0, 1, TimeZone="UTC");

for metricIndex = 1:numel(metrics)
    endDate = [endDate; metrics(metricIndex).Dates(:)]; %#ok<AGROW>
end

endDate = unique(endDate);
endDate = sort(endDate, "descend");
data = table(endDate, VariableNames={'EndDate'});

for metricIndex = 1:numel(metrics)
    metric = metrics(metricIndex);
    values = NaN(numel(endDate), 1);

    for valueIndex = 1:numel(metric.Dates)
        rowIndex = find(endDate == metric.Dates(valueIndex), 1);

        if ~isempty(rowIndex)
            values(rowIndex) = metric.Values(valueIndex);
        end
    end

    data.(metric.VariableName) = values;
end
end

function data = emptyStatementTable(options)
data = table(NaT(0, 1, TimeZone="UTC"), VariableNames={'EndDate'});
data.Properties.UserData = struct( ...
    "Symbol", options.Symbol, ...
    "Source", "fundamentals-timeseries", ...
    "StatementType", options.StatementType, ...
    "Frequency", options.Frequency);
end
