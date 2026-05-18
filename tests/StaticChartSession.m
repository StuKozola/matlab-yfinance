% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef StaticChartSession < handle
    %STATICCHARTSESSION Test double that returns a fixed chart response.

    properties
        Response struct
        QuoteResponse struct = struct()
        QuoteSummaryResponse struct = struct()
        SearchResponse struct = struct()
        LookupResponse struct = struct()
        CalendarResponse struct = struct()
        OptionsResponse struct = struct()
        FundamentalsTimeSeriesResponse struct = struct()
        ScreenerResponse struct = struct()
        MarketSummaryResponse struct = struct()
        MarketTimeResponse struct = struct()
        SectorResponse struct = struct()
        IndustryResponse struct = struct()
        IsinSearchResponse (1,1) string = ""
        LastSymbol (1,1) string = ""
        LastQuoteSymbols (:,1) string = strings(0, 1)
        LastQuoteSummarySymbol (1,1) string = ""
        LastQuoteSummaryRequest struct = struct()
        LastSearchQuery (1,1) string = ""
        LastSearchRequest struct = struct()
        LastLookupQuery (1,1) string = ""
        LastLookupRequest struct = struct()
        LastCalendarType (1,1) string = ""
        LastCalendarQuery struct = struct()
        LastCalendarRequest struct = struct()
        LastScreenerQuery (1,1) string = ""
        LastScreenerRequest struct = struct()
        LastCustomScreenerQuery struct = struct()
        LastCustomScreenerRequest struct = struct()
        LastMarketSummaryMarket (1,1) string = ""
        LastMarketTimeMarket (1,1) string = ""
        LastSectorKey (1,1) string = ""
        LastIndustryKey (1,1) string = ""
        LastOptionsSymbol (1,1) string = ""
        LastOptionsRequest struct = struct()
        LastFundamentalsTimeSeriesSymbol (1,1) string = ""
        LastFundamentalsTimeSeriesRequest struct = struct()
        LastIsinSearchQuery (1,1) string = ""
        LastOptions struct = struct()
    end

    methods
        function obj = StaticChartSession(response, options)
            arguments
                response struct
                options.QuoteResponse struct = struct()
                options.QuoteSummaryResponse struct = struct()
                options.SearchResponse struct = struct()
                options.LookupResponse struct = struct()
                options.CalendarResponse struct = struct()
                options.OptionsResponse struct = struct()
                options.FundamentalsTimeSeriesResponse struct = struct()
                options.ScreenerResponse struct = struct()
                options.MarketSummaryResponse struct = struct()
                options.MarketTimeResponse struct = struct()
                options.SectorResponse struct = struct()
                options.IndustryResponse struct = struct()
                options.IsinSearchResponse (1,1) string = ""
            end

            obj.Response = response;
            obj.QuoteResponse = options.QuoteResponse;
            obj.QuoteSummaryResponse = options.QuoteSummaryResponse;
            obj.SearchResponse = options.SearchResponse;
            obj.LookupResponse = options.LookupResponse;
            obj.CalendarResponse = options.CalendarResponse;
            obj.OptionsResponse = options.OptionsResponse;
            obj.FundamentalsTimeSeriesResponse = options.FundamentalsTimeSeriesResponse;
            obj.ScreenerResponse = options.ScreenerResponse;
            obj.MarketSummaryResponse = options.MarketSummaryResponse;
            obj.MarketTimeResponse = options.MarketTimeResponse;
            obj.SectorResponse = options.SectorResponse;
            obj.IndustryResponse = options.IndustryResponse;
            obj.IsinSearchResponse = options.IsinSearchResponse;
        end

        function response = getChart(obj, symbol, varargin)
            obj.LastSymbol = symbol;
            obj.LastOptions = namedOptions(varargin);
            response = obj.Response;
        end

        function response = getQuote(obj, symbols)
            obj.LastQuoteSymbols = yfinance.internal.normalizeSymbols(symbols);
            response = obj.QuoteResponse;
        end

        function response = getQuoteSummary(obj, symbol, varargin)
            obj.LastQuoteSummarySymbol = symbol;
            obj.LastQuoteSummaryRequest = namedOptions(varargin);
            response = obj.QuoteSummaryResponse;
        end

        function response = getSearch(obj, queryText, varargin)
            obj.LastSearchQuery = queryText;
            obj.LastSearchRequest = namedOptions(varargin);
            response = obj.SearchResponse;
        end

        function response = getLookup(obj, queryText, varargin)
            obj.LastLookupQuery = queryText;
            obj.LastLookupRequest = namedOptions(varargin);
            response = obj.LookupResponse;
        end

        function response = getCalendar(obj, calendarType, queryStruct, varargin)
            obj.LastCalendarType = calendarType;
            obj.LastCalendarQuery = queryStruct;
            obj.LastCalendarRequest = namedOptions(varargin);
            response = obj.CalendarResponse;
        end

        function response = getScreener(obj, queryText, varargin)
            obj.LastScreenerQuery = queryText;
            obj.LastScreenerRequest = namedOptions(varargin);
            response = obj.ScreenerResponse;
        end

        function response = postScreener(obj, queryStruct, varargin)
            obj.LastCustomScreenerQuery = queryStruct;
            obj.LastCustomScreenerRequest = namedOptions(varargin);
            response = obj.ScreenerResponse;
        end

        function response = getMarketSummary(obj, market)
            obj.LastMarketSummaryMarket = market;
            response = obj.MarketSummaryResponse;
        end

        function response = getMarketTime(obj, market)
            obj.LastMarketTimeMarket = market;
            response = obj.MarketTimeResponse;
        end

        function response = getSector(obj, key)
            obj.LastSectorKey = key;
            response = obj.SectorResponse;
        end

        function response = getIndustry(obj, key)
            obj.LastIndustryKey = key;
            response = obj.IndustryResponse;
        end

        function response = getOptions(obj, symbol, varargin)
            obj.LastOptionsSymbol = symbol;
            obj.LastOptionsRequest = namedOptions(varargin);
            response = obj.OptionsResponse;
        end

        function response = getFundamentalsTimeSeries(obj, symbol, varargin)
            obj.LastFundamentalsTimeSeriesSymbol = symbol;
            obj.LastFundamentalsTimeSeriesRequest = namedOptions(varargin);
            response = obj.FundamentalsTimeSeriesResponse;
        end

        function text = getIsinSearch(obj, queryText)
            obj.LastIsinSearchQuery = queryText;
            text = obj.IsinSearchResponse;
        end
    end
end

function options = namedOptions(values)
options = struct();

for valueIndex = 1:2:numel(values)
    name = char(values{valueIndex});
    options.(name) = values{valueIndex + 1};
end
end
