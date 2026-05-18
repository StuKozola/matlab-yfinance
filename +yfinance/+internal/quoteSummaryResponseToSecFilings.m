% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = quoteSummaryResponseToSecFilings(response, options)
%QUOTESUMMARYRESPONSETOSECFILINGS Convert Yahoo SEC filing records to a table.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);

if ~isfield(result, "secFilings") || isempty(result.secFilings) || ...
        ~isfield(result.secFilings, "filings") || isempty(result.secFilings.filings)
    data = emptySecFilingsTable(options.Symbol);
    return
end

filings = normalizeFilings(result.secFilings.filings);
rowCount = numel(filings);
filingDate = NaT(rowCount, 1, TimeZone="UTC");
epochDate = NaT(rowCount, 1, TimeZone="UTC");
formType = strings(rowCount, 1);
title = strings(rowCount, 1);
edgarUrl = strings(rowCount, 1);
exhibits = cell(rowCount, 1);

for rowIndex = 1:rowCount
    filing = filings{rowIndex};
    filingDate(rowIndex) = filingDateField(filing, "date");
    epochDate(rowIndex) = epochDateField(filing, "epochDate");
    formType(rowIndex) = stringField(filing, "type");
    title(rowIndex) = stringField(filing, "title");
    edgarUrl(rowIndex) = stringField(filing, "edgarUrl");
    exhibits{rowIndex} = exhibitsTable(filing);
end

data = table(filingDate, epochDate, formType, title, edgarUrl, exhibits, VariableNames={ ...
    'Date', ...
    'EpochDate', ...
    'Type', ...
    'Title', ...
    'EdgarUrl', ...
    'Exhibits'});
data.Properties.UserData = struct("Symbol", options.Symbol, "Module", "secFilings");
end

function filings = normalizeFilings(filings)
if iscell(filings)
    filings = filings(:);
else
    filings = num2cell(filings(:));
end
end

function value = filingDateField(inputStruct, fieldName)
value = NaT(1, 1, TimeZone="UTC");

if ~isfield(inputStruct, fieldName) || isempty(inputStruct.(fieldName))
    return
end

rawValue = yfinance.internal.unwrapYahooValue(inputStruct.(fieldName));

if isstring(rawValue) || ischar(rawValue)
    value = datetime(string(rawValue), InputFormat="yyyy-MM-dd", TimeZone="UTC");
elseif isnumeric(rawValue) && ~isempty(rawValue)
    value = datetime(double(rawValue), ConvertFrom="posixtime", TimeZone="UTC");
end
end

function value = epochDateField(inputStruct, fieldName)
value = NaT(1, 1, TimeZone="UTC");

if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    rawValue = yfinance.internal.unwrapYahooValue(inputStruct.(fieldName));

    if isnumeric(rawValue) && ~isempty(rawValue)
        value = datetime(double(rawValue), ConvertFrom="posixtime", TimeZone="UTC");
    end
end
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(yfinance.internal.unwrapYahooValue(inputStruct.(fieldName)));
else
    value = missing;
end
end

function data = exhibitsTable(filing)
if ~isfield(filing, "exhibits") || isempty(filing.exhibits)
    data = emptyExhibitsTable();
    return
end

exhibits = filing.exhibits;

if iscell(exhibits)
    exhibits = exhibits(:);
else
    exhibits = num2cell(exhibits(:));
end

rowCount = numel(exhibits);
type = strings(rowCount, 1);
url = strings(rowCount, 1);

for rowIndex = 1:rowCount
    type(rowIndex) = stringField(exhibits{rowIndex}, "type");
    url(rowIndex) = stringField(exhibits{rowIndex}, "url");
end

data = table(type, url, VariableNames={'Type', 'Url'});
end

function data = emptySecFilingsTable(symbol)
data = table( ...
    NaT(0, 1, TimeZone="UTC"), ...
    NaT(0, 1, TimeZone="UTC"), ...
    strings(0, 1), ...
    strings(0, 1), ...
    strings(0, 1), ...
    cell(0, 1), ...
    VariableNames={'Date', 'EpochDate', 'Type', 'Title', 'EdgarUrl', 'Exhibits'});
data.Properties.UserData = struct("Symbol", symbol, "Module", "secFilings");
end

function data = emptyExhibitsTable()
data = table(strings(0, 1), strings(0, 1), VariableNames={'Type', 'Url'});
end
