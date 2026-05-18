% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

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

        function webSocketStreamTransportUsesStreamClient(testCase)
            transport = FakeStreamTransport([
                streamFrame("AAPL", 200.25)
                streamFrame("MSFT", 300.5)]);
            client = yfinance.WebSocket( ...
                Transport="stream", ...
                StreamTransport=transport, ...
                Verbose=false);

            client.subscribe(["aapl", "msft"]);
            messages = client.listen([], MaxIterations=2);
            client.unsubscribe("MSFT");
            client.close();

            testCase.verifyEqual(client.Transport, "stream");
            testCase.verifyEqual(client.Subscriptions, "AAPL");
            testCase.verifyFalse(client.IsOpen);
            testCase.verifyFalse(transport.IsOpen);
            testCase.verifyEqual(transport.CloseCount, 1);
            testCase.verifyEqual(height(messages), 2);
            testCase.verifyEqual(messages.Symbol, ["AAPL"; "MSFT"]);
            testCase.verifyEqual(messages.RegularMarketPrice, [200.25; 300.5], AbsTol=1e-6);

            subscribePayload = jsondecode(char(transport.SentMessages(1)));
            unsubscribePayload = jsondecode(char(transport.SentMessages(2)));
            testCase.verifyEqual(string(subscribePayload.subscribe(:)), ["AAPL"; "MSFT"]);
            testCase.verifyEqual(string(unsubscribePayload.unsubscribe), "MSFT");
        end

        function experimentalWebSocketDefaultsToStreamTransport(testCase)
            transport = FakeStreamTransport(streamFrame("BTC-USD", 100000.5));
            client = yfinance.ExperimentalWebSocket( ...
                StreamTransport=transport, ...
                Verbose=false, ...
                HeartbeatInterval=0);

            client.subscribe("BTC-USD");
            messages = client.listen([], MaxIterations=1);
            client.close();

            testCase.verifyEqual(client.Transport, "stream");
            testCase.verifyEqual(numel(transport.SentMessages), 2);
            testCase.verifyEqual(height(messages), 1);
            testCase.verifyEqual(messages.Symbol, "BTC-USD");
            testCase.verifyEqual(messages.RegularMarketPrice, 100000.5, AbsTol=1e-6);
        end

        function experimentalWebSocketListenHandlesReconnectLoop(testCase)
            transport = FakeStreamTransport([
                streamFrame("AAPL", 200.25)
                ""
                streamFrame("MSFT", 300.5)
                streamFrame("BTC-USD", 100000.5)]);
            client = yfinance.ExperimentalWebSocket( ...
                StreamTransport=transport, ...
                Verbose=false, ...
                MaxReconnects=1, ...
                HeartbeatInterval=0);
            recorder = CallbackRecorder();

            client.subscribe(["AAPL", "MSFT", "BTC-USD"]);
            messages = client.listen(@(message) recorder.record(message), MaxIterations=3);
            client.close();

            testCase.verifyEqual(height(messages), 3);
            testCase.verifyEqual(messages.Symbol, ["AAPL"; "MSFT"; "BTC-USD"]);
            testCase.verifyEqual(numel(recorder.Messages), 3);
            testCase.verifyEqual(recorder.symbols(), ["AAPL"; "MSFT"; "BTC-USD"]);
            testCase.verifyEqual(transport.OpenCount, 2);
            testCase.verifyEqual(transport.CloseCount, 2);
            testCase.verifyEqual(numel(transport.SentMessages), 5);
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

function frame = streamFrame(symbol, price)
payload = struct("message", pricingDataMessage(symbol, price));
frame = string(jsonencode(payload));
end

function message = pricingDataMessage(symbol, price)
bytes = [
    stringField(1, symbol)
    floatField(2, price)
    sint64Field(3, 1)
    stringField(4, "USD")
    stringField(5, "NMS")];
message = string(java.util.Base64.getEncoder().encodeToString(uint8(bytes(:))));
end

function bytes = stringField(fieldNumber, value)
bytes = lengthDelimitedField(fieldNumber, uint8(char(value)).');
end

function bytes = lengthDelimitedField(fieldNumber, value)
value = uint8(value(:));
bytes = [
    varint(uint64(fieldNumber * 8 + 2))
    varint(uint64(numel(value)))
    value];
end

function bytes = floatField(fieldNumber, value)
bytes = [
    varint(uint64(fieldNumber * 8 + 5))
    typecast(single(value), "uint8").'];
end

function bytes = sint64Field(fieldNumber, value)
bytes = [
    varint(uint64(fieldNumber * 8))
    varint(zigZagEncode(value))];
end

function value = zigZagEncode(value)
if value >= 0
    value = uint64(value * 2);
else
    value = uint64(-2 * value - 1);
end
end

function bytes = varint(value)
bytes = uint8.empty(0, 1);

while value >= 128
    bytes(end + 1, 1) = uint8(bitor(bitand(value, 127), 128)); %#ok<AGROW>
    value = bitshift(value, -7);
end

bytes(end + 1, 1) = uint8(value);
end
