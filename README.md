# Raspberry Pi Network LED Monitor

This project consists of a Bash script (`network-leds.sh`) and a corresponding systemd service (`network-leds.service`) that monitor network connectivity and provide visual feedback using onboard LEDs. The **red LED** indicates the status of the Raspberry Pi's Access Point (AP), while the **green LED** provides information about the device's Internet connectivity.

## LED Logic & Usefulness

### Red LED (AP Status & Client Count)
- **Logic:**
  - **WLAN0 Interface Check:**  
    - When the `wlan0` interface (acting as the AP) is **up**, the red LED is normally turned on.
  - **Client Connection Counting (Mode 1):**  
    - If `RED_LED_MODE` is set to `1`, the script counts the number of connected devices.
    - **No Connected Clients:** The red LED remains on continuously.
    - **One or More Connected Clients:** The LED remains on for a calculated period and then blinks once for each connected device. Each blink consists of a brief off/on cycle.
- **Why It's Useful:**  
  This method provides a simple visual indicator not only to show that the AP is operational but also to convey how many devices are connected—allowing you to quickly gauge network usage without logging into a management console.

### Green LED (Internet Connectivity Status)
- **Logic:**
  - **Connectivity Check:**  
    - The script checks for Internet connectivity via `wlan1` and `eth0` interfaces.
  - **Blink Patterns:**  
    - **wlan1 Connected Only:** The green LED blinks **once**.
    - **eth0 Connected Only:** The green LED blinks **twice**.
    - **Both Interfaces Connected:** The green LED blinks **three times**.
    - **No Connection:** The green LED remains off.
- **Why It's Useful:**  
  This approach lets you quickly determine which interface is providing Internet connectivity at a glance. Different blink counts make it easier to debug and understand the status of your network connections.

## Script Variables & Configuration

At the top of `network-leds.sh`, you will find a few configurable variables:

- **`TOTAL_CYCLE_TIME`**  
  Sets the total duration (in seconds) for each monitoring cycle.  
  _Default:_ `15`

- **`BLINK_TIME`**  
  Defines the duration (in seconds) for each phase of a blink (off or on).  
  _Default:_ `0.5`

- **`RED_LED_MODE`**  
  Controls the red LED behavior.  
  - `0`: Legacy behavior – the red LED stays on as long as `wlan0` is up.  
  - `1`: New behavior – the red LED blinks a number of times corresponding to the number of connected devices (if any), after an initial on period.  
  _Default:_ `1`

These variables allow you to easily adjust the timing of the cycles and the blink pattern to suit your needs.

## Installation & Setup

### 1. Create the Script

Clone or download the repository containing the files. On your Raspberry Pi, copy `network-leds.sh` to `/usr/local/bin/`:

```  
sudo cp network-leds.sh /usr/local/bin/  
```  

Make the script executable:

```  
sudo chmod +x /usr/local/bin/network-leds.sh  
```  

### 2. Create the systemd Service

Copy the `network-leds.service` file to the systemd directory:

```  
sudo cp network-leds.service /etc/systemd/system/  
```  

### 3. Enable & Start the Service

Reload the systemd daemon to recognize the new service:

```  
sudo systemctl daemon-reload  
```  

Enable the service to start automatically at boot:

```  
sudo systemctl enable network-leds.service  
```  

Start the service:

```  
sudo systemctl start network-leds.service  
```  

### 4. Verify the Service

Check the status of the service to ensure it’s running correctly:

```  
sudo systemctl status network-leds.service  
```  

If needed, review the logs for troubleshooting:

```  
journalctl -u network-leds.service  
```  
