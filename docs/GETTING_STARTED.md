# Getting Started

Add the repository root to the MATLAB path, then use the `yfinance` package namespace:

```matlab
addpath("D:\matlab-yfinance")

ticker = yfinance.Ticker("AAPL");
prices = ticker.history(Period="1mo");
info = ticker.fastInfo();
```

Run validation from the repository root:

```matlab
buildtool test
buildtool check
```

Package the toolbox into `dist/`:

```matlab
buildtool package
```
