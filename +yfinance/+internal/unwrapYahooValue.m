% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function value = unwrapYahooValue(value)
%UNWRAPYAHOOVALUE Convert Yahoo formatted values to plain MATLAB values.

if isstruct(value)
    if isScalarFormattedValue(value)
        value = formattedRawValue(value);
        return
    end

    fieldNames = fieldnames(value);
    output = struct();

    for fieldIndex = 1:numel(fieldNames)
        fieldName = fieldNames{fieldIndex};
        output.(matlab.lang.makeValidName(fieldName)) = yfinance.internal.unwrapYahooValue(value.(fieldName));
    end

    value = output;
elseif iscell(value)
    value = unwrapCell(value);
end
end

function value = unwrapCell(value)
if isempty(value)
    value = strings(0, 1);
    return
end

if all(cellfun(@ischar, value))
    value = string(value);
    return
end

for valueIndex = 1:numel(value)
    value{valueIndex} = yfinance.internal.unwrapYahooValue(value{valueIndex});
end
end

function value = isScalarFormattedValue(inputStruct)
fields = string(fieldnames(inputStruct));
value = isscalar(inputStruct) && any(fields == "raw") && (any(fields == "fmt") || any(fields == "longFmt"));
end

function value = formattedRawValue(inputStruct)
if isfield(inputStruct, "raw") && ~isempty(inputStruct.raw)
    value = inputStruct.raw;
elseif isfield(inputStruct, "fmt") && ~isempty(inputStruct.fmt)
    value = string(inputStruct.fmt);
elseif isfield(inputStruct, "longFmt") && ~isempty(inputStruct.longFmt)
    value = string(inputStruct.longFmt);
else
    value = [];
end
end
