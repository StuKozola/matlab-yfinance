% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef ExperimentalWebSocket < yfinance.WebSocket
    %EXPERIMENTALWEBSOCKET Opt-in Yahoo protobuf WebSocket client.

    methods
        function obj = ExperimentalWebSocket(options)
            arguments
                options.Url (1,1) string = "wss://streamer.finance.yahoo.com/?version=2"
                options.Verbose (1,1) logical = true
                options.PollInterval (1,1) double {mustBeNonnegative} = 0
                options.Session = yfinance.internal.Session()
                options.StreamClient = []
                options.StreamTransport = []
            end

            obj@yfinance.WebSocket( ...
                Url=options.Url, ...
                Transport="stream", ...
                Verbose=options.Verbose, ...
                PollInterval=options.PollInterval, ...
                Session=options.Session, ...
                StreamClient=options.StreamClient, ...
                StreamTransport=options.StreamTransport);
        end
    end
end
