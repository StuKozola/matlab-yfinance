classdef TestSessionTransport < matlab.unittest.TestCase
    %TESTSESSIONTRANSPORT Verify Session HTTP retry and error handling.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function retriesRateLimitThenSucceeds(testCase)
            request = SequenceRequest({ ...
                MException("MATLAB:webservices:HTTP429StatusCodeError", "The server returned status 429 Too Many Requests."), ...
                searchResponse()});
            session = yfinance.internal.Session( ...
                MaxRetries=1, ...
                RetryDelay=0, ...
                RequestFunction=@(varargin) request.send(varargin{:}));

            response = session.getSearch("apple", QuotesCount=0, NewsCount=0);

            testCase.verifyEqual(request.CallCount, 2);
            testCase.verifyTrue(isfield(response, "quotes"));
        end

        function emptyResponseRetriesThenSucceeds(testCase)
            request = SequenceRequest({[], searchResponse()});
            session = yfinance.internal.Session( ...
                MaxRetries=1, ...
                RetryDelay=0, ...
                RequestFunction=@(varargin) request.send(varargin{:}));

            response = session.getSearch("apple", QuotesCount=0, NewsCount=0);

            testCase.verifyEqual(request.CallCount, 2);
            testCase.verifyTrue(isfield(response, "news"));
        end

        function unauthorizedDoesNotRetry(testCase)
            request = SequenceRequest({ ...
                MException("MATLAB:webservices:HTTP401StatusCodeError", "The server returned status 401 Unauthorized.")});
            session = yfinance.internal.Session( ...
                MaxRetries=2, ...
                RetryDelay=0, ...
                RequestFunction=@(varargin) request.send(varargin{:}));

            testCase.verifyError( ...
                @() session.getQuote("AAPL"), ...
                "yfinance:Unauthorized");
            testCase.verifyEqual(request.CallCount, 1);
        end

        function timeoutClassifiesAfterRetries(testCase)
            request = SequenceRequest({ ...
                MException("MATLAB:webservices:Timeout", "The request timed out."), ...
                MException("MATLAB:webservices:Timeout", "The request timed out.")});
            session = yfinance.internal.Session( ...
                MaxRetries=1, ...
                RetryDelay=0, ...
                RequestFunction=@(varargin) request.send(varargin{:}));

            testCase.verifyError( ...
                @() session.getSearch("apple", QuotesCount=0, NewsCount=0), ...
                "yfinance:Timeout");
            testCase.verifyEqual(request.CallCount, 2);
        end

        function requestReceivesWebOptions(testCase)
            request = SequenceRequest({searchResponse()});
            session = yfinance.internal.Session( ...
                Timeout=12, ...
                UserAgent="test-agent", ...
                RequestFunction=@(varargin) request.send(varargin{:}));

            session.getSearch("apple", QuotesCount=0, NewsCount=0);

            webOptions = request.LastArguments{end};
            testCase.verifyEqual(webOptions.Timeout, 12);
            testCase.verifyEqual(string(webOptions.UserAgent), "test-agent");
        end

        function postScreenerSendsJsonBody(testCase)
            request = SequenceRequest({screenerResponse()});
            query = struct("operator", "EQ", "operands", {{"region", "us"}});
            session = yfinance.internal.Session( ...
                UseCredentials=false, ...
                PostRequestFunction=@(varargin) request.send(varargin{:}));

            session.postScreener( ...
                query, ...
                Count=2, ...
                Offset=3, ...
                SortField="percentchange", ...
                SortAscending=true, ...
                QuoteType="EQUITY");

            body = request.LastArguments{1};
            webOptions = request.LastArguments{2};
            testCase.verifyTrue(startsWith(string(request.LastUrl), "https://query1.finance.yahoo.com/v1/finance/screener?"));
            testCase.verifyEqual(body.count, 2);
            testCase.verifyEqual(body.size, 2);
            testCase.verifyEqual(body.offset, 3);
            testCase.verifyEqual(body.sortField, "percentchange");
            testCase.verifyEqual(body.sortType, "ASC");
            testCase.verifyEqual(body.quoteType, "EQUITY");
            testCase.verifyEqual(body.query.operator, "EQ");
            testCase.verifyEqual(string(webOptions.MediaType), "application/json");
        end

        function postScreenerRejectsInvalidCount(testCase)
            session = yfinance.internal.Session(UseCredentials=false);
            query = struct("operator", "EQ", "operands", {{"region", "us"}});

            testCase.verifyError( ...
                @() session.postScreener(query, Count=251), ...
                "yfinance:InvalidCount");
        end

        function quoteSummaryUsesQuery2Endpoint(testCase)
            request = SequenceRequest({quoteSummaryResponse()});
            session = yfinance.internal.Session( ...
                UseCredentials=false, ...
                RequestFunction=@(varargin) request.send(varargin{:}));

            session.getQuoteSummary("aapl", Modules=["price", "summaryDetail"]);

            testCase.verifyTrue(startsWith(string(request.LastUrl), "https://query2.finance.yahoo.com"));
            testCase.verifyEqual(string(request.LastArguments{1}), "modules");
            testCase.verifyEqual(string(request.LastArguments{2}), "price,summaryDetail");
            testCase.verifyEqual(string(request.LastArguments{3}), "corsDomain");
            testCase.verifyEqual(string(request.LastArguments{4}), "finance.yahoo.com");
            testCase.verifyEqual(string(request.LastArguments{5}), "formatted");
            testCase.verifyEqual(string(request.LastArguments{6}), "false");
            testCase.verifyEqual(string(request.LastArguments{7}), "symbol");
            testCase.verifyEqual(string(request.LastArguments{8}), "AAPL");
        end

        function fundamentalsTimeSeriesUsesQuery2Endpoint(testCase)
            request = SequenceRequest({timeseriesResponse()});
            session = yfinance.internal.Session(RequestFunction=@(varargin) request.send(varargin{:}));
            startTime = datetime("2024-01-01", TimeZone="UTC");
            endTime = datetime("2024-04-01", TimeZone="UTC");

            session.getFundamentalsTimeSeries( ...
                "aapl", ...
                Types=["shares_out", "trailingPegRatio"], ...
                Start=startTime, ...
                End=endTime);

            testCase.verifyTrue(startsWith(string(request.LastUrl), "https://query2.finance.yahoo.com"));
            testCase.verifyTrue(contains(string(request.LastUrl), "/ws/fundamentals-timeseries/v1/finance/timeseries/AAPL"));
            testCase.verifyEqual(string(request.LastArguments{1}), "symbol");
            testCase.verifyEqual(string(request.LastArguments{2}), "AAPL");
            testCase.verifyEqual(string(request.LastArguments{3}), "type");
            testCase.verifyEqual(string(request.LastArguments{4}), "shares_out,trailingPegRatio");
            testCase.verifyEqual(string(request.LastArguments{5}), "period1");
            testCase.verifyEqual(string(request.LastArguments{6}), "1704067200");
            testCase.verifyEqual(string(request.LastArguments{7}), "period2");
            testCase.verifyEqual(string(request.LastArguments{8}), "1711929600");
        end

        function fundamentalsTimeSeriesRejectsInvalidDateRange(testCase)
            session = yfinance.internal.Session(RequestFunction=@webread);

            testCase.verifyError( ...
                @() session.getFundamentalsTimeSeries( ...
                    "AAPL", ...
                    Types="shares_out", ...
                    Start=datetime("2024-04-01", TimeZone="UTC"), ...
                    End=datetime("2024-01-01", TimeZone="UTC")), ...
                "yfinance:InvalidDateRange");
        end

        function quoteSummaryAddsCookieAndCrumb(testCase)
            credential = SequenceRequest({ ...
                credentialResponse(204, "", "A1=B1"), ...
                credentialResponse(200, "crumb123", "")});
            request = SequenceRequest({quoteSummaryResponse()});
            session = yfinance.internal.Session( ...
                RequestFunction=@(varargin) request.send(varargin{:}), ...
                CredentialRequestFunction=@(varargin) credential.send(varargin{:}));

            session.getQuoteSummary("AAPL", Modules="price");

            testCase.verifyEqual(credential.CallCount, 2);
            testCase.verifyEqual(credential.Urls(1), "https://fc.yahoo.com");
            testCase.verifyEqual(credential.Urls(2), "https://query1.finance.yahoo.com/v1/test/getcrumb");
            testCase.verifyEqual(session.CookieHeader, "A1=B1");
            testCase.verifyEqual(session.Crumb, "crumb123");
            testCase.verifyEqual(string(request.LastArguments{9}), "crumb");
            testCase.verifyEqual(string(request.LastArguments{10}), "crumb123");

            webOptions = request.LastArguments{end};
            testCase.verifyEqual(webOptions.HeaderFields, {'Cookie', 'A1=B1'});
        end

        function quoteSummaryFallsBackToSecondCrumbEndpoint(testCase)
            credential = SequenceRequest({ ...
                credentialResponse(204, "", "A1=B1"), ...
                credentialResponse(401, "", ""), ...
                credentialResponse(200, "crumb456", "")});
            request = SequenceRequest({quoteSummaryResponse()});
            session = yfinance.internal.Session( ...
                RequestFunction=@(varargin) request.send(varargin{:}), ...
                CredentialRequestFunction=@(varargin) credential.send(varargin{:}));

            session.getQuoteSummary("AAPL", Modules="price");

            testCase.verifyEqual(credential.CallCount, 3);
            testCase.verifyEqual(credential.Urls(3), "https://query2.finance.yahoo.com/v1/test/getcrumb");
            testCase.verifyEqual(session.Crumb, "crumb456");
            testCase.verifyEqual(string(request.LastArguments{10}), "crumb456");
        end

        function credentialRateLimitReportsRateLimit(testCase)
            credential = SequenceRequest({ ...
                credentialResponse(204, "", "A1=B1"), ...
                credentialResponse(429, "Too Many Requests", "")});
            request = SequenceRequest({quoteSummaryResponse()});
            session = yfinance.internal.Session( ...
                RequestFunction=@(varargin) request.send(varargin{:}), ...
                CredentialRequestFunction=@(varargin) credential.send(varargin{:}));

            testCase.verifyError( ...
                @() session.getQuoteSummary("AAPL", Modules="price"), ...
                "yfinance:RateLimited");
            testCase.verifyEqual(request.CallCount, 0);
        end

        function unauthorizedQuoteSummaryRefreshesCredentials(testCase)
            credential = SequenceRequest({ ...
                credentialResponse(204, "", "A1=B1"), ...
                credentialResponse(200, "oldcrumb", ""), ...
                credentialResponse(204, "", "A2=B2"), ...
                credentialResponse(200, "newcrumb", "")});
            request = SequenceRequest({ ...
                MException("MATLAB:webservices:HTTP401StatusCodeError", "The server returned status 401 Unauthorized."), ...
                quoteSummaryResponse()});
            session = yfinance.internal.Session( ...
                RequestFunction=@(varargin) request.send(varargin{:}), ...
                CredentialRequestFunction=@(varargin) credential.send(varargin{:}));

            response = session.getQuoteSummary("AAPL", Modules="price");

            testCase.verifyEqual(request.CallCount, 2);
            testCase.verifyTrue(isfield(response, "quoteSummary"));
            testCase.verifyEqual(session.CookieHeader, "A2=B2");
            testCase.verifyEqual(session.Crumb, "newcrumb");
            testCase.verifyEqual(string(request.LastArguments{10}), "newcrumb");
        end
    end
end

function response = searchResponse()
response = struct("quotes", struct.empty(0, 1), "news", struct.empty(0, 1));
end

function response = quoteSummaryResponse()
response = struct("quoteSummary", struct("result", struct("price", struct()), "error", []));
end

function response = timeseriesResponse()
response = struct("timeseries", struct("result", struct(), "error", []));
end

function response = screenerResponse()
result = struct("quotes", struct.empty(0, 1), "count", 0, "total", 0);
response = struct("finance", struct("result", result, "error", []));
end

function response = credentialResponse(statusCode, body, cookieHeader)
response = struct( ...
    "StatusCode", statusCode, ...
    "Body", body, ...
    "CookieHeader", cookieHeader);
end
