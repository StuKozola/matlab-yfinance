% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef Lookup < handle
    %LOOKUP Look up Yahoo Finance instruments by type.

    properties (Constant)
        ValidTypes (1,:) string = ["all", "equity", "mutualfund", "etf", "index", "future", "currency", "cryptocurrency"]
    end

    properties (SetAccess = private)
        Query (1,1) string
    end

    properties (Dependent)
        All table
        Stock table
        MutualFund table
        ETF table
        Index table
        Future table
        Currency table
        Cryptocurrency table
    end

    properties (Access = private)
        Session
    end

    methods
        function obj = Lookup(queryText, options)
            arguments
                queryText (1,1) string {mustBeNonzeroLengthText}
                options.Session = yfinance.internal.Session()
            end

            obj.Query = strtrim(queryText);
            obj.Session = options.Session;
        end

        function data = getAll(obj, options)
            %GETALL Return all matching financial instruments.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
            end

            data = obj.lookupType("all", options.Count);
        end

        function data = getStock(obj, options)
            %GETSTOCK Return matching equity instruments.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
            end

            data = obj.lookupType("equity", options.Count);
        end

        function data = getMutualFund(obj, options)
            %GETMUTUALFUND Return matching mutual fund instruments.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
            end

            data = obj.lookupType("mutualfund", options.Count);
        end

        function data = getETF(obj, options)
            %GETETF Return matching ETF instruments.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
            end

            data = obj.lookupType("etf", options.Count);
        end

        function data = getIndex(obj, options)
            %GETINDEX Return matching index instruments.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
            end

            data = obj.lookupType("index", options.Count);
        end

        function data = getFuture(obj, options)
            %GETFUTURE Return matching futures instruments.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
            end

            data = obj.lookupType("future", options.Count);
        end

        function data = getCurrency(obj, options)
            %GETCURRENCY Return matching currency instruments.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
            end

            data = obj.lookupType("currency", options.Count);
        end

        function data = getCryptocurrency(obj, options)
            %GETCRYPTOCURRENCY Return matching cryptocurrency instruments.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 25
            end

            data = obj.lookupType("cryptocurrency", options.Count);
        end

        function value = get.All(obj)
            value = obj.getAll();
        end

        function value = get.Stock(obj)
            value = obj.getStock();
        end

        function value = get.MutualFund(obj)
            value = obj.getMutualFund();
        end

        function value = get.ETF(obj)
            value = obj.getETF();
        end

        function value = get.Index(obj)
            value = obj.getIndex();
        end

        function value = get.Future(obj)
            value = obj.getFuture();
        end

        function value = get.Currency(obj)
            value = obj.getCurrency();
        end

        function value = get.Cryptocurrency(obj)
            value = obj.getCryptocurrency();
        end
    end

    methods (Access = private)
        function data = lookupType(obj, lookupType, count)
            if ~ismember(lookupType, obj.ValidTypes)
                error("yfinance:InvalidLookupType", "Unsupported lookup type '%s'.", lookupType);
            end

            response = obj.Session.getLookup(obj.Query, Type=lookupType, Count=count);
            data = yfinance.internal.lookupResponseToTable( ...
                response, ...
                Query=obj.Query, ...
                Type=lookupType);
        end
    end
end
