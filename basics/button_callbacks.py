from gpiozero import Button
from time import sleep

# Define the GPIO pin number where the BUTTON is connected
# Using BOARD numbering (physical pin number on the board)
BTN_PIN = "BOARD11"

def pressed():
    print("button was pressed")

def released():
    print("button was released")

# The button is initialized with pull_up=False,
# expecting the button to pull the pin HIGH when pressed.
btn = Button(BTN_PIN, pull_up=False)

# Assign the functions to the button's event handlers
btn.when_pressed = pressed
btn.when_released = released

# To keep the script running and listening for button events
while True:
    sleep(0.1)