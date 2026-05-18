% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function targets = quoteSummaryResponseToAnalystPriceTargets(response, options)
%QUOTESUMMARYRESPONSETOANALYSTPRICETARGETS Convert analyst target fields.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
targets = struct("Symbol", options.Symbol);

if ~isfield(result, "financialData") || isempty(result.financialData)
    targets.Raw = struct();
    return
end

financialData = result.financialData;
targets.Raw = financialData;
targets = copyField(targets, financialData, "targetHighPrice", "TargetHighPrice");
targets = copyField(targets, financialData, "targetLowPrice", "TargetLowPrice");
targets = copyField(targets, financialData, "targetMeanPrice", "TargetMeanPrice");
targets = copyField(targets, financialData, "targetMedianPrice", "TargetMedianPrice");
targets = copyField(targets, financialData, "recommendationMean", "RecommendationMean");
targets = copyField(targets, financialData, "recommendationKey", "RecommendationKey");
targets = copyField(targets, financialData, "numberOfAnalystOpinions", "NumberOfAnalystOpinions");
end

function output = copyField(output, inputStruct, sourceName, targetName)
if isfield(inputStruct, sourceName) && ~isempty(inputStruct.(sourceName))
    output.(targetName) = yfinance.internal.unwrapYahooValue(inputStruct.(sourceName));
end
end
