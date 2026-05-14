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
if isstruct(values)
    if isfield(values, "raw")
        values = values.raw;
    else
        values = [];
    end
end

if isempty(values)
    values = NaT(0, 1, TimeZone="UTC");
    return
end

values = double(values(:));
values = datetime(values, ConvertFrom="posixtime", TimeZone="UTC");
end
