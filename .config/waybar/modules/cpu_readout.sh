#!/bin/sh

# --- Configuration ---
CRIT="#f53c3c"
WARN="#ffa500"
NORM="#00FF00"
PAD="#262626"

T_WARN=65
T_CRIT=70
U_WARN=50
U_CRIT=80
# ---------------------

# --- CPU Temp and Usage Readout ---
# Extracting Tctl from the k10temp block
temp_c=$(sensors | awk '/Tctl/{print int($2 + 0.5); exit}' 2>/dev/null)
cpu_u=$(top -bn1 | awk '/%Cpu/ {print int(100 - $8)}' 2>/dev/null)


# --- AWK Final Formatting ---
FINAL_OUTPUT=$(awk -v TC="$temp_c" -v UC="$cpu_u" \
    -v CRIT="$CRIT" -v WARN="$WARN" -v NORM="$NORM" -v PAD="$PAD" \
    -v T_WARN="$T_WARN" -v T_CRIT="$T_CRIT" -v U_WARN="$U_WARN" -v U_CRIT="$U_CRIT" 'BEGIN {
    
    # --- 1. Determine Component Colors ---
    # T_COLOR will be one of the hex codes (e.g., "#f53c3c")
    T_COLOR = (TC >= T_CRIT) ? CRIT : (TC >= T_WARN) ? WARN : NORM
    T_VAL = (TC == "") ? "N/A" : TC "°C"

    U_COLOR = (UC >= U_CRIT) ? CRIT : (UC >= U_WARN) ? WARN : NORM
    
    # Format and Safely pad the usage value
    U_VAL_FORMATTED = sprintf("%03d", UC)
    sub(/^0*/, "<span color=\"" PAD "\">" "&</span>", U_VAL_FORMATTED)
    U_VAL = U_VAL_FORMATTED "%"


    # --- 2. Determine Overall (Label) Color ---
    # Convert colors back to a numerical severity level for comparison (higher = more critical)
    # 3 = CRIT, 2 = WARN, 1 = NORM
    T_SEVERITY = (T_COLOR == CRIT) ? 3 : (T_COLOR == WARN) ? 2 : 1
    U_SEVERITY = (U_COLOR == CRIT) ? 3 : (U_COLOR == WARN) ? 2 : 1
    
    # Get the highest severity level
    MAX_SEVERITY = (T_SEVERITY > U_SEVERITY) ? T_SEVERITY : U_SEVERITY
    
    # Convert highest severity back to hex color for the "CPU:" label
    LABEL_COLOR = (MAX_SEVERITY == 3) ? CRIT : (MAX_SEVERITY == 2) ? WARN : NORM


    # --- 3. Print Final Output ---
    # Prepend the output with the colored "CPU:" label
    print "<span color=\"" LABEL_COLOR "\">CPU:</span>" \
          " <span color=\"" T_COLOR "\">" T_VAL "</span>" \
          " <span color=\"" U_COLOR "\">" U_VAL "</span>"
}')

echo "$FINAL_OUTPUT"
