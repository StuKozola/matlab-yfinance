% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef Screener
    %SCREENER Run and hold Yahoo Finance screener results.

    properties (SetAccess = private)
        Query (1,1) string
        Result struct
        Quotes table
        Raw struct
    end

    methods
        function obj = Screener(queryName, options)
            arguments
                queryName
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
                options.Size (1,1) double {mustBeNonnegativeIntegerOrNaN} = NaN
                options.Offset (1,1) double {mustBeNonnegative, mustBeInteger} = 0
                options.SortField (1,1) string = "ticker"
                options.SortAscending (1,1) logical = false
                options.Session = yfinance.internal.Session()
            end

            obj.Result = yfinance.screen( ...
                queryName, ...
                Count=options.Count, ...
                Size=options.Size, ...
                Offset=options.Offset, ...
                SortField=options.SortField, ...
                SortAscending=options.SortAscending, ...
                Session=options.Session);
            obj.Query = obj.Result.Query;
            obj.Quotes = obj.Result.Quotes;
            obj.Raw = obj.Result.Raw;
        end
    end
end

function mustBeNonnegativeIntegerOrNaN(value)
if isnan(value)
    return
end

mustBeNonnegative(value);
mustBeInteger(value);
end
