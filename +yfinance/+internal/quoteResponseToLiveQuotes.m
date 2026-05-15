function data = quoteResponseToLiveQuotes(response, options)
%QUOTERESPONSETOLIVEQUOTES Convert Yahoo quote snapshots to a table.

arguments
    response struct
    options.Symbols (:,1) string = strings(0, 1)
end

if ~isfield(response, "quoteResponse") || isempty(response.quoteResponse)
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a quoteResponse payload.");
end

payload = response.quoteResponse;

if isfield(payload, "error") && ~isempty(payload.error)
    error("yfinance:YahooError", "Yahoo Finance returned a quote error for live quotes.");
end

if ~isfield(payload, "result") || isempty(payload.result)
    data = table();
    data.Properties.UserData = struct("Symbols", options.Symbols);
    return
end

data = yfinance.internal.yahooStructArrayToTable(payload.result);
data.Properties.UserData = struct("Symbols", options.Symbols);
end
