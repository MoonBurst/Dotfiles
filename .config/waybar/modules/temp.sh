#!/bin/bash

# ==========================================================
#               CONFIGURATION
# ==========================================================
CITY="Houston"
API_KEY="340c6f5eecff61ffd342313e4f2a7547"

# Define Pango Markup Color Tags (Waybar Compatible)
# NOTE: Removed the backslash (\) from before the hash (#)
GREEN_TAG="<span foreground='#00FF00'>"  # Bright Green
YELLOW_TAG="<span foreground='yellow'>"    # Yellow (using a name is fine too)
RED_TAG="<span foreground='#FF0000'>"      # Bright Red (FIXED)
CLOSE_TAG="</span>"                      # Closing tag for the color
# ==========================================================


# --- Fetch and Validate Weather Data ---
weather=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=$CITY&appid=$API_KEY")

if ! echo "$weather" | jq -e '.main.temp' >/dev/null; then
    echo "{\"text\": \"N/A\", \"tooltip\": \"Weather data unavailable\"}"
    exit 1
fi

# --- Process Temperature ---
temp=$(echo "$weather" | jq -r '.main.temp')

# Calculate temp in Fahrenheit (to two decimal places)
temp_fahrenheit=$(awk -v temp=$temp 'BEGIN{ printf("%.2f\n", ((temp - 273.15) * 9/5) + 32) }')

# Round the temperature to the nearest whole number for comparison
rounded_temp=$(awk -v temp=$temp_fahrenheit 'BEGIN{ printf "%.0f\n", temp }')

# --- Determine Color Tag ---
COLOR_TAG=""
if (( rounded_temp <= 76 )); then
    COLOR_TAG=$GREEN_TAG
elif (( rounded_temp >= 77 && rounded_temp <= 85 )); then
    COLOR_TAG=$YELLOW_TAG
elif (( rounded_temp >= 86 )); then
    COLOR_TAG=$RED_TAG
fi

# Get the weather description
weather_description=$(echo "$weather" | jq -r '.weather[0].description')

# --- Output Result in Pango Markup (JSON) ---
# Ensure no escaping is used inside the color attribute values.
echo "${COLOR_TAG}${temp_fahrenheit}°F${CLOSE_TAG}"
# ${weather_description}"
