classdef WebSocket < handle
    %WEBSOCKET MATLAB-compatible live quote client.

    properties
        Url (1,1) string = "wss://streamer.finance.yahoo.com/?version=2"
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
    end

    methods
        function obj = WebSocket(options)
            arguments
                options.Url (1,1) string = "wss://streamer.finance.yahoo.com/?version=2"
                options.Verbose (1,1) logical = true
                options.PollInterval (1,1) double {mustBeNonnegative} = 15
                options.Session = yfinance.internal.Session()
            end

            obj.Url = options.Url;
            obj.Verbose = options.Verbose;
            obj.PollInterval = options.PollInterval;
            obj.Session = options.Session;
        end

        function subscribe(obj, symbols)
            %SUBSCRIBE Add symbols to the live quote subscription set.
            symbols = yfinance.internal.normalizeSymbols(symbols);

            if isempty(symbols)
                error("yfinance:InvalidSymbol", "At least one ticker symbol must be provided.");
            end

            obj.Subscriptions = unique([obj.Subscriptions; symbols], "stable");
            obj.IsOpen = true;
        end

        function unsubscribe(obj, symbols)
            %UNSUBSCRIBE Remove symbols from the live quote subscription set.
            symbols = yfinance.internal.normalizeSymbols(symbols);
            obj.Subscriptions = obj.Subscriptions(~ismember(obj.Subscriptions, symbols));
        end

        function quotes = poll(obj)
            %POLL Read one quote snapshot for the subscribed symbols.
            if isempty(obj.Subscriptions)
                quotes = table();
                quotes.Properties.UserData = struct("Symbols", obj.Subscriptions);
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
                options.PollInterval (1,1) double {mustBeNonnegative} = obj.PollInterval
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
            obj.IsOpen = false;
        end
    end

    methods (Access = protected)
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

function mustBePositiveIntegerOrInf(value)
if isinf(value)
    return
end

mustBePositive(value);
mustBeInteger(value);
end
