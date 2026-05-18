# matlab-yfinance

MATLAB implementation of the core ideas and public API shape of Python [`yfinance`](https://github.com/ranaroussi/yfinance).

This repository is a MATLAB toolbox project. The implementation target is a pure MATLAB package under the `yfinance` namespace, with no runtime dependency on Python.

## Status

Initial release candidate. The core MATLAB API surface is in place, fixture-backed unit tests cover the implemented data paths, and optional live Yahoo smoke tests are isolated from the default test suite.

Implemented today:

- `yfinance.Ticker(symbol)`
- `yfinance.Tickers(symbols)`
- `Ticker.history(...)` using Yahoo Finance chart data
- `Ticker.historyMetadata()`
- `Tickers.history(...)` and `Tickers.download(...)`
- `Tickers.news(...)`
- `Tickers.live(...)`
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
- `Ticker.fundsData()` and `Ticker.getFundsData()`
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
- `yfinance.Search(query)` with quotes, news, lists, research reports, navigation links, raw response, and upstream-style search flags
- `yfinance.Lookup(query)`
- `yfinance.screen(queryName, ...)`
- `yfinance.screen(queryObject, ...)` with `yfinance.EquityQuery`, `yfinance.FundQuery`, or `yfinance.ETFQuery`
- `yfinance.Screener(queryNameOrObject, ...)`
- `yfinance.predefinedScreenerQueries()` and `yfinance.PREDEFINED_SCREENER_QUERIES()`
- `yfinance.Market(market)` for market summary and status
- `yfinance.Sector(key)` for sector overview, companies, ETFs, mutual funds, and industries
- `yfinance.Industry(key)` for industry overview, companies, and sector links
- `yfinance.FundsData(symbol)` for ETF and mutual fund profile, holdings, operations, ratings, and sector weights
- `yfinance.Calendars(...)` for earnings, IPO, economic-event, and split calendars
- `yfinance.WebSocket` and `yfinance.AsyncWebSocket` live quote clients using a MATLAB-compatible polling baseline
- `yfinance.ExperimentalWebSocket` and `yfinance.WebSocket(Transport="stream")` for opt-in Yahoo protobuf streaming
- Process-local configuration helpers: `yfinance.config()`, `yfinance.setConfig(...)`, `yfinance.set_config(...)`, `yfinance.enableDebugMode()`, `yfinance.enable_debug_mode()`, `yfinance.setTzCacheLocation(...)`, and `yfinance.set_tz_cache_location(...)`
- `buildtool docs` for generated markdown API reference
- `buildtool package` for `.mltbx` toolbox packaging into `dist/`
- Shared Yahoo HTTP transport with retry/backoff, cookie/crumb acquisition, and structured errors for rate limits, authorization failures, timeouts, network failures, and empty responses

The original first-pass implementation plan is now covered. No release-blocking upstream export gaps remain for the current MATLAB scope. Remaining work should focus on broader live-stream fidelity, Yahoo schema drift repairs, and post-release polish.

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for the full implementation plan, [docs/PARITY_AUDIT.md](docs/PARITY_AUDIT.md) for the current upstream parity checklist, and [docs/RELEASE_NOTES.md](docs/RELEASE_NOTES.md) for release notes.

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
fundData = ticker.fundsData();
topHoldings = fundData.TopHoldings;
sectorWeights = fundData.SectorWeightings;
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
batchNews = tickers.news(Count=3);

results = yfinance.Search("apple");
symbols = results.Quotes.Symbol;
researchReports = results.Research;
navLinks = results.Nav;

lookup = yfinance.Lookup("apple");
stockMatches = lookup.getStock(Count=10);
cryptoMatches = lookup.Cryptocurrency;

gainers = yfinance.screen("day_gainers", Count=10);
screener = yfinance.Screener("most_actives", Count=10);
predefinedQueries = yfinance.predefinedScreenerQueries();
predefinedDefinitions = yfinance.PREDEFINED_SCREENER_QUERIES();

query = yfinance.EquityQuery("and", { ...
    yfinance.EquityQuery("gt", {"percentchange", 3}), ...
    yfinance.EquityQuery("eq", {"region", "us"})});
customGainers = yfinance.screen(query, Size=10, SortField="percentchange", SortAscending=true);

etfQuery = yfinance.ETFQuery("eq", {"region", "us"});
etfs = yfinance.Screener(etfQuery, Size=10);

market = yfinance.Market("us");
marketSummary = market.Summary;
marketStatus = market.Status;

sector = yfinance.Sector("technology");
sectorIndustries = sector.Industries;

industry = yfinance.Industry("software-infrastructure");
industryLeaders = industry.TopPerformingCompanies;

spyFundData = yfinance.FundsData("SPY");
spyHoldings = spyFundData.TopHoldings;

calendars = yfinance.Calendars(Start=datetime("today"), End=datetime("today") + days(7));
earningsCalendar = calendars.getEarningsCalendar(FilterMostActive=false);
ipoCalendar = calendars.IpoInfoCalendar;

live = yfinance.WebSocket(PollInterval=5);
live.subscribe(["AAPL", "MSFT"]);
snapshot = live.listen([], MaxIterations=1);
live.close();

stream = yfinance.ExperimentalWebSocket();
stream.subscribe("BTC-USD");
tick = stream.listen([], MaxIterations=1);
stream.close();

currentConfig = yfinance.config();
yfinance.setConfig(Timeout=20, Retries=3, RetryDelay=0.25);
yfinance.enableDebugMode();
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

`yfinance.config()` returns process-local defaults for subsequently created sessions. Use `yfinance.setConfig(...)` or upstream-compatible `yfinance.set_config(...)` to adjust retry count, timeout, retry delay, user agent, credential use, debug logging, proxy metadata, or the upstream-compatible timezone cache location. MATLAB does not require yfinance's Python timezone cache, so the timezone cache path is stored for compatibility and documentation rather than used by core date conversion.

`yfinance.WebSocket` and `yfinance.AsyncWebSocket` provide the upstream subscribe/listen/unsubscribe workflow through repeated quote endpoint snapshots by default. This remains the supported MATLAB baseline. Opt-in streaming is available through `yfinance.ExperimentalWebSocket` or `yfinance.WebSocket(Transport="stream")`, which use Yahoo's `wss://` stream and decode protobuf pricing payloads without Python. See [docs/LIVE_STREAMING_AND_TESTS.md](docs/LIVE_STREAMING_AND_TESTS.md) for the support policy and optional live test workflow, and [docs/WEBSOCKET_PROTOBUF_INVESTIGATION.md](docs/WEBSOCKET_PROTOBUF_INVESTIGATION.md) for implementation details.

Experimental streaming shares the same live quote table shape where Yahoo supplies matching fields, but it remains opt-in because Yahoo's stream is unofficial and can change without notice.

## Development

Run checks with MATLAB buildtool from the repository root:

```matlab
buildtool test
buildtool check
buildtool docs
buildtool package
```

GitHub Actions also runs `test`, `check`, and toolbox packaging on pushes and pull requests. Successful workflow runs upload the generated `.mltbx` as the `matlab-yfinance-toolbox` artifact. Tags matching `v*` run the release workflow, which builds the toolbox and attaches the `.mltbx` to a GitHub Release.

Optional live Yahoo smoke tests are isolated from the default suite:

```matlab
setenv("YFINANCE_LIVE_TESTS", "1")
buildtool liveTest
```

The live target treats known Yahoo availability failures such as rate limits, authorization changes, timeouts, empty responses, network errors, and WebSocket handshake rejections as skipped assumptions. It includes an opt-in experimental streaming smoke test and still fails when a live smoke test reaches Yahoo successfully but the toolbox behavior is incorrect.

The project follows MATLAB package conventions, `matlab.unittest` for tests, generated markdown API docs, and build tasks for repeatable validation. Toolbox packages are written to `dist/`, which is intentionally ignored by git.

The current implementation is versioned as `0.1.2` and tested with MATLAB R2024b.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Disclaimer

This project is not affiliated with Yahoo, Yahoo Finance, or the upstream Python `yfinance` maintainers. Yahoo Finance data is subject to Yahoo's terms and availability. This toolbox is intended for research and educational use.
