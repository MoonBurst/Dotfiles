#!/usr/bin/env bash

# Variables for Navi and Fiio devices

NAVI_LINE=$(wpctl status | awk '/Output/{gsub(/[^:]+:|\*/, ""); print;}/Navi 31 HDMI\/DP Audio Digital Stereo \(HDMI\)/{print $0}' | tr -d '.')
NAVI_NUM=$(echo "$(echo \"$NAVI_LINE\" | awk '{gsub(/[.]+:\s+/, "/"); print $2}')" | tr -d '\n')
echo -n $(printf '%s\n' "$NAVI_NUM")

IFOO_LINE=$(wpctl status | awk '/Output/{gsub(/[^:]+:|\*/, ""); print;}/Fiio E10 Analog Stereo/{print $0}' | tr -d '.')   
IFOO_NUM=$(echo "$FIOO_LINE" | awk '{gsub(/[@.]+:\s+/, "/"); print $2}')
echo -n $(printf '%s\n' "$IFOO_NUM")

# Function to switch devices based on the given argument ("speakers" or "headphones") and set the default device accordingly
switch_devices() {
  argument=$1
  case $argument in
    speakers)
      wpctl set-default "$NAVI_NUM"
      ;;
    headphones)
      wpctl set-default "$IFOO_NUM"
      ;;
    status)
      get_default() {
        status=$(wpctl status)
        default=$(echo "$status" | awk '/Default: [0-9]+/{print $NF}' | tr -d '.')
        echo "Current default device is $default:"
      }
      get_default
      ;;
    *)
      echo "Usage: switch_devices.sh [speakers|headphones|status]" >&2
      exit 1
      ;;
  esac
}

# Call the switch_devices function with the desired argument ("speakers", "headphones", or "status")
switch_devices speakers   # Set NaviNum as the default device for speakers
wpctl set-default "$NAVI_NUM"
switch_devices headphones  # Set Ifoo_num as the default device for headphones
wpctl set-default "$IFOO_NUM"
