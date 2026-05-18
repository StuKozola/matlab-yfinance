% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef CallbackRecorder < handle
    %CALLBACKRECORDER Test helper that stores live quote callback payloads.

    properties
        Messages (:,1) cell = cell(0, 1)
    end

    methods
        function record(obj, message)
            obj.Messages{end + 1, 1} = message;
        end

        function value = symbols(obj)
            value = strings(numel(obj.Messages), 1);

            for messageIndex = 1:numel(obj.Messages)
                value(messageIndex) = obj.Messages{messageIndex}.Symbol;
            end
        end
    end
end
