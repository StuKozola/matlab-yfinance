function expirations = optionsResponseToExpirations(response, options)
%OPTIONSRESPONSETOEXPIRATIONS Convert Yahoo options expirations to datetimes.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = optionResult(response, options.Symbol);

if ~isfield(result, "expirationDates") || isempty(result.expirationDates)
    expirations = NaT(0, 1, TimeZone="UTC");
    return
end

expirationDates = double(result.expirationDates(:));
expirations = datetime(expirationDates, ConvertFrom="posixtime", TimeZone="UTC");
expirations = expirations(:);
end

function result = optionResult(response, symbol)
if ~isfield(response, "optionChain")
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain an optionChain payload.");
end

optionChain = response.optionChain;

if isfield(optionChain, "error") && ~isempty(optionChain.error)
    error("yfinance:YahooError", "Yahoo Finance returned an options error for %s.", symbol);
end

if ~isfield(optionChain, "result") || isempty(optionChain.result)
    error("yfinance:NoData", "Yahoo Finance returned no options data for %s.", symbol);
end

result = optionChain.result;

if iscell(result)
    result = result{1};
elseif numel(result) > 1
    result = result(1);
end
end
