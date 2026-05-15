classdef Screener
    %SCREENER Run and hold Yahoo Finance predefined screener results.

    properties (SetAccess = private)
        Query (1,1) string
        Result struct
        Quotes table
        Raw struct
    end

    methods
        function obj = Screener(queryName, options)
            arguments
                queryName (1,1) string {mustBeNonzeroLengthText}
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
                options.Offset (1,1) double {mustBeNonnegative, mustBeInteger} = 0
                options.Session = yfinance.internal.Session()
            end

            obj.Query = strtrim(queryName);
            obj.Result = yfinance.screen( ...
                obj.Query, ...
                Count=options.Count, ...
                Offset=options.Offset, ...
                Session=options.Session);
            obj.Quotes = obj.Result.Quotes;
            obj.Raw = obj.Result.Raw;
        end
    end
end
