% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TlsTcpConnection < handle
    %TLSTCPCONNECTION Minimal TLS socket adapter for internal WebSocket transport.

    properties (SetAccess = private)
        Socket = []
        InputStream = []
        OutputStream = []
    end

    properties (Constant)
        SupportsBlockingRead = true
    end

    properties (Dependent)
        NumBytesAvailable
    end

    methods
        function obj = TlsTcpConnection(options)
            arguments
                options.Host (1,1) string
                options.Port (1,1) double {mustBeInteger, mustBePositive}
                options.Timeout (1,1) double {mustBePositive} = 30
            end

            obj.open(options.Host, options.Port, options.Timeout);
        end

        function count = get.NumBytesAvailable(obj)
            if isempty(obj.InputStream)
                count = 0;
                return
            end

            try
                count = double(obj.InputStream.available());
            catch
                count = 0;
            end
        end

        function write(obj, data, ~)
            bytes = uint8(data(:));

            for byteIndex = 1:numel(bytes)
                obj.OutputStream.write(int32(bytes(byteIndex)));
            end

            obj.OutputStream.flush();
        end

        function data = read(obj, count, ~)
            count = double(count);
            data = zeros(count, 1, "uint8");

            for byteIndex = 1:count
                value = obj.readByte();

                if value < 0
                    error("yfinance:NetworkError", "TLS WebSocket connection closed while reading data.");
                end

                data(byteIndex) = uint8(value);
            end
        end

        function close(obj)
            if ~isempty(obj.Socket)
                obj.Socket.close();
            end

            obj.Socket = [];
            obj.InputStream = [];
            obj.OutputStream = [];
        end
    end

    methods (Access = private)
        function value = readByte(obj)
            try
                value = obj.InputStream.read();
            catch exception
                if contains(string(exception.message), "timed out", IgnoreCase=true)
                    error("yfinance:Timeout", "Timed out waiting for TLS WebSocket data.");
                end

                error("yfinance:NetworkError", "Could not read TLS WebSocket data. %s", exception.message);
            end
        end

        function open(obj, host, port, timeout)
            socket = [];

            try
                socketFactory = javax.net.ssl.SSLSocketFactory.getDefault();
                socket = socketFactory.createSocket(char(host), int32(port));
                socket.setSoTimeout(int32(max(1, round(timeout*1000))));
                parameters = socket.getSSLParameters();
                parameters.setEndpointIdentificationAlgorithm('HTTPS');
                socket.setSSLParameters(parameters);
                socket.startHandshake();

                obj.Socket = socket;
                obj.InputStream = socket.getInputStream();
                obj.OutputStream = socket.getOutputStream();
            catch exception
                closeSocket(socket);
                error( ...
                    "yfinance:NetworkError", ...
                    "Could not open TLS WebSocket connection to %s:%d. %s", ...
                    host, ...
                    port, ...
                    exception.message);
            end
        end
    end
end

function closeSocket(socket)
if isempty(socket)
    return
end

try
    socket.close();
catch
    % Ignore cleanup failures while reporting the original connection error.
end
end
