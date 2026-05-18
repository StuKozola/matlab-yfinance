# Yahoo WebSocket and Protobuf Investigation

Investigation date: 2026-05-18

## Summary

The MATLAB toolbox currently exposes `yfinance.WebSocket` and `yfinance.AsyncWebSocket` with upstream-compatible subscribe, listen, unsubscribe, callback, and close workflows backed by repeated Yahoo quote snapshots. This is still the recommended supported behavior for the next release line.

True upstream live-stream parity would require a Yahoo WebSocket client plus a protobuf decoder for Yahoo's pricing payload. That is feasible, but it is a larger dependency and maintenance decision than the current pure MATLAB polling implementation.

## Upstream Behavior Reviewed

Sources reviewed:

- Upstream live implementation: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/live.py
- Upstream pricing schema: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/pricing.proto
- Upstream WebSocket API docs: https://ranaroussi.github.io/yfinance/reference/api/yfinance.WebSocket.html
- Upstream AsyncWebSocket API docs: https://ranaroussi.github.io/yfinance/reference/api/yfinance.AsyncWebSocket.html
- MATLAB TCP/IP client docs: https://www.mathworks.com/help/matlab/ref/tcpclient.html

Observed upstream design:

- Default stream URL is `wss://streamer.finance.yahoo.com/?version=2`.
- Subscribe and unsubscribe are JSON control messages with symbol lists.
- Incoming frames are JSON objects with a base64-encoded `message` payload.
- The `message` payload decodes to a protobuf `PricingData` message.
- Async upstream behavior periodically resends the subscription set as a heartbeat.
- The protobuf schema includes fields for symbol id, price, time, currency, exchange, quote type, market hours, change fields, volume, day high/low, option fields, crypto fields, and market cap.

## MATLAB Implementation Options

### Option 1: Keep Polling as Supported Baseline

Keep the current implementation as the default `WebSocket` and `AsyncWebSocket` behavior.

Benefits:

- Pure MATLAB and toolbox-packaging friendly.
- Uses the same shared Yahoo HTTP transport, retries, credentials, and structured errors.
- Easy to test with existing fixture-backed quote response tests.
- Stable enough for users who need callback-style live snapshots rather than tick-by-tick streaming.

Costs:

- Not true Yahoo push streaming.
- Latency and update frequency are limited by `PollInterval`.
- Does not decode Yahoo protobuf live payloads.

### Option 2: Experimental Java WebSocket Plus MATLAB Protobuf Decoder

Implement a new internal stream transport using Java or another bundled client and decode protobuf bytes in MATLAB.

Benefits:

- Preserves pure MATLAB user API while avoiding a Python runtime dependency.
- Can keep `WebSocket` and `AsyncWebSocket` methods aligned with upstream.
- Protobuf message shape is small enough to decode with a generated or handwritten minimal decoder.

Costs:

- Requires secure WebSocket support, reconnect behavior, heartbeat handling, base64 decoding, and protobuf wire decoding.
- Adds meaningful maintenance burden around Java compatibility and packaged dependencies.
- Yahoo can change the stream payload without notice.

### Option 3: Optional Python Bridge

Add an opt-in path that shells through Python `yfinance` for true streaming.

Benefits:

- Fastest route to exact upstream behavior.
- Offloads WebSocket and protobuf details to upstream yfinance.

Costs:

- Violates the current no-Python-runtime design goal for the default toolbox.
- Makes installation and CI behavior less deterministic.
- Introduces Python package and protobuf version conflicts outside MATLAB's control.

## Recommendation

Do not replace the current polling implementation in the next maintenance release.

The best next implementation step is an opt-in experimental class or mode, not a default behavior change:

1. Add `yfinance.ExperimentalWebSocket` or `yfinance.WebSocket(Transport="stream")`.
2. Keep `Transport="poll"` as the default.
3. Isolate all WebSocket/protobuf code under `+yfinance/+internal/+live`.
4. Start with a recorded protobuf fixture test before any live stream test.
5. Decode only the upstream `PricingData` fields into the existing live quote table shape.
6. Gate live stream tests behind the existing opt-in live test policy.

## Current Implementation Groundwork

The first streaming prerequisite is now implemented under `+yfinance/+internal/+live`:

- `decodePricingDataMessage` decodes base64 text or raw `uint8` bytes for Yahoo `PricingData` protobuf messages.
- `pricingDataToLiveQuotes` converts decoded messages into the MATLAB live quote table shape used by the current polling callback path.
- `streamControlMessage` builds Yahoo-compatible subscribe and unsubscribe JSON control frames.
- `decodeStreamFrame` and `streamFramesToLiveQuotes` decode Yahoo stream JSON frames into live quote tables.
- `StreamClient` defines an internal transport boundary with open, subscribe, unsubscribe, receive, and close methods.
- `WebSocketTransport` implements an internal RFC 6455 client for unencrypted `ws://` transports, including HTTP upgrade, masked client frames, text receive, ping/pong, and close handling.
- Fixture-backed tests cover base64 decoding, all core quote fields, double fields, unknown protobuf field skipping, malformed/truncated payload errors, and table conversion.
- Fake transport tests cover control messages, frame decoding, quote table conversion, subscription bookkeeping, raw WebSocket framing, and close behavior without network access.

This does not create a production Yahoo streaming path yet. The internal transport is limited to `ws://`; Yahoo's default stream uses `wss://`, and MATLAB R2024b's Java 8 runtime does not provide the standard Java TLS WebSocket client. The public `WebSocket` and `AsyncWebSocket` classes still use polling by default.

## Acceptance Criteria for True Streaming

- Subscribe and unsubscribe send Yahoo-compatible JSON control messages.
- Listen decodes base64 protobuf `PricingData` payloads without Python.
- Callback messages use stable MATLAB struct or table fields matching current live quote names where possible.
- Reconnect and heartbeat behavior are covered by unit tests with a fake stream transport.
- A malformed protobuf payload returns a structured `yfinance:` error or callback error record.
- Default polling behavior remains unchanged unless users explicitly choose streaming.

## Current Decision

Current release line: keep polling as supported baseline. Treat true WebSocket/protobuf streaming as experimental future work, with protobuf payload decoding, the internal stream transport boundary, and raw `ws://` framing now available as groundwork.
