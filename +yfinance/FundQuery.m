% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef FundQuery < yfinance.internal.ScreenerQuery
    %FUNDQUERY Build Yahoo Finance mutual fund screener filters.

    methods
        function obj = FundQuery(operator, operands)
            arguments
                operator (1,1) string {mustBeNonzeroLengthText}
                operands (1,:) cell
            end

            obj@yfinance.internal.ScreenerQuery(operator, operands, "MUTUALFUND");
        end
    end
end
