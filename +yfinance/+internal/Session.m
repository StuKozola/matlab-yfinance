classdef Session < handle
    %SESSION HTTP session for Yahoo Finance endpoints.

    properties
        Timeout (1,1) double {mustBePositive} = 30
        UserAgent (1,1) string = yfinance.internal.defaultUserAgent()
        MaxRetries (1,1) double {mustBeNonnegative, mustBeInteger} = 2
        RetryDelay (1,1) double {mustBeNonnegative} = 0.5
        RequestFunction (1,1) function_handle = @webread
        CredentialRequestFunction (1,1) function_handle = @yfinance.internal.httpTextRequest
        UseCredentials (1,1) logical = true
    end

    properties (SetAccess = private)
        CookieHeader (1,1) string = ""
        Crumb (1,1) string = ""
    end

    methods
        function obj = Session(options)
            arguments
                options.Timeout (1,1) double {mustBePositive} = 30
                options.UserAgent (1,1) string = yfinance.internal.defaultUserAgent()
                options.MaxRetries (1,1) double {mustBeNonnegative, mustBeInteger} = 2
                options.RetryDelay (1,1) double {mustBeNonnegative} = 0.5
                options.RequestFunction (1,1) function_handle = @webread
                options.CredentialRequestFunction (1,1) function_handle = @yfinance.internal.httpTextRequest
                options.UseCredentials (1,1) logical = true
                options.CookieHeader (1,1) string = ""
                options.Crumb (1,1) string = ""
            end

            obj.Timeout = options.Timeout;
            obj.UserAgent = options.UserAgent;
            obj.MaxRetries = options.MaxRetries;
            obj.RetryDelay = options.RetryDelay;
            obj.RequestFunction = options.RequestFunction;
            obj.CredentialRequestFunction = options.CredentialRequestFunction;
            obj.UseCredentials = options.UseCredentials;
            obj.CookieHeader = options.CookieHeader;
            obj.Crumb = options.Crumb;
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
            url = "https://query2.finance.yahoo.com/v10/finance/quoteSummary/" + urlencode(symbol);
            query = { ...
                "modules", char(strjoin(modules, ",")), ...
                "corsDomain", "finance.yahoo.com", ...
                "formatted", "false", ...
                "symbol", char(symbol)};
            query = obj.addCrumbToQuery(query);

            try
                response = obj.requestJson(url, query, "quote summary data", symbol);
            catch exception
                if ~(obj.UseCredentials && string(exception.identifier) == "yfinance:Unauthorized")
                    rethrow(exception);
                end

                obj.clearCredentials();
                query = obj.addCrumbToQuery(query);
                response = obj.requestJson(url, query, "quote summary data", symbol);
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

        function response = getFundamentalsTimeSeries(obj, symbol, options)
            %GETFUNDAMENTALSTIMESERIES Read Yahoo fundamentals time-series data.
            arguments
                obj
                symbol (1,1) string {mustBeNonzeroLengthText}
                options.Types (1,:) string {mustBeNonzeroLengthText}
                options.Start (1,1) datetime
                options.End (1,1) datetime
            end

            symbol = upper(strtrim(symbol));
            types = strtrim(options.Types);
            startTime = options.Start;
            endTime = options.End;

            if strlength(string(startTime.TimeZone)) == 0
                startTime.TimeZone = "UTC";
            end

            if strlength(string(endTime.TimeZone)) == 0
                endTime.TimeZone = "UTC";
            end

            if startTime >= endTime
                error("yfinance:InvalidDateRange", "Start must be before End.");
            end

            url = "https://query2.finance.yahoo.com/ws/fundamentals-timeseries/v1/finance/timeseries/" + urlencode(symbol);
            query = { ...
                "symbol", char(symbol), ...
                "type", char(strjoin(types, ",")), ...
                "period1", yfinance.internal.datetimeToUnixText(startTime), ...
                "period2", yfinance.internal.datetimeToUnixText(endTime)};
            response = obj.requestJson(url, query, "fundamentals time-series data", symbol);
        end
    end

    methods (Access = private)
        function response = requestJson(obj, url, query, dataDescription, context)
            webOptions = obj.jsonWebOptions();
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

        function query = addCrumbToQuery(obj, query)
            if ~obj.UseCredentials
                return
            end

            obj.ensureCredentials();

            if obj.Crumb == ""
                return
            end

            queryNames = string(query(1:2:end));
            crumbIndex = find(queryNames == "crumb", 1);

            if ~isempty(crumbIndex)
                query{2*crumbIndex} = char(obj.Crumb);
                return
            end

            query = [query, {"crumb", char(obj.Crumb)}];
        end

        function ensureCredentials(obj)
            if obj.Crumb ~= ""
                return
            end

            obj.acquireCookie();
            obj.Crumb = obj.acquireCrumb();
        end

        function acquireCookie(obj)
            response = obj.requestCredential("https://fc.yahoo.com");

            if response.CookieHeader ~= ""
                obj.CookieHeader = response.CookieHeader;
            end
        end

        function crumb = acquireCrumb(obj)
            crumb = "";
            isRateLimited = false;
            crumbUrls = [ ...
                "https://query1.finance.yahoo.com/v1/test/getcrumb", ...
                "https://query2.finance.yahoo.com/v1/test/getcrumb"];

            for urlIndex = 1:numel(crumbUrls)
                response = obj.requestCredential(crumbUrls(urlIndex));
                [crumb, isCurrentRateLimited] = obj.crumbFromResponse(response);
                isRateLimited = isRateLimited || isCurrentRateLimited;

                if crumb ~= ""
                    return
                end
            end

            if isRateLimited
                error( ...
                    "yfinance:RateLimited", ...
                    "Yahoo Finance rate limited credential requests. Retry later or reduce request frequency.");
            end
        end

        function response = requestCredential(obj, url)
            try
                response = obj.CredentialRequestFunction( ...
                    url, ...
                    Timeout=obj.Timeout, ...
                    UserAgent=obj.UserAgent, ...
                    CookieHeader=obj.CookieHeader);
            catch exception
                classifiedException = obj.classifyRequestException(exception, "credentials", url);
                throw(classifiedException);
            end

            response = obj.normalizeCredentialResponse(response);

            if response.CookieHeader ~= ""
                obj.CookieHeader = response.CookieHeader;
            end
        end

        function webOptions = jsonWebOptions(obj)
            if obj.CookieHeader == ""
                webOptions = weboptions( ...
                    ContentType="json", ...
                    Timeout=obj.Timeout, ...
                    UserAgent=char(obj.UserAgent));
            else
                webOptions = weboptions( ...
                    ContentType="json", ...
                    Timeout=obj.Timeout, ...
                    UserAgent=char(obj.UserAgent), ...
                    HeaderFields={'Cookie', char(obj.CookieHeader)});
            end
        end

        function clearCredentials(obj)
            obj.CookieHeader = "";
            obj.Crumb = "";
        end

        function pauseBeforeRetry(obj, attempt)
            if attempt > obj.MaxRetries || obj.RetryDelay == 0
                return
            end

            pause(obj.RetryDelay * 2^(attempt - 1));
        end
    end

    methods (Static, Access = private)
        function response = normalizeCredentialResponse(response)
            if ~isstruct(response)
                error("yfinance:InvalidResponse", "Credential response must be a scalar struct.");
            end

            if ~isfield(response, "StatusCode") || isempty(response.StatusCode)
                response.StatusCode = 200;
            end

            if ~isfield(response, "Body") || isempty(response.Body)
                response.Body = "";
            end

            if ~isfield(response, "CookieHeader") || isempty(response.CookieHeader)
                response.CookieHeader = "";
            end

            response.StatusCode = double(response.StatusCode);
            response.Body = string(response.Body);
            response.CookieHeader = string(response.CookieHeader);
        end

        function [crumb, isRateLimited] = crumbFromResponse(response)
            body = strtrim(response.Body);
            crumb = "";
            isRateLimited = response.StatusCode == 429 || contains(lower(body), "too many requests");

            if isRateLimited || response.StatusCode >= 400 || body == "" || contains(lower(body), "<html")
                return
            end

            crumb = body;
        end

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
