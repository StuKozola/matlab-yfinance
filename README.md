# matlab-yfinance

MATLAB implementation of the core ideas and public API shape of Python [`yfinance`](https://github.com/ranaroussi/yfinance).

This repository is being initialized as a MATLAB toolbox project. The implementation target is a pure MATLAB package under the `yfinance` namespace, with no runtime dependency on Python.

## Status

Early project scaffold. See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for the full implementation plan.

## Planned Usage

```matlab
ticker = yfinance.Ticker("AAPL");
prices = ticker.history(Period="1mo", Interval="1d");

data = yfinance.download(["AAPL", "MSFT"], Period="6mo");
```

## Development

Run checks with MATLAB buildtool from the repository root:

```matlab
buildtool test
buildtool check
```

The project follows MATLAB package conventions, `matlab.unittest` for tests, and build tasks for repeatable validation.

## Disclaimer

This project is not affiliated with Yahoo, Yahoo Finance, or the upstream Python `yfinance` maintainers. Yahoo Finance data is subject to Yahoo's terms and availability. This toolbox is intended for research and educational use.

