# Getting Started

Install the toolbox from a release package or add the repository root to the MATLAB path, then use the `yfinance` package namespace:

```matlab
addpath(pwd)

ticker = yfinance.Ticker("AAPL");
prices = ticker.history(Period="1mo");
info = ticker.fastInfo();
```

See [INSTALLATION.md](INSTALLATION.md) for toolbox release and source checkout details.

Run validation from the repository root:

```matlab
buildtool test
buildtool check
```

Package the toolbox into `dist/`:

```matlab
buildtool package
```
