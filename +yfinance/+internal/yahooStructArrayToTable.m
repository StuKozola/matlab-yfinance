% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = yahooStructArrayToTable(records, options)
%YAHOOSTRUCTARRAYTOTABLE Convert Yahoo struct records to a MATLAB table.

arguments
    records = struct.empty(0, 1)
    options.Symbol (1,1) string = ""
    options.Module (1,1) string = ""
end

records = normalizeRecords(records);

if isempty(records)
    data = table();
    data.Properties.UserData = struct("Symbol", options.Symbol, "Module", options.Module);
    return
end

fieldNames = recordFieldNames(records);
rowCount = numel(records);
data = table();

for fieldIndex = 1:numel(fieldNames)
    fieldName = fieldNames(fieldIndex);
    values = cell(rowCount, 1);

    for rowIndex = 1:rowCount
        if isfield(records(rowIndex), fieldName) && ~isempty(records(rowIndex).(fieldName))
            values{rowIndex} = yfinance.internal.unwrapYahooValue(records(rowIndex).(fieldName));
        end
    end

    data.(yfinance.internal.pascalFieldName(fieldName)) = normalizeColumn(values, fieldName);
end

data.Properties.UserData = struct("Symbol", options.Symbol, "Module", options.Module);
end

function records = normalizeRecords(records)
if iscell(records)
    if isempty(records)
        records = struct.empty(0, 1);
    else
        records = normalizeRecordCells(records);
    end
end

records = records(:);
end

function records = normalizeRecordCells(recordCells)
recordCells = recordCells(:);
fieldNames = strings(0, 1);

for recordIndex = 1:numel(recordCells)
    fieldNames = [fieldNames; string(fieldnames(recordCells{recordIndex}))]; %#ok<AGROW>
end

fieldNames = unique(fieldNames, "stable");
template = cell2struct(cell(numel(fieldNames), 1), cellstr(fieldNames), 1);
records = repmat(template, numel(recordCells), 1);

for recordIndex = 1:numel(recordCells)
    record = recordCells{recordIndex};
    names = fieldnames(record);

    for fieldIndex = 1:numel(names)
        records(recordIndex).(names{fieldIndex}) = record.(names{fieldIndex});
    end
end
end

function fieldNames = recordFieldNames(records)
fieldNames = strings(0, 1);

for recordIndex = 1:numel(records)
    fieldNames = [fieldNames; string(fieldnames(records(recordIndex)))]; %#ok<AGROW>
end

fieldNames = unique(fieldNames, "stable");
end

function column = normalizeColumn(values, fieldName)
nonemptyValues = values(~cellfun(@isempty, values));

if isempty(nonemptyValues)
    column = cell(size(values));
elseif isUnixDateColumn(nonemptyValues, fieldName)
    column = datetimeColumn(values);
elseif all(cellfun(@isScalarNumeric, nonemptyValues))
    column = numericColumn(values);
elseif all(cellfun(@isScalarText, nonemptyValues))
    column = stringColumn(values);
else
    column = values;
end
end

function value = isUnixDateColumn(values, fieldName)
lowerFieldName = lower(fieldName);
value = (endsWith(lowerFieldName, "date") || endsWith(lowerFieldName, "time")) && ...
    all(cellfun(@isScalarNumeric, values));
end

function column = datetimeColumn(values)
column = NaT(numel(values), 1, TimeZone="UTC");

for valueIndex = 1:numel(values)
    if ~isempty(values{valueIndex})
        column(valueIndex) = datetime(double(values{valueIndex}), ConvertFrom="posixtime", TimeZone="UTC");
    end
end
end

function column = numericColumn(values)
column = NaN(numel(values), 1);

for valueIndex = 1:numel(values)
    if ~isempty(values{valueIndex})
        column(valueIndex) = double(values{valueIndex});
    end
end
end

function column = stringColumn(values)
column = strings(numel(values), 1);

for valueIndex = 1:numel(values)
    if isempty(values{valueIndex})
        column(valueIndex) = missing;
    else
        column(valueIndex) = string(values{valueIndex});
    end
end
end

function value = isScalarNumeric(value)
value = isnumeric(value) && isscalar(value);
end

function value = isScalarText(value)
value = (isstring(value) || ischar(value)) && isscalar(string(value));
end
