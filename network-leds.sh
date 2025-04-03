#!/bin/bash

# Configuration variables
TOTAL_CYCLE_TIME=15        # Total cycle time in seconds
BLINK_TIME=0.5             # Duration for each off or on blink phase (in seconds)

# New variable to control red LED behavior:
#   Set to 0: old behavior (red LED on constantly when wlan0 is up)
#   Set to 1: new behavior (blink a number of times equal to connected devices)
RED_LED_MODE=1

# LED device directories for red and green LEDs
RED_LED_DIR="/sys/class/leds/PWR"
GREEN_LED_DIR="/sys/class/leds/ACT"

# Verify that the LED directories exist
if [ ! -d "$RED_LED_DIR" ]; then
  echo "Error: LED device 'PWR' not found." >&2
  exit 1
fi

if [ ! -d "$GREEN_LED_DIR" ]; then
  echo "Error: LED device 'ACT' not found." >&2
  exit 1
fi

# Paths to trigger files
RED_TRIGGER="$RED_LED_DIR/trigger"
GREEN_TRIGGER="$GREEN_LED_DIR/trigger"

# Disable the default trigger if not already set to 'none'
if ! grep -q "\[none\]" "$RED_TRIGGER"; then
  echo none > "$RED_TRIGGER"
fi

if ! grep -q "\[none\]" "$GREEN_TRIGGER"; then
  echo none > "$GREEN_TRIGGER"
fi

# Define brightness file paths
RED_BRIGHTNESS="$RED_LED_DIR/brightness"
GREEN_BRIGHTNESS="$GREEN_LED_DIR/brightness"

# Main monitoring loop
while true; do
  # Record the cycle start time
  start_time=$(date +%s)

  ## RED LED LOGIC ##
  if ip link show wlan0 | grep -q "state UP"; then
    if [ "$RED_LED_MODE" -eq 0 ]; then
      # Mode 0: Simply keep the red LED on when wlan0 is up.
      echo 1 > "$RED_BRIGHTNESS"
    else
      # Mode 1: Check for connected devices.
      num_clients=$(iw dev wlan0 station dump | grep -c "Station")
      if [ "$num_clients" -eq 0 ]; then
        # No connected devices: red LED remains on continuously.
        echo 1 > "$RED_BRIGHTNESS"
      else
        # There are connected devices.
        # Each blink cycle takes 2 * BLINK_TIME seconds (off then on).
        blink_duration=$(echo "$num_clients * 2 * $BLINK_TIME" | bc | awk '{printf "%.0f", $0}')
        # Calculate on_duration so that the cycle totals TOTAL_CYCLE_TIME seconds.
        on_duration=$(( TOTAL_CYCLE_TIME - blink_duration ))
        if [ "$on_duration" -lt 0 ]; then
          on_duration=0
        fi

        # LED on for the non-blink period.
        echo 1 > "$RED_BRIGHTNESS"
        sleep "$on_duration"

        # Blink the red LED num_clients times.
        for i in $(seq 1 "$num_clients"); do
          echo 0 > "$RED_BRIGHTNESS"
          sleep "$BLINK_TIME"
          echo 1 > "$RED_BRIGHTNESS"
          sleep "$BLINK_TIME"
        done
      fi
    fi
  else
    # If wlan0 is down, turn the red LED off.
    echo 0 > "$RED_BRIGHTNESS"
  fi

  ## GREEN LED LOGIC ##
  # Determine connectivity for internet.
  wlan1_connected=0
  eth0_connected=0

  if iw dev wlan1 link | grep -q "Connected"; then
    wlan1_connected=1
  fi

  if ip link show eth0 | grep -q "state UP"; then
    eth0_connected=1
  fi

  # Determine blink count based on connectivity:
  #   1 blink for wlan1 only, 2 blinks for eth0 only, 3 blinks for both.
  blink_count=0
  if [ "$wlan1_connected" -eq 1 ] && [ "$eth0_connected" -eq 0 ]; then
    blink_count=1
  elif [ "$eth0_connected" -eq 1 ] && [ "$wlan1_connected" -eq 0 ]; then
    blink_count=2
  elif [ "$wlan1_connected" -eq 1 ] && [ "$eth0_connected" -eq 1 ]; then
    blink_count=3
  fi

  if [ "$blink_count" -eq 0 ]; then
    echo 0 > "$GREEN_BRIGHTNESS"
  else
    # For the green LED, start with the LED on.
    echo 1 > "$GREEN_BRIGHTNESS"
    # Blink the LED blink_count times.
    for i in $(seq 1 "$blink_count"); do
      echo 0 > "$GREEN_BRIGHTNESS"
      sleep "$BLINK_TIME"
      echo 1 > "$GREEN_BRIGHTNESS"
      sleep "$BLINK_TIME"
    done
  fi

  # Calculate elapsed time and sleep for the remainder of the TOTAL_CYCLE_TIME.
  end_time=$(date +%s)
  elapsed=$(( end_time - start_time ))
  remaining=$(( TOTAL_CYCLE_TIME - elapsed ))
  if [ "$remaining" -gt 0 ]; then
    sleep "$remaining"
  fi
done
