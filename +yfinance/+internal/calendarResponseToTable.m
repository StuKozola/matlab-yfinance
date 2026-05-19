% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = calendarResponseToTable(response, options)
%CALENDARRESPONSETOTABLE Convert Yahoo calendar visualization data to a table.

arguments
    response struct
    options.CalendarType (1,1) string {mustBeNonzeroLengthText}
end

definition = yfinance.internal.calendarDefinition(options.CalendarType);
document = firstDocument(response);

if isempty(fieldnames(document))
    data = table();
    data.Properties.UserData = struct("CalendarType", definition.CalendarType);
    return
end

columns = normalizeStructs(fieldOrDefault(document, "columns", struct.empty(0, 1)));
variableNames = variableNamesFromColumns(columns);
rows = normalizeRows(fieldOrDefault(document, "rows", {}), numel(variableNames));
data = table();

for variableIndex = 1:numel(variableNames)
    variableName = variableNames(variableIndex);
    values = rows(:, variableIndex);

    if ismember(variableName, definition.DatetimeColumns)
        data.(variableName) = datetimeColumn(values);
    elseif ismember(variableName, definition.NumericColumns)
        column = numericColumn(values);

        if ismember(variableName, definition.ZeroAsMissingColumns)
            column(column == 0) = NaN;
        end

        data.(variableName) = column;
    else
        data.(variableName) = inferredColumn(values);
    end
end

data.Properties.UserData = struct("CalendarType", definition.CalendarType);
end

function document = firstDocument(response)
document = struct();

if ~isfield(response, "finance") || isempty(response.finance)
    return
end

finance = response.finance;

if isfield(finance, "error") && ~isempty(finance.error)
    error("yfinance:YahooError", "Yahoo Finance returned a calendar error.");
end

if ~isfield(finance, "result") || isempty(finance.result)
    return
end

result = firstElement(finance.result);

if ~isfield(result, "documents") || isempty(result.documents)
    return
end

document = firstElement(result.documents);
end

function value = firstElement(value)
if iscell(value)
    value = value{1};
else
    value = value(1);
end
end

function value = fieldOrDefault(input, fieldName, defaultValue)
if isstruct(input) && isfield(input, fieldName) && ~isempty(input.(fieldName))
    value = input.(fieldName);
else
    value = defaultValue;
end
end

function records = normalizeStructs(records)
if iscell(records)
    records = normalizeStructCells(records);
end

records = records(:);
end

function records = normalizeStructCells(recordCells)
recordCells = recordCells(:);
fieldNames = strings(0, 1);

for recordIndex = 1:numel(recordCells)
    if isstruct(recordCells{recordIndex})
        fieldNames = [fieldNames; string(fieldnames(recordCells{recordIndex}))]; %#ok<AGROW>
    end
end

fieldNames = unique(fieldNames, "stable");

if isempty(fieldNames)
    records = struct.empty(0, 1);
    return
end

template = cell2struct(cell(numel(fieldNames), 1), cellstr(fieldNames), 1);
records = repmat(template, numel(recordCells), 1);

for recordIndex = 1:numel(recordCells)
    record = recordCells{recordIndex};

    if ~isstruct(record)
        continue
    end

    names = fieldnames(record);

    for fieldIndex = 1:numel(names)
        records(recordIndex).(names{fieldIndex}) = record.(names{fieldIndex});
    end
end
end

function variableNames = variableNamesFromColumns(columns)
variableNames = strings(numel(columns), 1);
eventStartDateCount = 0;

for columnIndex = 1:numel(columns)
    label = string(fieldOrDefault(columns(columnIndex), "label", "Variable" + columnIndex));
    columnType = string(fieldOrDefault(columns(columnIndex), "type", ""));

    if label == "Event Start Date"
        eventStartDateCount = eventStartDateCount + 1;

        if eventStartDateCount > 1 || columnType == "STRING"
            label = "Timing";
        end
    end

    variableNames(columnIndex) = canonicalLabel(label);
end

variableNames = matlab.lang.makeValidName(variableNames);
variableNames = matlab.lang.makeUniqueStrings(variableNames);
end

function label = canonicalLabel(label)
switch label
    case "Symbol"
        label = "Symbol";
    case "Company Name"
        label = "Company";
    case "Market Cap (Intraday)"
        label = "MarketCap";
    case "Event Name"
        label = "EventName";
    case "Event Start Date"
        label = "EventStartDate";
    case "EPS Estimate"
        label = "EPSEstimate";
    case "Reported EPS"
        label = "ReportedEPS";
    case "Surprise (%)"
        label = "SurprisePercent";
    case "Exchange Short Name"
        label = "Exchange";
    case "Proposed Ticker Symbol"
        label = "ProposedTickerSymbol";
    case "Proposed Exchange Symbol"
        label = "ProposedExchangeSymbol";
    case "Shares Offered"
        label = "SharesOffered";
    case "Proposed Share Price"
        label = "ProposedSharePrice";
    case "Priced Date"
        label = "PricedDate";
    case "Dollar Value of Shares Offered"
        label = "DollarValueOfSharesOffered";
    case "Country Code"
        label = "Country";
    case "Timezone Short Name"
        label = "TimeZone";
    case "GMT Offset Milliseconds"
        label = "GmtOffsetMilliseconds";
    case "Market Expectation"
        label = "Consensus";
    case "Prior to This"
        label = "Previous";
    case "Revised from"
        label = "Revised";
    case "Optionable?"
        label = "Optionable";
    otherwise
        label = regexprep(label, "[^\w]", " ");
end
end

function rows = normalizeRows(rows, columnCount)
if columnCount == 0
    rows = cell(0, 0);
    return
end

if isempty(rows)
    rows = cell(0, columnCount);
    return
end

if iscell(rows)
    rows = cellRows(rows, columnCount);
elseif isnumeric(rows) || islogical(rows)
    rows = num2cell(rows);
else
    rows = {rows};
end

if size(rows, 2) ~= columnCount
    rows = reshapeRows(rows, columnCount);
end
end

function rows = cellRows(rows, columnCount)
if all(cellfun(@iscell, rows(:)))
    rowCells = rows(:);
    rows = cell(numel(rowCells), columnCount);

    for rowIndex = 1:numel(rowCells)
        row = rowCells{rowIndex};
        row = row(:).';
        rows(rowIndex, 1:min(columnCount, numel(row))) = row(1:min(columnCount, numel(row)));
    end
elseif isvector(rows) && numel(rows) == columnCount
    rows = rows(:).';
end
end

function rows = reshapeRows(rows, columnCount)
if isvector(rows) && mod(numel(rows), columnCount) == 0
    rows = reshape(rows, columnCount, []).';
else
    rowCount = size(rows, 1);
    output = cell(rowCount, columnCount);
    output(:, 1:min(columnCount, size(rows, 2))) = rows(:, 1:min(columnCount, size(rows, 2)));
    rows = output;
end
end

function column = inferredColumn(values)
nonemptyValues = values(~cellfun(@isempty, values));

if isempty(nonemptyValues)
    column = strings(numel(values), 1);
    column(:) = missing;
elseif all(cellfun(@isScalarNumeric, nonemptyValues))
    column = numericColumn(values);
elseif all(cellfun(@isScalarLogical, nonemptyValues))
    column = logicalColumn(values);
else
    column = stringColumn(values);
end
end

function column = numericColumn(values)
column = NaN(numel(values), 1);

for valueIndex = 1:numel(values)
    if isempty(values{valueIndex})
        continue
    end

    value = values{valueIndex};

    if isnumeric(value) || islogical(value)
        column(valueIndex) = double(value);
    else
        text = erase(string(value), ",");
        column(valueIndex) = str2double(text);
    end
end
end

function column = logicalColumn(values)
column = false(numel(values), 1);

for valueIndex = 1:numel(values)
    if ~isempty(values{valueIndex})
        column(valueIndex) = logical(values{valueIndex});
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

function column = datetimeColumn(values)
column = NaT(numel(values), 1, TimeZone="UTC");

for valueIndex = 1:numel(values)
    if isempty(values{valueIndex})
        continue
    end

    column(valueIndex) = singleDatetime(values{valueIndex});
end
end

function value = singleDatetime(inputValue)
if isdatetime(inputValue)
    value = inputValue;

    if strlength(string(value.TimeZone)) == 0
        value.TimeZone = "UTC";
    end

    return
end

if isnumeric(inputValue) && isscalar(inputValue)
    value = datetime(double(inputValue), ConvertFrom="posixtime", TimeZone="UTC");
    return
end

text = strtrim(string(inputValue));
formats = [
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    "yyyy-MM-dd'T'HH:mm:ss'Z'"
    "yyyy-MM-dd HH:mm:ss"
    "yyyy-MM-dd"];

for formatIndex = 1:numel(formats)
    try
        value = datetime(text, InputFormat=formats(formatIndex), TimeZone="UTC");
        return
    catch
    end
end

try
    value = datetime(text, TimeZone="UTC");
catch
    value = NaT(1, 1, TimeZone="UTC");
end
end

function value = isScalarNumeric(value)
value = isnumeric(value) && isscalar(value);
end

function value = isScalarLogical(value)
value = islogical(value) && isscalar(value);
end
