function info = quoteSummaryResponseToInfo(response, options)
%QUOTESUMMARYRESPONSETOINFO Convert Yahoo quoteSummary modules to a struct.

arguments
    response struct
    options.Symbol (1,1) string = ""
end

result = quoteSummaryResult(response, options.Symbol);
info = struct("Symbol", options.Symbol);
moduleNames = fieldnames(result);

for moduleIndex = 1:numel(moduleNames)
    moduleName = moduleNames{moduleIndex};
    moduleValue = result.(moduleName);

    if isempty(moduleValue) || ~isstruct(moduleValue)
        continue
    end

    info.(matlab.lang.makeValidName(moduleName)) = unwrapValue(moduleValue);
    info = mergeModuleFields(info, moduleValue);
end

info.Raw = result;
end

function result = quoteSummaryResult(response, symbol)
if ~isfield(response, "quoteSummary")
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain a quoteSummary payload.");
end

quoteSummary = response.quoteSummary;

if isfield(quoteSummary, "error") && ~isempty(quoteSummary.error)
    error("yfinance:YahooError", "Yahoo Finance returned a quote summary error for %s.", symbol);
end

if ~isfield(quoteSummary, "result") || isempty(quoteSummary.result)
    error("yfinance:NoData", "Yahoo Finance returned no quote summary data for %s.", symbol);
end

result = quoteSummary.result;

if iscell(result)
    result = result{1};
elseif numel(result) > 1
    result = result(1);
end
end

function info = mergeModuleFields(info, moduleValue)
fieldNames = fieldnames(moduleValue);

for fieldIndex = 1:numel(fieldNames)
    sourceName = fieldNames{fieldIndex};
    targetName = matlab.lang.makeValidName(sourceName);

    if isfield(info, targetName)
        continue
    end

    info.(targetName) = unwrapValue(moduleValue.(sourceName));
end
end

function value = unwrapValue(value)
if isstruct(value)
    if isScalarFormattedValue(value)
        value = formattedRawValue(value);
        return
    end

    fieldNames = fieldnames(value);
    output = struct();

    for fieldIndex = 1:numel(fieldNames)
        fieldName = fieldNames{fieldIndex};
        output.(matlab.lang.makeValidName(fieldName)) = unwrapValue(value.(fieldName));
    end

    value = output;
elseif iscell(value)
    value = unwrapCell(value);
end
end

function value = unwrapCell(value)
if isempty(value)
    value = strings(0, 1);
    return
end

if all(cellfun(@ischar, value))
    value = string(value);
    return
end

for valueIndex = 1:numel(value)
    value{valueIndex} = unwrapValue(value{valueIndex});
end
end

function value = isScalarFormattedValue(inputStruct)
fields = string(fieldnames(inputStruct));
value = isscalar(inputStruct) && any(fields == "raw") && (any(fields == "fmt") || any(fields == "longFmt"));
end

function value = formattedRawValue(inputStruct)
if isfield(inputStruct, "raw") && ~isempty(inputStruct.raw)
    value = inputStruct.raw;
elseif isfield(inputStruct, "fmt") && ~isempty(inputStruct.fmt)
    value = string(inputStruct.fmt);
elseif isfield(inputStruct, "longFmt") && ~isempty(inputStruct.longFmt)
    value = string(inputStruct.longFmt);
else
    value = [];
end
end
