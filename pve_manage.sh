#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
HOST="https://pve.local:8006"
NODE="pve"

# --- DO NOT EDIT ANYTHING BELOW THIS LINE ---

# Get the directory where the script is located, robustly handling symlinks and sourcing.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- Token Loading ---
# Check if a .secret.sh file exists in the script's directory.
if [ -f "$SCRIPT_DIR/.secret.sh" ]; then
	# If it exists, source it to load the TOKEN variable.
	source "$SCRIPT_DIR/.secret.sh"
else
	# If .secret.sh doesn't exist, check if TOKEN is already defined in the environment.
	if [[ -z $TOKEN ]]; then
		echo "Error: No token for the Proxmox VE API has been provided."
		echo "Please define the TOKEN variable in a '.secret.sh' file in the script's directory"
		echo "or set it as an environment variable before running the script."
		exit 1
	fi
fi

# --- Helper Functions for LXC Containers ---

# Get the hostname (name) of an LXC container.
# Arguments: TOKEN, HOST, NODE, VMID
lxc_name() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	curl --silent --insecure --header "Authorization: $token" "$host/api2/json/nodes/$node/lxc/$vmid/config" | jq -r '.data.hostname'
}

# Get the current status of an LXC container.
# Arguments: TOKEN, HOST, NODE, VMID
lxc_status() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	curl --silent --insecure --header "Authorization: $token" "$host/api2/json/nodes/$node/lxc/$vmid/status/current" | jq -r '.data.status'
}

# Start an LXC container if it's not already running.
# Arguments: TOKEN, HOST, NODE, VMID
lxc_start() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	local name=$(lxc_name "$token" "$host" "$node" "$vmid")

	if [ "$(lxc_status "$token" "$host" "$node" "$vmid")" != "running" ]; then
		echo "Starting LXC: $vmid ($name)"
		curl --silent --insecure --header "Authorization: $token" --request POST "$host/api2/json/nodes/$node/lxc/$vmid/status/start" >/dev/null 2>&1
		echo "Start command has been sent to LXC: $vmid ($name)"
	else
		echo "Error: LXC $vmid ($name) is already running!"
		exit 1
	fi
}

# Reboot an LXC container if it's running.
# Arguments: TOKEN, HOST, NODE, VMID
lxc_reboot() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	local name=$(lxc_name "$token" "$host" "$node" "$vmid")

	if [ "$(lxc_status "$token" "$host" "$node" "$vmid")" == "running" ]; then
		echo "Rebooting LXC: $vmid ($name)"
		curl --silent --insecure --header "Authorization: $token" --request POST "$host/api2/json/nodes/$node/lxc/$vmid/status/reboot" >/dev/null 2>&1
		echo "Reboot command has been sent to LXC: $vmid ($name)"
	else
		echo "Error: LXC $vmid ($name) is not running!"
		exit 1
	fi
}

# Shutdown an LXC container if it's running.
# Arguments: TOKEN, HOST, NODE, VMID
lxc_shutdown() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	local name=$(lxc_name "$token" "$host" "$node" "$vmid")

	if [ "$(lxc_status "$token" "$host" "$node" "$vmid")" == "running" ]; then
		echo "Shutting down LXC: $vmid ($name)"
		curl --silent --insecure --header "Authorization: $token" --request POST "$host/api2/json/nodes/$node/lxc/$vmid/status/shutdown" >/dev/null 2>&1
		echo "Shutdown command has been sent to LXC: $vmid ($name)"
	else
		echo "Error: LXC $vmid ($name) is not running!"
		exit 1
	fi
}

# Stop an LXC container if it's running.
# Arguments: TOKEN, HOST, NODE, VMID
lxc_stop() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	local name=$(lxc_name "$token" "$host" "$node" "$vmid")

	if [ "$(lxc_status "$token" "$host" "$node" "$vmid")" == "running" ]; then
		echo "Stopping LXC: $vmid ($name)"
		curl --silent --insecure --header "Authorization: $token" --request POST "$host/api2/json/nodes/$node/lxc/$vmid/status/stop" >/dev/null 2>&1
		echo "Stop command has been sent to LXC: $vmid ($name)"
	else
		echo "Error: LXC $vmid ($name) is not running!"
		exit 1
	fi
}

# --- Helper Functions for QEMU Virtual Machines ---

# Get the name of a QEMU virtual machine.
# Arguments: TOKEN, HOST, NODE, VMID
vm_name() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	curl --silent --insecure --header "Authorization: $token" "$host/api2/json/nodes/$node/qemu/$vmid/config" | jq -r '.data.name'
}

# Get the current status of a QEMU virtual machine.
# Arguments: TOKEN, HOST, NODE, VMID
vm_status() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	curl --silent --insecure --header "Authorization: $token" "$host/api2/json/nodes/$node/qemu/$vmid/status/current" | jq -r '.data.status'
}

# Start a QEMU virtual machine if it's not already running.
# Arguments: TOKEN, HOST, NODE, VMID
vm_start() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	local name=$(vm_name "$token" "$host" "$node" "$vmid")

	if [ "$(vm_status "$token" "$host" "$node" "$vmid")" != "running" ]; then
		echo "Starting VM: $vmid ($name)"
		curl --silent --insecure --header "Authorization: $token" --request POST "$host/api2/json/nodes/$node/qemu/$vmid/status/start" >/dev/null 2>&1
		echo "Start command has been sent to VM: $vmid ($name)"
	else
		echo "Error: VM $vmid ($name) is already running!"
		exit 1
	fi
}

# Reboot a QEMU virtual machine if it's running.
# Arguments: TOKEN, HOST, NODE, VMID
vm_reboot() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	local name=$(vm_name "$token" "$host" "$node" "$vmid")

	if [ "$(vm_status "$token" "$host" "$node" "$vmid")" == "running" ]; then
		echo "Rebooting VM: $vmid ($name)"
		curl --silent --insecure --header "Authorization: $token" --request POST "$host/api2/json/nodes/$node/qemu/$vmid/status/reboot" >/dev/null 2>&1
		echo "Reboot command has been sent to VM: $vmid ($name)"
	else
		echo "Error: VM $vmid ($name) is not running!"
		exit 1
	fi
}

# Shutdown a QEMU virtual machine if it's running.
# Arguments: TOKEN, HOST, NODE, VMID
vm_shutdown() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	local name=$(vm_name "$token" "$host" "$node" "$vmid")

	if [ "$(vm_status "$token" "$host" "$node" "$vmid")" == "running" ]; then
		echo "Shutting down VM: $vmid ($name)"
		curl --silent --insecure --header "Authorization: $token" --request POST "$host/api2/json/nodes/$node/qemu/$vmid/status/shutdown" >/dev/null 2>&1
		echo "Shutdown command has been sent to VM: $vmid ($name)"
	else
		echo "Error: VM $vmid ($name) is not running!"
		exit 1
	fi
}

# Stop a QEMU virtual machine if it's running.
# Arguments: TOKEN, HOST, NODE, VMID
vm_stop() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	local name=$(vm_name "$token" "$host" "$node" "$vmid")

	if [ "$(vm_status "$token" "$host" "$node" "$vmid")" == "running" ]; then
		echo "Stopping VM: $vmid ($name)"
		curl --silent --insecure --header "Authorization: $token" --request POST "$host/api2/json/nodes/$node/qemu/$vmid/status/stop" >/dev/null 2>&1
		echo "Stop command has been sent to VM: $vmid ($name)"
	else
		echo "Error: VM $vmid ($name) is not running!"
		exit 1
	fi
}

# Reset a QEMU virtual machine if it's running.
# Arguments: TOKEN, HOST, NODE, VMID
vm_reset() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	local name=$(vm_name "$token" "$host" "$node" "$vmid")

	if [ "$(vm_status "$token" "$host" "$node" "$vmid")" == "running" ]; then
		echo "Resetting VM: $vmid ($name)"
		curl --silent --insecure --header "Authorization: $token" --request POST "$host/api2/json/nodes/$node/qemu/$vmid/status/reset" >/dev/null 2>&1
		echo "Reset command has been sent to VM: $vmid ($name)"
	else
		echo "Error: VM $vmid ($name) is not running!"
		exit 1
	fi
}

# --- Entity Type Determination ---

# Determine if the given VMID is an LXC container or a QEMU VM.
# Returns "lxc", "qemu", or an empty string if not found.
# Arguments: TOKEN, HOST, NODE, VMID
get_entity_type() {
	local token=$1
	local host=$2
	local node=$3
	local vmid=$4

	# Check if the VMID exists as an LXC container.
	# We query the list of LXCs and check if our vmid is in the 'data' array.
	local is_lxc=$(curl --silent --insecure --header "Authorization: $token" "$host/api2/json/nodes/$node/lxc" | jq -r --arg vmid_str "$vmid" '.data[] | select(.vmid == ($vmid_str | tonumber)) | .vmid')

	# Check if the VMID exists as a QEMU VM.
	# We query the list of QEMU VMs and check if our vmid is in the 'data' array.
	local is_qemu=$(curl --silent --insecure --header "Authorization: $token" "$host/api2/json/nodes/$node/qemu" | jq -r --arg vmid_str "$vmid" '.data[] | select(.vmid == ($vmid_str | tonumber)) | .vmid')

	if [[ -n "$is_lxc" ]]; then
		echo "lxc"
	elif [[ -n "$is_qemu" ]]; then
		echo "qemu"
	else
		# If neither is found, print an error and exit.
		echo "Error: VMID $vmid not found as an LXC container or QEMU virtual machine on node $node." >&2
		exit 1
	fi
}

# --- Main Script Logic ---

# Check if the correct number of arguments has been provided.
if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Usage: $0 <VMID> <start|stop|reboot|shutdown|reset>"
	echo "VMID: The ID of the LXC container or the QEMU virtual machine."
	echo "Action: The action to perform (start, stop, reboot, shutdown, reset)."
	exit 1
fi

VMID="$1"
ACTION="$2"

# Determine the type of the entity (LXC or QEMU VM).
ENTITY_TYPE=$(get_entity_type "$TOKEN" "$HOST" "$NODE" "$VMID")

# Use a case statement to handle different actions.
case "$ACTION" in
	start)
		if [[ "$ENTITY_TYPE" == "lxc" ]]; then
			lxc_start "$TOKEN" "$HOST" "$NODE" "$VMID"
		elif [[ "$ENTITY_TYPE" == "qemu" ]]; then
			vm_start "$TOKEN" "$HOST" "$NODE" "$VMID"
		fi
		;;
	stop)
		if [[ "$ENTITY_TYPE" == "lxc" ]]; then
			lxc_stop "$TOKEN" "$HOST" "$NODE" "$VMID"
		elif [[ "$ENTITY_TYPE" == "qemu" ]]; then
			vm_stop "$TOKEN" "$HOST" "$NODE" "$VMID"
		fi
		;;
	reboot)
		if [[ "$ENTITY_TYPE" == "lxc" ]]; then
			lxc_reboot "$TOKEN" "$HOST" "$NODE" "$VMID"
		elif [[ "$ENTITY_TYPE" == "qemu" ]]; then
			vm_reboot "$TOKEN" "$HOST" "$NODE" "$VMID"
		fi
		;;
	shutdown)
		if [[ "$ENTITY_TYPE" == "lxc" ]]; then
			lxc_shutdown "$TOKEN" "$HOST" "$NODE" "$VMID"
		elif [[ "$ENTITY_TYPE" == "qemu" ]]; then
			vm_shutdown "$TOKEN" "$HOST" "$NODE" "$VMID"
		fi
		;;
	reset)
		if [[ "$ENTITY_TYPE" == "qemu" ]]; then
			vm_reset "$TOKEN" "$HOST" "$NODE" "$VMID"
		else
			echo "Error: The 'reset' action is only applicable to QEMU virtual machines, not LXC containers." >&2
			exit 1
		fi
		;;
	*) #Default case for invalid actions.
		echo "Error: Invalid action '$ACTION'." >&2
		echo "Valid actions are: start, stop, reboot, shutdown, reset." >&2
		exit 1
		;;
esac
