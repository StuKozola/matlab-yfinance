% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef Calendars < handle
    %CALENDARS Access Yahoo Finance event calendars.

    properties (SetAccess = private)
        Start (1,1) datetime
        End (1,1) datetime
    end

    properties (Dependent)
        EarningsCalendar
        IpoInfoCalendar
        EconomicEventsCalendar
        SplitsCalendar
    end

    properties (Access = private)
        Session
        CalendarCache struct = struct()
        RequestCache struct = struct()
        MostActiveQuery = yfinance.internal.CalendarQuery("or", {})
    end

    methods
        function obj = Calendars(options)
            arguments
                options.Start = NaT
                options.End = NaT
                options.Session = yfinance.internal.Session()
            end

            if hasDateInput(options.Start)
                startTime = normalizeDateInput(options.Start);
            else
                startTime = dateshift(datetime("today", TimeZone="UTC"), "start", "day");
            end

            if hasDateInput(options.End)
                endTime = normalizeDateInput(options.End);
            else
                endTime = startTime + days(7);
            end

            validateDateRange(startTime, endTime);
            obj.Start = startTime;
            obj.End = endTime;
            obj.Session = options.Session;
        end

        function data = getEarningsCalendar(obj, options)
            %GETEARNINGSCALENDAR Return earnings calendar events.
            arguments
                obj
                options.MarketCap (1,1) double = NaN
                options.FilterMostActive (1,1) logical = true
                options.Start = NaT
                options.End = NaT
                options.Limit (1,1) double {mustBeNonnegative, mustBeInteger} = 12
                options.Offset (1,1) double {mustBeNonnegative, mustBeInteger} = 0
                options.Force (1,1) logical = false
            end

            [startTime, endTime] = obj.resolveDateRange(options.Start, options.End);
            eventType = yfinance.internal.CalendarQuery("or", { ...
                yfinance.internal.CalendarQuery("eq", {"eventtype", "EAD"}), ...
                yfinance.internal.CalendarQuery("eq", {"eventtype", "ERA"})});
            operands = { ...
                yfinance.internal.CalendarQuery("eq", {"region", "us"}), ...
                eventType, ...
                yfinance.internal.CalendarQuery("gte", {"startdatetime", calendarDateText(startTime)}), ...
                yfinance.internal.CalendarQuery("lte", {"startdatetime", calendarDateText(endTime)})};

            if ~isnan(options.MarketCap)
                if options.MarketCap < 10000000
                    warning("yfinance:SmallMarketCap", "MarketCap filtering below 10000000 may return noisy calendar data.");
                end

                operands{end + 1} = yfinance.internal.CalendarQuery("gte", {"intradaymarketcap", options.MarketCap});
            end

            if options.FilterMostActive && options.Offset == 0
                mostActiveQuery = obj.getMostActiveQuery(options.MarketCap, options.Force);

                if ~mostActiveQuery.isEmpty()
                    operands{end + 1} = mostActiveQuery;
                end
            end

            query = yfinance.internal.CalendarQuery("and", operands);
            data = obj.fetchCalendar( ...
                "sp_earnings", ...
                query, ...
                Limit=options.Limit, ...
                Offset=options.Offset, ...
                Force=options.Force);
        end

        function data = getIpoInfoCalendar(obj, options)
            %GETIPOINFOCALENDAR Return IPO calendar events.
            arguments
                obj
                options.Start = NaT
                options.End = NaT
                options.Limit (1,1) double {mustBeNonnegative, mustBeInteger} = 25
                options.Offset (1,1) double {mustBeNonnegative, mustBeInteger} = 0
                options.Force (1,1) logical = false
            end

            [startTime, endTime] = obj.resolveDateRange(options.Start, options.End);
            query = yfinance.internal.CalendarQuery("or", { ...
                yfinance.internal.CalendarQuery("gtelt", {"startdatetime", calendarDateText(startTime), calendarDateText(endTime)}), ...
                yfinance.internal.CalendarQuery("gtelt", {"pricedDate", calendarDateText(startTime), calendarDateText(endTime)})});
            data = obj.fetchCalendar( ...
                "ipo_info", ...
                query, ...
                Limit=options.Limit, ...
                Offset=options.Offset, ...
                Force=options.Force);
        end

        function data = getEconomicEventsCalendar(obj, options)
            %GETECONOMICEVENTSCALENDAR Return economic calendar events.
            arguments
                obj
                options.Start = NaT
                options.End = NaT
                options.Limit (1,1) double {mustBeNonnegative, mustBeInteger} = 25
                options.Offset (1,1) double {mustBeNonnegative, mustBeInteger} = 0
                options.Force (1,1) logical = false
            end

            data = obj.fetchCalendar( ...
                "economic_event", ...
                obj.dateRangeQuery(options.Start, options.End), ...
                Limit=options.Limit, ...
                Offset=options.Offset, ...
                Force=options.Force);
        end

        function data = getSplitsCalendar(obj, options)
            %GETSPLITSCALENDAR Return stock split calendar events.
            arguments
                obj
                options.Start = NaT
                options.End = NaT
                options.Limit (1,1) double {mustBeNonnegative, mustBeInteger} = 25
                options.Offset (1,1) double {mustBeNonnegative, mustBeInteger} = 0
                options.Force (1,1) logical = false
            end

            data = obj.fetchCalendar( ...
                "splits", ...
                obj.dateRangeQuery(options.Start, options.End), ...
                Limit=options.Limit, ...
                Offset=options.Offset, ...
                Force=options.Force);
        end

        function data = get.EarningsCalendar(obj)
            data = obj.getEarningsCalendar();
        end

        function data = get.IpoInfoCalendar(obj)
            data = obj.getIpoInfoCalendar();
        end

        function data = get.EconomicEventsCalendar(obj)
            data = obj.getEconomicEventsCalendar();
        end

        function data = get.SplitsCalendar(obj)
            data = obj.getSplitsCalendar();
        end
    end

    methods (Access = private)
        function data = fetchCalendar(obj, calendarType, query, options)
            arguments
                obj
                calendarType (1,1) string {mustBeNonzeroLengthText}
                query (1,1) yfinance.internal.CalendarQuery
                options.Limit (1,1) double {mustBeNonnegative, mustBeInteger}
                options.Offset (1,1) double {mustBeNonnegative, mustBeInteger}
                options.Force (1,1) logical = false
            end

            queryStruct = query.toStruct();
            request = struct( ...
                "CalendarType", calendarType, ...
                "Limit", options.Limit, ...
                "Offset", options.Offset, ...
                "Query", queryStruct);
            cacheField = matlab.lang.makeValidName(calendarType);
            requestKey = string(jsonencode(request));

            if ~options.Force && isfield(obj.RequestCache, cacheField) && ...
                    isfield(obj.CalendarCache, cacheField) && ...
                    obj.RequestCache.(cacheField) == requestKey
                data = obj.CalendarCache.(cacheField);
                return
            end

            response = obj.Session.getCalendar( ...
                calendarType, ...
                queryStruct, ...
                Limit=options.Limit, ...
                Offset=options.Offset);
            data = yfinance.internal.calendarResponseToTable(response, CalendarType=calendarType);
            obj.RequestCache.(cacheField) = requestKey;
            obj.CalendarCache.(cacheField) = data;
        end

        function query = dateRangeQuery(obj, startInput, endInput)
            [startTime, endTime] = obj.resolveDateRange(startInput, endInput);
            query = yfinance.internal.CalendarQuery("and", { ...
                yfinance.internal.CalendarQuery("gte", {"startdatetime", calendarDateText(startTime)}), ...
                yfinance.internal.CalendarQuery("lte", {"startdatetime", calendarDateText(endTime)})});
        end

        function [startTime, endTime] = resolveDateRange(obj, startInput, endInput)
            hasStart = hasDateInput(startInput);
            hasEnd = hasDateInput(endInput);

            if hasStart ~= hasEnd
                warning("yfinance:IncompleteDateRange", "Provide both Start and End, or neither, for calendar queries.");
            end

            if hasStart
                startTime = normalizeDateInput(startInput);
            else
                startTime = obj.Start;
            end

            if hasEnd
                endTime = normalizeDateInput(endInput);
            else
                endTime = obj.End;
            end

            validateDateRange(startTime, endTime);
        end

        function query = getMostActiveQuery(obj, marketCap, force)
            if ~force && ~obj.MostActiveQuery.isEmpty()
                query = obj.MostActiveQuery;
                return
            end

            try
                screener = yfinance.screen("most_actives", Count=200, Session=obj.Session);
                query = mostActiveQueryFromQuotes(screener.Quotes, marketCap);
            catch exception
                if ~startsWith(string(exception.identifier), "yfinance:")
                    rethrow(exception);
                end

                query = yfinance.internal.CalendarQuery("or", {});
            end

            obj.MostActiveQuery = query;
        end
    end
end

function value = hasDateInput(value)
if isempty(value)
    value = false;
elseif isdatetime(value)
    value = ~(isscalar(value) && isnat(value));
elseif isstring(value) || ischar(value)
    value = strlength(strtrim(string(value))) > 0;
else
    value = true;
end
end

function value = normalizeDateInput(value)
if isdatetime(value)
    validateattributes(value, {'datetime'}, {'scalar'});
elseif isnumeric(value) && isscalar(value)
    value = datetime(double(value), ConvertFrom="posixtime", TimeZone="UTC");
elseif isstring(value) || ischar(value)
    text = strtrim(string(value));

    try
        value = datetime(text, InputFormat="yyyy-MM-dd", TimeZone="UTC");
    catch
        value = datetime(text, TimeZone="UTC");
    end
else
    error("yfinance:InvalidDate", "Calendar dates must be scalar datetimes, strings, or Unix timestamps.");
end

if strlength(string(value.TimeZone)) == 0
    value.TimeZone = "UTC";
end

value = dateshift(value, "start", "day");
end

function validateDateRange(startTime, endTime)
if startTime > endTime
    error("yfinance:InvalidDateRange", "Calendar Start must be on or before End.");
end
end

function text = calendarDateText(value)
value.Format = "yyyy-MM-dd";
text = string(value);
end

function query = mostActiveQueryFromQuotes(quotes, marketCap)
query = yfinance.internal.CalendarQuery("or", {});

if ~istable(quotes) || height(quotes) == 0 || ~ismember("Symbol", string(quotes.Properties.VariableNames))
    return
end

symbols = string(quotes.Symbol);
useSymbol = strlength(symbols) > 0;

if ~isnan(marketCap)
    if ~ismember("MarketCap", string(quotes.Properties.VariableNames))
        return
    end

    useSymbol = useSymbol & quotes.MarketCap >= marketCap;
end

symbols = symbols(useSymbol);
operands = cell(1, numel(symbols));

for symbolIndex = 1:numel(symbols)
    operands{symbolIndex} = yfinance.internal.CalendarQuery("eq", {"ticker", symbols(symbolIndex)});
end

query = yfinance.internal.CalendarQuery("or", operands);
end
