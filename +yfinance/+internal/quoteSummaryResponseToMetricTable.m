% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = quoteSummaryResponseToMetricTable(response, options)
%QUOTESUMMARYRESPONSETOMETRICTABLE Convert scalar module fields to metric rows.

arguments
    response struct
    options.Symbol (1,1) string = ""
    options.Module (1,1) string
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);

if ~isfield(result, options.Module) || isempty(result.(options.Module))
    data = emptyMetricTable(options.Symbol, options.Module);
    return
end

moduleData = yfinance.internal.unwrapYahooValue(result.(options.Module));
fieldNames = fieldnames(moduleData);
metric = strings(numel(fieldNames), 1);
value = cell(numel(fieldNames), 1);

for fieldIndex = 1:numel(fieldNames)
    fieldName = string(fieldNames{fieldIndex});
    metric(fieldIndex) = fieldName;
    value{fieldIndex} = moduleData.(fieldName);
end

data = table(metric, value, VariableNames={'Metric', 'Value'});
data.Properties.UserData = struct("Symbol", options.Symbol, "Module", options.Module);
end

function data = emptyMetricTable(symbol, module)
data = table(strings(0, 1), cell(0, 1), VariableNames={'Metric', 'Value'});
data.Properties.UserData = struct("Symbol", symbol, "Module", module);
end
