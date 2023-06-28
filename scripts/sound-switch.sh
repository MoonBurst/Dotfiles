#!/bin/bash
# strict mode
# set -euo pipefail
# IFS=$'\n\t'

arg="${1:-}"
#get list with "pactl list short sinks"
case "$arg" in
	--speakers)
    SINK="alsa_output.pci-0000_26_00.1.hdmi-stereo-extra2"
    pactl set-default-sink "$SINK"
    pactl list-sink-inputs | grep index | while read line; do
    pactl move-sink-input `echo $line | cut -f2 -d' '` "$SINK"
    done
	#	dunstify -a "audio-swap" "Switched to Speakers" -u low -r 3930
		;;
  --headphones)
    SINK="alsa_output.usb-FiiO_DigiHug_USB_Audio-01.analog-stereo"
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
