% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = fundamentalsTimeSeriesResponseToShares(response, options)
%FUNDAMENTALSTIMESERIESRESPONSETOSHARES Convert Yahoo share-count history.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

if ~isfield(response, "timeseries") || isempty(response.timeseries)
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a timeseries payload.");
end

timeseries = response.timeseries;

if isfield(timeseries, "error") && ~isempty(timeseries.error)
    error("yfinance:YahooError", "Yahoo Finance returned a timeseries error for %s.", options.Symbol);
end

if ~isfield(timeseries, "result") || isempty(timeseries.result)
    data = emptySharesTimetable(options.Symbol);
    return
end

result = timeseries.result;
result = result(1);

if ~isfield(result, "shares_out") || isempty(result.shares_out)
    data = emptySharesTimetable(options.Symbol);
    return
end

[times, values] = sharesSeries(result);

if isempty(times)
    data = emptySharesTimetable(options.Symbol);
    return
end

data = timetable(times(:), values(:), VariableNames={'SharesOutstanding'});
data.Properties.DimensionNames{1} = 'Time';
data = sortrows(data);
data.Properties.UserData = struct( ...
    "Symbol", options.Symbol, ...
    "Source", "fundamentals-timeseries", ...
    "Type", "shares_out");
end

function [times, values] = sharesSeries(result)
shares = result.shares_out;

if isnumeric(shares)
    rawValues = double(shares(:));
    times = timestampTimes(result, numel(rawValues));
    values = rawValues(1:numel(times));
    return
end

shares = normalizeRecords(shares);
rowCount = numel(shares);
times = NaT(rowCount, 1, TimeZone="UTC");
values = NaN(rowCount, 1);

for rowIndex = 1:rowCount
    record = shares(rowIndex);
    times(rowIndex) = recordTime(record);
    values(rowIndex) = recordValue(record);
end

validRows = ~isnat(times) & ~isnan(values);
times = times(validRows);
values = values(validRows);
end

function times = timestampTimes(result, rowCount)
if ~isfield(result, "timestamp") || isempty(result.timestamp)
    times = NaT(0, 1, TimeZone="UTC");
    return
end

timestamps = double(result.timestamp(:));
rowCount = min(rowCount, numel(timestamps));
times = datetime(timestamps(1:rowCount), ConvertFrom="posixtime", TimeZone="UTC");
end

function value = recordTime(record)
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

function records = normalizeRecords(records)
if iscell(records)
    records = [records{:}];
end

records = records(:);
end

function data = emptySharesTimetable(symbol)
data = timetable( ...
    NaT(0, 1, TimeZone="UTC"), ...
    NaN(0, 1), ...
    VariableNames={'SharesOutstanding'});
data.Properties.DimensionNames{1} = 'Time';
data.Properties.UserData = struct( ...
    "Symbol", symbol, ...
    "Source", "fundamentals-timeseries", ...
    "Type", "shares_out");
end
