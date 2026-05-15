classdef Ticker
    %TICKER Access Yahoo Finance data for a single symbol.

    properties (SetAccess = private)
        Symbol (1,1) string
    end

    properties (Access = private)
        Session
    end

    methods
        function obj = Ticker(symbol, options)
            arguments
                symbol (1,1) string {mustBeNonzeroLengthText}
                options.Session = yfinance.internal.Session()
            end

            obj.Symbol = upper(strtrim(symbol));
            obj.Session = options.Session;
        end

        function data = history(obj, options)
            %HISTORY Return historical OHLCV data for the ticker.
            arguments
                obj
                options.Period (1,1) string = "1mo"
                options.Interval (1,1) string = "1d"
                options.Start datetime = NaT
                options.End datetime = NaT
                options.AutoAdjust (1,1) logical = true
                options.IncludePrePost (1,1) logical = false
            end

            response = obj.Session.getChart( ...
                obj.Symbol, ...
                Period=options.Period, ...
                Interval=options.Interval, ...
                Start=options.Start, ...
                End=options.End, ...
                IncludePrePost=options.IncludePrePost);

            data = yfinance.internal.chartResponseToTimetable( ...
                response, ...
                Symbol=obj.Symbol, ...
                AutoAdjust=options.AutoAdjust);
        end

        function metadata = historyMetadata(obj)
            %HISTORYMETADATA Return Yahoo chart metadata for the ticker.

            response = obj.Session.getChart(obj.Symbol, Period="5d", Interval="1d");
            metadata = yfinance.internal.chartResponseToHistoryMetadata(response, Symbol=obj.Symbol);
        end

        function info = fastInfo(obj)
            %FASTINFO Return fast quote metadata for the ticker.

            try
                response = obj.Session.getQuote(obj.Symbol);
                info = yfinance.internal.quoteResponseToFastInfo(response, Symbol=obj.Symbol);
            catch exception
                if ~startsWith(string(exception.identifier), "yfinance:")
                    rethrow(exception);
                end

                response = obj.Session.getChart(obj.Symbol, Period="5d", Interval="1d");
                info = yfinance.internal.chartResponseToFastInfo(response, Symbol=obj.Symbol);
            end
        end

        function info = info(obj, options)
            %INFO Return quote summary metadata for the ticker.
            arguments
                obj
                options.Modules (1,:) string = yfinance.internal.defaultInfoModules()
            end

            try
                response = obj.Session.getQuoteSummary(obj.Symbol, Modules=options.Modules);
                info = yfinance.internal.quoteSummaryResponseToInfo(response, Symbol=obj.Symbol);
            catch exception
                if ~startsWith(string(exception.identifier), "yfinance:")
                    rethrow(exception);
                end

                info = obj.fastInfo();
                info.InfoSource = "fastInfoFallback";
            end
        end

        function data = quoteSummary(obj, options)
            %QUOTESUMMARY Return selected Yahoo quoteSummary modules.
            arguments
                obj
                options.Modules (1,:) string = yfinance.internal.defaultInfoModules()
            end

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules=options.Modules);
            data = yfinance.internal.quoteSummaryResponseToInfo(response, Symbol=obj.Symbol);
        end

        function data = summaryDetail(obj)
            %SUMMARYDETAIL Return summary detail metadata for the ticker.

            data = obj.quoteSummary(Modules="summaryDetail");
        end

        function data = defaultKeyStatistics(obj)
            %DEFAULTKEYSTATISTICS Return default key statistics for the ticker.

            data = obj.quoteSummary(Modules="defaultKeyStatistics");
        end

        function data = financialData(obj)
            %FINANCIALDATA Return financial data metadata for the ticker.

            data = obj.quoteSummary(Modules="financialData");
        end

        function data = assetProfile(obj)
            %ASSETPROFILE Return asset profile metadata for the ticker.

            data = obj.quoteSummary(Modules="assetProfile");
        end

        function data = summaryProfile(obj)
            %SUMMARYPROFILE Return summary profile metadata for the ticker.

            data = obj.quoteSummary(Modules="summaryProfile");
        end

        function data = quoteType(obj)
            %QUOTETYPE Return quote type metadata for the ticker.

            data = obj.quoteSummary(Modules="quoteType");
        end

        function data = fundProfile(obj)
            %FUNDPROFILE Return fund profile metadata for the ticker.

            data = obj.quoteSummary(Modules="fundProfile");
        end

        function data = netSharePurchaseActivity(obj)
            %NETSHAREPURCHASEACTIVITY Return net share purchase activity metadata.

            data = obj.quoteSummary(Modules="netSharePurchaseActivity");
        end

        function data = fundamentals(obj)
            %FUNDAMENTALS Return commonly used fundamentals modules.

            data = obj.quoteSummary(Modules=[ ...
                "summaryDetail", ...
                "defaultKeyStatistics", ...
                "financialData", ...
                "assetProfile", ...
                "quoteType"]);
        end

        function data = calendar(obj)
            %CALENDAR Return calendar event metadata for the ticker.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="calendarEvents");
            data = yfinance.internal.quoteSummaryResponseToCalendar(response, Symbol=obj.Symbol);
        end

        function data = secFilings(obj)
            %SECFILINGS Return SEC filing records for the ticker.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="secFilings");
            data = yfinance.internal.quoteSummaryResponseToSecFilings(response, Symbol=obj.Symbol);
        end

        function data = shares(obj)
            %SHARES Return current Yahoo share-count metrics for the ticker.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules=["defaultKeyStatistics", "price"]);
            data = yfinance.internal.quoteSummaryResponseToShares(response, Symbol=obj.Symbol);
        end

        function data = sharesFull(obj, options)
            %SHARESFULL Return historical shares outstanding for the ticker.
            arguments
                obj
                options.Start (1,1) datetime = NaT
                options.End (1,1) datetime = NaT
            end

            endTime = options.End;

            if isnat(endTime)
                endTime = datetime("now", TimeZone="UTC");
            end

            startTime = options.Start;

            if isnat(startTime)
                startTime = endTime - days(548);
            end

            response = obj.Session.getFundamentalsTimeSeries( ...
                obj.Symbol, ...
                Types="shares_out", ...
                Start=startTime, ...
                End=endTime);
            data = yfinance.internal.fundamentalsTimeSeriesResponseToShares(response, Symbol=obj.Symbol);
        end

        function data = valuation(obj)
            %VALUATION Return valuation measures for the ticker.

            response = obj.Session.getQuoteSummary( ...
                obj.Symbol, ...
                Modules=["price", "summaryDetail", "defaultKeyStatistics", "financialData"]);
            data = yfinance.internal.quoteSummaryResponseToValuation(response, Symbol=obj.Symbol);
        end

        function data = valuationMeasures(obj)
            %VALUATIONMEASURES Return valuation measures for the ticker.

            data = obj.valuation();
        end

        function data = analystPriceTargets(obj)
            %ANALYSTPRICETARGETS Return analyst target price metadata.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="financialData");
            data = yfinance.internal.quoteSummaryResponseToAnalystPriceTargets(response, Symbol=obj.Symbol);
        end

        function data = recommendations(obj)
            %RECOMMENDATIONS Return analyst recommendation trends.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="recommendationTrend");
            data = yfinance.internal.quoteSummaryResponseToRecommendations(response, Symbol=obj.Symbol);
        end

        function data = recommendationsSummary(obj)
            %RECOMMENDATIONSSUMMARY Return analyst recommendation summary trends.

            data = obj.recommendations();
        end

        function data = upgradesDowngrades(obj)
            %UPGRADESDOWNGRADES Return analyst rating change history.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="upgradeDowngradeHistory");
            data = yfinance.internal.quoteSummaryResponseToUpgradesDowngrades(response, Symbol=obj.Symbol);
        end

        function data = sustainability(obj)
            %SUSTAINABILITY Return ESG and sustainability score metadata.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="esgScores");
            data = yfinance.internal.quoteSummaryResponseToSustainability(response, Symbol=obj.Symbol);
        end

        function data = majorHolders(obj)
            %MAJORHOLDERS Return major holder breakdown metrics.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="majorHoldersBreakdown");
            data = yfinance.internal.quoteSummaryResponseToMetricTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module="majorHoldersBreakdown");
        end

        function data = institutionalHolders(obj)
            %INSTITUTIONALHOLDERS Return institutional ownership records.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="institutionOwnership");
            data = yfinance.internal.quoteSummaryResponseToHolderTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module="institutionOwnership", ...
                RecordField="ownershipList");
        end

        function data = mutualFundHolders(obj)
            %MUTUALFUNDHOLDERS Return mutual fund ownership records.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="fundOwnership");
            data = yfinance.internal.quoteSummaryResponseToHolderTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module="fundOwnership", ...
                RecordField="ownershipList");
        end

        function data = insiderTransactions(obj)
            %INSIDERTRANSACTIONS Return insider transaction records.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="insiderTransactions");
            data = yfinance.internal.quoteSummaryResponseToHolderTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module="insiderTransactions", ...
                RecordField="transactions");
        end

        function data = insiderPurchases(obj)
            %INSIDERPURCHASES Return insider purchase summary records.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="insiderTransactions");
            data = yfinance.internal.quoteSummaryResponseToHolderTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module="insiderTransactions", ...
                RecordField="purchases");
        end

        function data = insiderRosterHolders(obj)
            %INSIDERROSTERHOLDERS Return insider roster holder records.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="insiderHolders");
            data = yfinance.internal.quoteSummaryResponseToHolderTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module="insiderHolders", ...
                RecordField="holders");
        end

        function data = earningsEstimate(obj)
            %EARNINGSESTIMATE Return analyst earnings estimate rows.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="earningsTrend");
            data = yfinance.internal.quoteSummaryResponseToEarningsTrendTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Key="earningsEstimate", ...
                CurrencyKey="earningsCurrency");
        end

        function data = revenueEstimate(obj)
            %REVENUEESTIMATE Return analyst revenue estimate rows.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="earningsTrend");
            data = yfinance.internal.quoteSummaryResponseToEarningsTrendTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Key="revenueEstimate", ...
                CurrencyKey="revenueCurrency");
        end

        function data = earningsHistory(obj)
            %EARNINGSHISTORY Return historical earnings surprise rows.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="earningsHistory");
            data = yfinance.internal.quoteSummaryResponseToEarningsHistory(response, Symbol=obj.Symbol);
        end

        function data = epsTrend(obj)
            %EPSTREND Return analyst EPS trend rows.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="earningsTrend");
            data = yfinance.internal.quoteSummaryResponseToEarningsTrendTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Key="epsTrend", ...
                CurrencyKey="epsTrendCurrency");
        end

        function data = epsRevisions(obj)
            %EPSREVISIONS Return analyst EPS revision rows.

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="earningsTrend");
            data = yfinance.internal.quoteSummaryResponseToEarningsTrendTable( ...
                response, ...
                Symbol=obj.Symbol, ...
                Key="epsRevisions", ...
                CurrencyKey="epsRevisionsCurrency");
        end

        function data = growthEstimates(obj)
            %GROWTHESTIMATES Return stock and peer growth estimate rows.

            response = obj.Session.getQuoteSummary( ...
                obj.Symbol, ...
                Modules=["earningsTrend", "industryTrend", "sectorTrend", "indexTrend"]);
            data = yfinance.internal.quoteSummaryResponseToGrowthEstimates(response, Symbol=obj.Symbol);
        end

        function data = news(obj, options)
            %NEWS Return recent Yahoo Finance news for the ticker.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 8
            end

            response = obj.Session.getSearch(obj.Symbol, QuotesCount=0, NewsCount=options.Count);
            result = yfinance.internal.searchResponseToResult(response, Query=obj.Symbol);
            data = result.News;
        end

        function data = incomeStmt(obj, options)
            %INCOMESTMT Return income statement data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
                options.Trailing (1,1) logical = false
            end

            if options.Trailing
                if options.Quarterly
                    error("yfinance:InvalidFrequency", "Income statement cannot be both quarterly and trailing.");
                end

                data = obj.ttmIncomeStmt();
                return
            end

            module = yfinance.internal.financialStatementModule("income", options.Quarterly);
            response = obj.Session.getQuoteSummary(obj.Symbol, Modules=module);
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module=module);
        end

        function data = financials(obj, options)
            %FINANCIALS Return income statement financials for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
                options.Trailing (1,1) logical = false
            end

            data = obj.incomeStmt(Quarterly=options.Quarterly, Trailing=options.Trailing);
        end

        function data = quarterlyIncomeStmt(obj)
            %QUARTERLYINCOMESTMT Return quarterly income statement data.

            data = obj.incomeStmt(Quarterly=true);
        end

        function data = ttmIncomeStmt(obj)
            %TTMINCOMESTMT Return trailing twelve-month income statement data.

            types = yfinance.internal.fundamentalsTimeSeriesTypes("income", "trailing");
            response = obj.Session.getFundamentalsTimeSeries( ...
                obj.Symbol, ...
                Types=types, ...
                Start=datetime(2016, 12, 31, TimeZone="UTC"), ...
                End=datetime("now", TimeZone="UTC"));
            data = yfinance.internal.fundamentalsTimeSeriesResponseToFinancialStatement( ...
                response, ...
                Symbol=obj.Symbol, ...
                StatementType="income", ...
                Frequency="trailing", ...
                Types=types);
        end

        function data = quarterlyFinancials(obj)
            %QUARTERLYFINANCIALS Return quarterly income statement financials.

            data = obj.quarterlyIncomeStmt();
        end

        function data = ttmFinancials(obj)
            %TTMFINANCIALS Return trailing twelve-month income statement financials.

            data = obj.ttmIncomeStmt();
        end

        function data = balanceSheet(obj, options)
            %BALANCESHEET Return balance sheet data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
            end

            module = yfinance.internal.financialStatementModule("balance", options.Quarterly);
            response = obj.Session.getQuoteSummary(obj.Symbol, Modules=module);
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module=module);
        end

        function data = quarterlyBalanceSheet(obj)
            %QUARTERLYBALANCESHEET Return quarterly balance sheet data.

            data = obj.balanceSheet(Quarterly=true);
        end

        function data = cashFlow(obj, options)
            %CASHFLOW Return cash flow statement data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
                options.Trailing (1,1) logical = false
            end

            if options.Trailing
                if options.Quarterly
                    error("yfinance:InvalidFrequency", "Cash flow statement cannot be both quarterly and trailing.");
                end

                data = obj.ttmCashFlow();
                return
            end

            module = yfinance.internal.financialStatementModule("cashflow", options.Quarterly);
            response = obj.Session.getQuoteSummary(obj.Symbol, Modules=module);
            data = yfinance.internal.quoteSummaryResponseToFinancialStatement( ...
                response, ...
                Symbol=obj.Symbol, ...
                Module=module);
        end

        function data = quarterlyCashFlow(obj)
            %QUARTERLYCASHFLOW Return quarterly cash flow statement data.

            data = obj.cashFlow(Quarterly=true);
        end

        function data = ttmCashFlow(obj)
            %TTMCASHFLOW Return trailing twelve-month cash flow statement data.

            types = yfinance.internal.fundamentalsTimeSeriesTypes("cashflow", "trailing");
            response = obj.Session.getFundamentalsTimeSeries( ...
                obj.Symbol, ...
                Types=types, ...
                Start=datetime(2016, 12, 31, TimeZone="UTC"), ...
                End=datetime("now", TimeZone="UTC"));
            data = yfinance.internal.fundamentalsTimeSeriesResponseToFinancialStatement( ...
                response, ...
                Symbol=obj.Symbol, ...
                StatementType="cashflow", ...
                Frequency="trailing", ...
                Types=types);
        end

        function data = earnings(obj, options)
            %EARNINGS Return earnings and revenue chart rows.
            arguments
                obj
                options.Quarterly (1,1) logical = false
            end

            response = obj.Session.getQuoteSummary(obj.Symbol, Modules="earnings");
            data = yfinance.internal.quoteSummaryResponseToEarnings( ...
                response, ...
                Symbol=obj.Symbol, ...
                Quarterly=options.Quarterly);
        end

        function data = quarterlyEarnings(obj)
            %QUARTERLYEARNINGS Return quarterly earnings and revenue rows.

            data = obj.earnings(Quarterly=true);
        end

        function expirations = options(obj)
            %OPTIONS Return option expiration dates for the ticker.

            response = obj.Session.getOptions(obj.Symbol);
            expirations = yfinance.internal.optionsResponseToExpirations(response, Symbol=obj.Symbol);
        end

        function chain = optionChain(obj, expiration)
            %OPTIONCHAIN Return calls and puts for one option expiration.
            arguments
                obj
                expiration = []
            end

            response = obj.Session.getOptions(obj.Symbol, Expiration=expiration);
            chain = yfinance.internal.optionsResponseToOptionChain(response, Symbol=obj.Symbol);
        end

        function data = actions(obj, options)
            %ACTIONS Return dividends, splits, and capital gains for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            historyData = obj.history( ...
                Period=options.Period, ...
                Interval="1d", ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=false);
            data = yfinance.internal.selectActionData(historyData);
        end

        function data = dividends(obj, options)
            %DIVIDENDS Return dividend payments for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            historyData = obj.history( ...
                Period=options.Period, ...
                Interval="1d", ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=false);
            data = yfinance.internal.selectActionData(historyData, "Dividends");
        end

        function data = splits(obj, options)
            %SPLITS Return stock split ratios for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            historyData = obj.history( ...
                Period=options.Period, ...
                Interval="1d", ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=false);
            data = yfinance.internal.selectActionData(historyData, "StockSplits");
        end

        function data = capitalGains(obj, options)
            %CAPITALGAINS Return capital gains distributions for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            historyData = obj.history( ...
                Period=options.Period, ...
                Interval="1d", ...
                Start=options.Start, ...
                End=options.End, ...
                AutoAdjust=false);
            data = yfinance.internal.selectActionData(historyData, "CapitalGains");
        end

        function metadata = getHistoryMetadata(obj)
            %GETHISTORYMETADATA Return Yahoo chart metadata for the ticker.

            metadata = obj.historyMetadata();
        end

        function info = getFastInfo(obj)
            %GETFASTINFO Return fast quote metadata for the ticker.

            info = obj.fastInfo();
        end

        function info = getInfo(obj, options)
            %GETINFO Return quote summary metadata for the ticker.
            arguments
                obj
                options.Modules (1,:) string = yfinance.internal.defaultInfoModules()
            end

            info = obj.info(Modules=options.Modules);
        end

        function isinValue = isin(obj)
            %ISIN Return the ticker's ISIN when the lookup service can resolve it.

            if contains(obj.Symbol, "-") || contains(obj.Symbol, "^")
                isinValue = "-";
                return
            end

            queryText = obj.Symbol;
            infoData = obj.info();

            if isfield(infoData, "shortName") && strlength(string(infoData.shortName)) > 0
                queryText = string(infoData.shortName);
            end

            text = obj.Session.getIsinSearch(queryText);
            isinValue = yfinance.internal.businessInsiderSearchResponseToIsin( ...
                text, ...
                Symbol=obj.Symbol, ...
                Query=queryText);
        end

        function isinValue = getIsin(obj)
            %GETISIN Return the ticker's ISIN when the lookup service can resolve it.

            isinValue = obj.isin();
        end

        function data = getCalendar(obj)
            %GETCALENDAR Return calendar event metadata for the ticker.

            data = obj.calendar();
        end

        function data = getSecFilings(obj)
            %GETSECFILINGS Return SEC filing records for the ticker.

            data = obj.secFilings();
        end

        function data = getShares(obj)
            %GETSHARES Return current Yahoo share-count metrics for the ticker.

            data = obj.shares();
        end

        function data = getSharesFull(obj, options)
            %GETSHARESFULL Return historical shares outstanding for the ticker.
            arguments
                obj
                options.Start (1,1) datetime = NaT
                options.End (1,1) datetime = NaT
            end

            data = obj.sharesFull(Start=options.Start, End=options.End);
        end

        function data = getValuationMeasures(obj)
            %GETVALUATIONMEASURES Return valuation measures for the ticker.

            data = obj.valuationMeasures();
        end

        function data = getAnalystPriceTargets(obj)
            %GETANALYSTPRICETARGETS Return analyst target price metadata.

            data = obj.analystPriceTargets();
        end

        function data = getRecommendations(obj)
            %GETRECOMMENDATIONS Return analyst recommendation trends.

            data = obj.recommendations();
        end

        function data = getRecommendationsSummary(obj)
            %GETRECOMMENDATIONSSUMMARY Return analyst recommendation summary trends.

            data = obj.recommendationsSummary();
        end

        function data = getUpgradesDowngrades(obj)
            %GETUPGRADESDOWNGRADES Return analyst rating change history.

            data = obj.upgradesDowngrades();
        end

        function data = getSustainability(obj)
            %GETSUSTAINABILITY Return ESG and sustainability score metadata.

            data = obj.sustainability();
        end

        function data = getMajorHolders(obj)
            %GETMAJORHOLDERS Return major holder breakdown metrics.

            data = obj.majorHolders();
        end

        function data = getInstitutionalHolders(obj)
            %GETINSTITUTIONALHOLDERS Return institutional ownership records.

            data = obj.institutionalHolders();
        end

        function data = getMutualFundHolders(obj)
            %GETMUTUALFUNDHOLDERS Return mutual fund ownership records.

            data = obj.mutualFundHolders();
        end

        function data = getInsiderTransactions(obj)
            %GETINSIDERTRANSACTIONS Return insider transaction records.

            data = obj.insiderTransactions();
        end

        function data = getInsiderPurchases(obj)
            %GETINSIDERPURCHASES Return insider purchase summary records.

            data = obj.insiderPurchases();
        end

        function data = getInsiderRosterHolders(obj)
            %GETINSIDERROSTERHOLDERS Return insider roster holder records.

            data = obj.insiderRosterHolders();
        end

        function data = getEarningsEstimate(obj)
            %GETEARNINGSESTIMATE Return analyst earnings estimate rows.

            data = obj.earningsEstimate();
        end

        function data = getRevenueEstimate(obj)
            %GETREVENUEESTIMATE Return analyst revenue estimate rows.

            data = obj.revenueEstimate();
        end

        function data = getEarningsHistory(obj)
            %GETEARNINGSHISTORY Return historical earnings surprise rows.

            data = obj.earningsHistory();
        end

        function data = getEpsTrend(obj)
            %GETEPSTREND Return analyst EPS trend rows.

            data = obj.epsTrend();
        end

        function data = getEpsRevisions(obj)
            %GETEPSREVISIONS Return analyst EPS revision rows.

            data = obj.epsRevisions();
        end

        function data = getGrowthEstimates(obj)
            %GETGROWTHESTIMATES Return stock and peer growth estimate rows.

            data = obj.growthEstimates();
        end

        function data = getNews(obj, options)
            %GETNEWS Return recent Yahoo Finance news for the ticker.
            arguments
                obj
                options.Count (1,1) double {mustBeNonnegative, mustBeInteger} = 8
            end

            data = obj.news(Count=options.Count);
        end

        function data = incomeStatement(obj, options)
            %INCOMESTATEMENT Return income statement data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
                options.Trailing (1,1) logical = false
            end

            data = obj.incomeStmt(Quarterly=options.Quarterly, Trailing=options.Trailing);
        end

        function data = getIncomeStmt(obj, options)
            %GETINCOMESTMT Return income statement data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
                options.Trailing (1,1) logical = false
            end

            data = obj.incomeStmt(Quarterly=options.Quarterly, Trailing=options.Trailing);
        end

        function data = balancesheet(obj, options)
            %BALANCESHEET Return balance sheet data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
            end

            data = obj.balanceSheet(Quarterly=options.Quarterly);
        end

        function data = getBalanceSheet(obj, options)
            %GETBALANCESHEET Return balance sheet data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
            end

            data = obj.balanceSheet(Quarterly=options.Quarterly);
        end

        function data = cashflow(obj, options)
            %CASHFLOW Return cash flow statement data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
                options.Trailing (1,1) logical = false
            end

            data = obj.cashFlow(Quarterly=options.Quarterly, Trailing=options.Trailing);
        end

        function data = getCashFlow(obj, options)
            %GETCASHFLOW Return cash flow statement data for the ticker.
            arguments
                obj
                options.Quarterly (1,1) logical = false
                options.Trailing (1,1) logical = false
            end

            data = obj.cashFlow(Quarterly=options.Quarterly, Trailing=options.Trailing);
        end

        function data = getEarnings(obj, options)
            %GETEARNINGS Return earnings and revenue chart rows.
            arguments
                obj
                options.Quarterly (1,1) logical = false
            end

            data = obj.earnings(Quarterly=options.Quarterly);
        end

        function expirations = getOptions(obj)
            %GETOPTIONS Return option expiration dates for the ticker.

            expirations = obj.options();
        end

        function chain = getOptionChain(obj, expiration)
            %GETOPTIONCHAIN Return calls and puts for one option expiration.
            arguments
                obj
                expiration = []
            end

            chain = obj.optionChain(expiration);
        end

        function data = getActions(obj, options)
            %GETACTIONS Return dividends, splits, and capital gains for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            data = obj.actions(Period=options.Period, Start=options.Start, End=options.End);
        end

        function data = getDividends(obj, options)
            %GETDIVIDENDS Return dividend payments for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            data = obj.dividends(Period=options.Period, Start=options.Start, End=options.End);
        end

        function data = getSplits(obj, options)
            %GETSPLITS Return stock split ratios for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            data = obj.splits(Period=options.Period, Start=options.Start, End=options.End);
        end

        function data = getCapitalGains(obj, options)
            %GETCAPITALGAINS Return capital gains distributions for the ticker.
            arguments
                obj
                options.Period (1,1) string = "max"
                options.Start datetime = NaT
                options.End datetime = NaT
            end

            data = obj.capitalGains(Period=options.Period, Start=options.Start, End=options.End);
        end
    end
end
