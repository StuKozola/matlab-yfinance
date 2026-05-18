% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function quotes = streamFramesToLiveQuotes(frames)
%STREAMFRAMESTOLIVEQUOTES Convert Yahoo stream frames to a live quote table.

frames = string(frames(:));
messages = repmat(emptyDecodedMessage(), numel(frames), 1);

for frameIndex = 1:numel(frames)
    messages(frameIndex) = yfinance.internal.live.decodeStreamFrame(frames(frameIndex));
end

quotes = yfinance.internal.live.pricingDataToLiveQuotes(messages);
end

function message = emptyDecodedMessage()
message = yfinance.internal.live.decodePricingDataMessage(uint8.empty(0, 1));
end
