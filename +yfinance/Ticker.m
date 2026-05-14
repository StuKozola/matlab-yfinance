classdef Ticker
    %TICKER Access Yahoo Finance data for a single symbol.

    properties (SetAccess = private)
        Symbol (1,1) string
    end

    methods
        function obj = Ticker(symbol)
            arguments
                symbol (1,1) string {mustBeNonzeroLengthText}
            end

            obj.Symbol = upper(strtrim(symbol));
        end

        function data = history(obj, options)
            %HISTORY Return historical OHLCV data for the ticker.
            arguments
                obj
                options.Period (1,1) string = "1mo"
                options.Interval (1,1) string = "1d"
                options.Start datetime = NaT
                options.End datetime = NaT
                options.AutoAdjust (1,1) logical = true
            end

            data = yfinance.internal.notImplemented("Ticker.history", obj.Symbol);
        end
    end
end

