% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function calendar = quoteSummaryResponseToCalendar(response, options)
%QUOTESUMMARYRESPONSETOCALENDAR Convert Yahoo calendar events to a struct.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
calendar = struct("Symbol", options.Symbol);

if ~isfield(result, "calendarEvents") || isempty(result.calendarEvents)
    calendar.Raw = struct();
    return
end

calendarEvents = result.calendarEvents;
calendar.Raw = calendarEvents;

if isfield(calendarEvents, "earnings")
    earnings = yfinance.internal.unwrapYahooValue(calendarEvents.earnings);
    calendar.Earnings = earnings;

    if isfield(earnings, "earningsDate")
        calendar.EarningsDate = unixValuesToDatetime(earnings.earningsDate);
    end
end

calendar = copyDateField(calendar, calendarEvents, "exDividendDate", "ExDividendDate");
calendar = copyDateField(calendar, calendarEvents, "dividendDate", "DividendDate");
calendar = copyDateField(calendar, calendarEvents, "earningsDate", "EarningsDate");
calendar = copyDateField(calendar, calendarEvents, "revenueDate", "RevenueDate");
end

function output = copyDateField(output, inputStruct, sourceName, targetName)
if isfield(inputStruct, sourceName) && ~isempty(inputStruct.(sourceName))
    output.(targetName) = unixValuesToDatetime(yfinance.internal.unwrapYahooValue(inputStruct.(sourceName)));
end
end

function values = unixValuesToDatetime(values)
values = yfinance.internal.unwrapYahooValue(values);

if isempty(values)
    values = NaT(0, 1, TimeZone="UTC");
    return
end

inputValues = valuesToCell(values);
outputValues = NaT(numel(inputValues), 1, TimeZone="UTC");

for valueIndex = 1:numel(inputValues)
    outputValues(valueIndex) = unixValueToDatetime(inputValues{valueIndex});
end

values = outputValues;
end

function values = valuesToCell(values)
if iscell(values)
    values = values(:);
elseif isstring(values)
    values = cellstr(values(:));
elseif ischar(values)
    values = {values};
else
    values = num2cell(values(:));
end
end

function value = unixValueToDatetime(value)
value = yfinance.internal.unwrapYahooValue(value);

if isempty(value)
    value = NaT(1, 1, TimeZone="UTC");
    return
end

if isdatetime(value)
    if strlength(string(value.TimeZone)) == 0
        value.TimeZone = "UTC";
    end

    return
end

if isnumeric(value) || islogical(value)
    numericValue = double(value(1));
elseif isstring(value) || ischar(value)
    numericValue = str2double(string(value));
else
    numericValue = NaN;
end

if isnan(numericValue)
    value = NaT(1, 1, TimeZone="UTC");
else
    value = datetime(numericValue, ConvertFrom="posixtime", TimeZone="UTC");
end
end
