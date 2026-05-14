function info = quoteResponseToFastInfo(response, options)
%QUOTERESPONSETOFASTINFO Convert a Yahoo quote response to a fastInfo struct.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

quote = selectQuote(response, options.Symbol);
info = struct();

info.Symbol = string(fieldOrDefault(quote, "symbol", options.Symbol));
info.Raw = quote;

info = copyField(info, quote, "currency", "Currency");
info = copyField(info, quote, "exchange", "Exchange");
info = copyField(info, quote, "exchangeTimezoneName", "ExchangeTimezoneName");
info = copyField(info, quote, "quoteType", "QuoteType");
info = copyField(info, quote, "shortName", "ShortName");
info = copyField(info, quote, "longName", "LongName");
info = copyField(info, quote, "regularMarketPrice", "LastPrice");
info = copyField(info, quote, "regularMarketPreviousClose", "PreviousClose");
info = copyField(info, quote, "regularMarketOpen", "Open");
info = copyField(info, quote, "regularMarketDayHigh", "DayHigh");
info = copyField(info, quote, "regularMarketDayLow", "DayLow");
info = copyField(info, quote, "regularMarketVolume", "Volume");
info = copyField(info, quote, "regularMarketTime", "LastTradeTime");
info = copyField(info, quote, "marketCap", "MarketCap");
info = copyField(info, quote, "averageDailyVolume10Day", "TenDayAverageVolume");
info = copyField(info, quote, "averageDailyVolume3Month", "ThreeMonthAverageVolume");
info = copyField(info, quote, "fiftyTwoWeekHigh", "FiftyTwoWeekHigh");
info = copyField(info, quote, "fiftyTwoWeekLow", "FiftyTwoWeekLow");

if isfield(info, "LastTradeTime") && isnumeric(info.LastTradeTime) && ~isempty(info.LastTradeTime)
    info.LastTradeTime = datetime(double(info.LastTradeTime), ConvertFrom="posixtime", TimeZone="UTC");
end
end

function quote = selectQuote(response, symbol)
if ~isfield(response, "quoteResponse")
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a quoteResponse payload.");
end

payload = response.quoteResponse;

if isfield(payload, "error") && ~isempty(payload.error)
    error("yfinance:YahooError", "Yahoo Finance returned a quote error for %s.", symbol);
end

if ~isfield(payload, "result") || isempty(payload.result)
    error("yfinance:NoData", "Yahoo Finance returned no quote data for %s.", symbol);
end

results = payload.result;

if iscell(results)
    results = [results{:}];
end

quote = results(1);

if symbol == ""
    return
end

for resultIndex = 1:numel(results)
    candidate = results(resultIndex);

    if isfield(candidate, "symbol") && strcmpi(string(candidate.symbol), symbol)
        quote = candidate;
        return
    end
end
end

function value = fieldOrDefault(inputStruct, fieldName, defaultValue)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = inputStruct.(fieldName);
else
    value = defaultValue;
end
end

function output = copyField(output, inputStruct, sourceName, targetName)
if isfield(inputStruct, sourceName) && ~isempty(inputStruct.(sourceName))
    output.(targetName) = inputStruct.(sourceName);
end
end
