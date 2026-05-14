classdef Ticker
    %TICKER Access Yahoo Finance data for a single symbol.

    properties (SetAccess = private)
        Symbol (1,1) string
    end

    properties (Access = private)
        Session
    end

    methods
        function obj = Ticker(symbol, options)
            arguments
                symbol (1,1) string {mustBeNonzeroLengthText}
                options.Session = yfinance.internal.Session()
            end

            obj.Symbol = upper(strtrim(symbol));
            obj.Session = options.Session;
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

            response = obj.Session.getChart( ...
                obj.Symbol, ...
                Period=options.Period, ...
                Interval=options.Interval, ...
                Start=options.Start, ...
                End=options.End);

            data = yfinance.internal.chartResponseToTimetable( ...
                response, ...
                Symbol=obj.Symbol, ...
                AutoAdjust=options.AutoAdjust);
        end
    end
end
