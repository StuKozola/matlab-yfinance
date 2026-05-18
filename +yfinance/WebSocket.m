% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef WebSocket < handle
    %WEBSOCKET MATLAB-compatible live quote client.

    properties
        Url (1,1) string = "wss://streamer.finance.yahoo.com/?version=2"
        Transport (1,1) string {mustBeLiveTransport} = "poll"
        Verbose (1,1) logical = true
        PollInterval (1,1) double {mustBeNonnegative} = 15
    end

    properties (SetAccess = protected)
        IsOpen (1,1) logical = false
    end

    properties (SetAccess = private)
        Subscriptions (:,1) string = strings(0, 1)
    end

    properties (Access = protected)
        Session
        StreamClient = []
    end

    methods
        function obj = WebSocket(options)
            arguments
                options.Url (1,1) string = "wss://streamer.finance.yahoo.com/?version=2"
                options.Transport (1,1) string {mustBeLiveTransport} = "poll"
                options.Verbose (1,1) logical = true
                options.PollInterval (1,1) double {mustBeNonnegative} = 15
                options.Session = yfinance.internal.Session()
                options.StreamClient = []
                options.StreamTransport = []
            end

            obj.Url = options.Url;
            obj.Transport = lower(options.Transport);
            obj.Verbose = options.Verbose;
            obj.PollInterval = options.PollInterval;
            obj.Session = options.Session;
            obj.StreamClient = initializeStreamClient(options.StreamClient, options.StreamTransport);
        end

        function subscribe(obj, symbols)
            %SUBSCRIBE Add symbols to the live quote subscription set.
            symbols = yfinance.internal.normalizeSymbols(symbols);

            if isempty(symbols)
                error("yfinance:InvalidSymbol", "At least one ticker symbol must be provided.");
            end

            if obj.isStreamTransport()
                obj.ensureStreamClient();
                obj.StreamClient.subscribe(symbols);
                obj.Subscriptions = obj.StreamClient.Subscriptions;
                obj.IsOpen = obj.StreamClient.IsOpen;
                return
            end

            obj.Subscriptions = unique([obj.Subscriptions; symbols], "stable");
            obj.IsOpen = true;
        end

        function unsubscribe(obj, symbols)
            %UNSUBSCRIBE Remove symbols from the live quote subscription set.
            symbols = yfinance.internal.normalizeSymbols(symbols);

            if isempty(symbols)
                return
            end

            if obj.isStreamTransport()
                obj.ensureStreamClient();
                obj.StreamClient.unsubscribe(symbols);
                obj.Subscriptions = obj.StreamClient.Subscriptions;
                obj.IsOpen = obj.StreamClient.IsOpen;
                return
            end

            obj.Subscriptions = obj.Subscriptions(~ismember(obj.Subscriptions, symbols));
        end

        function quotes = poll(obj)
            %POLL Read one quote snapshot for the subscribed symbols.
            if isempty(obj.Subscriptions)
                quotes = table();
                quotes.Properties.UserData = struct("Symbols", obj.Subscriptions);
                return
            end

            if obj.isStreamTransport()
                obj.ensureStreamClient();
                quotes = obj.StreamClient.receive(MaxFrames=1);
                obj.IsOpen = obj.StreamClient.IsOpen;
                return
            end

            response = obj.Session.getQuote(obj.Subscriptions);
            quotes = yfinance.internal.quoteResponseToLiveQuotes(response, Symbols=obj.Subscriptions);
            obj.IsOpen = true;
        end

        function messages = listen(obj, messageHandler, options)
            %LISTEN Poll subscribed quotes and optionally dispatch callbacks.
            arguments
                obj
                messageHandler = []
                options.MaxIterations (1,1) double {mustBePositiveIntegerOrInf} = Inf
                options.PollInterval (1,1) double {mustBeNonnegative} = obj.defaultListenInterval()
            end

            messages = table();
            iteration = 0;

            while iteration < options.MaxIterations
                iteration = iteration + 1;
                quotes = obj.poll();

                if isempty(messages.Properties.VariableNames)
                    messages = quotes;
                else
                    messages = [messages; quotes]; %#ok<AGROW>
                end

                obj.dispatch(quotes, messageHandler);

                if iteration < options.MaxIterations && options.PollInterval > 0
                    pause(options.PollInterval);
                end
            end
        end

        function close(obj)
            %CLOSE Mark the live quote client closed.
            if obj.isStreamTransport() && ~isempty(obj.StreamClient)
                obj.StreamClient.close();
            end

            obj.IsOpen = false;
        end
    end

    methods (Access = protected)
        function value = isStreamTransport(obj)
            value = lower(obj.Transport) == "stream";
        end

        function interval = defaultListenInterval(obj)
            if obj.isStreamTransport()
                interval = 0;
            else
                interval = obj.PollInterval;
            end
        end

        function ensureStreamClient(obj)
            if isempty(obj.StreamClient)
                transport = yfinance.internal.live.WebSocketTransport(Url=obj.Url);
                obj.StreamClient = yfinance.internal.live.StreamClient(transport);
            end
        end

        function dispatch(~, quotes, messageHandler)
            if isempty(messageHandler) || height(quotes) == 0
                return
            end

            messages = table2struct(quotes);

            for messageIndex = 1:numel(messages)
                messageHandler(messages(messageIndex));
            end
        end
    end
end

function client = initializeStreamClient(client, transport)
if ~isempty(client) && ~isempty(transport)
    error("yfinance:InvalidInput", "Specify either StreamClient or StreamTransport, not both.");
end

if isempty(client) && ~isempty(transport)
    client = yfinance.internal.live.StreamClient(transport);
end
end

function mustBeLiveTransport(value)
mustBeMember(lower(value), ["poll", "stream"]);
end

function mustBePositiveIntegerOrInf(value)
if isinf(value)
    return
end

mustBePositive(value);
mustBeInteger(value);
end
