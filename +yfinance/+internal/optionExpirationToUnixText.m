function value = optionExpirationToUnixText(expiration)
%OPTIONEXPIRATIONTOUNIXTEXT Convert an option expiration value to Unix seconds.

if isempty(expiration)
    value = "";
    return
end

if isdatetime(expiration)
    value = datetimeExpirationToText(expiration);
    return
end

if isnumeric(expiration)
    value = char(string(floor(double(expiration))));
    return
end

if ischar(expiration) || isstring(expiration)
    expirationText = string(expiration);

    if strlength(strtrim(expirationText)) == 0
        value = "";
        return
    end

    numericValue = str2double(expirationText);

    if ~isnan(numericValue)
        value = char(string(floor(numericValue)));
        return
    end

    expirationTime = datetime(expirationText, TimeZone="UTC");
    value = datetimeExpirationToText(expirationTime);
    return
end

error("yfinance:InvalidExpiration", "Expiration must be a datetime, numeric Unix timestamp, or date string.");
end

function value = datetimeExpirationToText(expiration)
if numel(expiration) ~= 1 || isnat(expiration)
    error("yfinance:InvalidExpiration", "Expiration must be a scalar non-NaT datetime.");
end

if strlength(string(expiration.TimeZone)) == 0
    expiration.TimeZone = "UTC";
end

value = char(string(floor(posixtime(expiration))));
end
