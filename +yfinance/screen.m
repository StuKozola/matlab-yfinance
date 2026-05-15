function result = screen(queryName, options)
%SCREEN Run a predefined Yahoo Finance screener.

arguments
    queryName (1,1) string {mustBeNonzeroLengthText}
    options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
    options.Offset (1,1) double {mustBeNonnegative, mustBeInteger} = 0
    options.Session = yfinance.internal.Session()
end

response = options.Session.getScreener( ...
    queryName, ...
    Count=options.Count, ...
    Offset=options.Offset);
result = yfinance.internal.screenerResponseToResult(response, Query=queryName);
end
