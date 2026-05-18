% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef Industry < handle
    %INDUSTRY Access Yahoo Finance industry data.

    properties (SetAccess = private)
        Key (1,1) string
    end

    properties (Dependent)
        Name string
        Symbol string
        Overview struct
        TopCompanies table
        ResearchReports table
        SectorKey string
        SectorName string
        TopPerformingCompanies table
        TopGrowthCompanies table
        Raw struct
    end

    properties (Access = private)
        Session
        IsFetched (1,1) logical = false
        DataCache struct = struct()
    end

    methods
        function obj = Industry(key, options)
            arguments
                key (1,1) string {mustBeNonzeroLengthText}
                options.Session = yfinance.internal.Session()
            end

            obj.Key = lower(strtrim(key));
            obj.Session = options.Session;
        end

        function value = get.Name(obj)
            value = obj.cachedField("Name");
        end

        function value = get.Symbol(obj)
            value = obj.cachedField("Symbol");
        end

        function value = get.Overview(obj)
            value = obj.cachedField("Overview");
        end

        function value = get.TopCompanies(obj)
            value = obj.cachedField("TopCompanies");
        end

        function value = get.ResearchReports(obj)
            value = obj.cachedField("ResearchReports");
        end

        function value = get.SectorKey(obj)
            value = obj.cachedField("SectorKey");
        end

        function value = get.SectorName(obj)
            value = obj.cachedField("SectorName");
        end

        function value = get.TopPerformingCompanies(obj)
            value = obj.cachedField("TopPerformingCompanies");
        end

        function value = get.TopGrowthCompanies(obj)
            value = obj.cachedField("TopGrowthCompanies");
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

            response = obj.Session.getIndustry(obj.Key);
            obj.DataCache = yfinance.internal.industryResponseToData(response, Key=obj.Key);
            obj.IsFetched = true;
        end

        function value = cachedField(obj, fieldName)
            obj.ensureFetched();
            value = obj.DataCache.(fieldName);
        end
    end
end
