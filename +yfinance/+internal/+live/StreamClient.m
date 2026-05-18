% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef StreamClient < handle
    %STREAMCLIENT Internal Yahoo live stream transport boundary.

    properties (SetAccess = private)
        Transport
        Subscriptions (:,1) string = strings(0, 1)
        IsOpen (1,1) logical = false
        ReconnectCount (1,1) double = 0
    end

    properties
        MaxReconnects (1,1) double {mustBeNonnegative, mustBeInteger} = 2
        HeartbeatInterval (1,1) double {mustBeNonnegative} = 15
        Clock (1,1) function_handle = @currentTime
    end

    properties (Access = private)
        LastHeartbeatTime (1,1) double = NaN
    end

    methods
        function obj = StreamClient(transport, options)
            arguments
                transport
                options.MaxReconnects (1,1) double {mustBeNonnegative, mustBeInteger} = 2
                options.HeartbeatInterval (1,1) double {mustBeNonnegative} = 15
                options.Clock (1,1) function_handle = @currentTime
            end

            obj.Transport = transport;
            obj.MaxReconnects = options.MaxReconnects;
            obj.HeartbeatInterval = options.HeartbeatInterval;
            obj.Clock = options.Clock;
        end

        function open(obj)
            obj.Transport.open();
            obj.IsOpen = true;
        end

        function subscribe(obj, symbols)
            symbols = yfinance.internal.normalizeSymbols(symbols);

            if isempty(symbols)
                error("yfinance:InvalidSymbol", "At least one ticker symbol must be provided.");
            end

            obj.ensureOpen();
            obj.sendSubscribe(symbols);
            obj.Subscriptions = unique([obj.Subscriptions; symbols], "stable");
        end

        function unsubscribe(obj, symbols)
            symbols = yfinance.internal.normalizeSymbols(symbols);

            if isempty(symbols)
                return
            end

            obj.ensureOpen();
            obj.Transport.send(yfinance.internal.live.streamControlMessage("unsubscribe", symbols));
            obj.Subscriptions = obj.Subscriptions(~ismember(obj.Subscriptions, symbols));
            obj.LastHeartbeatTime = obj.Clock();
        end

        function quotes = receive(obj, options)
            arguments
                obj
                options.MaxFrames (1,1) double {mustBeNonnegative, mustBeInteger} = 1
                options.MaxReconnects (1,1) double {mustBeNonnegative, mustBeInteger} = obj.MaxReconnects
            end

            obj.ensureOpen();
            obj.sendHeartbeatIfDue();
            frames = strings(0, 1);

            for frameIndex = 1:options.MaxFrames
                frame = obj.receiveFrameWithReconnect(options.MaxReconnects);

                if strlength(frame) == 0
                    break
                end

                frames(end + 1, 1) = string(frame); %#ok<AGROW>
            end

            quotes = yfinance.internal.live.streamFramesToLiveQuotes(frames);
        end

        function close(obj)
            if obj.IsOpen
                obj.Transport.close();
            end

            obj.IsOpen = false;
        end
    end

    methods (Access = private)
        function ensureOpen(obj)
            if ~obj.IsOpen
                obj.open();
            end
        end

        function sendSubscribe(obj, symbols)
            obj.Transport.send(yfinance.internal.live.streamControlMessage("subscribe", symbols));
            obj.LastHeartbeatTime = obj.Clock();
        end

        function sendHeartbeatIfDue(obj)
            if isempty(obj.Subscriptions)
                return
            end

            now = obj.Clock();

            if isnan(obj.LastHeartbeatTime) || (now - obj.LastHeartbeatTime) >= obj.HeartbeatInterval
                obj.sendSubscribe(obj.Subscriptions);
            end
        end

        function frame = receiveFrameWithReconnect(obj, maxReconnects)
            reconnects = 0;

            while true
                try
                    frame = obj.Transport.receive();
                catch exception
                    if ~isReconnectableError(exception)
                        rethrow(exception);
                    end

                    if reconnects >= maxReconnects
                        obj.closeTransport();
                        rethrow(exception);
                    end

                    reconnects = reconnects + 1;
                    obj.reconnect();
                    continue
                end

                if strlength(frame) > 0 || isempty(obj.Subscriptions)
                    return
                end

                if reconnects >= maxReconnects
                    obj.closeTransport();
                    return
                end

                reconnects = reconnects + 1;
                obj.reconnect();
            end
        end

        function reconnect(obj)
            if obj.IsOpen
                obj.closeTransport();
            end

            obj.open();
            obj.ReconnectCount = obj.ReconnectCount + 1;

            if ~isempty(obj.Subscriptions)
                obj.sendSubscribe(obj.Subscriptions);
            end
        end

        function closeTransport(obj)
            try
                obj.Transport.close();
            catch
                % Ignore close failures while replacing a broken stream.
            end

            obj.IsOpen = false;
        end
    end
end

function value = isReconnectableError(exception)
reconnectableIdentifiers = [
    "yfinance:Timeout"
    "yfinance:NetworkError"
    "yfinance:WebSocketHandshakeFailed"];
value = ismember(string(exception.identifier), reconnectableIdentifiers);
end

function value = currentTime()
value = posixtime(datetime("now", TimeZone="UTC"));
end
