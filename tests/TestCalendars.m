% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestCalendars < matlab.unittest.TestCase
    %TESTCALENDARS Verify Yahoo Finance calendar APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (Test)
        function calendarQueryConvertsToYahooStruct(testCase)
            query = yfinance.internal.CalendarQuery("and", { ...
                yfinance.internal.CalendarQuery("eq", {"region", "us"}), ...
                yfinance.internal.CalendarQuery("gtelt", {"startdatetime", "2026-05-18", "2026-05-25"})});

            value = query.toStruct();

            testCase.verifyEqual(value.operator, "and");
            testCase.verifyEqual(value.operands{1}.operator, "eq");
            testCase.verifyEqual(value.operands{1}.operands{2}, "us");
            testCase.verifyEqual(value.operands{2}.operator, "gtelt");
        end

        function earningsCalendarResponseConvertsToTable(testCase)
            data = yfinance.internal.calendarResponseToTable( ...
                earningsCalendarFixture(), ...
                CalendarType="sp_earnings");

            testCase.verifySize(data, [2, 9]);
            testCase.verifyEqual(data.Symbol, ["AAPL"; "MSFT"]);
            testCase.verifyEqual(data.MarketCap, [2500000000000; 3000000000000]);
            testCase.verifyEqual(data.Timing(1), "Before Market Open");
            testCase.verifyEqual(data.EventStartDate(1), datetime(2026, 5, 20, 12, 0, 0, TimeZone="UTC"));
            testCase.verifyTrue(isnan(data.ReportedEPS(1)));
            testCase.verifyEqual(data.Properties.UserData.CalendarType, "sp_earnings");
        end

        function emptyCalendarResponseReturnsEmptyTable(testCase)
            data = yfinance.internal.calendarResponseToTable( ...
                emptyCalendarFixture(), ...
                CalendarType="economic_event");

            testCase.verifySize(data, [0, 0]);
            testCase.verifyEqual(data.Properties.UserData.CalendarType, "economic_event");
        end

        function missingCalendarRowValuesBecomeMissing(testCase)
            data = yfinance.internal.calendarResponseToTable( ...
                missingCalendarValueFixture(), ...
                CalendarType="sp_earnings");

            testCase.verifySize(data, [2, 4]);
            testCase.verifyTrue(ismissing(data.Company(2)));
            testCase.verifyTrue(isnan(data.MarketCap(2)));
            testCase.verifyTrue(isnat(data.EventStartDate(2)));
        end

        function flatCalendarRowsAreReshaped(testCase)
            data = yfinance.internal.calendarResponseToTable( ...
                flatCalendarRowsFixture(), ...
                CalendarType="sp_earnings");

            testCase.verifySize(data, [2, 3]);
            testCase.verifyEqual(data.Symbol, ["AAPL"; "MSFT"]);
            testCase.verifyEqual(data.EventStartDate(2), datetime(2026, 5, 21, TimeZone="UTC"));
            testCase.verifyTrue(isnan(data.MarketCap(2)));
        end

        function cellWrappedCalendarDocumentsHandleColumnDrift(testCase)
            data = yfinance.internal.calendarResponseToTable( ...
                cellWrappedCalendarDocumentFixture(), ...
                CalendarType="sp_earnings");

            testCase.verifySize(data, [1, 3]);
            testCase.verifyEqual(data.Symbol, "AAPL");
            testCase.verifyEqual(data.MarketCap, 2500000000000);
            testCase.verifyEqual(data.EventStartDate, datetime(2026, 5, 20, TimeZone="UTC"));
        end

        function getEarningsCalendarUsesSession(testCase)
            session = StaticChartSession(emptyChartFixture(), CalendarResponse=earningsCalendarFixture());
            calendars = yfinance.Calendars( ...
                Start=datetime(2026, 5, 18), ...
                End=datetime(2026, 5, 25), ...
                Session=session);

            data = calendars.getEarningsCalendar(FilterMostActive=false, Limit=5, Offset=2);

            testCase.verifyEqual(session.LastCalendarType, "sp_earnings");
            testCase.verifyEqual(session.LastCalendarRequest.Limit, 5);
            testCase.verifyEqual(session.LastCalendarRequest.Offset, 2);
            testCase.verifyEqual(session.LastCalendarQuery.operator, "and");
            testCase.verifyEqual(session.LastCalendarQuery.operands{1}.operator, "eq");
            testCase.verifyEqual(data.Symbol(1), "AAPL");
        end

        function getIpoInfoCalendarUsesGteltQuery(testCase)
            session = StaticChartSession(emptyChartFixture(), CalendarResponse=ipoCalendarFixture());
            calendars = yfinance.Calendars( ...
                Start=datetime(2026, 5, 18, TimeZone="UTC"), ...
                End=datetime(2026, 5, 25, TimeZone="UTC"), ...
                Session=session);

            data = calendars.getIpoInfoCalendar(Limit=6);

            testCase.verifyEqual(session.LastCalendarType, "ipo_info");
            testCase.verifyEqual(session.LastCalendarQuery.operator, "or");
            testCase.verifyEqual(session.LastCalendarQuery.operands{1}.operator, "gtelt");
            testCase.verifyEqual(data.ProposedTickerSymbol, "ACME");
            testCase.verifyEqual(data.PricedDate, datetime(2026, 5, 20, TimeZone="UTC"));
        end

        function economicAndSplitsCalendarsUseDateRangeQuery(testCase)
            session = StaticChartSession(emptyChartFixture(), CalendarResponse=economicCalendarFixture());
            calendars = yfinance.Calendars( ...
                Start=datetime(2026, 5, 18, TimeZone="UTC"), ...
                End=datetime(2026, 5, 25, TimeZone="UTC"), ...
                Session=session);

            economic = calendars.getEconomicEventsCalendar(Limit=3);
            session.CalendarResponse = splitsCalendarFixture();
            splits = calendars.getSplitsCalendar(Limit=4);

            testCase.verifyEqual(economic.EventName, "Retail Sales");
            testCase.verifyEqual(economic.Consensus, 0.4);
            testCase.verifyEqual(splits.Symbol, "XYZ");
            testCase.verifyTrue(splits.Optionable);
            testCase.verifyEqual(session.LastCalendarQuery.operator, "and");
        end
    end
end

function response = earningsCalendarFixture()
columns = [
    column("Symbol", "STRING")
    column("Company Name", "STRING")
    column("Market Cap (Intraday)", "NUMBER")
    column("Event Name", "STRING")
    column("Event Start Date", "DATETIME")
    column("Event Start Date", "STRING")
    column("EPS Estimate", "NUMBER")
    column("Reported EPS", "NUMBER")
    column("Surprise (%)", "NUMBER")];
rows = {
    {"AAPL", "Apple Inc.", 2500000000000, "Earnings Date", "2026-05-20T12:00:00Z", "Before Market Open", 1.25, 0, 0}
    {"MSFT", "Microsoft Corporation", 3000000000000, "Earnings Date", "2026-05-21T20:00:00Z", "After Market Close", 2.1, 2.4, 14.2}};
response = calendarResponse(columns, rows);
end

function response = ipoCalendarFixture()
columns = [
    column("Symbol", "STRING")
    column("Company Name", "STRING")
    column("Exchange Short Name", "STRING")
    column("Proposed Ticker Symbol", "STRING")
    column("Proposed Exchange Symbol", "STRING")
    column("Shares Offered", "NUMBER")
    column("Proposed Share Price", "NUMBER")
    column("Priced Date", "DATE")
    column("Dollar Value of Shares Offered", "NUMBER")];
rows = {{"", "Acme Robotics", "NYSE", "ACME", "NYSE", 10000000, 15, "2026-05-20", 150000000}};
response = calendarResponse(columns, rows);
end

function response = economicCalendarFixture()
columns = [
    column("Event Name", "STRING")
    column("Country Code", "STRING")
    column("Event Start Date", "DATETIME")
    column("Timezone Short Name", "STRING")
    column("GMT Offset Milliseconds", "NUMBER")
    column("Period", "STRING")
    column("Market Expectation", "NUMBER")
    column("Actual", "NUMBER")
    column("Prior to This", "NUMBER")
    column("Revised from", "NUMBER")];
rows = {{"Retail Sales", "US", "2026-05-19T12:30:00Z", "EDT", -14400000, "Apr", 0.4, 0.5, 0.3, 0.2}};
response = calendarResponse(columns, rows);
end

function response = splitsCalendarFixture()
columns = [
    column("Symbol", "STRING")
    column("Company Name", "STRING")
    column("Event Start Date", "DATETIME")
    column("Event Start Date", "STRING")
    column("Ratio", "STRING")
    column("Optionable?", "BOOLEAN")];
rows = {{"XYZ", "XYZ Corp.", "2026-05-22T00:00:00Z", "Before Market Open", "2:1", true}};
response = calendarResponse(columns, rows);
end

function response = emptyCalendarFixture()
response = struct("finance", struct("result", [], "error", []));
end

function response = missingCalendarValueFixture()
columns = [
    column("Symbol", "STRING")
    column("Company Name", "STRING")
    column("Market Cap (Intraday)", "NUMBER")
    column("Event Start Date", "DATETIME")];
rows = {
    {"AAPL", "Apple Inc.", 2500000000000, "2026-05-20T12:00:00Z"}
    {"MSFT", [], [], []}};
response = calendarResponse(columns, rows);
end

function response = flatCalendarRowsFixture()
columns = [
    column("Symbol", "STRING")
    column("Event Start Date", "DATETIME")
    column("Market Cap (Intraday)", "NUMBER")];
rows = {"AAPL", "2026-05-20", 2500000000000, "MSFT", "2026-05-21", []};
response = calendarResponse(columns, rows);
end

function response = cellWrappedCalendarDocumentFixture()
columns = {
    column("Symbol", "STRING")
    struct("label", "Market Cap (Intraday)")
    column("Event Start Date", "DATE")};
rows = {{"AAPL", "2,500,000,000,000", "2026-05-20"}};
document = struct("columns", {columns}, "rows", {rows});
result = struct("documents", {{document}});
response = struct("finance", struct("result", result, "error", []));
end

function value = column(label, type)
value = struct("label", label, "type", type);
end

function response = calendarResponse(columns, rows)
document = struct("columns", columns, "rows", {rows});
result = struct("documents", document);
response = struct("finance", struct("result", result, "error", []));
end

function response = emptyChartFixture()
response = struct("chart", struct("result", [], "error", []));
end
