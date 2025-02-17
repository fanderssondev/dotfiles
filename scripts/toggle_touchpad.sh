#!/bin/bash

# This script toggles the touchpad on/off


if gsettings get org.gnome.desktop.peripherals.touchpad send-events | grep -q "disabled"; then
    gsettings set org.gnome.desktop.peripherals.touchpad send-events enabled
    notify-send -i input-touchpad "Touchpad" "Enabled"
else
    gsettings set org.gnome.desktop.peripherals.touchpad send-events disabled
    notify-send -i emblem-nowrite "Touchpad" "Disabled"
fi
