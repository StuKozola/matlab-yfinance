% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function info = chartResponseToFastInfo(response, options)
%CHARTRESPONSETOFASTINFO Convert Yahoo chart metadata to a fastInfo struct.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

meta = chartMetadata(response, options.Symbol);
info = struct();

info.Symbol = string(fieldOrDefault(meta, "symbol", options.Symbol));
info.Raw = meta;

info = copyField(info, meta, "currency", "Currency");
info = copyField(info, meta, "exchangeName", "Exchange");
info = copyField(info, meta, "fullExchangeName", "ExchangeName");
info = copyField(info, meta, "exchangeTimezoneName", "ExchangeTimezoneName");
info = copyField(info, meta, "instrumentType", "QuoteType");
info = copyField(info, meta, "regularMarketPrice", "LastPrice");
info = copyFirstAvailable(info, meta, ["regularMarketPreviousClose", "previousClose", "chartPreviousClose"], "PreviousClose");
info = copyField(info, meta, "regularMarketDayHigh", "DayHigh");
info = copyField(info, meta, "regularMarketDayLow", "DayLow");
info = copyField(info, meta, "regularMarketVolume", "Volume");
info = copyField(info, meta, "regularMarketTime", "LastTradeTime");
info = copyField(info, meta, "fiftyTwoWeekHigh", "FiftyTwoWeekHigh");
info = copyField(info, meta, "fiftyTwoWeekLow", "FiftyTwoWeekLow");

if isfield(info, "LastTradeTime") && isnumeric(info.LastTradeTime) && ~isempty(info.LastTradeTime)
    info.LastTradeTime = datetime(double(info.LastTradeTime), ConvertFrom="posixtime", TimeZone="UTC");
end
end

function meta = chartMetadata(response, symbol)
if ~isfield(response, "chart")
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a chart payload.");
end

chart = response.chart;

if isfield(chart, "error") && ~isempty(chart.error)
    error("yfinance:YahooError", "Yahoo Finance returned a chart error for %s.", symbol);
end

if ~isfield(chart, "result") || isempty(chart.result)
    error("yfinance:NoData", "Yahoo Finance returned no chart metadata for %s.", symbol);
end

result = chart.result;

if iscell(result)
    result = result{1};
elseif numel(result) > 1
    result = result(1);
end

if ~isfield(result, "meta") || isempty(result.meta)
    error("yfinance:NoData", "Yahoo Finance returned no chart metadata for %s.", symbol);
end

meta = result.meta;
end

function value = fieldOrDefault(inputStruct, fieldName, defaultValue)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = inputStruct.(fieldName);
else
    value = defaultValue;
end
end

function output = copyField(output, inputStruct, sourceName, targetName)
if isfield(inputStruct, sourceName) && ~isempty(inputStruct.(sourceName))
    output.(targetName) = inputStruct.(sourceName);
end
end

function output = copyFirstAvailable(output, inputStruct, sourceNames, targetName)
for sourceIndex = 1:numel(sourceNames)
    sourceName = sourceNames(sourceIndex);

    if isfield(inputStruct, sourceName) && ~isempty(inputStruct.(sourceName))
        output.(targetName) = inputStruct.(sourceName);
        return
    end
end
end
