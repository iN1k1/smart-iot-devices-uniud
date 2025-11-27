from gpiozero import Button
from time import sleep

# Define the GPIO pin number where the BUTTON is connected
# Using BOARD numbering (physical pin number on the board)
BTN_PIN = "BOARD11"

# pull_up=False:
# This setting expects the button to be wired between the GPIO pin and 3.3V.
# When the button is released, the pin is LOW (0V)
# because it's usually connected to Ground (GND)
# through a pull-down resistor (either internal or external).
# When the button is pressed, it connects the pin to 3.3V,
# pulling the state HIGH.
btn = Button(BTN_PIN, pull_up=False)

# loop
while True:

    # check if button is pressed
    if btn.is_pressed:
        print("button is pressed")

    # wait for 0.1 seconds
    sleep(0.1)