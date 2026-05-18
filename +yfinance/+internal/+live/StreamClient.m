% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef StreamClient < handle
    %STREAMCLIENT Internal Yahoo live stream transport boundary.

    properties (SetAccess = private)
        Transport
        Subscriptions (:,1) string = strings(0, 1)
        IsOpen (1,1) logical = false
    end

    methods
        function obj = StreamClient(transport)
            obj.Transport = transport;
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
            obj.Transport.send(yfinance.internal.live.streamControlMessage("subscribe", symbols));
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
        end

        function quotes = receive(obj, options)
            arguments
                obj
                options.MaxFrames (1,1) double {mustBeNonnegative, mustBeInteger} = 1
            end

            obj.ensureOpen();
            frames = strings(0, 1);

            for frameIndex = 1:options.MaxFrames
                frame = obj.Transport.receive();

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
    end
end
