function data = quoteSummaryResponseToHolderTable(response, options)
%QUOTESUMMARYRESPONSETOHOLDERTABLE Convert Yahoo holder records to a table.

arguments
    response struct
    options.Symbol (1,1) string = ""
    options.Module (1,1) string
    options.RecordField (1,1) string
end

result = yfinance.internal.quoteSummaryResult(response, Symbol=options.Symbol);

if ~isfield(result, options.Module) || isempty(result.(options.Module))
    data = emptyHolderTable(options.Symbol, options.Module);
    return
end

moduleData = result.(options.Module);

if ~isfield(moduleData, options.RecordField) || isempty(moduleData.(options.RecordField))
    data = emptyHolderTable(options.Symbol, options.Module);
    return
end

data = yfinance.internal.yahooStructArrayToTable( ...
    moduleData.(options.RecordField), ...
    Symbol=options.Symbol, ...
    Module=options.Module);
end

function data = emptyHolderTable(symbol, module)
data = table();
data.Properties.UserData = struct("Symbol", symbol, "Module", module);
end
