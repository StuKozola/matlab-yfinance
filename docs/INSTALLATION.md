# Installation

## Toolbox Release

Install the packaged toolbox from the latest GitHub release.

```matlab
matlab.addons.install("matlab-yfinance-0.1.3.mltbx")
```

After installation, verify MATLAB can resolve the package:

```matlab
yfinance.version()
prices = yfinance.download("AAPL", Period="5d");
```

## Source Checkout

For development, work from a local repository checkout and add the repository root to the MATLAB path:

```matlab
addpath(pwd)
```

Run the fixture-backed validation and package build from the repository root:

```matlab
buildtool package
```

The build writes generated API docs to `docs/API_REFERENCE.md` and the packaged toolbox to `dist/`.

## Updating

To update from a source checkout, pull the latest `main`, restart MATLAB or clear loaded classes if needed, and rerun validation:

```matlab
buildtool test
buildtool check
```

For installed toolbox releases, uninstall the older toolbox from MATLAB Add-On Manager before installing a newer `.mltbx` if MATLAB reports a duplicate add-on.

## Optional Live Smoke Tests

The default build does not require network access. Live Yahoo smoke tests are opt-in:

```matlab
setenv("YFINANCE_LIVE_TESTS", "1")
buildtool liveTest
```

The live target exercises downloads, search, screeners, fast quote metadata, options, fund data, calendars, and experimental streaming. Known Yahoo availability failures are treated as skipped assumptions; parser or behavior regressions still fail the target when Yahoo returns usable data.
