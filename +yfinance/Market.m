% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef Market < handle
    %MARKET Access Yahoo Finance market summary and status data.

    properties (SetAccess = private)
        Name (1,1) string
    end

    properties (Dependent)
        Summary table
        Status struct
        Raw struct
    end

    properties (Access = private)
        Session
        IsFetched (1,1) logical = false
        SummaryCache table = table()
        StatusCache struct = struct()
        RawCache struct = struct()
    end

    methods
        function obj = Market(name, options)
            arguments
                name (1,1) string {mustBeNonzeroLengthText}
                options.Session = yfinance.internal.Session()
            end

            obj.Name = lower(strtrim(name));
            obj.Session = options.Session;
        end

        function value = get.Summary(obj)
            obj.ensureFetched();
            value = obj.SummaryCache;
        end

        function value = get.Status(obj)
            obj.ensureFetched();
            value = obj.StatusCache;
        end

        function value = get.Raw(obj)
            obj.ensureFetched();
            value = obj.RawCache;
        end
    end

    methods (Access = private)
        function ensureFetched(obj)
            if obj.IsFetched
                return
            end

            summaryResponse = obj.Session.getMarketSummary(obj.Name);
            statusResponse = obj.Session.getMarketTime(obj.Name);

            obj.SummaryCache = yfinance.internal.marketSummaryResponseToTable( ...
                summaryResponse, ...
                Market=obj.Name);
            obj.StatusCache = yfinance.internal.marketTimeResponseToStatus( ...
                statusResponse, ...
                Market=obj.Name);
            obj.RawCache = struct( ...
                "Summary", summaryResponse, ...
                "Status", statusResponse);
            obj.IsFetched = true;
        end
    end
end
