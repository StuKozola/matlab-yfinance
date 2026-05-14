function validateInterval(interval)
%VALIDATEINTERVAL Validate a Yahoo chart interval value.

validIntervals = ["1m", "2m", "5m", "15m", "30m", "60m", "90m", "1h", "1d", "5d", "1wk", "1mo", "3mo"];

if ~ismember(interval, validIntervals)
    error( ...
        "yfinance:InvalidInterval", ...
        "Interval must be one of: %s.", ...
        strjoin(validIntervals, ", "));
end
end
