classdef Tickers
    %TICKERS Container for multiple yfinance.Ticker instances.

    properties (SetAccess = private)
        Symbols (:,1) string
        Items (:,1) yfinance.Ticker
    end

    properties (Access = private)
        Session
    end

    methods
        function obj = Tickers(symbols, options)
            arguments
                symbols {mustBeText}
                options.Session = yfinance.internal.Session()
            end

            symbols = yfinance.internal.normalizeSymbols(symbols);

            obj.Symbols = symbols;
            obj.Session = options.Session;
            obj.Items = arrayfun(@(symbol) yfinance.Ticker(symbol, Session=options.Session), symbols);
        end

        function data = history(obj, options)
            %HISTORY Return historical OHLCV data for all symbols.
            arguments
                obj
                options.Period (1,1) string = "1mo"
                options.Interval (1,1) string = "1d"
                options.Start datetime = NaT
                options.End datetime = NaT
                options.AutoAdjust (1,1) logical = true
                options.IncludePrePost (1,1) logical = false
            end

            data = yfinance.download( ...
                obj.Symbols, ...
                Period=options.Period, ...
                Interval=options.Interval, ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=options.AutoAdjust, ...
                IncludePrePost=options.IncludePrePost, ...
                Session=obj.Session);
        end

        function data = download(obj, options)
            %DOWNLOAD Download historical OHLCV data for all symbols.
            arguments
                obj
                options.Period (1,1) string = "1mo"
                options.Interval (1,1) string = "1d"
                options.Start datetime = NaT
                options.End datetime = NaT
                options.AutoAdjust (1,1) logical = true
                options.IncludePrePost (1,1) logical = false
            end

            data = obj.history( ...
                Period=options.Period, ...
                Interval=options.Interval, ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=options.AutoAdjust, ...
                IncludePrePost=options.IncludePrePost);
        end

        function data = fastInfo(obj)
            %FASTINFO Return fast quote metadata for all symbols.

            data = struct();

            for symbolIndex = 1:numel(obj.Symbols)
                symbol = obj.Symbols(symbolIndex);
                fieldName = matlab.lang.makeValidName(symbol);
                data.(fieldName) = obj.Items(symbolIndex).fastInfo();
            end
        end
    end
end
