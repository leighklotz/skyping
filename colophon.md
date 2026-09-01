# Provenance Document: `skyping.sh`

## 1. Overview
* **Project Name:** Skyping Script Development
* **Target Toolchain:** Answer Agent / Hallux Framework
* **Primary Objective:** Develop a robust Bash script to monitor real-time ADS-B aircraft data via JSON and send an email alert containing flight details once a specific tail number/flight identifier is detected.

---

## 2. Data Sources & Context Ingestion
The development of the final script relied on three primary sources:

### A. Real-Time API Endpoint (External)
* **URL:** `http://adsb.example.com/tar1090/data/aircraft.json`
* **Format:** JSON array containing real-time aircraft telemetry (hex code, type, altitude, groundspeed, track, lat/long, squawk).

### B. Workspace Context (Local)
The agent was provided with local context via the `lx` and `bx` tools:
* **Command History:** Full `.bash_history` containing previous iterations of failed scripts and manual debugging attempts.

### C. User Input (Arguments)
The script was designed to accept two runtime arguments:
* `$1`: The Target Flight Number (e.g., `DAL656`).
* `$2`: The Recipient Email Address.

---

## 3. Iterative Development & Prompt History

The final script is the result of an iterative "evolutionary" prompting process where each failure was analyzed and corrected in subsequent turns.

### Phase I: Initial Concept (Baseline)
**Prompt:**
> *"write a bash script thst takrs a flight number such as DAL656 and an email addrress and then fetches this airplane.json oncr a minute until tue flight appears and then the scri0pt fornats the info received in email to the address ajd tuwn exits"*

**Result:** Created `skyping-1.sh`.
* **Status:** ❌ Failed.
* **Error Root Cause:** "Backslash Hell." The script attempted manual string concatenation within a `jq` filter using escaped double quotes (`\"`). Due to how Bash passes single-quoted strings to `jq`, the parser interpreted the escape sequences as literal characters, causing syntax errors in the `jq` engine.

### Phase II: Refinement & Attempted Fixes
**Prompt:**
> *"write a bash script that takes a flight number such as DAL656 and an email address and then fetches this airplane.json once a minute until the flight appears and then the script formats the info received in email to the address and exits."*

**Result:** Created versions `skyping-2.sh` through `skyping-2-2.sh`.
* **Status:** ❌ Partial Failure / Inconsistent.
* **Error Root Cause:** Continued struggles with nested quoting (the "quote hell" problem) while trying to build complex human-readable text blocks via concatenation (`+`).

### Phase III: Synthesis & Final Optimization
**Prompt (Synthesis Prompt):**
> *"Fix my skyping bash script. Write the final, good bash script you synthesize from these attempts. Use tools to read the files. Analyze, and then output the one script in a bash fence."*

**Result:** Created `skyping.sh` (The Final Version).
* **Status:** ✅ Success.
* **Key Engineering Improvement:** Abandoned manual string concatenation (`"text" + variable + "text"`) in favor of **JQ String Interpolation** (`\"\(variable)\"`). This approach eliminated the need for complex backslash escaping, making the `jq` filter syntactically simple and robust against shell-parsing errors.

---

## 4. Final Technical Specifications
*   **Language:** Bash (Shell)
*   **Dependencies:** `curl`, `jq`, `mailutils/postfix`.
*   **Core Logic:**
    1.  Normalization of input via `tr` (Uppercase conversion).
    2.  Infinite polling loop with a 60-second sleep interval.
    3.  Regex-based matching within `jq` to handle trailing whitespace in the ADS-B JSON data (`sub(" +$"; "")`).
    4.  Graceful error handling for network timeouts and missing keys via null-coalescing operators (`// "N/A"`).
