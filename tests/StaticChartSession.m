classdef StaticChartSession < handle
    %STATICCHARTSESSION Test double that returns a fixed chart response.

    properties
        Response struct
        LastSymbol (1,1) string = ""
        LastOptions struct = struct()
    end

    methods
        function obj = StaticChartSession(response)
            obj.Response = response;
        end

        function response = getChart(obj, symbol, varargin)
            obj.LastSymbol = symbol;
            obj.LastOptions = namedOptions(varargin);
            response = obj.Response;
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
