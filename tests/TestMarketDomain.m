% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestMarketDomain < matlab.unittest.TestCase
    %TESTMARKETDOMAIN Verify market, sector, and industry APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function marketParsesSummaryAndStatus(testCase)
            session = StaticChartSession( ...
                emptyChartFixture(), ...
                MarketSummaryResponse=marketSummaryFixture(), ...
                MarketTimeResponse=marketTimeFixture());

            market = yfinance.Market("US", Session=session);
            summary = market.Summary;
            status = market.Status;

            testCase.verifyEqual(session.LastMarketSummaryMarket, "us");
            testCase.verifyEqual(session.LastMarketTimeMarket, "us");
            testCase.verifyEqual(summary.Exchange, ["SNP"; "DJI"]);
            testCase.verifyEqual(summary.RegularMarketPrice, [5000; 39000]);
            testCase.verifyEqual(status.Market, "us");
            testCase.verifyEqual(status.Status, "open");
            testCase.verifyEqual(status.GmtOffset, -14400);
            testCase.verifyClass(status.Open, "datetime");
        end

        function emptyMarketSummaryReturnsEmptyTable(testCase)
            data = yfinance.internal.marketSummaryResponseToTable(emptyMarketSummaryFixture(), Market="us");

            testCase.verifyEqual(height(data), 0);
            testCase.verifyEqual(data.Properties.UserData.Market, "us");
        end

        function sectorParsesDomainData(testCase)
            session = StaticChartSession(emptyChartFixture(), SectorResponse=sectorFixture());

            sector = yfinance.Sector("Technology", Session=session);
            name = sector.Name;

            testCase.verifyEqual(session.LastSectorKey, "technology");
            testCase.verifyEqual(name, "Technology");
            testCase.verifyEqual(sector.Symbol, "^YH101");
            testCase.verifyEqual(sector.Overview.CompaniesCount, 740);
            testCase.verifyEqual(sector.Overview.MarketCap, 18000000000000);
            testCase.verifyEqual(sector.TopCompanies.Symbol(1), "MSFT");
            testCase.verifyEqual(sector.TopETFs.Symbol, "XLK");
            testCase.verifyEqual(sector.TopMutualFunds.Name, "Vanguard Information Technology Index");
            testCase.verifyEqual(sector.Industries.Key, "software-infrastructure");
            testCase.verifyEqual(sector.Industries.MarketWeight, 0.25);
            testCase.verifyTrue(isfield(sector.Raw, "overview"));
        end

        function industryParsesDomainData(testCase)
            session = StaticChartSession(emptyChartFixture(), IndustryResponse=industryFixture());

            industry = yfinance.Industry("Software-Infrastructure", Session=session);
            name = industry.Name;

            testCase.verifyEqual(session.LastIndustryKey, "software-infrastructure");
            testCase.verifyEqual(name, "Software - Infrastructure");
            testCase.verifyEqual(industry.SectorKey, "technology");
            testCase.verifyEqual(industry.SectorName, "Technology");
            testCase.verifyEqual(industry.TopPerformingCompanies.Symbol(1), "ORCL");
            testCase.verifyEqual(industry.TopPerformingCompanies.YtdReturn(1), 0.18);
            testCase.verifyEqual(industry.TopGrowthCompanies.Symbol(1), "SNOW");
            testCase.verifyEqual(industry.TopGrowthCompanies.GrowthEstimate(1), 0.31);
        end
    end
end

function response = marketSummaryFixture()
result = { ...
    struct( ...
    "exchange", "SNP", ...
    "shortName", "S&P 500", ...
    "regularMarketPrice", 5000, ...
    "regularMarketChange", 20, ...
    "regularMarketChangePercent", 0.004), ...
    struct( ...
    "exchange", "DJI", ...
    "shortName", "Dow Jones Industrial Average", ...
    "regularMarketPrice", 39000, ...
    "regularMarketChange", 100, ...
    "regularMarketChangePercent", 0.003)};
response = struct("marketSummaryResponse", struct("result", {result}, "error", []));
end

function response = emptyMarketSummaryFixture()
response = struct("marketSummaryResponse", struct("result", [], "error", []));
end

function response = marketTimeFixture()
timezone = struct("short", "EDT", "gmtoffset", -14400);
marketTime = struct( ...
    "exchange", "NMS", ...
    "status", "open", ...
    "open", "2026-05-15T09:30:00-04:00", ...
    "close", "2026-05-15T16:00:00-04:00", ...
    "timezone", {{timezone}});
marketTimes = struct("marketTime", {{marketTime}});
response = struct("finance", struct("marketTimes", {{marketTimes}}, "error", []));
end

function response = sectorFixture()
data = domainPayload("Technology", "^YH101");
data.topETFs = {struct("symbol", "XLK", "name", "Technology Select Sector SPDR Fund")};
data.topMutualFunds = {struct("symbol", "VITAX", "name", "Vanguard Information Technology Index")};
data.industries = { ...
    struct("key", "all", "name", "All Industries", "symbol", "", "marketWeight", formattedValue(1)), ...
    struct("key", "software-infrastructure", "name", "Software - Infrastructure", "symbol", "^YH352010", "marketWeight", formattedValue(0.25))};
response = struct("data", data);
end

function response = industryFixture()
data = domainPayload("Software - Infrastructure", "^YH352010");
data.sectorKey = "technology";
data.sectorName = "Technology";
data.topPerformingCompanies = {struct( ...
    "symbol", "ORCL", ...
    "name", "Oracle Corporation", ...
    "ytdReturn", formattedValue(0.18), ...
    "lastPrice", formattedValue(130), ...
    "targetPrice", formattedValue(140))};
data.topGrowthCompanies = {struct( ...
    "symbol", "SNOW", ...
    "name", "Snowflake Inc.", ...
    "ytdReturn", formattedValue(0.12), ...
    "growthEstimate", formattedValue(0.31))};
response = struct("data", data);
end

function data = domainPayload(name, symbol)
data = struct( ...
    "name", name, ...
    "symbol", symbol, ...
    "overview", struct( ...
    "companiesCount", 740, ...
    "marketCap", formattedValue(18000000000000), ...
    "messageBoardId", "sec-tech", ...
    "description", "Technology companies.", ...
    "industriesCount", 12, ...
    "marketWeight", formattedValue(0.32), ...
    "employeeCount", formattedValue(2500000)), ...
    "topCompanies", {{struct( ...
    "symbol", "MSFT", ...
    "name", "Microsoft Corporation", ...
    "rating", "Buy", ...
    "marketWeight", formattedValue(0.18))}}, ...
    "researchReports", {{struct( ...
    "id", "r1", ...
    "title", "Technology sector outlook")}});
end

function value = formattedValue(raw)
value = struct("raw", raw, "fmt", string(raw));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
