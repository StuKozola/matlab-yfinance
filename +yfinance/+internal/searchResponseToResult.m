% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function result = searchResponseToResult(response, options)
%SEARCHRESPONSETORESULT Convert Yahoo search response to MATLAB tables.

arguments
    response struct
    options.Query (1,1) string = ""
end

result = struct();
result.Query = options.Query;
result.Quotes = quotesTable(fieldOrDefault(response, "quotes", struct.empty(0, 1)));
result.News = newsTable(fieldOrDefault(response, "news", struct.empty(0, 1)));
result.Lists = genericTable(fieldOrDefault(response, "lists", struct.empty(0, 1)), "lists");
result.Research = genericTable(fieldOrDefault(response, "researchReports", struct.empty(0, 1)), "researchReports");
result.Nav = genericTable(fieldOrDefault(response, "nav", struct.empty(0, 1)), "nav");
result.All = struct( ...
    "Quotes", result.Quotes, ...
    "News", result.News, ...
    "Lists", result.Lists, ...
    "Research", result.Research, ...
    "Nav", result.Nav);
result.Response = response;
result.Raw = response;
end

function data = quotesTable(quotes)
quotes = normalizeStructArray(quotes);
rowCount = numel(quotes);

symbol = strings(rowCount, 1);
shortName = strings(rowCount, 1);
longName = strings(rowCount, 1);
quoteType = strings(rowCount, 1);
exchange = strings(rowCount, 1);
score = NaN(rowCount, 1);
type = strings(rowCount, 1);

for rowIndex = 1:rowCount
    item = quotes{rowIndex};
    symbol(rowIndex) = stringField(item, "symbol");
    shortName(rowIndex) = stringField(item, "shortname");
    longName(rowIndex) = stringField(item, "longname");
    quoteType(rowIndex) = stringField(item, "quoteType");
    exchange(rowIndex) = stringField(item, "exchange");
    score(rowIndex) = numericField(item, "score");
    type(rowIndex) = stringField(item, "typeDisp");
end

data = table( ...
    symbol, ...
    shortName, ...
    longName, ...
    quoteType, ...
    exchange, ...
    score, ...
    type, ...
    VariableNames={'Symbol', 'ShortName', 'LongName', 'QuoteType', 'Exchange', 'Score', 'Type'});
end

function data = newsTable(news)
news = normalizeStructArray(news);
rowCount = numel(news);

title = strings(rowCount, 1);
publisher = strings(rowCount, 1);
link = strings(rowCount, 1);
providerPublishTime = NaT(rowCount, 1, TimeZone="UTC");
type = strings(rowCount, 1);
uuid = strings(rowCount, 1);

for rowIndex = 1:rowCount
    item = news{rowIndex};
    title(rowIndex) = stringField(item, "title");
    publisher(rowIndex) = stringField(item, "publisher");
    link(rowIndex) = stringField(item, "link");
    providerPublishTime(rowIndex) = datetimeField(item, "providerPublishTime");
    type(rowIndex) = stringField(item, "type");
    uuid(rowIndex) = stringField(item, "uuid");
end

data = table( ...
    title, ...
    publisher, ...
    link, ...
    providerPublishTime, ...
    type, ...
    uuid, ...
    VariableNames={'Title', 'Publisher', 'Link', 'ProviderPublishTime', 'Type', 'UUID'});
end

function data = genericTable(records, moduleName)
data = yfinance.internal.yahooStructArrayToTable(records, Module=moduleName);
end

function value = fieldOrDefault(inputStruct, fieldName, defaultValue)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = inputStruct.(fieldName);
else
    value = defaultValue;
end
end

function items = normalizeStructArray(items)
if isempty(items)
    items = cell(0, 1);
elseif iscell(items)
    items = items(:);
elseif isstruct(items)
    items = num2cell(items(:));
else
    items = cell(0, 1);
end
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(inputStruct.(fieldName));
else
    value = missing;
end
end

function value = numericField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = double(inputStruct.(fieldName));
else
    value = NaN;
end
end

function value = datetimeField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = datetime(double(inputStruct.(fieldName)), ConvertFrom="posixtime", TimeZone="UTC");
else
    value = NaT(1, 1, TimeZone="UTC");
end
end
