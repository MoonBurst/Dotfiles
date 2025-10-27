#!/usr/bin/env bash

# Usage: grab <string1> <string2> <string3>

directory=~/Documents/Equestria
string1="$1"
string2="$2"
string3="$3"

# Define color codes
red="\033[31m"
orange="\033[91m"
yellow="\033[93m"
green="\033[32m"
cyan="\033[36m"
purple="\033[35m"
blue="\033[34m"
pink="\033[95m"
black="\033[30m"
brown="\033[33m"
white="\033[97m"
gray="\033[90m"
reset="\033[0m"

# Search for files with 3 strings and display matching lines with color coding and bbcode formatting
find "$directory" -type f \
  -exec awk \
    -v s1="$string1" \
    -v s2="$string2" \
    -v s3="$string3" \
    -v r="$reset" \
    -v red="$red" \
    -v orange="$orange" \
    -v yellow="$yellow" \
    -v green="$green" \
    -v cyan="$cyan" \
    -v purple="$purple" \
    -v blue="$blue" \
    -v pink="$pink" \
    -v black="$black" \
    -v brown="$brown" \
    -v white="$white" \
    -v gray="$gray" ' \
    BEGIN { FS = ": " } 
    { 
      if ($0 ~ s1 && $0 ~ s2 && $0 ~ s3) {
        gsub(/\[(e?)icon\]([a-zA-Z0-9_\-\s]+)\[\/e?icon\]/, "", $0)
        gsub(/\[url=([^]]*)\]/, "\x1b[4m\x1b]8;;\\1\x1b\\", $0)
        gsub(/\[\/url\]/, "\x1b]8;;\x1b\\\x1b[24m", $0)
        
        gsub(/\[color=red\]/, red)
        gsub(/\[\/color\]/, r)
        gsub(/\[color=orange\]/, orange)
        gsub(/\[color=yellow\]/, yellow)
        gsub(/\[color=green\]/, green)
        gsub(/\[color=cyan\]/, cyan)
        gsub(/\[color=purple\]/, purple)
        gsub(/\[color=blue\]/, blue)
        gsub(/\[color=pink\]/, pink)
        gsub(/\[color=black\]/, black)
        gsub(/\[color=brown\]/, brown)
        gsub(/\[color=white\]/, white)
        gsub(/\[color=gray\]/, gray)
        
        # Apply bbcode formatting
        gsub(/\[b\]/, "\033[1m")
        gsub(/\[\/b\]/, r)
        gsub(/\[sup\]/, "\033[1m")
        gsub(/\[\/sup\]/, r)
        gsub(/\[sub\]/, "\033[4m")
        gsub(/\[\/sub\]/, r)
        gsub(/\[u\]/, "\033[4m")
        gsub(/\[\/u\]/, r)
        gsub(/\[i\]/, "\033[3m")
        gsub(/\[\/i\]/, r)
        
        while (match($0, /\[color=([a-z]+)\](.*?)\[\/color\]/, arr)) {
          color_code = arr[1]
          content = arr[2]
          gsub(arr[0], r color_code content r, $0)
        }
        
        gsub(/\[\/color\]/, r "& " r)
        
        line = $0
        gsub(/" /, "\"\n", line)
        gsub(/\\n/, "\n\n\n", line) # Add three line breaks after each message
        
        file = FILENAME
        sub(/^.*\//, "", file) # Remove the directory from the file path
        
        if (prev_file != file) {
          printf "%s:\n", file
          prev_file = file
        }
        
        printf "%s\n", line
      }
    }
    ' {} \;
