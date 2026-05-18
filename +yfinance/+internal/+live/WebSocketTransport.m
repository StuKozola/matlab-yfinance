% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef WebSocketTransport < handle
    %WEBSOCKETTRANSPORT Internal RFC 6455 transport for unencrypted ws:// URLs.

    properties
        Url (1,1) string
        Timeout (1,1) double {mustBePositive} = 30
        ConnectionFactory (1,1) function_handle = @defaultConnectionFactory
        KeyGenerator (1,1) function_handle = @randomWebSocketKey
    end

    properties (SetAccess = private)
        Connection = []
        IsOpen (1,1) logical = false
    end

    properties (Access = private)
        ParsedUrl struct = struct()
    end

    methods
        function obj = WebSocketTransport(options)
            arguments
                options.Url (1,1) string = "wss://streamer.finance.yahoo.com/?version=2"
                options.Timeout (1,1) double {mustBePositive} = 30
                options.ConnectionFactory (1,1) function_handle = @defaultConnectionFactory
                options.KeyGenerator (1,1) function_handle = @randomWebSocketKey
            end

            obj.Url = options.Url;
            obj.Timeout = options.Timeout;
            obj.ConnectionFactory = options.ConnectionFactory;
            obj.KeyGenerator = options.KeyGenerator;
        end

        function open(obj)
            parsed = parseWebSocketUrl(obj.Url);

            if parsed.Scheme == "wss"
                error( ...
                    "yfinance:UnsupportedTransport", ...
                    "MATLAB R2024b does not provide a built-in TLS WebSocket client. Use an internal test transport or a future TLS-capable transport for %s.", ...
                    obj.Url);
            end

            key = string(obj.KeyGenerator());
            obj.Connection = obj.ConnectionFactory(parsed.Host, parsed.Port, obj.Timeout);
            writeBytes(obj.Connection, handshakeRequest(parsed, key));
            response = readHttpHeader(obj.Connection, obj.Timeout);
            validateHandshake(response, key);
            obj.ParsedUrl = parsed;
            obj.IsOpen = true;
        end

        function send(obj, message)
            obj.ensureOpen();
            payload = uint8(char(string(message))).';
            writeBytes(obj.Connection, websocketFrame(1, payload, true));
        end

        function message = receive(obj)
            obj.ensureOpen();

            while true
                [opcode, payload] = readFrame(obj.Connection, obj.Timeout);

                switch opcode
                    case 1
                        message = string(native2unicode(payload.', "UTF-8"));
                        return
                    case 8
                        obj.IsOpen = false;
                        message = "";
                        return
                    case 9
                        writeBytes(obj.Connection, websocketFrame(10, payload, true));
                    case 10
                        continue
                    otherwise
                        error("yfinance:InvalidStreamFrame", "Unsupported WebSocket opcode %d.", opcode);
                end
            end
        end

        function close(obj)
            if obj.IsOpen && ~isempty(obj.Connection)
                writeBytes(obj.Connection, websocketFrame(8, uint8.empty(0, 1), true));
            end

            obj.IsOpen = false;
            obj.Connection = [];
        end
    end

    methods (Access = private)
        function ensureOpen(obj)
            if ~obj.IsOpen
                obj.open();
            end
        end
    end
end

function connection = defaultConnectionFactory(host, port, timeout)
connection = tcpclient(host, port, Timeout=timeout, ConnectTimeout=timeout);
end

function parsed = parseWebSocketUrl(url)
try
    uri = matlab.net.URI(strtrim(url));
catch exception
    error("yfinance:InvalidUrl", "Invalid WebSocket URL. %s", exception.message);
end

scheme = lower(string(uri.Scheme));

if scheme ~= "ws" && scheme ~= "wss"
    error("yfinance:InvalidUrl", "WebSocket URL must start with ws:// or wss://.");
end

host = string(uri.Host);

if strlength(host) == 0 || ismissing(host)
    error("yfinance:InvalidUrl", "WebSocket URL must include a host.");
end

path = string(uri.EncodedPath);

if isempty(path) || strlength(path) == 0 || ismissing(path)
    path = "/";
end

query = string(uri.EncodedQuery);

if ~isempty(query) && strlength(query) > 0 && ~ismissing(query)
    path = path + "?" + query;
end

portValue = uri.Port;

if isempty(portValue)
    if scheme == "wss"
        port = 443;
    else
        port = 80;
    end
else
    port = str2double(string(portValue));

    if isnan(port)
        error("yfinance:InvalidUrl", "WebSocket URL contains an invalid port.");
    end
end

parsed = struct("Scheme", scheme, "Host", host, "Port", port, "Path", path);
end

function request = handshakeRequest(parsed, key)
hostHeader = parsed.Host;

if ~(parsed.Scheme == "ws" && parsed.Port == 80) && ~(parsed.Scheme == "wss" && parsed.Port == 443)
    hostHeader = hostHeader + ":" + string(parsed.Port);
end

lines = [
    "GET " + parsed.Path + " HTTP/1.1"
    "Host: " + hostHeader
    "Upgrade: websocket"
    "Connection: Upgrade"
    "Sec-WebSocket-Key: " + key
    "Sec-WebSocket-Version: 13"
    ""
    ""];
request = uint8(char(strjoin(lines, sprintf('\r\n')))).';
end

function response = readHttpHeader(connection, timeout)
deadline = tic;
buffer = uint8.empty(0, 1);
terminator = uint8(char(sprintf('\r\n\r\n'))).';

while true
    available = bytesAvailable(connection);

    if available > 0
        buffer = [buffer; readBytes(connection, 1)]; %#ok<AGROW>

        if containsBytePattern(buffer, terminator)
            response = string(native2unicode(buffer.', "UTF-8"));
            return
        end

        continue
    end

    if toc(deadline) > timeout
        error("yfinance:Timeout", "Timed out waiting for WebSocket handshake response.");
    end

    pause(0.01);
end
end

function validateHandshake(response, key)
if ~startsWith(response, "HTTP/1.1 101") && ~startsWith(response, "HTTP/1.0 101")
    error("yfinance:WebSocketHandshakeFailed", "WebSocket server did not accept the upgrade request.");
end

headers = lower(response);

if ~contains(headers, "upgrade: websocket") || ~contains(headers, "connection: upgrade")
    error("yfinance:WebSocketHandshakeFailed", "WebSocket upgrade response did not contain required headers.");
end

expectedAccept = lower(secWebSocketAccept(key));

if ~contains(headers, "sec-websocket-accept: " + expectedAccept)
    error("yfinance:WebSocketHandshakeFailed", "WebSocket upgrade response contained an invalid accept key.");
end
end

function [opcode, payload] = readFrame(connection, timeout)
header = readExact(connection, 2, timeout);
opcode = double(bitand(header(1), 15));
masked = bitand(header(2), 128) ~= 0;
payloadLength = double(bitand(header(2), 127));

if payloadLength == 126
    payloadLength = bytesToUint(readExact(connection, 2, timeout));
elseif payloadLength == 127
    payloadLength = bytesToUint(readExact(connection, 8, timeout));
end

maskKey = uint8.empty(0, 1);

if masked
    maskKey = readExact(connection, 4, timeout);
end

payload = readExact(connection, payloadLength, timeout);

if masked
    payload = applyMask(payload, maskKey);
end
end

function frame = websocketFrame(opcode, payload, masked)
payload = uint8(payload(:));
firstByte = uint8(128 + opcode);
payloadLength = numel(payload);

if payloadLength <= 125
    lengthBytes = uint8(payloadLength);
elseif payloadLength <= 65535
    lengthBytes = [uint8(126); uint16ToBytes(payloadLength)];
else
    lengthBytes = [uint8(127); uint64ToBytes(payloadLength)];
end

if masked
    lengthBytes(1) = bitor(lengthBytes(1), 128);
    maskKey = randi([0, 255], 4, 1, "uint8");
    payload = applyMask(payload, maskKey);
    frame = [firstByte; lengthBytes; maskKey; payload];
else
    frame = [firstByte; lengthBytes; payload];
end
end

function payload = applyMask(payload, maskKey)
for payloadIndex = 1:numel(payload)
    keyIndex = mod(payloadIndex - 1, 4) + 1;
    payload(payloadIndex) = bitxor(payload(payloadIndex), maskKey(keyIndex));
end
end

function data = readExact(connection, count, timeout)
deadline = tic;
data = uint8.empty(0, 1);

while numel(data) < count
    available = min(bytesAvailable(connection), count - numel(data));

    if available > 0
        data = [data; readBytes(connection, available)]; %#ok<AGROW>
    elseif toc(deadline) > timeout
        error("yfinance:Timeout", "Timed out waiting for WebSocket frame data.");
    else
        pause(0.01);
    end
end
end

function count = bytesAvailable(connection)
count = double(connection.NumBytesAvailable);
end

function writeBytes(connection, data)
write(connection, uint8(data(:)), "uint8");
end

function data = readBytes(connection, count)
data = read(connection, count, "uint8");
data = uint8(data(:));
end

function value = bytesToUint(bytes)
value = 0;

for byteIndex = 1:numel(bytes)
    value = value * 256 + double(bytes(byteIndex));
end
end

function bytes = uint16ToBytes(value)
bytes = uint8([floor(value / 256); mod(value, 256)]);
end

function bytes = uint64ToBytes(value)
bytes = zeros(8, 1, "uint8");

for byteIndex = 8:-1:1
    bytes(byteIndex) = uint8(mod(value, 256));
    value = floor(value / 256);
end
end

function value = containsBytePattern(bytes, pattern)
value = false;

if numel(bytes) < numel(pattern)
    return
end

for index = 1:(numel(bytes) - numel(pattern) + 1)
    if isequal(bytes(index:(index + numel(pattern) - 1)), pattern)
        value = true;
        return
    end
end
end

function key = randomWebSocketKey()
bytes = randi([0, 255], 16, 1, "uint8");
key = string(java.util.Base64.getEncoder().encodeToString(bytes));
end

function accept = secWebSocketAccept(key)
guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
digest = java.security.MessageDigest.getInstance("SHA-1");
hash = digest.digest(uint8(char(key + guid)));
accept = string(java.util.Base64.getEncoder().encodeToString(hash));
end
