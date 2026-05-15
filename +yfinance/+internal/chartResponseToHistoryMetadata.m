function metadata = chartResponseToHistoryMetadata(response, options)
%CHARTRESPONSETOHISTORYMETADATA Convert Yahoo chart metadata to a struct.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

metadata = chartMetadata(response, options.Symbol);
metadata.Symbol = string(fieldOrDefault(metadata, "symbol", options.Symbol));
metadata.Raw = metadata;

if isfield(metadata, "regularMarketTime") && ~isempty(metadata.regularMarketTime)
    metadata.RegularMarketTime = datetime( ...
        double(metadata.regularMarketTime), ...
        ConvertFrom="posixtime", ...
        TimeZone="UTC");
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
