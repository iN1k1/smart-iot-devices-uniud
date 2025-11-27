# Import required libraries
from gpiozero import LED  # For controlling GPIO pins
from time import sleep    # For adding delays

# Define the GPIO pin number where the LED is connected
# Using BOARD numbering (physical pin number on the board)
LED_PIN = "BOARD11"

# Initialize an LED object on the specified pin
led = LED(LED_PIN)

# Main loop to blink the LED
while True:
    led.on()       # Turn the LED on
    sleep(1)       # Wait for 1 second
    led.off()      # Turn the LED off
    sleep(1)       # Wait for 1 second before repeating