function data = download(symbols, options)
%DOWNLOAD Download historical market data for one or more symbols.

arguments
    symbols {mustBeText}
    options.Period (1,1) string = "1mo"
    options.Interval (1,1) string = "1d"
    options.Start datetime = NaT
    options.End datetime = NaT
    options.AutoAdjust (1,1) logical = true
    options.Session = yfinance.internal.Session()
end

symbols = yfinance.internal.normalizeSymbols(symbols);

if isempty(symbols)
    error("yfinance:InvalidSymbol", "At least one ticker symbol must be provided.");
end

if isscalar(symbols)
    ticker = yfinance.Ticker(symbols, Session=options.Session);
    data = ticker.history( ...
        Period=options.Period, ...
        Interval=options.Interval, ...
        Start=options.Start, ...
        End=options.End, ...
        AutoAdjust=options.AutoAdjust);
    return
end

data = struct();

for symbolIndex = 1:numel(symbols)
    symbol = symbols(symbolIndex);
    fieldName = matlab.lang.makeValidName(symbol);
    ticker = yfinance.Ticker(symbol, Session=options.Session);

    data.(fieldName) = ticker.history( ...
        Period=options.Period, ...
        Interval=options.Interval, ...
        Start=options.Start, ...
        End=options.End, ...
        AutoAdjust=options.AutoAdjust);
end
end
