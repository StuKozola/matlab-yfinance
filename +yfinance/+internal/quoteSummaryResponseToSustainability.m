function data = quoteSummaryResponseToSustainability(response, options)
%QUOTESUMMARYRESPONSETOSUSTAINABILITY Convert Yahoo ESG scores to a struct.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
data = struct("Symbol", options.Symbol);

if ~isfield(result, "esgScores") || isempty(result.esgScores)
    data.Raw = struct();
    return
end

data.Raw = result.esgScores;
scores = yfinance.internal.unwrapYahooValue(result.esgScores);
fieldNames = fieldnames(scores);

for fieldIndex = 1:numel(fieldNames)
    sourceName = string(fieldNames{fieldIndex});
    data.(yfinance.internal.pascalFieldName(sourceName)) = scores.(sourceName);
end
end
