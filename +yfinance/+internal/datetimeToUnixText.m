function value = datetimeToUnixText(time)
%DATETIMETOUNIXTEXT Convert a scalar datetime to Unix seconds text.

arguments
    time (1,1) datetime
end

if isnat(time)
    error("yfinance:InvalidDateRange", "Datetime values must not be NaT.");
end

if strlength(string(time.TimeZone)) == 0
    time.TimeZone = "UTC";
end

value = char(string(floor(posixtime(time))));
end
