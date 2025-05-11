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

# Package list for removal (adapted for Ubuntu)
REMOVE_PACKAGES=(
    # GNOME Applications
    "baobab" "epiphany-browser" "evince" "firefox" "gnome-abrt"
    "gnome-boxes" "gnome-calendar" "gnome-clocks" "gnome-color-manager"
    "gnome-connections" "gnome-console" "gnome-contacts" "gnome-logs"
    "gnome-maps" "gnome-music" "gnome-remote-desktop" "gnome-shell-extensions"
    "gnome-tour" "gnome-user-docs" "gnome-user-share" "gnome-weather"
    "malcontent" "orca" "rhythmbox" "simple-scan" "snapshot" "totem" "yelp"

    # Input Methods
    "ibus-anthy" "ibus-hangul" "ibus-libpinyin" "ibus-typing-booster"
    "im-chooser"

    # KDE Applications
    "akregator" "dragonplayer" "drkonqi" "elisa" "filelight" "kaddressbook"
    "kamoso" "kcharselect" "kde-connect" "kde-partitionmanager" "kdebugsettings"
    "kfind" "khelpcenter" "kgpg" "kmahjongg" "kmail" "kmines" "kmouth"
    "kjournald" "kolourpaint" "kontact" "korganizer" "kpat" "krdc" "krfb"
    "neochat" "plasma-welcome" "qrca" "skanlite"

    # LibreOffice Suite
    "libreoffice-calc" "libreoffice-core" "libreoffice-draw" "libreoffice-impress"
    "libreoffice-math" "libreoffice-writer"

    # System Tools
    "mediawriter" "podman" "setroubleshoot"
)

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
        if sudo apt-get remove -y --purge "$PACKAGE"; then
            echo -e "${GREEN}Successfully removed $PACKAGE${NC}"
        else
            echo -e "${RED}Failed to remove $PACKAGE${NC}"
            failed_removals+=("$PACKAGE")
        fi
    done
    
    # Clean up unused dependencies
    echo -e "${YELLOW}Cleaning up unused dependencies...${NC}"
    sudo apt-get autoremove -y
    
    print_failed_summary "remove" failed_removals
    return 0
}

# Main menu function
main_menu() {
    while true; do
        echo -e "${BLUE}\n=== MAIN MENU ===${NC}"
        echo "1. Remove system packages"
        echo "2. Exit"
        
        read -rp "Enter your choice (1-2): " CHOICE
        
        case $CHOICE in
            1) remove_packages ;;
            2)
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