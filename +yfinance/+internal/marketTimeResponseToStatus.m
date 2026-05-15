function status = marketTimeResponseToStatus(response, options)
%MARKETTIMERESPONSETOSTATUS Convert Yahoo market-time data.

arguments
    response struct
    options.Market (1,1) string = ""
end

if ~isfield(response, "finance") || isempty(response.finance)
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain market time data.");
end

finance = response.finance;

if isfield(finance, "error") && ~isempty(finance.error)
    error("yfinance:YahooError", "Yahoo Finance returned a market time error for %s.", options.Market);
end

marketTime = firstMarketTime(finance);
status = struct( ...
    "Market", options.Market, ...
    "Exchange", stringField(marketTime, "exchange"), ...
    "Status", stringField(marketTime, "status"), ...
    "Open", dateTimeField(marketTime, "open"), ...
    "Close", dateTimeField(marketTime, "close"), ...
    "Timezone", struct(), ...
    "GmtOffset", NaN, ...
    "Raw", marketTime);

if isfield(marketTime, "timezone") && ~isempty(marketTime.timezone)
    timezone = firstElement(marketTime.timezone);
    status.Timezone = yfinance.internal.unwrapYahooValue(timezone);

    if isfield(timezone, "gmtoffset") && ~isempty(timezone.gmtoffset)
        status.GmtOffset = double(timezone.gmtoffset);
    end
end
end

function value = firstMarketTime(finance)
if ~isfield(finance, "marketTimes") || isempty(finance.marketTimes)
    value = struct();
    return
end

marketTimes = firstElement(finance.marketTimes);

if ~isfield(marketTimes, "marketTime") || isempty(marketTimes.marketTime)
    value = struct();
else
    value = firstElement(marketTimes.marketTime);
end
end

function value = firstElement(value)
if iscell(value)
    value = value{1};
else
    value = value(1);
end
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(inputStruct.(fieldName));
else
    value = "";
end
end

function value = dateTimeField(inputStruct, fieldName)
if ~isfield(inputStruct, fieldName) || isempty(inputStruct.(fieldName))
    value = NaT(1, 1, TimeZone="UTC");
    return
end

try
    value = datetime(string(inputStruct.(fieldName)), InputFormat="yyyy-MM-dd'T'HH:mm:ssXXX", TimeZone="UTC");
catch
    value = datetime(string(inputStruct.(fieldName)), TimeZone="UTC");
end
end
