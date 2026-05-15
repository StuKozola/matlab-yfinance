function result = screenerResponseToResult(response, options)
%SCREENERRESPONSETORESULT Convert Yahoo screener responses to MATLAB data.

arguments
    response struct
    options.Query (1,1) string = ""
end

if ~isfield(response, "finance") || isempty(response.finance)
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a finance payload.");
end

finance = response.finance;

if isfield(finance, "error") && ~isempty(finance.error)
    error("yfinance:YahooError", "Yahoo Finance returned a screener error for %s.", options.Query);
end

result = struct();
result.Query = options.Query;
result.Title = "";
result.Description = "";
result.Start = NaN;
result.Count = NaN;
result.Total = NaN;
result.Quotes = table();
result.Raw = struct();

if ~isfield(finance, "result") || isempty(finance.result)
    return
end

rawResult = firstResult(finance.result);
result.Raw = rawResult;
result.Title = stringField(rawResult, "title");
result.Description = stringField(rawResult, "description");
result.Start = numericField(rawResult, "start");
result.Count = numericField(rawResult, "count");
result.Total = numericField(rawResult, "total");

if isfield(rawResult, "quotes") && ~isempty(rawResult.quotes)
    result.Quotes = yfinance.internal.yahooStructArrayToTable(rawResult.quotes);
end
end

function result = firstResult(results)
if iscell(results)
    result = results{1};
else
    result = results(1);
end
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(inputStruct.(fieldName));
else
    value = "";
end
end

function value = numericField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName)) && isnumeric(inputStruct.(fieldName))
    value = double(inputStruct.(fieldName));
else
    value = NaN;
end
end
