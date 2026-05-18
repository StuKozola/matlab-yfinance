% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef FakeConnectionFactory < handle
    %FAKECONNECTIONFACTORY Captures WebSocket transport connection requests.

    properties
        Connection
        LastHost (1,1) string = ""
        LastPort (1,1) double = NaN
        LastTimeout (1,1) double = NaN
        CallCount (1,1) double = 0
    end

    methods
        function obj = FakeConnectionFactory(connection)
            obj.Connection = connection;
        end

        function connection = create(obj, host, port, timeout)
            obj.LastHost = string(host);
            obj.LastPort = double(port);
            obj.LastTimeout = double(timeout);
            obj.CallCount = obj.CallCount + 1;
            connection = obj.Connection;
        end
    end
end
