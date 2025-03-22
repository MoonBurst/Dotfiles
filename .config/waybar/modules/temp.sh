#!/bin/bash

# Replace YOUR_API_KEY with your actual OpenWeatherMap API key
API_KEY="340c6f5eecff61ffd342313e4f2a7547"

# Replace YOUR_CITY_NAME with the name of your city
CITY="Houston"

weather=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=Houston&appid=340c6f5eecff61ffd342313e4f2a7547")

temp=$(echo "$weather" | jq -r '.main.temp')
temp_fahrenheit=$(awk -v temp=$temp 'BEGIN{ printf("%.2f\n", ((temp - 273.15) * 9/5) + 32) }')

weather_description=$(echo "$weather" | jq -r '.weather[0].description')

echo "$temp_fahrenheit°F"
