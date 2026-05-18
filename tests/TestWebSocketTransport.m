% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestWebSocketTransport < matlab.unittest.TestCase
    %TESTWEBSOCKETTRANSPORT Verify internal WebSocket transport.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function openSendsHandshakeAndValidatesAccept(testCase)
            connection = FakeTcpConnection(handshakeResponse(fixedAcceptKey()));
            transport = yfinance.internal.live.WebSocketTransport( ...
                Url="ws://stream.example.test/live?version=2", ...
                KeyGenerator=@fixedWebSocketKey, ...
                ConnectionFactory=@(~, ~, ~) connection);

            transport.open();
            request = string(native2unicode(connection.WriteBuffer.', "UTF-8"));

            testCase.verifyTrue(transport.IsOpen);
            testCase.verifyTrue(contains(request, "GET /live?version=2 HTTP/1.1"));
            testCase.verifyTrue(contains(request, "Host: stream.example.test"));
            testCase.verifyTrue(contains(request, "Upgrade: websocket"));
            testCase.verifyTrue(contains(request, "Sec-WebSocket-Key: " + fixedWebSocketKey()));
        end

        function sendWritesMaskedTextFrame(testCase)
            connection = FakeTcpConnection(handshakeResponse(fixedAcceptKey()));
            transport = yfinance.internal.live.WebSocketTransport( ...
                Url="ws://stream.example.test", ...
                KeyGenerator=@fixedWebSocketKey, ...
                ConnectionFactory=@(~, ~, ~) connection);

            transport.open();
            connection.WriteBuffer = uint8.empty(0, 1);
            transport.send("{""subscribe"":[""AAPL""]}");
            [opcode, payload, masked] = decodeClientFrame(connection.WriteBuffer);

            testCase.verifyEqual(opcode, 1);
            testCase.verifyTrue(masked);
            testCase.verifyEqual(string(native2unicode(payload.', "UTF-8")), "{""subscribe"":[""AAPL""]}");
        end

        function openIncludesExplicitPortInHostHeader(testCase)
            connection = FakeTcpConnection(handshakeResponse(fixedAcceptKey()));
            transport = yfinance.internal.live.WebSocketTransport( ...
                Url="ws://stream.example.test:8080/live", ...
                KeyGenerator=@fixedWebSocketKey, ...
                ConnectionFactory=@(~, ~, ~) connection);

            transport.open();
            request = string(native2unicode(connection.WriteBuffer.', "UTF-8"));

            testCase.verifyTrue(contains(request, "GET /live HTTP/1.1"));
            testCase.verifyTrue(contains(request, "Host: stream.example.test:8080"));
        end

        function receiveReadsServerTextFrame(testCase)
            connection = FakeTcpConnection([
                handshakeResponse(fixedAcceptKey())
                serverTextFrame("{""message"":""abc""}")]);
            transport = yfinance.internal.live.WebSocketTransport( ...
                Url="ws://stream.example.test", ...
                KeyGenerator=@fixedWebSocketKey, ...
                ConnectionFactory=@(~, ~, ~) connection);

            transport.open();
            message = transport.receive();

            testCase.verifyEqual(message, "{""message"":""abc""}");
        end

        function receiveRespondsToPingBeforeTextFrame(testCase)
            connection = FakeTcpConnection(handshakeResponse(fixedAcceptKey()));
            transport = yfinance.internal.live.WebSocketTransport( ...
                Url="ws://stream.example.test", ...
                KeyGenerator=@fixedWebSocketKey, ...
                ConnectionFactory=@(~, ~, ~) connection);

            transport.open();
            connection.WriteBuffer = uint8.empty(0, 1);
            connection.appendReadBuffer([
                serverPingFrame("ok")
                serverTextFrame("{""message"":""abc""}")]);
            message = transport.receive();
            [opcode, payload, masked] = decodeClientFrame(connection.WriteBuffer);

            testCase.verifyEqual(message, "{""message"":""abc""}");
            testCase.verifyEqual(opcode, 10);
            testCase.verifyTrue(masked);
            testCase.verifyEqual(string(native2unicode(payload.', "UTF-8")), "ok");
        end

        function closeWritesMaskedCloseFrame(testCase)
            connection = FakeTcpConnection(handshakeResponse(fixedAcceptKey()));
            transport = yfinance.internal.live.WebSocketTransport( ...
                Url="ws://stream.example.test", ...
                KeyGenerator=@fixedWebSocketKey, ...
                ConnectionFactory=@(~, ~, ~) connection);

            transport.open();
            connection.WriteBuffer = uint8.empty(0, 1);
            transport.close();
            [opcode, payload, masked] = decodeClientFrame(connection.WriteBuffer);

            testCase.verifyFalse(transport.IsOpen);
            testCase.verifyEqual(opcode, 8);
            testCase.verifyTrue(masked);
            testCase.verifyEmpty(payload);
            testCase.verifyTrue(connection.Closed);
        end

        function wssUrlUsesSecureConnectionFactory(testCase)
            connection = FakeTcpConnection(handshakeResponse(fixedAcceptKey()));
            secureFactory = FakeConnectionFactory(connection);
            transport = yfinance.internal.live.WebSocketTransport( ...
                Url="wss://streamer.finance.yahoo.com/?version=2", ...
                Timeout=7, ...
                KeyGenerator=@fixedWebSocketKey, ...
                SecureConnectionFactory=@secureFactory.create);

            transport.open();
            request = string(native2unicode(connection.WriteBuffer.', "UTF-8"));

            testCase.verifyTrue(transport.IsOpen);
            testCase.verifyEqual(secureFactory.CallCount, 1);
            testCase.verifyEqual(secureFactory.LastHost, "streamer.finance.yahoo.com");
            testCase.verifyEqual(secureFactory.LastPort, 443);
            testCase.verifyEqual(secureFactory.LastTimeout, 7);
            testCase.verifyTrue(contains(request, "GET /?version=2 HTTP/1.1"));
            testCase.verifyTrue(contains(request, "Host: streamer.finance.yahoo.com"));
        end

        function badHandshakeAcceptErrors(testCase)
            connection = FakeTcpConnection(handshakeResponse("bad-accept"));
            transport = yfinance.internal.live.WebSocketTransport( ...
                Url="ws://stream.example.test", ...
                KeyGenerator=@fixedWebSocketKey, ...
                ConnectionFactory=@(~, ~, ~) connection);

            testCase.verifyError(@() transport.open(), "yfinance:WebSocketHandshakeFailed");
        end
    end
end

function key = fixedWebSocketKey()
key = "dGhlIHNhbXBsZSBub25jZQ==";
end

function key = fixedAcceptKey()
key = "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=";
end

function bytes = handshakeResponse(acceptKey)
text = "HTTP/1.1 101 Switching Protocols" + newline + ...
    "Upgrade: websocket" + newline + ...
    "Connection: Upgrade" + newline + ...
    "Sec-WebSocket-Accept: " + acceptKey + newline + ...
    newline;
text = replace(text, newline, sprintf("\r\n"));
bytes = uint8(char(text)).';
end

function frame = serverTextFrame(message)
payload = uint8(char(message)).';
frame = [uint8(129); uint8(numel(payload)); payload];
end

function frame = serverPingFrame(message)
payload = uint8(char(message)).';
frame = [uint8(137); uint8(numel(payload)); payload];
end

function [opcode, payload, masked] = decodeClientFrame(frame)
opcode = double(bitand(frame(1), 15));
masked = bitand(frame(2), 128) ~= 0;
payloadLength = double(bitand(frame(2), 127));
position = 3;

if payloadLength == 126
    payloadLength = double(frame(position)) * 256 + double(frame(position + 1));
    position = position + 2;
elseif payloadLength == 127
    payloadLength = 0;

    for byteIndex = 1:8
        payloadLength = payloadLength * 256 + double(frame(position));
        position = position + 1;
    end
end

maskKey = uint8.empty(0, 1);

if masked
    maskKey = frame(position:(position + 3));
    position = position + 4;
end

payload = frame(position:(position + payloadLength - 1));

if masked
    for payloadIndex = 1:numel(payload)
        keyIndex = mod(payloadIndex - 1, 4) + 1;
        payload(payloadIndex) = bitxor(payload(payloadIndex), maskKey(keyIndex));
    end
end
end
