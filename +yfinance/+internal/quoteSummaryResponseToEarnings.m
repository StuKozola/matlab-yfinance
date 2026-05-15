function data = quoteSummaryResponseToEarnings(response, options)
%QUOTESUMMARYRESPONSETOEARNINGS Convert Yahoo earnings chart data to a table.

arguments
    response struct
    options.Symbol (1,1) string = ""
    options.Quarterly (1,1) logical = false
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);
frequency = earningsFrequency(options.Quarterly);

if ~isfield(result, "earnings") || isempty(result.earnings) || ...
        ~isfield(result.earnings, "financialsChart") || isempty(result.earnings.financialsChart) || ...
        ~isfield(result.earnings.financialsChart, frequency) || isempty(result.earnings.financialsChart.(frequency))
    data = emptyEarningsTable(options.Symbol, frequency, "");
    return
end

earningsData = result.earnings;
records = earningsData.financialsChart.(frequency);

if iscell(records)
    records = [records{:}];
end

rowCount = numel(records);
period = strings(rowCount, 1);
revenue = NaN(rowCount, 1);
earnings = NaN(rowCount, 1);

for rowIndex = 1:rowCount
    item = records(rowIndex);
    period(rowIndex) = stringField(item, "date");
    revenue(rowIndex) = numericField(item, "revenue");
    earnings(rowIndex) = numericField(item, "earnings");
end

currency = stringField(earningsData, "financialCurrency");
data = table(period, revenue, earnings, VariableNames={'Period', 'Revenue', 'Earnings'});
data.Properties.UserData = struct( ...
    "Symbol", options.Symbol, ...
    "Module", "earnings", ...
    "Frequency", frequency, ...
    "Currency", currency);
end

function value = earningsFrequency(isQuarterly)
if isQuarterly
    value = "quarterly";
else
    value = "yearly";
end
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(yfinance.internal.unwrapYahooValue(inputStruct.(fieldName)));
else
    value = missing;
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

function data = emptyEarningsTable(symbol, frequency, currency)
data = table(strings(0, 1), NaN(0, 1), NaN(0, 1), VariableNames={'Period', 'Revenue', 'Earnings'});
data.Properties.UserData = struct( ...
    "Symbol", symbol, ...
    "Module", "earnings", ...
    "Frequency", frequency, ...
    "Currency", currency);
end
