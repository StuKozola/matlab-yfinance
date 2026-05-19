% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestLiveYahoo < matlab.unittest.TestCase
    %TESTLIVEYAHOO Optional live Yahoo Finance integration smoke tests.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
        end
    end

    methods (Test)
        function downloadReturnsRecentRows(testCase)
            data = testCase.runLiveRequest( ...
                @() yfinance.download("AAPL", Period="5d", Interval="1d"));

            testCase.verifyGreaterThan(height(data), 0);
            testCase.verifyTrue(ismember("Close", string(data.Properties.VariableNames)));
        end

        function searchReturnsQuoteMatches(testCase)
            results = testCase.runLiveRequest(@() yfinance.Search("AAPL", NewsCount=0));

            testCase.verifyGreaterThan(height(results.Quotes), 0);
            testCase.verifyTrue(ismember("Symbol", string(results.Quotes.Properties.VariableNames)));
        end

        function screenerReturnsQuotes(testCase)
            result = testCase.runLiveRequest(@() yfinance.screen("most_actives", Count=1));

            testCase.verifyGreaterThan(height(result.Quotes), 0);
            testCase.verifyTrue(ismember("Symbol", string(result.Quotes.Properties.VariableNames)));
        end

        function tickerFastInfoReturnsQuoteFields(testCase)
            info = testCase.runLiveRequest(@() fetchFastInfo("MSFT"));

            testCase.verifyEqual(info.Symbol, "MSFT");
            testCase.verifyTrue(isfield(info, "LastPrice"));
            testCase.verifyGreaterThan(info.LastPrice, 0);
        end

        function optionExpirationsReturnDatetimes(testCase)
            expirations = testCase.runLiveRequest(@() fetchOptionExpirations("AAPL"));

            testCase.verifyClass(expirations, "datetime");
            testCase.verifyGreaterThan(numel(expirations), 0);
            testCase.verifyEqual(string(expirations.TimeZone), "UTC");
        end

        function fundsDataReturnsTables(testCase)
            funds = testCase.runLiveRequest(@() yfinance.FundsData("SPY"));

            testCase.verifyClass(funds, "yfinance.FundsData");
            testCase.verifyEqual(funds.Symbol, "SPY");
            testCase.verifyTrue(istable(funds.TopHoldings));
            testCase.verifyTrue(istable(funds.SectorWeightings));
        end

        function calendarEndpointReturnsTable(testCase)
            calendars = yfinance.Calendars( ...
                Start=datetime("today", TimeZone="UTC"), ...
                End=datetime("today", TimeZone="UTC") + days(7));

            data = testCase.runLiveRequest(@() calendars.getEconomicEventsCalendar(Limit=5));

            testCase.verifyTrue(istable(data));
        end

        function experimentalWebSocketStreamReturnsQuote(testCase)
            data = testCase.runLiveRequest(@() receiveExperimentalStreamQuote("BTC-USD"));

            testCase.verifyGreaterThan(height(data), 0);
            testCase.verifyTrue(ismember("Symbol", string(data.Properties.VariableNames)));
            testCase.verifyTrue(ismember("RegularMarketPrice", string(data.Properties.VariableNames)));
            testCase.verifyEqual(data.Symbol(1), "BTC-USD");
        end
    end

    methods (Access = private)
        function output = runLiveRequest(testCase, requestFunction)
            try
                output = requestFunction();
            catch exception
                if isLiveYahooAvailabilityError(exception)
                    testCase.assumeTrue(false, ...
                        "Skipping live Yahoo smoke test because the endpoint is currently unavailable: " + ...
                        string(exception.identifier));
                end

                rethrow(exception);
            end
        end
    end
end

function value = isLiveYahooAvailabilityError(exception)
availabilityErrors = [
    "yfinance:RateLimited"
    "yfinance:Unauthorized"
    "yfinance:Timeout"
    "yfinance:NetworkError"
    "yfinance:WebSocketHandshakeFailed"
    "yfinance:EmptyResponse"];
value = ismember(string(exception.identifier), availabilityErrors);
end

function data = receiveExperimentalStreamQuote(symbol)
client = yfinance.ExperimentalWebSocket();
cleanup = onCleanup(@() client.close());
client.subscribe(symbol);
data = client.listen([], MaxIterations=1);
end

function info = fetchFastInfo(symbol)
ticker = yfinance.Ticker(symbol);
info = ticker.fastInfo();
end

function expirations = fetchOptionExpirations(symbol)
ticker = yfinance.Ticker(symbol);
expirations = ticker.options();
end
