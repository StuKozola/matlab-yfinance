classdef Search
    %SEARCH Search Yahoo Finance symbols and news.

    properties (SetAccess = private)
        Query (1,1) string
        Quotes
        News
        Raw struct
    end

    methods
        function obj = Search(queryText, options)
            arguments
                queryText (1,1) string {mustBeNonzeroLengthText}
                options.QuotesCount (1,1) double {mustBeNonnegative, mustBeInteger} = 8
                options.NewsCount (1,1) double {mustBeNonnegative, mustBeInteger} = 8
                options.Session = yfinance.internal.Session()
            end

            obj.Query = strtrim(queryText);
            response = options.Session.getSearch( ...
                obj.Query, ...
                QuotesCount=options.QuotesCount, ...
                NewsCount=options.NewsCount);
            result = yfinance.internal.searchResponseToResult(response, Query=obj.Query);

            obj.Quotes = result.Quotes;
            obj.News = result.News;
            obj.Raw = result.Raw;
        end
    end
end
