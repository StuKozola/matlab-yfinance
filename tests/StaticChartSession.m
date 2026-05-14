classdef StaticChartSession < handle
    %STATICCHARTSESSION Test double that returns a fixed chart response.

    properties
        Response struct
        QuoteResponse struct = struct()
        LastSymbol (1,1) string = ""
        LastQuoteSymbols (:,1) string = strings(0, 1)
        LastOptions struct = struct()
    end

    methods
        function obj = StaticChartSession(response, options)
            arguments
                response struct
                options.QuoteResponse struct = struct()
            end

            obj.Response = response;
            obj.QuoteResponse = options.QuoteResponse;
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
    end
end

function options = namedOptions(values)
options = struct();

for valueIndex = 1:2:numel(values)
    name = char(values{valueIndex});
    options.(name) = values{valueIndex + 1};
end
end
