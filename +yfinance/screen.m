function result = screen(query, options)
%SCREEN Run a predefined or custom Yahoo Finance screener.

arguments
    query
    options.Count (1,1) double {mustBeNonnegativeIntegerOrNaN} = NaN
    options.Size (1,1) double {mustBeNonnegativeIntegerOrNaN} = NaN
    options.Offset (1,1) double {mustBeNonnegative, mustBeInteger} = 0
    options.SortField (1,1) string = "ticker"
    options.SortAscending (1,1) logical = false
    options.UserId (1,1) string = ""
    options.UserIdType (1,1) string = "guid"
    options.Session = yfinance.internal.Session()
end

if isa(query, "yfinance.internal.ScreenerQuery")
    count = customCount(options.Count, options.Size);
    response = options.Session.postScreener( ...
        query.toStruct(), ...
        Count=count, ...
        Offset=options.Offset, ...
        SortField=options.SortField, ...
        SortAscending=options.SortAscending, ...
        UserId=options.UserId, ...
        UserIdType=options.UserIdType, ...
        QuoteType=query.QuoteType);
    result = yfinance.internal.screenerResponseToResult(response, Query=string(query));
else
    queryName = string(query);

    if ~isscalar(queryName) || strlength(strtrim(queryName)) == 0
        error("yfinance:InvalidQuery", "Screener query must be a predefined query name or a query object.");
    end

    queryName = strtrim(queryName);
    count = predefinedCount(options.Count, options.Size);
    response = options.Session.getScreener( ...
        queryName, ...
        Count=count, ...
        Offset=options.Offset);
    result = yfinance.internal.screenerResponseToResult(response, Query=queryName);
end
end

function count = predefinedCount(count, size)
if isnan(count)
    count = size;
end

if isnan(count)
    count = 25;
end

validateYahooCount(count);
end

function count = customCount(count, size)
if isnan(size)
    size = count;
end

if isnan(size)
    size = 100;
end

count = size;
validateYahooCount(count);
end

function validateYahooCount(count)
if count > 250
    error("yfinance:InvalidCount", "Yahoo Finance screeners limit Count or Size to 250 or less.");
end
end

function mustBeNonnegativeIntegerOrNaN(value)
if isnan(value)
    return
end

mustBeNonnegative(value);
mustBeInteger(value);
end
