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
                options.IncludePrePost (1,1) logical = false
            end

            response = obj.Session.getChart( ...
                obj.Symbol, ...
                Period=options.Period, ...
                Interval=options.Interval, ...
                Start=options.Start, ...
                End=options.End, ...
                IncludePrePost=options.IncludePrePost);

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

        function info = info(obj, options)
            %INFO Return quote summary metadata for the ticker.
            arguments
                obj
                options.Modules (1,:) string = yfinance.internal.defaultInfoModules()
            end

            try
                response = obj.Session.getQuoteSummary(obj.Symbol, Modules=options.Modules);
                info = yfinance.internal.quoteSummaryResponseToInfo(response, Symbol=obj.Symbol);
            catch exception
                if ~startsWith(string(exception.identifier), "yfinance:")
                    rethrow(exception);
                end

                info = obj.fastInfo();
                info.InfoSource = "fastInfoFallback";
            end
        end

        function data = calendar(obj)
            %CALENDAR Return calendar event metadata for the ticker.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="calendarEvents");
            data = yfinance.internal.quoteSummaryResponseToCalendar(response, Symbol=obj.Symbol);
        end

        function data = analystPriceTargets(obj)
            %ANALYSTPRICETARGETS Return analyst target price metadata.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="financialData");
            data = yfinance.internal.quoteSummaryResponseToAnalystPriceTargets(response, Symbol=obj.Symbol);
        end

        function data = recommendations(obj)
            %RECOMMENDATIONS Return analyst recommendation trends.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="recommendationTrend");
            data = yfinance.internal.quoteSummaryResponseToRecommendations(response, Symbol=obj.Symbol);
        end

        function data = incomeStmt(obj, options)
            %INCOMESTMT Return income statement data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
            end

            module = yfinance.internal.financialStatementModule("income", options.Quarterly);
            response = obj.Session.getQuoteSummary(obj.Symbol, Modules=module);
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module=module);
        end

        function data = balanceSheet(obj, options)
            %BALANCESHEET Return balance sheet data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
            end

            module = yfinance.internal.financialStatementModule("balance", options.Quarterly);
            response = obj.Session.getQuoteSummary(obj.Symbol, Modules=module);
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module=module);
        end

        function data = cashFlow(obj, options)
            %CASHFLOW Return cash flow statement data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
            end

            module = yfinance.internal.financialStatementModule("cashflow", options.Quarterly);
            response = obj.Session.getQuoteSummary(obj.Symbol, Modules=module);
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module=module);
        end

        function expirations = options(obj)
            %OPTIONS Return option expiration dates for the ticker.

            response = obj.Session.getOptions(obj.Symbol);
            expirations = yfinance.internal.optionsResponseToExpirations(response, Symbol=obj.Symbol);
        end

        function chain = optionChain(obj, expiration)
            %OPTIONCHAIN Return calls and puts for one option expiration.
            arguments
                obj
                expiration = []
            end

            response = obj.Session.getOptions(obj.Symbol, Expiration=expiration);
            chain = yfinance.internal.optionsResponseToOptionChain(response, Symbol=obj.Symbol);
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
