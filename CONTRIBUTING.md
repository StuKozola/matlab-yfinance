# Contributing

## Development Standards

- Keep runtime code pure MATLAB unless an optional development-only tool is explicitly documented.
- Put public APIs in `+yfinance`.
- Put implementation details in `+yfinance/+internal`.
- Prefer tables and timetables for tabular financial data.
- Add `matlab.unittest` coverage for new behavior.
- Keep endpoint-specific Yahoo Finance details isolated behind internal adapters.

## Validation

Before opening a pull request, run:

```matlab
buildtool test
buildtool check
```

Live Yahoo Finance tests should be optional and skipped by default when network access is unavailable.

