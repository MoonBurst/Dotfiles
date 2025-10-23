#!/usr/bin/env bash

# Check if OBS Studio is currently streaming
# This is a simplified check. A more robust solution might involve OBS WebSocket or similar.
# We're looking for an OBS process that is actively managing a stream.
# This example assumes 'obs' command line tool is in your PATH.

# Try to find a process that indicates streaming
# This is a heuristic and might need adjustment based on your OBS setup and version.
# A common way to check for active streaming is to see if 'obs' is running
# and potentially if its log or status indicates streaming.
# For simplicity, we'll assume if 'obs' is running, we can attempt to stop it,
# otherwise, we'll try to start it.
# A more accurate check would involve OBS's internal state, often via a plugin
# like OBS WebSocket if you want to query its API.

# METHOD 1: Check for a running OBS process (less precise for streaming state)
if pgrep -x "obs" > /dev/null; then
    echo "OBS Studio process detected. Attempting to stop streaming..."
    obs --stopstreaming &
    echo "Stop streaming command sent."
else
    echo "OBS Studio process not detected or not streaming. Attempting to start streaming..."
    obs --startstreaming &
    echo "Start streaming command sent."
fi

exit 0
