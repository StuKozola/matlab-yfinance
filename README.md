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
- `Ticker.options()`
- `Ticker.optionChain(expiration)`
- `yfinance.Search(query)`

Still planned:

- Broader quote/profile module coverage
- Fundamentals and financial statements
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
