% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestLookup < matlab.unittest.TestCase
    %TESTLOOKUP Verify Yahoo Finance lookup APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function lookupResponseConvertsToTable(testCase)
            data = yfinance.internal.lookupResponseToTable(lookupFixture(), Query="apple", Type="equity");

            testCase.verifyEqual(data.Symbol, ["AAPL"; "APLE"]);
            testCase.verifyEqual(data.ShortName(1), "Apple Inc.");
            testCase.verifyEqual(data.RegularMarketPrice(2), 15);
            testCase.verifyEqual(data.Properties.UserData.Query, "apple");
            testCase.verifyEqual(data.Properties.UserData.Type, "equity");
        end

        function lookupClassUsesSession(testCase)
            session = StaticChartSession(emptyChartFixture(), LookupResponse=lookupFixture());

            lookup = yfinance.Lookup(" apple ", Session=session);
            data = lookup.getStock(Count=2);

            testCase.verifyEqual(lookup.Query, "apple");
            testCase.verifyEqual(session.LastLookupQuery, "apple");
            testCase.verifyEqual(session.LastLookupRequest.Type, "equity");
            testCase.verifyEqual(session.LastLookupRequest.Count, 2);
            testCase.verifyEqual(data.Symbol(1), "AAPL");
        end

        function lookupDependentPropertyUsesDefaultCount(testCase)
            session = StaticChartSession(emptyChartFixture(), LookupResponse=lookupFixture());

            lookup = yfinance.Lookup("apple", Session=session);
            data = lookup.ETF;

            testCase.verifyEqual(session.LastLookupRequest.Type, "etf");
            testCase.verifyEqual(session.LastLookupRequest.Count, 25);
            testCase.verifyClass(data, "table");
        end

        function emptyLookupResponseReturnsEmptyTable(testCase)
            data = yfinance.internal.lookupResponseToTable(emptyLookupFixture(), Query="none", Type="all");

            testCase.verifyEqual(height(data), 0);
            testCase.verifyEqual(data.Properties.UserData.Query, "none");
        end
    end
end

function response = lookupFixture()
documents = { ...
    struct( ...
    "symbol", "AAPL", ...
    "shortName", "Apple Inc.", ...
    "quoteType", "EQUITY", ...
    "exchange", "NMS", ...
    "regularMarketPrice", 200), ...
    struct( ...
    "symbol", "APLE", ...
    "shortName", "Apple Hospitality REIT, Inc.", ...
    "quoteType", "EQUITY", ...
    "exchange", "NYQ", ...
    "regularMarketPrice", 15)};
result = struct("documents", {documents});
response = struct("finance", struct("result", {{result}}, "error", []));
end

function response = emptyLookupFixture()
response = struct("finance", struct("result", [], "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
