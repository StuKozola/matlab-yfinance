function data = selectActionData(historyData, variables)
%SELECTACTIONDATA Select nonzero corporate-action rows from history data.

arguments
    historyData timetable
    variables (1,:) string = ["Dividends", "StockSplits", "CapitalGains"]
end

missingVariables = setdiff(variables, string(historyData.Properties.VariableNames));

if ~isempty(missingVariables)
    error( ...
        "yfinance:InvalidHistoryData", ...
        "History data is missing action variable(s): %s.", ...
        strjoin(missingVariables, ", "));
end

data = historyData(:, cellstr(variables));
rowMask = false(height(data), 1);

for variableIndex = 1:numel(variables)
    values = data.(variables(variableIndex));
    rowMask = rowMask | (~isnan(values) & values ~= 0);
end

data = data(rowMask, :);
end
