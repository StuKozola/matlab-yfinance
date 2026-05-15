classdef StaticChartSession < handle
    %STATICCHARTSESSION Test double that returns a fixed chart response.

    properties
        Response struct
        QuoteResponse struct = struct()
        QuoteSummaryResponse struct = struct()
        SearchResponse struct = struct()
        OptionsResponse struct = struct()
        FundamentalsTimeSeriesResponse struct = struct()
        LastSymbol (1,1) string = ""
        LastQuoteSymbols (:,1) string = strings(0, 1)
        LastQuoteSummarySymbol (1,1) string = ""
        LastQuoteSummaryRequest struct = struct()
        LastSearchQuery (1,1) string = ""
        LastSearchRequest struct = struct()
        LastOptionsSymbol (1,1) string = ""
        LastOptionsRequest struct = struct()
        LastFundamentalsTimeSeriesSymbol (1,1) string = ""
        LastFundamentalsTimeSeriesRequest struct = struct()
        LastOptions struct = struct()
    end

    methods
        function obj = StaticChartSession(response, options)
            arguments
                response struct
                options.QuoteResponse struct = struct()
                options.QuoteSummaryResponse struct = struct()
                options.SearchResponse struct = struct()
                options.OptionsResponse struct = struct()
                options.FundamentalsTimeSeriesResponse struct = struct()
            end

            obj.Response = response;
            obj.QuoteResponse = options.QuoteResponse;
            obj.QuoteSummaryResponse = options.QuoteSummaryResponse;
            obj.SearchResponse = options.SearchResponse;
            obj.OptionsResponse = options.OptionsResponse;
            obj.FundamentalsTimeSeriesResponse = options.FundamentalsTimeSeriesResponse;
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
    end
end

function options = namedOptions(values)
options = struct();

for valueIndex = 1:2:numel(values)
    name = char(values{valueIndex});
    options.(name) = values{valueIndex + 1};
end
end
