% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function info = quoteSummaryResponseToInfo(response, options)
%QUOTESUMMARYRESPONSETOINFO Convert Yahoo quoteSummary modules to a struct.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
info = struct("Symbol", options.Symbol);
moduleNames = fieldnames(result);

for moduleIndex = 1:numel(moduleNames)
    moduleName = moduleNames{moduleIndex};
    moduleValue = result.(moduleName);

    if isempty(moduleValue) || ~isstruct(moduleValue)
        continue
    end

    info.(matlab.lang.makeValidName(moduleName)) = yfinance.internal.unwrapYahooValue(moduleValue);
    info = mergeModuleFields(info, moduleValue);
end

info.Raw = result;
end

function info = mergeModuleFields(info, moduleValue)
fieldNames = fieldnames(moduleValue);

for fieldIndex = 1:numel(fieldNames)
    sourceName = fieldNames{fieldIndex};
    targetName = matlab.lang.makeValidName(sourceName);

    if isfield(info, targetName)
        continue
    end

    info.(targetName) = yfinance.internal.unwrapYahooValue(moduleValue.(sourceName));
end
end
