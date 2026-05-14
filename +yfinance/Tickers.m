classdef Tickers
    %TICKERS Container for multiple yfinance.Ticker instances.

    properties (SetAccess = private)
        Symbols (:,1) string
        Items (:,1) yfinance.Ticker
    end

    methods
        function obj = Tickers(symbols)
            arguments
                symbols {mustBeText}
            end

            symbols = string(symbols);
            symbols = symbols(:);
            symbols = upper(strtrim(symbols));
            symbols(symbols == "") = [];

            obj.Symbols = symbols;
            obj.Items = arrayfun(@yfinance.Ticker, symbols);
        end
    end
end

