#!/bin/bash
read -r -d '' SED <<SED_SCRIPT
#s/^\-\- \[(.*?)\] /--
s^: /me^^g
s^\[b\]^\x1b[1m^g
s^\[/b\]^\x1b[22m^g
s^\[i\]^\x1b[3m^g
s^\[/i\]^\x1b[23m^g
s^\[u\]^\x1b[4m^g
s^\[/u\]^\x1b[24m^g
s^\[s\]^\x1b[9m^g
s^\[/s\]^\x1b[29m^g
s^\[color=black\]^\x1b[30m^g
s^\[color=red\]^\x1b[91m^g
s^\[color=green\]^\x1b[92m^g
s^\[color=lime\]^\x1b[92m^g
s^\[color=yellow\]^\x1b[93m^g
s^\[color=blue\]^\x1b[94m^g
s^\[color=magenta\]^\x1b[95m^g
s^\[color=pink\]^\x1b[38;5;218m^g
s^\[color=purple\]^\x1b[38;5;98m^g
s^\[color=cyan\]^\x1b[96m^g
s^\[color=white\]^\x1b[97m^g
s^\[color=orange\]^\x1b[38;5;208m^g
s^\[color=gray\]^\x1b[90m^g
s^\[/color\]^\x1b[39m^g
s^\[sub\]^^g
s^\[/sub\]^^g
s^\[sup\]^^g
s^\[/sup\]^^g
s!\[(e?)icon\]([a-zA-Z0-9_\x20\-]+)\[/e?icon\]![\1icon: \2]!g
s!\[url=([^]]*)\]!\x1b[4m\x1b]8;;\1\x1b\x5c!g
s!\[/url\]!\x1b]8;;\x1b\x5c\x1b[24m!g
SED_SCRIPT

while true; do
DATE=$(date); 
RESULT=$(curl -s https://chat.f-list.net/adl/$(TZ="GMT" date +"%F")/equestria.txt | tail -25 | ftfy | sed -E "$SED");
clear; echo "$DATE"; echo "$RESULT"; 
sleep 5; done;
