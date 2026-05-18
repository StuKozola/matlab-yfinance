% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

%% Getting Started with matlab-yfinance
% Basic historical prices, metadata, options, and fund data.

ticker = yfinance.Ticker("AAPL");
prices = ticker.history(Period="1mo", Interval="1d");
info = ticker.fastInfo();
fundamentals = ticker.fundamentals();
expirations = ticker.options();

spyFunds = yfinance.FundsData("SPY");
spyHoldings = spyFunds.TopHoldings;

disp(prices(1:min(5, height(prices)), :))
disp(info)
disp(fundamentals)
disp(expirations(1:min(3, numel(expirations))))
disp(spyHoldings(1:min(5, height(spyHoldings)), :))
