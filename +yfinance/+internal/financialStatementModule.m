% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function module = financialStatementModule(statementType, isQuarterly)
%FINANCIALSTATEMENTMODULE Return the Yahoo quoteSummary module for a statement.

arguments
    statementType (1,1) string
    isQuarterly (1,1) logical = false
end

statementType = lower(strtrim(statementType));

switch statementType
    case "income"
        module = "incomeStatementHistory";
    case "balance"
        module = "balanceSheetHistory";
    case "cashflow"
        module = "cashflowStatementHistory";
    otherwise
        error("yfinance:InvalidStatement", "Unsupported financial statement type: %s.", statementType);
end

if isQuarterly
    module = module + "Quarterly";
end
end
