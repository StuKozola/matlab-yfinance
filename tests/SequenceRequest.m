classdef SequenceRequest < handle
    %SEQUENCEREQUEST Test helper that returns or throws scripted results.

    properties
        Results cell
        CallCount (1,1) double = 0
        LastUrl (1,1) string = ""
        Urls (:,1) string = strings(0, 1)
        LastArguments cell = {}
    end

    methods
        function obj = SequenceRequest(results)
            obj.Results = results;
        end

        function response = send(obj, url, varargin)
            obj.CallCount = obj.CallCount + 1;
            obj.LastUrl = string(url);
            obj.Urls(end + 1, 1) = obj.LastUrl;
            obj.LastArguments = varargin;

            resultIndex = min(obj.CallCount, numel(obj.Results));
            result = obj.Results{resultIndex};

            if isa(result, "MException")
                throw(result);
            end

            response = result;
        end
    end
end
