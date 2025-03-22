#!/bin/zsh

volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | cut -d' ' -f2 | sed 's/0\.//')

if (( $volume == 0 )); then 
    echo "MUTE"
elif (( $volume <= 15 )); then
    echo " $volume"
elif (( $volume <= 25 )); then
    echo " $volume"
else
    echo " $volume"
fi
