function result = quoteSummaryResult(response, options)
%QUOTESUMMARYRESULT Extract the first Yahoo quoteSummary result.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

if ~isfield(response, "quoteSummary")
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a quoteSummary payload.");
end

quoteSummary = response.quoteSummary;

if isfield(quoteSummary, "error") && ~isempty(quoteSummary.error)
    error("yfinance:YahooError", "Yahoo Finance returned a quote summary error for %s.", options.Symbol);
end

if ~isfield(quoteSummary, "result") || isempty(quoteSummary.result)
    error("yfinance:NoData", "Yahoo Finance returned no quote summary data for %s.", options.Symbol);
end

result = quoteSummary.result;

if iscell(result)
    result = result{1};
elseif numel(result) > 1
    result = result(1);
end
end
