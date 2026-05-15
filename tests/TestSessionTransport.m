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

        function quoteSummaryUsesQuery2Endpoint(testCase)
            request = SequenceRequest({quoteSummaryResponse()});
            session = yfinance.internal.Session( ...
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
    end
end

function response = searchResponse()
response = struct("quotes", struct.empty(0, 1), "news", struct.empty(0, 1));
end

function response = quoteSummaryResponse()
response = struct("quoteSummary", struct("result", struct("price", struct()), "error", []));
end
