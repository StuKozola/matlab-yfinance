classdef Session
    %SESSION HTTP session for Yahoo Finance endpoints.

    properties
        Timeout (1,1) double {mustBePositive} = 30
        UserAgent (1,1) string = "matlab-yfinance/0.0.0"
    end

    methods
        function obj = Session(options)
            arguments
                options.Timeout (1,1) double {mustBePositive} = 30
                options.UserAgent (1,1) string = "matlab-yfinance/0.0.0"
            end

            obj.Timeout = options.Timeout;
            obj.UserAgent = options.UserAgent;
        end

        function response = getChart(obj, symbol, options)
            %GETCHART Read the Yahoo Finance chart endpoint for one symbol.
            arguments
                obj
                symbol (1,1) string {mustBeNonzeroLengthText}
                options.Period (1,1) string = "1mo"
                options.Interval (1,1) string = "1d"
                options.Start datetime = NaT
                options.End datetime = NaT
                options.IncludePrePost (1,1) logical = false
            end

            symbol = upper(strtrim(symbol));
            url = "https://query1.finance.yahoo.com/v8/finance/chart/" + urlencode(symbol);
            query = yfinance.internal.chartQueryParameters( ...
                Period=options.Period, ...
                Interval=options.Interval, ...
                Start=options.Start, ...
                End=options.End, ...
                IncludePrePost=options.IncludePrePost);

            webOptions = weboptions( ...
                ContentType="json", ...
                Timeout=obj.Timeout, ...
                UserAgent=char(obj.UserAgent));

            try
                response = webread(char(url), query{:}, webOptions);
            catch exception
                newException = MException( ...
                    "yfinance:NetworkError", ...
                    "Unable to read Yahoo Finance chart data for %s. %s", ...
                    symbol, ...
                    exception.message);
                throw(newException);
            end
        end

        function response = getQuote(obj, symbols)
            %GETQUOTE Read the Yahoo Finance quote endpoint for one or more symbols.
            arguments
                obj
                symbols {mustBeText}
            end

            symbols = yfinance.internal.normalizeSymbols(symbols);

            if isempty(symbols)
                error("yfinance:InvalidSymbol", "At least one ticker symbol must be provided.");
            end

            url = "https://query1.finance.yahoo.com/v7/finance/quote";
            query = {"symbols", char(strjoin(symbols, ","))};
            webOptions = weboptions( ...
                ContentType="json", ...
                Timeout=obj.Timeout, ...
                UserAgent=char(obj.UserAgent));

            try
                response = webread(char(url), query{:}, webOptions);
            catch exception
                newException = MException( ...
                    "yfinance:NetworkError", ...
                    "Unable to read Yahoo Finance quote data for %s. %s", ...
                    strjoin(symbols, ","), ...
                    exception.message);
                throw(newException);
            end
        end

        function response = getQuoteSummary(obj, symbol, options)
            %GETQUOTESUMMARY Read Yahoo Finance quote summary modules.
            arguments
                obj
                symbol (1,1) string {mustBeNonzeroLengthText}
                options.Modules (1,:) string = yfinance.internal.defaultInfoModules()
            end

            symbol = upper(strtrim(symbol));
            modules = yfinance.internal.normalizeModules(options.Modules);
            url = "https://query1.finance.yahoo.com/v10/finance/quoteSummary/" + urlencode(symbol);
            query = {"modules", char(strjoin(modules, ","))};
            webOptions = weboptions( ...
                ContentType="json", ...
                Timeout=obj.Timeout, ...
                UserAgent=char(obj.UserAgent));

            try
                response = webread(char(url), query{:}, webOptions);
            catch exception
                newException = MException( ...
                    "yfinance:NetworkError", ...
                    "Unable to read Yahoo Finance quote summary data for %s. %s", ...
                    symbol, ...
                    exception.message);
                throw(newException);
            end
        end

        function response = getSearch(obj, queryText, options)
            %GETSEARCH Read the Yahoo Finance search endpoint.
            arguments
                obj
                queryText (1,1) string {mustBeNonzeroLengthText}
                options.QuotesCount (1,1) double {mustBeNonnegative, mustBeInteger} = 8
                options.NewsCount (1,1) double {mustBeNonnegative, mustBeInteger} = 8
            end

            queryText = strtrim(queryText);
            url = "https://query1.finance.yahoo.com/v1/finance/search";
            query = { ...
                "q", char(queryText), ...
                "quotesCount", char(string(options.QuotesCount)), ...
                "newsCount", char(string(options.NewsCount))};
            webOptions = weboptions( ...
                ContentType="json", ...
                Timeout=obj.Timeout, ...
                UserAgent=char(obj.UserAgent));

            try
                response = webread(char(url), query{:}, webOptions);
            catch exception
                newException = MException( ...
                    "yfinance:NetworkError", ...
                    "Unable to read Yahoo Finance search data for %s. %s", ...
                    queryText, ...
                    exception.message);
                throw(newException);
            end
        end

        function response = getOptions(obj, symbol, options)
            %GETOPTIONS Read the Yahoo Finance options endpoint for one symbol.
            arguments
                obj
                symbol (1,1) string {mustBeNonzeroLengthText}
                options.Expiration = []
            end

            symbol = upper(strtrim(symbol));
            url = "https://query1.finance.yahoo.com/v7/finance/options/" + urlencode(symbol);
            query = {};
            expirationText = yfinance.internal.optionExpirationToUnixText(options.Expiration);

            if expirationText ~= ""
                query = {"date", char(expirationText)};
            end

            webOptions = weboptions( ...
                ContentType="json", ...
                Timeout=obj.Timeout, ...
                UserAgent=char(obj.UserAgent));

            try
                response = webread(char(url), query{:}, webOptions);
            catch exception
                newException = MException( ...
                    "yfinance:NetworkError", ...
                    "Unable to read Yahoo Finance options data for %s. %s", ...
                    symbol, ...
                    exception.message);
                throw(newException);
            end
        end
    end
end
