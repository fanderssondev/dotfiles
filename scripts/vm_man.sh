#!/bin/bash

# This is is made to be able to start/stop Virtualbox, and to be able to start/stop vm's in headless mode

# Define colors
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

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

# Function to start VirtualBox if needed
start_virtualbox() {
    if ! pgrep -x "VirtualBox" > /dev/null; then
        echo "Starting VirtualBox..."
        VirtualBox &  # Start VirtualBox in the background
        sleep 3  # Give it time to open

        # Minimize VirtualBox window
        xdotool search --name "Oracle VM VirtualBox Manager" windowminimize
    fi
}

# Function to shut down VirtualBox if no VMs are running
shutdown_virtualbox() {
    echo "Checking if all VMs are shut down..."
    while VBoxManage list runningvms | grep -q '"'; do
        echo "Waiting for VMs to shut down..."
        sleep 2  # Wait for VMs to power off completely
    done

    echo "No VMs are running. Shutting down VirtualBox..."
    pkill VirtualBox
}

# Handle 'up' (start VMs)
if [ "$ACTION" == "up" ]; then
    start_virtualbox  # Ensure VirtualBox is running

    for VM in "${VMS_TO_PROCESS[@]}"; do
            echo "Starting VM: $VM"
            if VBoxManage startvm "$VM" --type headless >/dev/null 2>&1; then
                echo -e "${GREEN}VM \"$VM\" has been successfully started.${RESET}"
            else
                echo -e "${RED}Failed to start VM \"$VM\". Check VirtualBox logs for details.${RESET}"
            fi
            sleep 2  # Small delay between starting VMs
    done

# Handle 'down' (shut down VMs)
elif [ "$ACTION" == "down" ]; then
    for VM in "${VMS_TO_PROCESS[@]}"; do
        if [[ " ${ALL_VMS[*]} " =~ " ${VM} " ]]; then
            echo "Shutting down VM: $VM"
            if VBoxManage controlvm "$VM" acpipowerbutton >/dev/null 2>&1; then
                echo -e "${GREEN}VM \"$VM\" has been successfully sent a shutdown signal.${RESET}"
            else
                echo -e "${RED}Failed to shut down VM \"$VM\". It may already be off.${RESET}"
            fi
            sleep 2  # Small delay between shutting down VMs
        else
            echo -e "${RED}Warning: VM '$VM' is not in the predefined list.${RESET}"
        fi
    done

    shutdown_virtualbox  # Wait until all VMs are fully off before closing VirtualBox

else
    echo -e "${RED}Invalid action: $ACTION. Use 'up' or 'down'.${RESET}"
    exit 1
fi


# ====================================================================
# ====================================================================

# The following code needs to be added to /etc/bash_completion.d/vm-man for auto completion


# #!/bin/bash
# 
# _vm_man_complete() {
#     local cur prev opts vms choices
#     cur="${COMP_WORDS[COMP_CWORD]}"
#     prev="${COMP_WORDS[COMP_CWORD-1]}"
# 
#     # Define available commands
#     opts="up down"
# 
#     # Extract VM names from ~/.ssh/config
#     vms=$(grep -iE "^Host " ~/.ssh/config | awk '{print $2}' | tr '\n' ' ')
# 
#     # First argument should be "up" or "down"
#     if [[ $COMP_CWORD -eq 1 ]]; then
#         COMPREPLY=($(compgen -W "$opts" -- "$cur"))
#         return
#     fi
# 
#     # If "up" or "down" is already provided, suggest VMs (including "all")
#     if [[ $COMP_CWORD -ge 2 ]]; then
#         # Get already typed VMs
#         local typed_vms="${COMP_WORDS[@]:1:$COMP_CWORD-1}"
# 
#         # Remove already typed VMs from the suggestion list
#         choices=$(echo "$vms all" | tr ' ' '\n' | grep -vFxf <(echo "$typed_vms" | tr ' ' '\n'))
# 
#         COMPREPLY=($(compgen -W "$choices" -- "$cur"))
#         return
#     fi
# }
# 
# # Register the completion function for vm-man
# complete -F _vm_man_complete vm-man
