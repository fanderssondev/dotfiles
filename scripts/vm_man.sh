#!/bin/bash

# This script starts/stops VirtualBox VMs in headless mode from WSL2.

# Define colors
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# Define the list of all VMs
ALL_VMS=("rocky8a" "rocky8b" "rocky8c" "ubuntu24a")

# Check if at least two arguments are provided
if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: $0 {up|down} {all | vm_name1 [vm_name2 ...]}${RESET}"
    exit 1
fi

ACTION="$1"
shift  # Remove first argument to process VM names

# Handle 'all' argument
if [ "$1" == "all" ]; then
    VMS_TO_PROCESS=("${ALL_VMS[@]}")
else
    VMS_TO_PROCESS=("$@")
fi

# Convert Windows path using wslpath (handles spaces properly)
VBOXMANAGE=$(wslpath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe")

# Verify that VBoxManage.exe exists
if [ ! -f "$VBOXMANAGE" ]; then
    echo -e "${RED}Error: VBoxManage.exe not found at $VBOXMANAGE. Ensure VirtualBox is installed on Windows.${RESET}"
    exit 1
fi

# Check if running inside WSL2
if ! grep -qi microsoft /proc/version; then
    echo -e "${RED}This script is designed to run in WSL2.${RESET}"
    exit 1
fi

# Function to start VirtualBox if needed
start_virtualbox() {
    if ! pgrep -f "VirtualBox.exe" > /dev/null; then
        echo "Starting VirtualBox..."
        powershell.exe -Command "Start-Process 'C:\\Program Files\\Oracle\\VirtualBox\\VirtualBox.exe' -WindowStyle Minimized"
        sleep 3  # Give it time to open
    fi
}

# Function to shut down VirtualBox if no VMs are running
shutdown_virtualbox() {
    echo "Checking if all VMs are shut down..."
    while "$VBOXMANAGE" list runningvms | grep -q '"'; do
        echo "Waiting for VMs to shut down..."
        sleep 2  # Wait for VMs to power off completely
    done

    echo "No VMs are running. Shutting down VirtualBox GUI..."
    
    # Check if VirtualBox.exe is running before trying to stop it
    if powershell.exe -Command "Get-Process -Name 'VirtualBox' -ErrorAction SilentlyContinue" | grep -q "VirtualBox"; then
        powershell.exe -Command "Stop-Process -Name 'VirtualBox' -Force"
        echo -e "${GREEN}VirtualBox has been closed.${RESET}"
    else
        echo -e "${RED}VirtualBox was not running.${RESET}"
    fi
}

# Handle 'up' (start VMs)
if [ "$ACTION" == "up" ]; then
    start_virtualbox  # Ensure VirtualBox is running

    for VM in "${VMS_TO_PROCESS[@]}"; do
        if [[ " ${ALL_VMS[*]} " =~ " ${VM} " ]]; then
            echo "Starting VM: $VM"
            if "$VBOXMANAGE" startvm "$VM" --type headless >/dev/null 2>&1; then
                echo -e "${GREEN}VM \"$VM\" has been successfully started.${RESET}"
            else
                echo -e "${RED}Failed to start VM \"$VM\". Check VirtualBox logs for details.${RESET}"
            fi
            sleep 2  # Small delay between starting VMs
        else
            echo -e "${RED}Warning: VM '$VM' is not in the predefined list.${RESET}"
        fi
    done

# Handle 'down' (shut down VMs)
elif [ "$ACTION" == "down" ]; then
    for VM in "${VMS_TO_PROCESS[@]}"; do
        if [[ " ${ALL_VMS[*]} " =~ " ${VM} " ]]; then
            echo "Shutting down VM: $VM"

            # Send ACPI shutdown signal
            if "$VBOXMANAGE" controlvm "$VM" acpipowerbutton >/dev/null 2>&1; then
                echo -e "${GREEN}VM \"$VM\" has been sent an ACPI shutdown signal.${RESET}"
            else
                echo -e "${RED}Failed to send ACPI shutdown signal to VM \"$VM\".${RESET}"
            fi

            # Wait for VM to power off (max 30 seconds)
            COUNT=0
            while "$VBOXMANAGE" list runningvms | grep -q "\"$VM\""; do
                if [ $COUNT -ge 15 ]; then
                    echo -e "${RED}VM \"$VM\" did not shut down in time. Forcing power off...${RESET}"
                    "$VBOXMANAGE" controlvm "$VM" poweroff
                    break
                fi
                echo "Waiting for VM \"$VM\" to shut down... ($COUNT/15)"
                sleep 2
                COUNT=$((COUNT+1))
            done

            echo -e "${GREEN}VM \"$VM\" is now off.${RESET}"
        else
            echo -e "${RED}Warning: VM '$VM' is not in the predefined list.${RESET}"
        fi
    done

    shutdown_virtualbox  # Wait until all VMs are fully off before closing VirtualBox

else
    echo -e "${RED}Invalid action: $ACTION. Use 'up' or 'down'.${RESET}"
    exit 1
fi

