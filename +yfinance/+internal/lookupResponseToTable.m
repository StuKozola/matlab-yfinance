% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = lookupResponseToTable(response, options)
%LOOKUPRESPONSETOTABLE Convert Yahoo lookup responses to a MATLAB table.

arguments
    response struct
    options.Query (1,1) string = ""
    options.Type (1,1) string = "all"
end

if ~isfield(response, "finance") || isempty(response.finance)
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a finance payload.");
end

finance = response.finance;

if isfield(finance, "error") && ~isempty(finance.error)
    error("yfinance:YahooError", "Yahoo Finance returned a lookup error for %s.", options.Query);
end

documents = struct.empty(0, 1);

if isfield(finance, "result") && ~isempty(finance.result)
    result = firstElement(finance.result);

    if isfield(result, "documents") && ~isempty(result.documents)
        documents = result.documents;
    end
end

data = yfinance.internal.yahooStructArrayToTable(documents);
data.Properties.UserData = struct("Query", options.Query, "Type", options.Type);
end

function value = firstElement(value)
if iscell(value)
    value = value{1};
else
    value = value(1);
end
end
