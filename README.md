# skyping

`skyping.sh` is a lightweight bash utility designed to monitor live ADS-B aircraft telemetry via a JSON feed. When a specific flight number enters the monitored airspace, the script extracts detailed flight information (altitude, speed, position, etc.) and sends an immediate email alert to a designated recipient.

## Features

*   **Real-time Monitoring**: Polls the ADS-B data source every 60 seconds.
*   **Detailed Telemetry**: Extracts Hex code, Aircraft Type, Altitude, Groundspeed, Track, Coordinates (Lat/Lon), and Squawk code.
*   **Automated Alerting**: Sends a formatted email summary via `mail` upon detection.
*   **Smart Matching**: Handles case-insensitive flight number matching and whitespace trimming.

## Prerequisites

The following tools must be installed on your system:

*   `curl`: To fetch the live aircraft data.
*   `jq`: For parsing JSON telemetry.
*   `mailutils` (or any MTA providing the `mail` command): To send email notifications.

On Debian/Ubuntu-based systems, you can install them using:
```bash
sudo apt update && sudo apt install curl jq mailutils
```

## Installation

1.  Clone or download this script to your local machine.
2.  Ensure the script is executable:
    ```bash
    chmod +x skyping.sh
    ```

## Usage

Run the script by passing the target **Flight Number** and the **Recipient Email Address** as arguments.

```bash
./skyping.sh <FLIGHT_NUMBER> <EMAIL>
```

### Example

To monitor flight `TA209` and send alerts to `your-email@example.com`:

```bash
./skyping.sh TA209 your-email@example.com
```

## How It Works

1.  **Polling**: The script fetches the current aircraft snapshot from a remote ADS-B JSON endpoint.
2.  **Parsing**: Using `jq`, it filters the list of all active aircraft to find an exact match for your target flight number.
3.  **Alerting**: 
    *   If a match is found, it compiles a human-readable summary and sends it via email.
    *   Once the alert is successfully sent, the script terminates automatically.
4.  **Error Handling**: If data cannot be fetched or if required tools are missing, the script will notify you in the terminal and retry after 60 seconds.

## Data Source

The tool pulls live telemetry from:
`http://adsb.example.com/tar1090/data/aircraft.json`
