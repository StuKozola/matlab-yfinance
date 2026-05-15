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
    end
end

function response = searchResponse()
response = struct("quotes", struct.empty(0, 1), "news", struct.empty(0, 1));
end
