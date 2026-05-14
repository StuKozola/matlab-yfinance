function data = download(symbols, options)
%DOWNLOAD Download historical market data for one or more symbols.

arguments
    symbols {mustBeText}
    options.Period (1,1) string = "1mo"
    options.Interval (1,1) string = "1d"
    options.Start datetime = NaT
    options.End datetime = NaT
    options.AutoAdjust (1,1) logical = true
end

symbols = string(symbols);
data = yfinance.internal.notImplemented("download", strjoin(symbols(:).', ","));
end

