% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = chartResponseToTimetable(response, options)
%CHARTRESPONSETOTIMETABLE Convert a Yahoo chart response to a timetable.

arguments
    response struct
    options.Symbol (1,1) string = ""
    options.AutoAdjust (1,1) logical = true
end

if ~isfield(response, "chart")
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a chart payload.");
end

chart = response.chart;
throwIfYahooError(chart, options.Symbol);

if ~isfield(chart, "result") || isempty(chart.result)
    error("yfinance:NoData", "Yahoo Finance returned no chart data for %s.", options.Symbol);
end

result = firstElement(chart.result);

if ~isfield(result, "timestamp") || isempty(result.timestamp)
    error("yfinance:NoData", "Yahoo Finance returned no price timestamps for %s.", options.Symbol);
end

timestamps = double(result.timestamp(:));
rowCount = numel(timestamps);
quote = firstElement(result.indicators.quote);

openPrices = numericColumn(quote, "open", rowCount);
highPrices = numericColumn(quote, "high", rowCount);
lowPrices = numericColumn(quote, "low", rowCount);
closePrices = numericColumn(quote, "close", rowCount);
volumes = numericColumn(quote, "volume", rowCount);
adjClosePrices = adjustedCloseColumn(result, closePrices, rowCount);

if options.AutoAdjust
    [openPrices, highPrices, lowPrices, closePrices] = autoAdjustPrices( ...
        openPrices, ...
        highPrices, ...
        lowPrices, ...
        closePrices, ...
        adjClosePrices);
end

[dividends, stockSplits, capitalGains] = actionColumns(result, timestamps);
timeZone = chartTimeZone(result);
times = datetime(timestamps, ConvertFrom="posixtime", TimeZone="UTC");
times.TimeZone = timeZone;

data = timetable( ...
    times, ...
    openPrices, ...
    highPrices, ...
    lowPrices, ...
    closePrices, ...
    adjClosePrices, ...
    volumes, ...
    dividends, ...
    stockSplits, ...
    capitalGains, ...
    VariableNames=[ ...
        "Open", ...
        "High", ...
        "Low", ...
        "Close", ...
        "AdjClose", ...
        "Volume", ...
        "Dividends", ...
        "StockSplits", ...
        "CapitalGains"]);

data.Properties.DimensionNames = {'Time', 'Variables'};
data.Properties.UserData = chartMetadata(result, options.Symbol);
end

function throwIfYahooError(chart, symbol)
if ~isfield(chart, "error") || isempty(chart.error)
    return
end

yahooError = chart.error;

if ~isstruct(yahooError)
    return
end

message = "Yahoo Finance returned an error";

if isfield(yahooError, "description") && ~isempty(yahooError.description)
    message = string(yahooError.description);
elseif isfield(yahooError, "code") && ~isempty(yahooError.code)
    message = string(yahooError.code);
end

error("yfinance:YahooError", "%s for %s.", message, symbol);
end

function value = firstElement(value)
if iscell(value)
    value = value{1};
elseif numel(value) > 1
    value = value(1);
end
end

function values = numericColumn(inputStruct, fieldName, rowCount)
values = NaN(rowCount, 1);

if ~isfield(inputStruct, fieldName)
    return
end

rawValues = inputStruct.(fieldName);

if isempty(rawValues)
    return
end

rawValues = double(rawValues(:));
copyCount = min(rowCount, numel(rawValues));
values(1:copyCount) = rawValues(1:copyCount);
end

function adjClosePrices = adjustedCloseColumn(result, closePrices, rowCount)
adjClosePrices = closePrices;

if ~isfield(result.indicators, "adjclose") || isempty(result.indicators.adjclose)
    return
end

adjClose = firstElement(result.indicators.adjclose);
adjClosePrices = numericColumn(adjClose, "adjclose", rowCount);
end

function [openPrices, highPrices, lowPrices, closePrices] = autoAdjustPrices( ...
    openPrices, highPrices, lowPrices, closePrices, adjClosePrices)

ratio = adjClosePrices ./ closePrices;
ratio(closePrices == 0 | isnan(closePrices) | isnan(adjClosePrices)) = NaN;

openPrices = openPrices .* ratio;
highPrices = highPrices .* ratio;
lowPrices = lowPrices .* ratio;
closePrices = adjClosePrices;
end

function [dividends, stockSplits, capitalGains] = actionColumns(result, timestamps)
rowCount = numel(timestamps);
dividends = zeros(rowCount, 1);
stockSplits = zeros(rowCount, 1);
capitalGains = zeros(rowCount, 1);

if ~isfield(result, "events") || isempty(result.events)
    return
end

events = result.events;

if isfield(events, "dividends")
    dividends = assignEventAmounts(dividends, events.dividends, timestamps, "amount");
end

if isfield(events, "splits")
    stockSplits = assignSplitRatios(stockSplits, events.splits, timestamps);
end

if isfield(events, "capitalGains")
    capitalGains = assignEventAmounts(capitalGains, events.capitalGains, timestamps, "amount");
end
end

function values = assignEventAmounts(values, events, timestamps, amountField)
eventNames = fieldnames(events);

for eventIndex = 1:numel(eventNames)
    event = events.(eventNames{eventIndex});
    rowIndex = find(timestamps == double(event.date), 1);

    if isempty(rowIndex) || ~isfield(event, amountField)
        continue
    end

    values(rowIndex) = double(event.(amountField));
end
end

function values = assignSplitRatios(values, events, timestamps)
eventNames = fieldnames(events);

for eventIndex = 1:numel(eventNames)
    event = events.(eventNames{eventIndex});
    rowIndex = find(timestamps == double(event.date), 1);

    if isempty(rowIndex)
        continue
    end

    values(rowIndex) = splitRatio(event);
end
end

function value = splitRatio(event)
if isfield(event, "numerator") && isfield(event, "denominator") && event.denominator ~= 0
    value = double(event.numerator) / double(event.denominator);
    return
end

if isfield(event, "splitRatio")
    parts = split(string(event.splitRatio), ":");

    if numel(parts) == 2
        numerator = str2double(parts(1));
        denominator = str2double(parts(2));

        if denominator ~= 0
            value = numerator / denominator;
            return
        end
    end
end

value = NaN;
end

function metadata = chartMetadata(result, symbol)
metadata = struct("Symbol", symbol);

if ~isfield(result, "meta") || isempty(result.meta)
    return
end

meta = result.meta;
metaFields = fieldnames(meta);

for fieldIndex = 1:numel(metaFields)
    fieldName = metaFields{fieldIndex};
    metadata.(fieldName) = meta.(fieldName);
end
end

function timeZone = chartTimeZone(result)
timeZone = "UTC";

if ~isfield(result, "meta") || isempty(result.meta)
    return
end

meta = result.meta;

if isfield(meta, "exchangeTimezoneName") && ~isempty(meta.exchangeTimezoneName)
    timeZone = string(meta.exchangeTimezoneName);
end
end
