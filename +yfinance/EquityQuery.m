% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef EquityQuery < yfinance.internal.ScreenerQuery
    %EQUITYQUERY Build Yahoo Finance stock screener filters.

    methods
        function obj = EquityQuery(operator, operands)
            arguments
                operator (1,1) string {mustBeNonzeroLengthText}
                operands (1,:) cell
            end

            obj@yfinance.internal.ScreenerQuery(operator, operands, "EQUITY");
        end
    end
end
