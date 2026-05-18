% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = sectorResponseToData(response, options)
%SECTORRESPONSETODATA Convert Yahoo sector domain data.

arguments
    response struct
    options.Key (1,1) string = ""
end

payload = domainData(response, "sector", options.Key);
data = commonDomainData(payload, options.Key);
data.TopETFs = symbolNameTable(fieldOrEmpty(payload, "topETFs"));
data.TopMutualFunds = symbolNameTable(fieldOrEmpty(payload, "topMutualFunds"));
data.Industries = industriesTable(fieldOrEmpty(payload, "industries"));
end

function data = commonDomainData(payload, key)
data = struct( ...
    "Key", key, ...
    "Name", stringField(payload, "name"), ...
    "Symbol", stringField(payload, "symbol"), ...
    "Overview", overviewStruct(fieldOrEmpty(payload, "overview")), ...
    "TopCompanies", yfinance.internal.yahooStructArrayToTable(fieldOrEmpty(payload, "topCompanies")), ...
    "ResearchReports", yfinance.internal.yahooStructArrayToTable(fieldOrEmpty(payload, "researchReports")), ...
    "Raw", payload);
end

function payload = domainData(response, dataDescription, key)
if ~isfield(response, "data") || isempty(response.data)
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain %s data for %s.", dataDescription, key);
end

payload = response.data;
end

function value = overviewStruct(overview)
value = struct( ...
    "CompaniesCount", numericField(overview, "companiesCount"), ...
    "MarketCap", rawField(overview, "marketCap"), ...
    "MessageBoardId", stringField(overview, "messageBoardId"), ...
    "Description", stringField(overview, "description"), ...
    "IndustriesCount", numericField(overview, "industriesCount"), ...
    "MarketWeight", rawField(overview, "marketWeight"), ...
    "EmployeeCount", rawField(overview, "employeeCount"));
end

function data = symbolNameTable(records)
records = normalizeRecords(records);
data = table(strings(numel(records), 1), strings(numel(records), 1), VariableNames=["Symbol", "Name"]);

for recordIndex = 1:numel(records)
    data.Symbol(recordIndex) = stringField(records(recordIndex), "symbol");
    data.Name(recordIndex) = stringField(records(recordIndex), "name");
end
end

function data = industriesTable(records)
records = normalizeRecords(records);
keys = strings(0, 1);
names = strings(0, 1);
symbols = strings(0, 1);
marketWeights = zeros(0, 1);

for recordIndex = 1:numel(records)
    name = stringField(records(recordIndex), "name");

    if name == "All Industries"
        continue
    end

    keys(end + 1, 1) = stringField(records(recordIndex), "key"); %#ok<AGROW>
    names(end + 1, 1) = name; %#ok<AGROW>
    symbols(end + 1, 1) = stringField(records(recordIndex), "symbol"); %#ok<AGROW>
    marketWeights(end + 1, 1) = rawField(records(recordIndex), "marketWeight"); %#ok<AGROW>
end

data = table(keys, names, symbols, marketWeights, VariableNames=["Key", "Name", "Symbol", "MarketWeight"]);
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

function value = fieldOrEmpty(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = inputStruct.(fieldName);
else
    value = struct.empty(0, 1);
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

function value = rawField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = yfinance.internal.unwrapYahooValue(inputStruct.(fieldName));
else
    value = NaN;
end
end
