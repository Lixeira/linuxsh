#!/bin/bash

set -eo pipefail

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
    "firefox" "baobab" "evince" "epiphany" "gnome-abrt"
    "gnome-calendar" "gnome-clocks" "gnome-color-manager"
    "gnome-connections" "gnome-console" "gnome-contacts"
    "gnome-logs" "gnome-maps" "gnome-music" "gnome-tour"
    "gnome-remote-desktop" "gnome-shell-extensions"
    "gnome-user-docs" "gnome-user-share" "yelp""gnome.snapshot"
    "malcontent" "orca" "simple-scan" 
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

# Function to install system packages
install_packages() {
    print_header "INSTALLING SYSTEM PACKAGES"
    local failed=0
    for PACKAGE in "${INSTALL_PACKAGES[@]}"; do
        echo -e "${YELLOW}Installing $PACKAGE...${NC}"
        if sudo dnf install -y "$PACKAGE"; then
            echo -e "${GREEN}Successfully installed $PACKAGE${NC}"
        else
            echo -e "${RED}Failed to install $PACKAGE${NC}"
            ((failed++))
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}Failed to install $failed package(s).${NC}"
        return 1
    else
        echo -e "${GREEN}All packages installed successfully.${NC}"
    fi
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
    
    local failed=0
    for PACKAGE in "${REMOVE_PACKAGES[@]}"; do
        echo -e "${YELLOW}Removing $PACKAGE...${NC}"
        if sudo dnf remove -y "$PACKAGE"; then
            echo -e "${GREEN}Successfully removed $PACKAGE${NC}"
        else
            echo -e "${RED}Failed to remove $PACKAGE${NC}"
            ((failed++))
        fi
    done
    
    # Clean up unused dependencies
    echo -e "${YELLOW}Cleaning up unused dependencies...${NC}"
    sudo dnf autoremove -y
    
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}Failed to remove $failed package(s).${NC}"
        return 1
    else
        echo -e "${GREEN}Package removal complete.${NC}"
    fi
}

# Function to install Flatpak applications
install_flatpaks() {
    print_header "INSTALLING FLATPAK PACKAGES"
    local failed=0
    for PACKAGE in "${FLATPAK_PACKAGES[@]}"; do
        echo -e "${YELLOW}Installing Flatpak package: $PACKAGE...${NC}"
        if flatpak install -y flathub "$PACKAGE"; then
            echo -e "${GREEN}Successfully installed $PACKAGE${NC}"
        else
            echo -e "${RED}Failed to install Flatpak package $PACKAGE${NC}"
            ((failed++))
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}Failed to install $failed Flatpak package(s).${NC}"
        return 1
    else
        echo -e "${GREEN}Flatpak installation complete.${NC}"
    fi
}

# Function to install NVIDIA Graphics drivers
install_nvidia() {
    print_header "INSTALLING NVIDIA GRAPHICS DRIVERS"
    
    echo -e "${YELLOW}This will install NVIDIA drivers and related packages.${NC}"
    echo -e "${YELLOW}Are you sure you have an NVIDIA GPU? (y/n)${NC}"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}NVIDIA driver installation cancelled.${NC}"
        return
    fi
    
    # Install required packages
    echo -e "${YELLOW}Installing required dependencies...${NC}"
    sudo dnf install -y kmodtool akmods mokutil openssl || {
        echo -e "${RED}Failed to install required dependencies.${NC}"
        return 1
    }
    
    # Generate and import MOK (Machine Owner Key) for Secure Boot
    echo -e "${YELLOW}Generating and importing MOK for Secure Boot...${NC}"
    sudo kmodgenca -a || {
        echo -e "${RED}Failed to generate MOK.${NC}"
        return 1
    }
    
    echo -e "${YELLOW}Please enter your password to proceed with MOK enrollment...${NC}"
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der || {
        echo -e "${RED}Failed to import MOK.${NC}"
        return 1
    }
    
    # Install NVIDIA drivers and CUDA
    echo -e "${YELLOW}Installing NVIDIA drivers...${NC}"
    sudo dnf install -y akmod-nvidia || {
        echo -e "${RED}Failed to install NVIDIA drivers.${NC}"
        return 1
    }
    
    echo -e "${YELLOW}Installing CUDA support...${NC}"
    sudo dnf install -y xorg-x11-drv-nvidia-cuda || {
        echo -e "${RED}Failed to install CUDA support.${NC}"
        return 1
    }
    
    # Confirm NVIDIA driver version
    echo -e "${YELLOW}Verifying installation...${NC}"
    if modinfo -F version nvidia; then
        echo -e "${GREEN}NVIDIA graphics installation complete.${NC}"
        echo -e "${YELLOW}You may need to reboot for changes to take effect.${NC}"
    else
        echo -e "${RED}Failed to verify NVIDIA driver installation.${NC}"
        return 1
    fi
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
        return 1
    fi
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