#!/bin/bash

count=$(dunstctl count waiting)
status=$(dunstctl is-paused)

if [ "$status" = "true" ]; then
    echo "🔕 $count"
else
    echo "🔔 $count"
fi
