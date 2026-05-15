function data = quoteSummaryResponseToEarningsHistory(response, options)
%QUOTESUMMARYRESPONSETOEARNINGSHISTORY Convert earnings history to a table.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);

if ~isfield(result, "earningsHistory") || isempty(result.earningsHistory) || ...
        ~isfield(result.earningsHistory, "history") || isempty(result.earningsHistory.history)
    data = emptyEarningsHistoryTable(options.Symbol);
    return
end

history = result.earningsHistory.history;

if iscell(history)
    history = [history{:}];
end

rowCount = numel(history);
quarter = NaT(rowCount, 1, TimeZone="UTC");
epsEstimate = NaN(rowCount, 1);
epsActual = NaN(rowCount, 1);
epsDifference = NaN(rowCount, 1);
surprisePercent = NaN(rowCount, 1);

for rowIndex = 1:rowCount
    item = history(rowIndex);
    quarter(rowIndex) = quarterField(item);
    epsEstimate(rowIndex) = numericField(item, "epsEstimate");
    epsActual(rowIndex) = numericField(item, "epsActual");
    epsDifference(rowIndex) = numericField(item, "epsDifference");
    surprisePercent(rowIndex) = numericField(item, "surprisePercent");
end

data = table(quarter, epsEstimate, epsActual, epsDifference, surprisePercent, VariableNames={ ...
    'Quarter', ...
    'EpsEstimate', ...
    'EpsActual', ...
    'EpsDifference', ...
    'SurprisePercent'});
data.Properties.UserData = struct("Symbol", options.Symbol, "Module", "earningsHistory");
end

function value = quarterField(inputStruct)
value = NaT(1, 1, TimeZone="UTC");

if ~isfield(inputStruct, "quarter") || isempty(inputStruct.quarter)
    return
end

quarter = inputStruct.quarter;

if isstruct(quarter) && isfield(quarter, "raw") && ~isempty(quarter.raw)
    value = datetime(double(quarter.raw), ConvertFrom="posixtime", TimeZone="UTC");
elseif isstruct(quarter) && isfield(quarter, "fmt") && ~isempty(quarter.fmt)
    value = datetime(string(quarter.fmt), InputFormat="yyyy-MM-dd", TimeZone="UTC");
elseif isstring(quarter) || ischar(quarter)
    value = datetime(string(quarter), InputFormat="yyyy-MM-dd", TimeZone="UTC");
end
end

function value = numericField(inputStruct, fieldName)
value = NaN;

if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    rawValue = yfinance.internal.unwrapYahooValue(inputStruct.(fieldName));

    if isnumeric(rawValue) && ~isempty(rawValue)
        value = double(rawValue);
    end
end
end

function data = emptyEarningsHistoryTable(symbol)
data = table( ...
    NaT(0, 1, TimeZone="UTC"), ...
    NaN(0, 1), ...
    NaN(0, 1), ...
    NaN(0, 1), ...
    NaN(0, 1), ...
    VariableNames={'Quarter', 'EpsEstimate', 'EpsActual', 'EpsDifference', 'SurprisePercent'});
data.Properties.UserData = struct("Symbol", symbol, "Module", "earningsHistory");
end
