% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef FakeStreamTransport < handle
    %FAKESTREAMTRANSPORT Test double for internal live stream transport.

    properties
        Frames (:,1) string = strings(0, 1)
        ReceiveErrorIdentifiers (:,1) string = strings(0, 1)
        SentMessages (:,1) string = strings(0, 1)
        IsOpen (1,1) logical = false
        OpenCount (1,1) double = 0
        CloseCount (1,1) double = 0
    end

    methods
        function obj = FakeStreamTransport(frames)
            if nargin > 0
                obj.Frames = string(frames(:));
            end
        end

        function open(obj)
            obj.IsOpen = true;
            obj.OpenCount = obj.OpenCount + 1;
        end

        function send(obj, message)
            obj.SentMessages(end + 1, 1) = string(message);
        end

        function frame = receive(obj)
            if ~isempty(obj.ReceiveErrorIdentifiers)
                identifier = obj.ReceiveErrorIdentifiers(1);
                obj.ReceiveErrorIdentifiers(1) = [];
                error(char(identifier), "Injected fake stream receive failure.");
            end

            if isempty(obj.Frames)
                frame = "";
                return
            end

            frame = obj.Frames(1);
            obj.Frames(1) = [];
        end

        function close(obj)
            obj.IsOpen = false;
            obj.CloseCount = obj.CloseCount + 1;
        end
    end
end
