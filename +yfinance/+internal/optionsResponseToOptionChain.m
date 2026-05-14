function chain = optionsResponseToOptionChain(response, options)
%OPTIONSRESPONSETOOPTIONCHAIN Convert Yahoo option chain data to tables.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = optionResult(response, options.Symbol);

if ~isfield(result, "options") || isempty(result.options)
    error("yfinance:NoData", "Yahoo Finance returned no option chain data for %s.", options.Symbol);
end

optionSet = firstElement(result.options);
expiration = optionExpiration(optionSet);

chain = struct();
chain.UnderlyingSymbol = string(fieldOrDefault(result, "underlyingSymbol", options.Symbol));
chain.Expiration = expiration;
chain.Calls = contractTable(fieldOrDefault(optionSet, "calls", struct.empty(0, 1)), expiration);
chain.Puts = contractTable(fieldOrDefault(optionSet, "puts", struct.empty(0, 1)), expiration);
chain.Raw = optionSet;
end

function result = optionResult(response, symbol)
if ~isfield(response, "optionChain")
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain an optionChain payload.");
end

optionChain = response.optionChain;

if isfield(optionChain, "error") && ~isempty(optionChain.error)
    error("yfinance:YahooError", "Yahoo Finance returned an options error for %s.", symbol);
end

if ~isfield(optionChain, "result") || isempty(optionChain.result)
    error("yfinance:NoData", "Yahoo Finance returned no options data for %s.", symbol);
end

result = firstElement(optionChain.result);
end

function value = firstElement(value)
if iscell(value)
    value = value{1};
elseif numel(value) > 1
    value = value(1);
end
end

function value = fieldOrDefault(inputStruct, fieldName, defaultValue)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = inputStruct.(fieldName);
else
    value = defaultValue;
end
end

function expiration = optionExpiration(optionSet)
if isfield(optionSet, "expirationDate") && ~isempty(optionSet.expirationDate)
    expiration = datetime(double(optionSet.expirationDate), ConvertFrom="posixtime", TimeZone="UTC");
else
    expiration = NaT(1, 1, TimeZone="UTC");
end
end

function data = contractTable(contracts, fallbackExpiration)
contracts = normalizeContracts(contracts);
rowCount = numel(contracts);

contractSymbol = strings(rowCount, 1);
lastTradeDate = NaT(rowCount, 1, TimeZone="UTC");
strike = NaN(rowCount, 1);
lastPrice = NaN(rowCount, 1);
bid = NaN(rowCount, 1);
ask = NaN(rowCount, 1);
change = NaN(rowCount, 1);
percentChange = NaN(rowCount, 1);
volume = NaN(rowCount, 1);
openInterest = NaN(rowCount, 1);
impliedVolatility = NaN(rowCount, 1);
inTheMoney = false(rowCount, 1);
contractSize = strings(rowCount, 1);
currency = strings(rowCount, 1);
expiration = repmat(fallbackExpiration, rowCount, 1);

for rowIndex = 1:rowCount
    contract = contracts(rowIndex);
    contractSymbol(rowIndex) = stringField(contract, "contractSymbol");
    lastTradeDate(rowIndex) = datetimeField(contract, "lastTradeDate");
    strike(rowIndex) = numericField(contract, "strike");
    lastPrice(rowIndex) = numericField(contract, "lastPrice");
    bid(rowIndex) = numericField(contract, "bid");
    ask(rowIndex) = numericField(contract, "ask");
    change(rowIndex) = numericField(contract, "change");
    percentChange(rowIndex) = numericField(contract, "percentChange");
    volume(rowIndex) = numericField(contract, "volume");
    openInterest(rowIndex) = numericField(contract, "openInterest");
    impliedVolatility(rowIndex) = numericField(contract, "impliedVolatility");
    inTheMoney(rowIndex) = logicalField(contract, "inTheMoney");
    contractSize(rowIndex) = stringField(contract, "contractSize");
    currency(rowIndex) = stringField(contract, "currency");

    if isfield(contract, "expiration") && ~isempty(contract.expiration)
        expiration(rowIndex) = datetime(double(contract.expiration), ConvertFrom="posixtime", TimeZone="UTC");
    end
end

data = table( ...
    contractSymbol, ...
    lastTradeDate, ...
    strike, ...
    lastPrice, ...
    bid, ...
    ask, ...
    change, ...
    percentChange, ...
    volume, ...
    openInterest, ...
    impliedVolatility, ...
    inTheMoney, ...
    contractSize, ...
    currency, ...
    expiration, ...
    VariableNames={ ...
        'ContractSymbol', ...
        'LastTradeDate', ...
        'Strike', ...
        'LastPrice', ...
        'Bid', ...
        'Ask', ...
        'Change', ...
        'PercentChange', ...
        'Volume', ...
        'OpenInterest', ...
        'ImpliedVolatility', ...
        'InTheMoney', ...
        'ContractSize', ...
        'Currency', ...
        'Expiration'});
end

function contracts = normalizeContracts(contracts)
if isempty(contracts)
    contracts = struct.empty(0, 1);
elseif iscell(contracts)
    contracts = [contracts{:}];
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

function value = logicalField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = logical(inputStruct.(fieldName));
else
    value = false;
end
end

function value = datetimeField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = datetime(double(inputStruct.(fieldName)), ConvertFrom="posixtime", TimeZone="UTC");
else
    value = NaT(1, 1, TimeZone="UTC");
end
end
