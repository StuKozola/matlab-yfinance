% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = quoteSummaryResponseToUpgradesDowngrades(response, options)
%QUOTESUMMARYRESPONSETOUPGRADESDOWNGRADES Convert analyst grade changes.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);

if ~isfield(result, "upgradeDowngradeHistory") || isempty(result.upgradeDowngradeHistory) || ...
        ~isfield(result.upgradeDowngradeHistory, "history") || isempty(result.upgradeDowngradeHistory.history)
    data = emptyUpgradesDowngradesTable(options.Symbol);
    return
end

history = result.upgradeDowngradeHistory.history;

if iscell(history)
    history = [history{:}];
end

rowCount = numel(history);
gradeDate = NaT(rowCount, 1, TimeZone="UTC");
firm = strings(rowCount, 1);
toGrade = strings(rowCount, 1);
fromGrade = strings(rowCount, 1);
action = strings(rowCount, 1);

for rowIndex = 1:rowCount
    item = history(rowIndex);
    gradeDate(rowIndex) = dateField(item, "epochGradeDate");
    firm(rowIndex) = stringField(item, "firm");
    toGrade(rowIndex) = stringField(item, "toGrade");
    fromGrade(rowIndex) = stringField(item, "fromGrade");
    action(rowIndex) = stringField(item, "action");
end

data = table(gradeDate, firm, toGrade, fromGrade, action, VariableNames={ ...
    'GradeDate', ...
    'Firm', ...
    'ToGrade', ...
    'FromGrade', ...
    'Action'});
data.Properties.UserData = struct("Symbol", options.Symbol, "Module", "upgradeDowngradeHistory");
end

function data = emptyUpgradesDowngradesTable(symbol)
data = table( ...
    NaT(0, 1, TimeZone="UTC"), ...
    strings(0, 1), ...
    strings(0, 1), ...
    strings(0, 1), ...
    strings(0, 1), ...
    VariableNames={'GradeDate', 'Firm', 'ToGrade', 'FromGrade', 'Action'});
data.Properties.UserData = struct("Symbol", symbol, "Module", "upgradeDowngradeHistory");
end

function value = dateField(inputStruct, fieldName)
value = NaT(1, 1, TimeZone="UTC");

if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    rawValue = yfinance.internal.unwrapYahooValue(inputStruct.(fieldName));
    value = datetime(double(rawValue), ConvertFrom="posixtime", TimeZone="UTC");
end
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(yfinance.internal.unwrapYahooValue(inputStruct.(fieldName)));
else
    value = missing;
end
end
