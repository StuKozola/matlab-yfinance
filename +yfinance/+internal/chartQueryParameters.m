function query = chartQueryParameters(options)
%CHARTQUERYPARAMETERS Build query arguments for the Yahoo chart endpoint.

arguments
    options.Period (1,1) string = "1mo"
    options.Interval (1,1) string = "1d"
    options.Start datetime = NaT
    options.End datetime = NaT
    options.IncludePrePost (1,1) logical = false
end

period = lower(strtrim(options.Period));
interval = lower(strtrim(options.Interval));

yfinance.internal.validatePeriod(period);
yfinance.internal.validateInterval(interval);

query = { ...
    "interval", char(interval), ...
    "events", "div,splits,capitalGains", ...
    "includeAdjustedClose", "true", ...
    "includePrePost", yfinance.internal.logicalToText(options.IncludePrePost)};

hasStart = ~isnat(options.Start);
hasEnd = ~isnat(options.End);

if hasEnd && ~hasStart
    error("yfinance:InvalidDateRange", "End can only be used when Start is also provided.");
end

if hasStart
    endTime = options.End;

    if ~hasEnd
        endTime = datetime("now", TimeZone="UTC");
    end

    if endTime <= options.Start
        error("yfinance:InvalidDateRange", "End must be later than Start.");
    end

    query = [query, { ...
        "period1", yfinance.internal.datetimeToUnixText(options.Start), ...
        "period2", yfinance.internal.datetimeToUnixText(endTime)}];
else
    query = [query, {"range", char(period)}];
end
end
