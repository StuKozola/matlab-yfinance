% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = quoteSummaryResponseToShares(response, options)
%QUOTESUMMARYRESPONSETOSHARES Convert Yahoo share-count metrics to a table.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
metric = strings(0, 1);
value = NaN(0, 1);

[metric, value] = appendMetric(result, "defaultKeyStatistics", "sharesOutstanding", metric, value);
[metric, value] = appendMetric(result, "defaultKeyStatistics", "floatShares", metric, value);
[metric, value] = appendMetric(result, "defaultKeyStatistics", "impliedSharesOutstanding", metric, value);
[metric, value] = appendMetric(result, "defaultKeyStatistics", "heldPercentInsiders", metric, value);
[metric, value] = appendMetric(result, "defaultKeyStatistics", "heldPercentInstitutions", metric, value);
[metric, value] = appendMetric(result, "price", "marketCap", metric, value);

data = table(metric, value, VariableNames={'Metric', 'Value'});
data.Properties.UserData = struct("Symbol", options.Symbol, "Module", "shares");
end

function [metric, value] = appendMetric(result, moduleName, fieldName, metric, value)
if ~isfield(result, moduleName) || isempty(result.(moduleName))
    return
end

moduleData = result.(moduleName);

if ~isfield(moduleData, fieldName) || isempty(moduleData.(fieldName))
    return
end

rawValue = yfinance.internal.unwrapYahooValue(moduleData.(fieldName));

if ~isnumeric(rawValue) || isempty(rawValue)
    return
end

metric(end + 1, 1) = fieldName;
value(end + 1, 1) = double(rawValue);
end
