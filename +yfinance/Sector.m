% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef Sector < handle
    %SECTOR Access Yahoo Finance sector data.

    properties (SetAccess = private)
        Key (1,1) string
    end

    properties (Dependent)
        Name string
        Symbol string
        Overview struct
        TopCompanies table
        ResearchReports table
        TopETFs table
        TopMutualFunds table
        Industries table
        Raw struct
    end

    properties (Access = private)
        Session
        IsFetched (1,1) logical = false
        DataCache struct = struct()
    end

    methods
        function obj = Sector(key, options)
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

        function value = get.TopETFs(obj)
            value = obj.cachedField("TopETFs");
        end

        function value = get.TopMutualFunds(obj)
            value = obj.cachedField("TopMutualFunds");
        end

        function value = get.Industries(obj)
            value = obj.cachedField("Industries");
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

            response = obj.Session.getSector(obj.Key);
            obj.DataCache = yfinance.internal.sectorResponseToData(response, Key=obj.Key);
            obj.IsFetched = true;
        end

        function value = cachedField(obj, fieldName)
            obj.ensureFetched();
            value = obj.DataCache.(fieldName);
        end
    end
end
