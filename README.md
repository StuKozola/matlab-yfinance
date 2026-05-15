# matlab-yfinance

MATLAB implementation of the core ideas and public API shape of Python [`yfinance`](https://github.com/ranaroussi/yfinance).

This repository is a MATLAB toolbox project. The implementation target is a pure MATLAB package under the `yfinance` namespace, with no runtime dependency on Python.

## Status

Active early implementation. The first usable Yahoo Finance data paths are in place and covered by MATLAB unit tests.

Implemented today:

- `yfinance.Ticker(symbol)`
- `yfinance.Tickers(symbols)`
- `Ticker.history(...)` using Yahoo Finance chart data
- `Tickers.history(...)` and `Tickers.download(...)`
- `yfinance.download(symbols, ...)` for one or more tickers
- `Ticker.actions()`
- `Ticker.dividends()`
- `Ticker.splits()`
- `Ticker.capitalGains()`
- `Ticker.fastInfo()`
- `Ticker.info()`
- `Ticker.calendar()`
- `Ticker.analystPriceTargets()`
- `Ticker.recommendations()`
- `Ticker.upgradesDowngrades()`
- `Ticker.sustainability()`
- `Ticker.majorHolders()`
- `Ticker.institutionalHolders()`
- `Ticker.mutualFundHolders()`
- `Ticker.insiderTransactions()`
- `Ticker.insiderPurchases()`
- `Ticker.insiderRosterHolders()`
- `Ticker.news()`
- `Ticker.incomeStmt()`
- `Ticker.balanceSheet()`
- `Ticker.cashFlow()`
- `Ticker.options()`
- `Ticker.optionChain(expiration)`
- `yfinance.Search(query)`
- Shared Yahoo HTTP transport with retry/backoff and structured errors for rate limits, authorization failures, timeouts, network failures, and empty responses

Still planned:

- Remaining quote/profile aliases and estimate tables
- Broader fundamentals and earnings coverage
- Screener, market, sector, industry, and funds APIs
- WebSocket/live quote support
- Toolbox packaging and generated API docs

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for the full implementation plan.

## Usage

```matlab
ticker = yfinance.Ticker("AAPL");
prices = ticker.history(Period="1mo", Interval="1d");

data = yfinance.download(["AAPL", "MSFT"], Period="6mo");

dividends = ticker.dividends(Period="1y");
info = ticker.fastInfo();
profile = ticker.info();
calendar = ticker.calendar();
targets = ticker.analystPriceTargets();
recommendations = ticker.recommendations();
ratings = ticker.upgradesDowngrades();
esg = ticker.sustainability();
majorHolders = ticker.majorHolders();
institutions = ticker.institutionalHolders();
funds = ticker.mutualFundHolders();
insiders = ticker.insiderTransactions();
news = ticker.news();

income = ticker.incomeStmt();
quarterlyIncome = ticker.incomeStmt(Quarterly=true);
balance = ticker.balanceSheet();
cash = ticker.cashFlow();

expirations = ticker.options();
chain = ticker.optionChain(expirations(1));

tickers = yfinance.Tickers(["AAPL", "MSFT"]);
batchPrices = tickers.history(Period="1mo");
batchInfo = tickers.fastInfo();

results = yfinance.Search("apple");
symbols = results.Quotes.Symbol;
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

Yahoo Finance endpoints are unofficial and can return rate limits or authorization errors. The shared HTTP transport retries transient failures such as `429` rate limits, timeouts, generic network failures, and empty responses. It raises structured MATLAB errors including:

- `yfinance:RateLimited`
- `yfinance:Unauthorized`
- `yfinance:Timeout`
- `yfinance:NetworkError`
- `yfinance:EmptyResponse`

Some quoteSummary-backed methods may be unavailable when Yahoo rate-limits the endpoint. Fixture-backed unit tests cover response parsing independently from live Yahoo availability.

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
