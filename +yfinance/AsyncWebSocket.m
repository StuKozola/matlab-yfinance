classdef AsyncWebSocket < yfinance.WebSocket
    %ASYNCWEBSOCKET Timer-backed live quote client.

    properties (SetAccess = private)
        Timer = []
    end

    properties (Access = private)
        MessageHandler = []
    end

    methods
        function obj = AsyncWebSocket(options)
            arguments
                options.Url (1,1) string = "wss://streamer.finance.yahoo.com/?version=2"
                options.Verbose (1,1) logical = true
                options.PollInterval (1,1) double {mustBePositive} = 15
                options.Session = yfinance.internal.Session()
            end

            obj@yfinance.WebSocket( ...
                Url=options.Url, ...
                Verbose=options.Verbose, ...
                PollInterval=options.PollInterval, ...
                Session=options.Session);
        end

        function start(obj, messageHandler, options)
            %START Begin timer-backed polling.
            arguments
                obj
                messageHandler = []
                options.PollInterval (1,1) double {mustBePositive} = obj.PollInterval
            end

            obj.stop();
            obj.MessageHandler = messageHandler;
            obj.Timer = timer( ...
                ExecutionMode="fixedSpacing", ...
                Period=options.PollInterval, ...
                TimerFcn=@(~, ~) obj.listen(obj.MessageHandler, MaxIterations=1, PollInterval=0));
            start(obj.Timer);
            obj.IsOpen = true;
        end

        function stop(obj)
            %STOP Stop timer-backed polling.
            if isempty(obj.Timer) || ~isvalid(obj.Timer)
                return
            end

            stop(obj.Timer);
            delete(obj.Timer);
            obj.Timer = [];
            obj.IsOpen = false;
        end

        function close(obj)
            %CLOSE Stop timer-backed polling and mark the client closed.
            obj.stop();
            close@yfinance.WebSocket(obj);
        end

        function delete(obj)
            obj.close();
        end
    end
end
