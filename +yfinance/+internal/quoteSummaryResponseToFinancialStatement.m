% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = quoteSummaryResponseToFinancialStatement(response, options)
%QUOTESUMMARYRESPONSETOFINANCIALSTATEMENT Convert Yahoo statements to a table.

arguments
    response struct
    options.Symbol (1,1) string = ""
    options.Module (1,1) string
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
moduleName = options.Module;

if ~isfield(result, moduleName) || isempty(result.(moduleName))
    data = emptyStatementTable();
    return
end

moduleData = result.(moduleName);
statements = statementArray(moduleData, moduleName);
data = statementTable(statements);
data.Properties.UserData = struct("Symbol", options.Symbol, "Module", moduleName);
end

function statements = statementArray(moduleData, moduleName)
statementField = statementFieldForModule(moduleName);

if ~isfield(moduleData, statementField) || isempty(moduleData.(statementField))
    statements = struct.empty(0, 1);
    return
end

statements = moduleData.(statementField);

if iscell(statements)
    statements = [statements{:}];
end

statements = statements(:);
end

function fieldName = statementFieldForModule(moduleName)
moduleName = lower(string(moduleName));

if startsWith(moduleName, "income")
    fieldName = "incomeStatementHistory";
elseif startsWith(moduleName, "balance")
    fieldName = "balanceSheetStatements";
elseif startsWith(moduleName, "cashflow")
    fieldName = "cashflowStatements";
else
    error("yfinance:InvalidStatement", "Unsupported financial statement module: %s.", moduleName);
end
end

function data = statementTable(statements)
if isempty(statements)
    data = emptyStatementTable();
    return
end

fieldNames = statementFieldNames(statements);
rowCount = numel(statements);
endDate = NaT(rowCount, 1, TimeZone="UTC");
columns = containers.Map("KeyType", "char", "ValueType", "any");

for fieldIndex = 1:numel(fieldNames)
    columns(fieldNames{fieldIndex}) = NaN(rowCount, 1);
end

for rowIndex = 1:rowCount
    statement = statements(rowIndex);
    endDate(rowIndex) = statementEndDate(statement);

    for fieldIndex = 1:numel(fieldNames)
        fieldName = fieldNames{fieldIndex};

        if isfield(statement, fieldName) && ~isempty(statement.(fieldName))
            values = columns(fieldName);
            values(rowIndex) = numericValue(statement.(fieldName));
            columns(fieldName) = values;
        end
    end
end

data = table(endDate, VariableNames={'EndDate'});

for fieldIndex = 1:numel(fieldNames)
    fieldName = fieldNames{fieldIndex};
    variableName = upperFirst(fieldName);
    data.(variableName) = columns(fieldName);
end
end

function fieldNames = statementFieldNames(statements)
fieldNames = strings(0, 1);

for rowIndex = 1:numel(statements)
    names = string(fieldnames(statements(rowIndex)));
    fieldNames = [fieldNames; names(:)]; %#ok<AGROW>
end

fieldNames = unique(fieldNames, "stable");
fieldNames(ismember(fieldNames, ["maxAge", "endDate"])) = [];
fieldNames = cellstr(fieldNames);
end

function value = statementEndDate(statement)
value = NaT(1, 1, TimeZone="UTC");

if ~isfield(statement, "endDate") || isempty(statement.endDate)
    return
end

rawValue = yfinance.internal.unwrapYahooValue(statement.endDate);

if isnumeric(rawValue) && ~isempty(rawValue)
    value = datetime(double(rawValue), ConvertFrom="posixtime", TimeZone="UTC");
end
end

function value = numericValue(inputValue)
inputValue = yfinance.internal.unwrapYahooValue(inputValue);

if isnumeric(inputValue) && ~isempty(inputValue)
    value = double(inputValue);
else
    value = NaN;
end
end

function value = upperFirst(value)
value = string(value);
value = upper(extractBetween(value, 1, 1)) + extractAfter(value, 1);
value = matlab.lang.makeValidName(value);
value = char(value);
end

function data = emptyStatementTable()
data = table(NaT(0, 1, TimeZone="UTC"), VariableNames={'EndDate'});
end
