# matlab-yfinance

MATLAB implementation of the core ideas and public API shape of Python [`yfinance`](https://github.com/ranaroussi/yfinance).

This repository is a MATLAB toolbox project. The implementation target is a pure MATLAB package under the `yfinance` namespace, with no runtime dependency on Python.

## Status

Active early implementation. The first usable Yahoo Finance data paths are in place and covered by MATLAB unit tests.

Implemented today:

- `yfinance.Ticker(symbol)`
- `yfinance.Tickers(symbols)`
- `Ticker.history(...)` using Yahoo Finance chart data
- `Ticker.historyMetadata()`
- `Tickers.history(...)` and `Tickers.download(...)`
- `yfinance.download(symbols, ...)` for one or more tickers
- `Ticker.actions()`
- `Ticker.dividends()`
- `Ticker.splits()`
- `Ticker.capitalGains()`
- `Ticker.fastInfo()`
- `Ticker.info()`
- `Ticker.isin()` and `Ticker.getIsin()`
- `Ticker.quoteSummary(Modules=...)`
- `Ticker.summaryDetail()`
- `Ticker.defaultKeyStatistics()`
- `Ticker.financialData()`
- `Ticker.assetProfile()`
- `Ticker.summaryProfile()`
- `Ticker.quoteType()`
- `Ticker.fundProfile()`
- `Ticker.netSharePurchaseActivity()`
- `Ticker.fundamentals()`
- `Ticker.calendar()`
- `Ticker.secFilings()`
- `Ticker.shares()`
- `Ticker.sharesFull()`
- `Ticker.valuation()`
- `Ticker.valuationMeasures()`
- `Ticker.analystPriceTargets()`
- `Ticker.recommendations()`
- `Ticker.recommendationsSummary()`
- `Ticker.upgradesDowngrades()`
- `Ticker.earningsEstimate()`
- `Ticker.revenueEstimate()`
- `Ticker.earningsHistory()`
- `Ticker.epsTrend()`
- `Ticker.epsRevisions()`
- `Ticker.growthEstimates()`
- `Ticker.sustainability()`
- `Ticker.majorHolders()`
- `Ticker.institutionalHolders()`
- `Ticker.mutualFundHolders()`
- `Ticker.insiderTransactions()`
- `Ticker.insiderPurchases()`
- `Ticker.insiderRosterHolders()`
- `Ticker.news()`
- `Ticker.earnings()`
- `Ticker.incomeStmt()`
- `Ticker.financials()`
- `Ticker.quarterlyIncomeStmt()`
- `Ticker.quarterlyFinancials()`
- `Ticker.ttmIncomeStmt()`
- `Ticker.ttmFinancials()`
- `Ticker.balanceSheet()`
- `Ticker.quarterlyBalanceSheet()`
- `Ticker.cashFlow()`
- `Ticker.quarterlyCashFlow()`
- `Ticker.ttmCashFlow()`
- `Ticker.quarterlyEarnings()`
- `Ticker.options()`
- `Ticker.optionChain(expiration)`
- Common yfinance compatibility aliases, including `getInfo()`, `getFastInfo()`, `getRecommendations()`, `getOptions()`, `getIncomeStmt()`, `getBalanceSheet()`, `getCashFlow()`, `cashflow()`, and `balancesheet()`
- `yfinance.Search(query)`
- `yfinance.screen(queryName, ...)`
- `yfinance.screen(queryObject, ...)` with `yfinance.EquityQuery`, `yfinance.FundQuery`, or `yfinance.ETFQuery`
- `yfinance.Screener(queryNameOrObject, ...)`
- Shared Yahoo HTTP transport with retry/backoff, cookie/crumb acquisition, and structured errors for rate limits, authorization failures, timeouts, network failures, and empty responses

Still planned:

- Market, sector, industry, and funds APIs
- WebSocket/live quote support
- Toolbox packaging and generated API docs

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for the full implementation plan.

## Usage

```matlab
ticker = yfinance.Ticker("AAPL");
prices = ticker.history(Period="1mo", Interval="1d");
metadata = ticker.historyMetadata();

data = yfinance.download(["AAPL", "MSFT"], Period="6mo");

dividends = ticker.dividends(Period="1y");
info = ticker.fastInfo();
profile = ticker.info();
isin = ticker.isin();
fundamentals = ticker.fundamentals();
statistics = ticker.defaultKeyStatistics();
calendar = ticker.calendar();
filings = ticker.secFilings();
shareMetrics = ticker.shares();
shareHistory = ticker.sharesFull(Start=datetime("2024-01-01"), End=datetime("today"));
valuation = ticker.valuation();
targets = ticker.analystPriceTargets();
recommendations = ticker.recommendations();
recommendationSummary = ticker.recommendationsSummary();
ratings = ticker.upgradesDowngrades();
epsEstimates = ticker.earningsEstimate();
revenueEstimates = ticker.revenueEstimate();
earningsSurprises = ticker.earningsHistory();
epsTrend = ticker.epsTrend();
epsRevisions = ticker.epsRevisions();
growth = ticker.growthEstimates();
esg = ticker.sustainability();
majorHolders = ticker.majorHolders();
institutions = ticker.institutionalHolders();
funds = ticker.mutualFundHolders();
insiders = ticker.insiderTransactions();
news = ticker.news();

earnings = ticker.earnings();
quarterlyEarnings = ticker.quarterlyEarnings();
income = ticker.incomeStmt();
financials = ticker.financials();
quarterlyIncome = ticker.incomeStmt(Quarterly=true);
quarterlyIncomeAlias = ticker.quarterlyIncomeStmt();
ttmIncome = ticker.ttmIncomeStmt();
ttmFinancials = ticker.ttmFinancials();
balance = ticker.balanceSheet();
quarterlyBalance = ticker.quarterlyBalanceSheet();
cash = ticker.cashFlow();
quarterlyCash = ticker.quarterlyCashFlow();
ttmCash = ticker.ttmCashFlow();

expirations = ticker.options();
chain = ticker.optionChain(expirations(1));

tickers = yfinance.Tickers(["AAPL", "MSFT"]);
batchPrices = tickers.history(Period="1mo");
batchInfo = tickers.fastInfo();

results = yfinance.Search("apple");
symbols = results.Quotes.Symbol;

gainers = yfinance.screen("day_gainers", Count=10);
screener = yfinance.Screener("most_actives", Count=10);

query = yfinance.EquityQuery("and", { ...
    yfinance.EquityQuery("gt", {"percentchange", 3}), ...
    yfinance.EquityQuery("eq", {"region", "us"})});
customGainers = yfinance.screen(query, Size=10, SortField="percentchange", SortAscending=true);

etfQuery = yfinance.ETFQuery("eq", {"region", "us"});
etfs = yfinance.Screener(etfQuery, Size=10);
```

`history` and `download` currently return MATLAB timetables with:

- `Open`
- `High`
- `Low`
- `Close`
- `AdjClose`
- `Volume`
- `Dividends`
- `StockSplits`
- `CapitalGains`

## Reliability Notes

Yahoo Finance endpoints are unofficial and can return rate limits or authorization errors. The shared HTTP transport uses a browser-style default user agent and retries transient failures such as `429` rate limits, timeouts, generic network failures, and empty responses. For quoteSummary-backed methods, the session attempts Yahoo cookie/crumb acquisition, appends the crumb to requests, sends the captured cookie header, and refreshes credentials once after an authorization failure. It raises structured MATLAB errors including:

- `yfinance:RateLimited`
- `yfinance:Unauthorized`
- `yfinance:Timeout`
- `yfinance:NetworkError`
- `yfinance:EmptyResponse`

Some quoteSummary-backed methods may still be unavailable when Yahoo rate-limits credential endpoints or changes its browser-style cookie/crumb flow. In that case, live calls raise structured errors such as `yfinance:RateLimited` or `yfinance:Unauthorized`; fixture-backed unit tests cover response parsing independently from live Yahoo availability.

## Development

Run checks with MATLAB buildtool from the repository root:

```matlab
buildtool test
buildtool check
```

The project follows MATLAB package conventions, `matlab.unittest` for tests, and build tasks for repeatable validation.

The current implementation is tested with MATLAB R2024b.

## Disclaimer

This project is not affiliated with Yahoo, Yahoo Finance, or the upstream Python `yfinance` maintainers. Yahoo Finance data is subject to Yahoo's terms and availability. This toolbox is intended for research and educational use.
