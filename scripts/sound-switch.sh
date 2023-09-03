#!/bin/bash
# strict mode
# set -euo pipefail
# IFS=$'\n\t'

arg="${1:-}"
#get list with "pactl list short sinks"
case "$arg" in
	--speakers)
    SINK=$(pactl list short sinks|grep hdmi-stereo-extra|cut -f2)
    pactl set-default-sink "$SINK"
    pactl list-sink-inputs | grep index | while read line; do
    pactl move-sink-input `echo $line | cut -f2 -d' '` "$SINK"
    done
	#	dunstify -a "audio-swap" "Switched to Speakers" -u low -r 3930
		;;
  --headphones)
    SINK=$(pactl list short sinks|grep DigiHug|cut -f2)
    pactl set-default-sink "$SINK"
    pactl list-sink-inputs | grep index | while read line; do
    pactl move-sink-input `echo $line | cut -f2 -d' '` "$SINK"
    done
   #dunstify -a "audio-swap" "Switched to Headphones" -u low -r 3930
    ;;
  --middle)
    notify-send "Middle click!"
    ;;
	*)
		echo "שׂ"
		;;
esac

