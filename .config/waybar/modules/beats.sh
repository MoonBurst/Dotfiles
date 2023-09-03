#!/bin/bash
set -e
read h m s<<<$(TZ=GMT-1 date "+%-H %-M %-S")
beats=$(perl -e "printf('%.2f',($s+($m*60)+($h*3600))/86.4)")
echo "@$beats"
