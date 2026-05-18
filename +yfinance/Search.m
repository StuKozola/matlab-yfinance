classdef Search
    %SEARCH Search Yahoo Finance symbols, news, lists, and research.

    properties (SetAccess = private)
        Query (1,1) string
        Quotes
        News
        Lists
        Research
        Nav
        All struct
        Response struct
        Raw struct
    end

    methods
        function obj = Search(queryText, options)
            arguments
                queryText (1,1) string {mustBeNonzeroLengthText}
                options.QuotesCount (1,1) double {mustBeNonnegative, mustBeInteger} = 8
                options.NewsCount (1,1) double {mustBeNonnegative, mustBeInteger} = 8
                options.ListsCount (1,1) double {mustBeNonnegative, mustBeInteger} = 8
                options.IncludeCb (1,1) logical = true
                options.IncludeNavLinks (1,1) logical = false
                options.IncludeResearch (1,1) logical = false
                options.IncludeCulturalAssets (1,1) logical = false
                options.EnableFuzzyQuery (1,1) logical = false
                options.RecommendedCount (1,1) double {mustBeNonnegative, mustBeInteger} = 8
                options.Session = yfinance.internal.Session()
            end

            obj.Query = strtrim(queryText);
            response = options.Session.getSearch( ...
                obj.Query, ...
                QuotesCount=options.QuotesCount, ...
                NewsCount=options.NewsCount, ...
                ListsCount=options.ListsCount, ...
                IncludeCb=options.IncludeCb, ...
                IncludeNavLinks=options.IncludeNavLinks, ...
                IncludeResearch=options.IncludeResearch, ...
                IncludeCulturalAssets=options.IncludeCulturalAssets, ...
                EnableFuzzyQuery=options.EnableFuzzyQuery, ...
                RecommendedCount=options.RecommendedCount);
            result = yfinance.internal.searchResponseToResult(response, Query=obj.Query);

            obj.Quotes = result.Quotes;
            obj.News = result.News;
            obj.Lists = result.Lists;
            obj.Research = result.Research;
            obj.Nav = result.Nav;
            obj.All = result.All;
            obj.Response = result.Response;
            obj.Raw = result.Raw;
        end
    end
end
