% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestLiveStreamScaffold < matlab.unittest.TestCase
    %TESTLIVESTREAMSCAFFOLD Verify internal live stream scaffolding.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function subscribeControlMessageUsesYahooShape(testCase)
            message = yfinance.internal.live.streamControlMessage("subscribe", ["aapl", "msft"]);
            payload = jsondecode(char(message));

            testCase.verifyEqual(string(payload.subscribe(:)), ["AAPL"; "MSFT"]);
        end

        function unsubscribeControlMessageUsesYahooShape(testCase)
            message = yfinance.internal.live.streamControlMessage("unsubscribe", "aapl");
            payload = jsondecode(char(message));

            testCase.verifyEqual(string(payload.unsubscribe), "AAPL");
        end

        function streamFrameDecodesPricingDataMessage(testCase)
            frame = streamFrame("AAPL", 200.25);

            data = yfinance.internal.live.decodeStreamFrame(frame);

            testCase.verifyEqual(data.Symbol, "AAPL");
            testCase.verifyEqual(data.RegularMarketPrice, 200.25, AbsTol=1e-6);
        end

        function streamFramesConvertToLiveQuoteTable(testCase)
            frames = [
                streamFrame("AAPL", 200.25)
                streamFrame("MSFT", 300.5)];

            quotes = yfinance.internal.live.streamFramesToLiveQuotes(frames);

            testCase.verifyEqual(height(quotes), 2);
            testCase.verifyEqual(quotes.Symbol, ["AAPL"; "MSFT"]);
            testCase.verifyEqual(quotes.RegularMarketPrice, [200.25; 300.5], AbsTol=1e-6);
            testCase.verifyEqual(quotes.Properties.UserData.Symbols, ["AAPL"; "MSFT"]);
        end

        function streamClientUsesTransportBoundary(testCase)
            transport = FakeStreamTransport([
                streamFrame("AAPL", 200.25)
                streamFrame("MSFT", 300.5)]);
            client = yfinance.internal.live.StreamClient(transport);

            client.subscribe(["aapl", "msft"]);
            quotes = client.receive(MaxFrames=2);
            client.unsubscribe("MSFT");
            client.close();

            testCase.verifyFalse(client.IsOpen);
            testCase.verifyFalse(transport.IsOpen);
            testCase.verifyEqual(transport.CloseCount, 1);
            testCase.verifyEqual(client.Subscriptions, "AAPL");
            testCase.verifyEqual(height(quotes), 2);
            testCase.verifyEqual(quotes.Symbol, ["AAPL"; "MSFT"]);

            subscribePayload = jsondecode(char(transport.SentMessages(1)));
            unsubscribePayload = jsondecode(char(transport.SentMessages(2)));
            testCase.verifyEqual(string(subscribePayload.subscribe(:)), ["AAPL"; "MSFT"]);
            testCase.verifyEqual(string(unsubscribePayload.unsubscribe), "MSFT");
        end

        function invalidFrameReportsStructuredError(testCase)
            testCase.verifyError( ...
                @() yfinance.internal.live.decodeStreamFrame("{}"), ...
                "yfinance:InvalidStreamFrame");
        end
    end
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
message = base64Encode(bytes);
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

function value = base64Encode(bytes)
value = string(java.util.Base64.getEncoder().encodeToString(uint8(bytes(:))));
end
