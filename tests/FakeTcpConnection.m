% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef FakeTcpConnection < handle
    %FAKETCPCONNECTION Test double for WebSocketTransport TCP operations.

    properties
        ReadBuffer (:,1) uint8 = uint8.empty(0, 1)
        WriteBuffer (:,1) uint8 = uint8.empty(0, 1)
    end

    properties (Dependent)
        NumBytesAvailable
    end

    methods
        function obj = FakeTcpConnection(readBuffer)
            if nargin > 0
                obj.ReadBuffer = uint8(readBuffer(:));
            end
        end

        function count = get.NumBytesAvailable(obj)
            count = numel(obj.ReadBuffer);
        end

        function write(obj, data, ~)
            obj.WriteBuffer = [obj.WriteBuffer; uint8(data(:))];
        end

        function data = read(obj, count, ~)
            count = min(count, numel(obj.ReadBuffer));
            data = obj.ReadBuffer(1:count);
            obj.ReadBuffer(1:count) = [];
        end

        function appendReadBuffer(obj, data)
            obj.ReadBuffer = [obj.ReadBuffer; uint8(data(:))];
        end
    end
end
