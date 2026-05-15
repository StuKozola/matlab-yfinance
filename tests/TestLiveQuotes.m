classdef TestLiveQuotes < matlab.unittest.TestCase
    %TESTLIVEQUOTES Verify live quote polling APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function quoteResponseConvertsToLiveQuoteTable(testCase)
            quotes = yfinance.internal.quoteResponseToLiveQuotes(quoteFixture(), Symbols=["AAPL"; "MSFT"]);

            testCase.verifyEqual(quotes.Symbol, ["AAPL"; "MSFT"]);
            testCase.verifyEqual(quotes.RegularMarketPrice, [200; 300]);
            testCase.verifyClass(quotes.RegularMarketTime, "datetime");
            testCase.verifyEqual(quotes.Properties.UserData.Symbols, ["AAPL"; "MSFT"]);
        end

        function webSocketSubscribeAndUnsubscribe(testCase)
            client = yfinance.WebSocket(Verbose=false);

            client.subscribe(["aapl", "msft"]);
            client.unsubscribe("MSFT");

            testCase.verifyEqual(client.Subscriptions, "AAPL");
            testCase.verifyTrue(client.IsOpen);
        end

        function webSocketPollUsesQuoteSession(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteResponse=quoteFixture());
            client = yfinance.WebSocket(Session=session, Verbose=false);

            client.subscribe(["AAPL", "MSFT"]);
            quotes = client.poll();

            testCase.verifyEqual(session.LastQuoteSymbols, ["AAPL"; "MSFT"]);
            testCase.verifyEqual(height(quotes), 2);
            testCase.verifyEqual(quotes.RegularMarketPrice(2), 300);
        end

        function webSocketListenReturnsSnapshots(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteResponse=quoteFixture());
            client = yfinance.WebSocket(Session=session, Verbose=false, PollInterval=0);

            client.subscribe("AAPL");
            messages = client.listen([], MaxIterations=1);

            testCase.verifyEqual(height(messages), 2);
            testCase.verifyEqual(messages.Symbol(1), "AAPL");
        end

        function asyncWebSocketInheritsPollingSurface(testCase)
            session = StaticChartSession(emptyChartFixture(), QuoteResponse=quoteFixture());
            client = yfinance.AsyncWebSocket(Session=session, Verbose=false, PollInterval=1);

            client.subscribe("AAPL");
            messages = client.listen([], MaxIterations=1);
            client.close();

            testCase.verifyEqual(messages.Symbol(1), "AAPL");
            testCase.verifyFalse(client.IsOpen);
        end
    end
end

function response = quoteFixture()
quotes(1) = struct( ...
    "symbol", "AAPL", ...
    "shortName", "Apple Inc.", ...
    "regularMarketPrice", 200, ...
    "regularMarketChange", 2, ...
    "regularMarketTime", 1778877000);
quotes(2) = struct( ...
    "symbol", "MSFT", ...
    "shortName", "Microsoft Corporation", ...
    "regularMarketPrice", 300, ...
    "regularMarketChange", 3, ...
    "regularMarketTime", 1778877000);
response = struct("quoteResponse", struct("result", quotes, "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
