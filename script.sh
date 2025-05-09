#!/bin/bash

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: This script should not be run as root.${NC}"
    exit 1
fi

# Check if sudo is available
if ! command -v sudo &> /dev/null; then
    echo -e "${RED}Error: sudo is not installed. Please install sudo first.${NC}"
    exit 1
fi

# Check if Flatpak is installed
if ! command -v flatpak &> /dev/null; then
    echo -e "${YELLOW}Flatpak is not installed. Would you like to install it? (y/n)${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        sudo dnf install -y flatpak || {
            echo -e "${RED}Failed to install Flatpak.${NC}"
            exit 1
        }
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    else
        echo -e "${RED}Flatpak is required for some operations. Exiting.${NC}"
        exit 1
    fi
fi

# Package lists
INSTALL_PACKAGES=("git" "curl")
REMOVE_PACKAGES=(
    "firefox" "baobab" "evince" "epiphany" "gnome-abrt" "ibus-anthy"
    "gnome-calendar" "gnome-clocks" "gnome-color-manager" "ibus-hangul"
    "gnome-connections" "gnome-console" "gnome-contacts"
    "ibus-typing-booster" "ibus-libpinyin" "gnome-weather"
    "gnome-logs" "gnome-maps" "gnome-music" "gnome-tour"
    "gnome-remote-desktop" "gnome-shell-extensions" "totem"
    "gnome-user-docs" "gnome-user-share" "yelp" "snapshot"
    "malcontent" "orca" "simple-scan" "rhythmbox" "gnome-boxes"
    "kontact" "Akregator" "mediawriter"
    "libreoffice-core" "libreoffice-writer" "libreoffice-draw" "libreoffice-calc" "libreoffice-impress" "libreoffice-math"
    "kmahjongg" "kmines" "kpat" "kolourpaint"
    "skanpage" "khelpcenter" "plasma-welcome"
    "kdebugsettings" "kde-connect" "kmail" "krfb"
    "krdc" "neochat" "dragon" "elisa-player" "kaddressbook"
    "kamoso" "qrca" "korganizer" "kde-partitionmanager"
    "kjournald" "im-chooser" "kmouth" "kcharselect"
    "filelight" "kfind" "kgpg" "plasma-drkonqi"
    "setroubleshoot" "podman"
)
FLATPAK_PACKAGES=("com.mattjakeman.ExtensionManager")

# Function to print header
print_header() {
    echo -e "${BLUE}\n=== $1 ===${NC}"
}

# Function to print failed operations summary
print_failed_summary() {
    local operation="$1"
    local -n failed_items=$2
    
    if [[ ${#failed_items[@]} -gt 0 ]]; then
        echo -e "${YELLOW}\nFailed to $operation the following packages:${NC}"
        printf '%s\n' "${failed_items[@]}"
    else
        echo -e "${GREEN}\nAll packages were successfully ${operation}ed.${NC}"
    fi
}

# Function to install system packages
install_packages() {
    print_header "INSTALLING SYSTEM PACKAGES"
    local failed_installs=()
    
    for PACKAGE in "${INSTALL_PACKAGES[@]}"; do
        echo -e "${YELLOW}Installing $PACKAGE...${NC}"
        if sudo dnf install -y "$PACKAGE"; then
            echo -e "${GREEN}Successfully installed $PACKAGE${NC}"
        else
            echo -e "${RED}Failed to install $PACKAGE${NC}"
            failed_installs+=("$PACKAGE")
        fi
    done
    
    print_failed_summary "install" failed_installs
    return 0
}

# Function to remove system packages
remove_packages() {
    print_header "REMOVING SYSTEM PACKAGES"
    echo -e "${YELLOW}The following packages will be removed:${NC}"
    printf '%s\n' "${REMOVE_PACKAGES[@]}"
    
    echo -e "\n${YELLOW}Are you sure you want to continue? (y/n)${NC}"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Package removal cancelled.${NC}"
        return
    fi
    
    local failed_removals=()
    for PACKAGE in "${REMOVE_PACKAGES[@]}"; do
        echo -e "${YELLOW}Removing $PACKAGE...${NC}"
        if sudo dnf remove -y "$PACKAGE"; then
            echo -e "${GREEN}Successfully removed $PACKAGE${NC}"
        else
            echo -e "${RED}Failed to remove $PACKAGE${NC}"
            failed_removals+=("$PACKAGE")
        fi
    done
    
    # Clean up unused dependencies
    echo -e "${YELLOW}Cleaning up unused dependencies...${NC}"
    sudo dnf autoremove -y
    
    print_failed_summary "remove" failed_removals
    return 0
}

# Function to install Flatpak applications
install_flatpaks() {
    print_header "INSTALLING FLATPAK PACKAGES"
    local failed_flatpaks=()
    
    for PACKAGE in "${FLATPAK_PACKAGES[@]}"; do
        echo -e "${YELLOW}Installing Flatpak package: $PACKAGE...${NC}"
        if flatpak install -y flathub "$PACKAGE"; then
            echo -e "${GREEN}Successfully installed $PACKAGE${NC}"
        else
            echo -e "${RED}Failed to install Flatpak package $PACKAGE${NC}"
            failed_flatpaks+=("$PACKAGE")
        fi
    done
    
    print_failed_summary "install" failed_flatpaks
    return 0
}

# Function to install NVIDIA Graphics drivers
install_nvidia() {
    print_header "INSTALLING NVIDIA GRAPHICS DRIVERS"
    local failed_steps=()
    
    echo -e "${YELLOW}This will install NVIDIA drivers and related packages.${NC}"
    echo -e "${YELLOW}Are you sure you have an NVIDIA GPU? (y/n)${NC}"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}NVIDIA driver installation cancelled.${NC}"
        return
    fi
    
    # Install required packages
    echo -e "${YELLOW}Installing required dependencies...${NC}"
    if sudo dnf install -y kmodtool akmods mokutil openssl; then
        echo -e "${GREEN}Dependencies installed successfully${NC}"
    else
        echo -e "${RED}Failed to install required dependencies${NC}"
        failed_steps+=("Dependencies installation")
    fi
    
    # Generate and import MOK (Machine Owner Key) for Secure Boot
    echo -e "${YELLOW}Generating and importing MOK for Secure Boot...${NC}"
    if sudo kmodgenca -a; then
        echo -e "${GREEN}MOK generated successfully${NC}"
    else
        echo -e "${RED}Failed to generate MOK${NC}"
        failed_steps+=("MOK generation")
    fi
    
    echo -e "${YELLOW}Please enter your password to proceed with MOK enrollment...${NC}"
    if sudo mokutil --import /etc/pki/akmods/certs/public_key.der; then
        echo -e "${GREEN}MOK imported successfully${NC}"
    else
        echo -e "${RED}Failed to import MOK${NC}"
        failed_steps+=("MOK import")
    fi
    
    # Install NVIDIA drivers and CUDA
    echo -e "${YELLOW}Installing NVIDIA drivers...${NC}"
    if sudo dnf install -y akmod-nvidia; then
        echo -e "${GREEN}NVIDIA drivers installed successfully${NC}"
    else
        echo -e "${RED}Failed to install NVIDIA drivers${NC}"
        failed_steps+=("NVIDIA drivers installation")
    fi
    
    echo -e "${YELLOW}Installing CUDA support...${NC}"
    if sudo dnf install -y xorg-x11-drv-nvidia-cuda; then
        echo -e "${GREEN}CUDA support installed successfully${NC}"
    else
        echo -e "${RED}Failed to install CUDA support${NC}"
        failed_steps+=("CUDA support installation")
    fi
    
    # Confirm NVIDIA driver version
    echo -e "${YELLOW}Verifying installation...${NC}"
    if modinfo -F version nvidia; then
        echo -e "${GREEN}NVIDIA driver verification successful${NC}"
    else
        echo -e "${RED}Failed to verify NVIDIA driver installation${NC}"
        failed_steps+=("Driver verification")
    fi
    
    if [[ ${#failed_steps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}\nThe following steps failed during NVIDIA installation:${NC}"
        printf '%s\n' "${failed_steps[@]}"
        echo -e "${YELLOW}You may need to address these issues manually.${NC}"
    else
        echo -e "${GREEN}NVIDIA graphics installation complete.${NC}"
    fi
    
    echo -e "${YELLOW}You may need to reboot for changes to take effect.${NC}"
    return 0
}

# Function to install Brave browser
install_brave() {
    print_header "INSTALLING BRAVE BROWSER"
    
    echo -e "${YELLOW}This will install Brave browser from their official repository.${NC}"
    echo -e "${YELLOW}Do you want to continue? (y/n)${NC}"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Brave installation cancelled.${NC}"
        return
    fi
    
    echo -e "${YELLOW}Installing Brave browser...${NC}"
    if curl -fsS https://dl.brave.com/install.sh | sh; then
        echo -e "${GREEN}Brave browser installation complete.${NC}"
    else
        echo -e "${RED}Failed to install Brave browser.${NC}"
    fi
    return 0
}

# Main menu function
main_menu() {
    while true; do
        echo -e "${BLUE}\n=== MAIN MENU ===${NC}"
        echo "1. Install system packages"
        echo "2. Remove system packages"
        echo "3. Install Flatpak packages"
        echo "4. Install NVIDIA graphics drivers"
        echo "5. Install Brave browser"
        echo "6. Exit"
        
        read -rp "Enter your choice (1-6): " CHOICE
        
        case $CHOICE in
            1) install_packages ;;
            2) remove_packages ;;
            3) install_flatpaks ;;
            4) install_nvidia ;;
            5) install_brave ;;
            6)
                echo -e "${GREEN}Exiting script. Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
        
        read -rp "Press Enter to continue..."
    done
}

# Check if we're being sourced or run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Run the main menu
    main_menu
fi
