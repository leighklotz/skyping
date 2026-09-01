#!/bin/bash

# --- Configuration & Dependency Check ---

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <FLIGHT_NUMBER> <EMAIL>"
    echo "Example: $0 TA209 myemail@example.com"
    exit 1
fi

if [ -z "$ADSB_URL" ]; then
    echo "ADSB_URL not set"
    exit 1
fi

# Normalize input: trim whitespace and convert to uppercase for matching
TARGET_FLIGHT=$(echo "$1" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
RECIPIENT="$2"

# Verify required tools are installed
for cmd in curl jq mail; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required tool '$cmd' is not installed."
        if [ "$cmd" = "jq" ]; then echo "   Install with: sudo apt install jq"; fi
        if [ "$cmd" = "mail" ]; then echo "   Install with: sudo apt install mailutils"; fi
        exit 1
    fi
done

echo "Starting monitor for flight: $TARGET_FLIGHT"
echo "Polling every 60 seconds... (Press Ctrl+C to stop)"
echo "---------------------------------------------"

# --- Main Monitoring Loop ---

while true; do
    # Fetch JSON data silently
    RAW_JSON=$(curl -s "$ADSB_URL")

    if [ $? -ne 0 ] || [ -z "$RAW_JSON" ]; then
        echo "$(date +'%H:%M:%S') - Error: Failed to fetch data. Retrying in 60s..."
        sleep 60
        continue
    fi

    # We use string interpolation \(...) inside jq to avoid the quote-escaping errors encountered previously.
    MATCHED_DATA=$(echo "$RAW_JSON" | jq -r --arg TARGET "$TARGET_FLIGHT" '
        [ .aircraft[]? | select(.flight != null and (.flight | sub(" +$"; "") == $TARGET)) ] | 
        if length > 0 then
            .[0] | "Flight Alert: \(.flight // "Unknown") detected!\n\n---\n" +
                   "Hex Code:     \"\(.hex // "N/A")\"\n" +
                   "Type:         \"\(.type // "Unknown")\"\n" +
                   "Altitude:     \(if .alt_baro != null then "\(.alt_baro) ft" else "N/A" end)\n" +
                   "Groundspeed:  \(if .gs != null then "\(.gs) kts" else "N/A" end)\n" +
                   "Track:        \(if .track != null then "\(.track)°" else "N/A" end)\n" +
                   "Latitude:     \"\(.lat // "N/A")\"\n" +
                   "Longitude:    \"\(.lon // "N/A")\"\n" +
                   "Squawk:       \(if .squawk != null then "\(.squawk)" else "N/A" end)\n\n" +
                   "Detected at:  \(now | strflocaltime("%Y-%m-%d %H:%M:%S"))"
        else 
            empty 
        end
    ')

    if [ -n "$MATCHED_DATA" ]; then
        echo "$(date) - MATCH FOUND! Sending email..."
        
        # Attempt to send the formatted data via mail
        echo -e "$MATCHED_DATA" | mail -s "FLIGHT ALERT: $TARGET_FLIGHT spotted!" "$RECIPIENT"

        if [ $? -eq 0 ]; then
            echo "Success! Email sent to $RECIPIENT."
        else
            echo "Error: Failed to send email. Check your MTA/mail configuration (e.g., postfix)."
        fi
        exit 0
    else
        # Flight not in current snapshot; wait and try again
        echo "$(date +'%H:%M:%S') - $TARGET_FLIGHT not detected yet..."
    fi

    sleep 60
done
