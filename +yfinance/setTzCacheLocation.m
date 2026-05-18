function currentConfig = setTzCacheLocation(location)
%SETTZCACHELOCATION Store an upstream-compatible timezone cache location.

arguments
    location (1,1) string
end

currentConfig = yfinance.setConfig(TimeZoneCacheLocation=location);
end
