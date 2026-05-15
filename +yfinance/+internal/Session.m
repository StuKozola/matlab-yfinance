classdef Session
    %SESSION HTTP session for Yahoo Finance endpoints.

    properties
        Timeout (1,1) double {mustBePositive} = 30
        UserAgent (1,1) string = "matlab-yfinance/0.0.0"
        MaxRetries (1,1) double {mustBeNonnegative, mustBeInteger} = 2
        RetryDelay (1,1) double {mustBeNonnegative} = 0.5
        RequestFunction (1,1) function_handle = @webread
    end

    methods
        function obj = Session(options)
            arguments
                options.Timeout (1,1) double {mustBePositive} = 30
                options.UserAgent (1,1) string = "matlab-yfinance/0.0.0"
                options.MaxRetries (1,1) double {mustBeNonnegative, mustBeInteger} = 2
                options.RetryDelay (1,1) double {mustBeNonnegative} = 0.5
                options.RequestFunction (1,1) function_handle = @webread
            end

            obj.Timeout = options.Timeout;
            obj.UserAgent = options.UserAgent;
            obj.MaxRetries = options.MaxRetries;
            obj.RetryDelay = options.RetryDelay;
            obj.RequestFunction = options.RequestFunction;
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

            response = obj.requestJson(url, query, "chart data", symbol);
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
            response = obj.requestJson(url, query, "quote data", strjoin(symbols, ","));
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
            response = obj.requestJson(url, query, "quote summary data", symbol);
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
            response = obj.requestJson(url, query, "search data", queryText);
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

            response = obj.requestJson(url, query, "options data", symbol);
        end
    end

    methods (Access = private)
        function response = requestJson(obj, url, query, dataDescription, context)
            webOptions = weboptions( ...
                ContentType="json", ...
                Timeout=obj.Timeout, ...
                UserAgent=char(obj.UserAgent));
            lastException = MException.empty(0, 1);

            for attempt = 1:(obj.MaxRetries + 1)
                try
                    response = obj.RequestFunction(char(url), query{:}, webOptions);

                    if isempty(response)
                        lastException = MException( ...
                            "yfinance:EmptyResponse", ...
                            "Yahoo Finance returned an empty response for %s.", ...
                            context);
                        obj.pauseBeforeRetry(attempt);
                        continue
                    end

                    return
                catch exception
                    lastException = obj.classifyRequestException(exception, dataDescription, context);

                    if ~obj.shouldRetry(lastException) || attempt > obj.MaxRetries
                        throw(lastException);
                    end

                    obj.pauseBeforeRetry(attempt);
                end
            end

            throw(lastException);
        end

        function pauseBeforeRetry(obj, attempt)
            if attempt > obj.MaxRetries || obj.RetryDelay == 0
                return
            end

            pause(obj.RetryDelay * 2^(attempt - 1));
        end
    end

    methods (Static, Access = private)
        function retry = shouldRetry(exception)
            retryableIds = [ ...
                "yfinance:RateLimited", ...
                "yfinance:Timeout", ...
                "yfinance:NetworkError", ...
                "yfinance:EmptyResponse"];
            retry = ismember(string(exception.identifier), retryableIds);
        end

        function exception = classifyRequestException(exception, dataDescription, context)
            identifier = string(exception.identifier);
            message = string(exception.message);
            lowerMessage = lower(message);

            if contains(identifier, "429") || contains(lowerMessage, "status 429") || contains(lowerMessage, "too many requests")
                exception = MException( ...
                    "yfinance:RateLimited", ...
                    "Yahoo Finance rate limited the request for %s. Retry later or reduce request frequency. %s", ...
                    context, ...
                    message);
            elseif contains(identifier, "401") || contains(identifier, "403") || ...
                    contains(lowerMessage, "status 401") || contains(lowerMessage, "status 403") || ...
                    contains(lowerMessage, "unauthorized") || contains(lowerMessage, "forbidden")
                exception = MException( ...
                    "yfinance:Unauthorized", ...
                    "Yahoo Finance rejected the request for %s. The endpoint may require different credentials, cookies, or crumb handling. %s", ...
                    context, ...
                    message);
            elseif contains(lower(identifier), "timeout") || contains(lowerMessage, "timed out") || contains(lowerMessage, "timeout")
                exception = MException( ...
                    "yfinance:Timeout", ...
                    "Timed out while reading Yahoo Finance %s for %s. %s", ...
                    dataDescription, ...
                    context, ...
                    message);
            elseif startsWith(identifier, "yfinance:")
                return
            else
                exception = MException( ...
                    "yfinance:NetworkError", ...
                    "Unable to read Yahoo Finance %s for %s. %s", ...
                    dataDescription, ...
                    context, ...
                    message);
            end
        end
    end
end
