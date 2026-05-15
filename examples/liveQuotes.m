%% Live Quote Polling
% MATLAB-compatible live quote snapshots with the WebSocket-style API.

client = yfinance.WebSocket(PollInterval=5);
client.subscribe(["AAPL", "MSFT"]);

snapshot = client.listen([], MaxIterations=1);
client.close();

disp(snapshot)
