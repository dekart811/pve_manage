# Proxmox VE Management Script

This Bash script provides a command-line interface to manage your [Proxmox VE](https://proxmox.com/en/products/proxmox-virtual-environment/overview) containers (LXC) and virtual machines (QEMU).  
It allows you to `start`, `stop`, `reboot`, `shutdown`, and `reset` your VMs/LXC containers by simply providing their `VMID` and the desired action.

## Features
* **Unified Control:** Manage both LXC containers and QEMU VMs with a single script.
* **Action-Oriented:** Perform common actions like `start`, `stop`, `reboot`, `shutdown` and `reset`.
* **Intelligent Type Detection:** Automatically determines if a given VMID is an LXC or a QEMU VM.
* **Token-Based Authentication:** Securely uses your Proxmox API token.
* **Error Handling:** Provides informative error messages for invalid inputs, non-existent entities, or incorrect actions.

## Prerequisites
Before running this script, ensure you have the following installed on your system:

* **Bash:** The script is written in Bash.
* `curl`**:** Used for making API requests to your Proxmox VE host.
* `jq`**:** A lightweight and flexible command-line JSON processor, used for parsing API responses.

You can typically install `curl` and `jq` using your distribution's package manager:
### Debian/Ubuntu
```bash
sudo apt update
sudo apt install curl jq
```
### Fedora/RHEL
```bash
sudo dnf install curl jq
```
### Arch Linux
```bash
sudo pacman -S curl jq
```

## Setup
1. **Download the Script:**  
   Save the provided script content into a file, for example, `pve_manage.sh`.
2. **Make it Executable:**  
   Give the script execution permissions:
      ```bash
      chmod +x pve_manage.sh
      ```
3. **Proxmox API Token:**  
   The script requires a Proxmox VE API token for authentication. You have two ways to provide this:  
   * **Recommended: `.secret.sh` file:**  
   Create a file named `.secret.sh` in the same directory as `pve_manage.sh`. Inside this file, define your `TOKEN` variable:
     ```bash
     # .secret.sh
     TOKEN="PVEAPIToken=your_username@your_realm!your_token_id=your_secret_uuid"
     ```
     **Remember to replace `your_username@your_realm!your_token_id=your_secret_uuid` with your actual Proxmox API token.** More info can be found [here](https://pve.proxmox.com/pve-docs/chapter-pveum.html#pveum_tokens).
   * **Environment Variable:**  
     Alternatively, you can export the `TOKEN` environment variable before running the script:  
     ```bash
     export TOKEN="PVEAPIToken=your_username@your_realm!your_token_id=your_secret_uuid"
     ./pve_manage.sh 100 start
     ```
     This method is less secure for persistent use as the token might be visible in your shell history or environment variables.

## Usage
Run the script by providing the **VMID** of your container/VM and the **action** you want to perform.
```bash
./pve_manage.sh <VMID> <action>
```
### Examples
* **Start VMID 100:**
  ```bash
  ./pve_manage.sh 100 start
  ```
* **Stop VMID 100:**
  ```bash
  ./pve_manage.sh 100 stop
  ```
* **Shutdown VMID 100:**
  ```bash
  ./pve_manage.sh 100 shutdown
  ```
* **Reboot VMID 100:**
  ```bash
  ./pve_manage.sh 100 reboot
  ```
* **Reset VMID 100:**
  ```bash
  ./pve_manage.sh 100 reset
  ```

## Available Actions
* `start`**:** Starts the specified LXC container or QEMU virtual machine.
* `stop`: Performs an **ungraceful** stop of the specified LXC container or QEMU virtual machine.
* `shutdown`**:** Performs a **graceful** shutdown of the specified LXC container or QEMU virtual machine.
* `reboot`**:** Reboots the specified LXC container or QEMU virtual machine.
* `reset`**: (QEMU only)** Resets the specified QEMU virtual machine. This is equivalent to a hard reset.

### Important Note: `reset` Action
The `reset` action is **only applicable to QEMU virtual machines**. If you attempt to use `reset` on an LXC container, the script will detect this and exit with an error message, preventing an invalid operation.
