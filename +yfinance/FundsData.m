% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef FundsData < handle
    %FUNDSDATA Access ETF and mutual fund profile and holdings data.

    properties (SetAccess = private)
        Symbol (1,1) string
    end

    properties (Dependent)
        QuoteType string
        Description string
        FundOverview struct
        FundOperations table
        AssetClasses struct
        TopHoldings table
        EquityHoldings table
        BondHoldings table
        BondRatings table
        SectorWeightings table
        Raw struct
    end

    properties (Access = private)
        Session
        IsFetched (1,1) logical = false
        DataCache struct = struct()
    end

    methods
        function obj = FundsData(symbol, options)
            arguments
                symbol (1,1) string {mustBeNonzeroLengthText}
                options.Session = yfinance.internal.Session()
            end

            obj.Symbol = upper(strtrim(symbol));
            obj.Session = options.Session;
        end

        function value = get.QuoteType(obj)
            value = obj.cachedField("QuoteType");
        end

        function value = get.Description(obj)
            value = obj.cachedField("Description");
        end

        function value = get.FundOverview(obj)
            value = obj.cachedField("FundOverview");
        end

        function value = get.FundOperations(obj)
            value = obj.cachedField("FundOperations");
        end

        function value = get.AssetClasses(obj)
            value = obj.cachedField("AssetClasses");
        end

        function value = get.TopHoldings(obj)
            value = obj.cachedField("TopHoldings");
        end

        function value = get.EquityHoldings(obj)
            value = obj.cachedField("EquityHoldings");
        end

        function value = get.BondHoldings(obj)
            value = obj.cachedField("BondHoldings");
        end

        function value = get.BondRatings(obj)
            value = obj.cachedField("BondRatings");
        end

        function value = get.SectorWeightings(obj)
            value = obj.cachedField("SectorWeightings");
        end

        function value = get.Raw(obj)
            value = obj.cachedField("Raw");
        end
    end

    methods (Access = private)
        function ensureFetched(obj)
            if obj.IsFetched
                return
            end

            response = obj.Session.getQuoteSummary( ...
                obj.Symbol, ...
                Modules=["quoteType", "summaryProfile", "fundProfile", "topHoldings"]);
            obj.DataCache = yfinance.internal.quoteSummaryResponseToFundsData( ...
                response, ...
                Symbol=obj.Symbol);
            obj.IsFetched = true;
        end

        function value = cachedField(obj, fieldName)
            obj.ensureFetched();
            value = obj.DataCache.(fieldName);
        end
    end
end
