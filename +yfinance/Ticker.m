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

        function info = fastInfo(obj)
            %FASTINFO Return fast quote metadata for the ticker.

            try
                response = obj.Session.getQuote(obj.Symbol);
                info = yfinance.internal.quoteResponseToFastInfo(response, Symbol=obj.Symbol);
            catch exception
                if ~startsWith(string(exception.identifier), "yfinance:")
                    rethrow(exception);
                end

                response = obj.Session.getChart(obj.Symbol, Period="5d", Interval="1d");
                info = yfinance.internal.chartResponseToFastInfo(response, Symbol=obj.Symbol);
            end
        end

        function data = actions(obj, options)
            %ACTIONS Return dividends, splits, and capital gains for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            historyData = obj.history( ...
                Period=options.Period, ...
                Interval="1d", ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=false);
            data = yfinance.internal.selectActionData(historyData);
        end

        function data = dividends(obj, options)
            %DIVIDENDS Return dividend payments for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            historyData = obj.history( ...
                Period=options.Period, ...
                Interval="1d", ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=false);
            data = yfinance.internal.selectActionData(historyData, "Dividends");
        end

        function data = splits(obj, options)
            %SPLITS Return stock split ratios for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            historyData = obj.history( ...
                Period=options.Period, ...
                Interval="1d", ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=false);
            data = yfinance.internal.selectActionData(historyData, "StockSplits");
        end

        function data = capitalGains(obj, options)
            %CAPITALGAINS Return capital gains distributions for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            historyData = obj.history( ...
                Period=options.Period, ...
                Interval="1d", ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=false);
            data = yfinance.internal.selectActionData(historyData, "CapitalGains");
        end
    end
end
