#!/usr/bin/env bash

# Define the static PID to target
PID="941950"

# Optional: Check if the provided static PID is a valid process
if ! kill -0 "$PID" >/dev/null 2>&1; then
    exec notify-send "Error" "Process ID $PID does not exist or you don't have permission to access it."
    exit 1
fi

# Determine the current state of the process
STATE=$(awk '/State:/ {print $2}' "/proc/$PID/status" 2>/dev/null)

if [ "$STATE" == "T" ]; then
    # Process is currently stopped, so unfreeze (continue) it
    kill -SIGCONT "$PID"
    exec notify-send "Window Unfrozen" "Process ID $PID (static) has been resumed."
else
    # Process is running or in another state, so freeze (stop) it
    kill -SIGSTOP "$PID"
    exec notify-send "Window Frozen" "Process ID $PID (static) has been paused."
fi
