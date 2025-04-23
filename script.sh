#!/bin/bash

set -e

# Check if Flatpak is installed
if ! command -v flatpak &> /dev/null; then
    echo "Flatpak is not installed. Please install Flatpak first."
    exit 1
fi

# Demo packages
INSTALL_PACKAGES=("htop" "git" "curl" "decibels" "gnome.papers")
REMOVE_PACKAGES=(
    "firefox" "baobab" "evince" "epiphany"
    "gnome-calendar" "gnome-clocks" "gnome-color-manager"
    "gnome-connections" "gnome-console" "gnome-contacts"
    "gnome-logs" "gnome-maps" "gnome-music"
    "gnome-remote-desktop" "gnome-shell-extensions"
    "gnome-tour" "gnome-user-docs" "gnome-user-share"
    "malcontent" "orca" "simple-scan" "yelp"
    "gnome.snapshot"
)

FLATPAK_PACKAGES=("com.mattjakeman.ExtensionManager" "com.obsproject.Studio")

# Function to install system packages
install_packages() {
    echo "Starting installation of packages..."
    for PACKAGE in "${INSTALL_PACKAGES[@]}"; do
        echo "Installing $PACKAGE..."
        sudo dnf install -y "$PACKAGE" || echo "Failed to install $PACKAGE"
    done
    echo "Installation complete."
}

# Function to remove system packages
remove_packages() {
    echo "Starting removal of packages..."
    for PACKAGE in "${REMOVE_PACKAGES[@]}"; do
        echo "Removing $PACKAGE..."
        sudo dnf remove -y "$PACKAGE" || echo "Failed to remove $PACKAGE"
    done
    echo "Removal complete."
}

# Function to install Flatpak applications
install_flatpaks() {
    echo "Starting installation of Flatpak packages..."
    for PACKAGE in "${FLATPAK_PACKAGES[@]}"; do
        echo "Installing Flatpak package: $PACKAGE..."
        flatpak install -y flathub "$PACKAGE" || echo "Failed to install Flatpak package $PACKAGE"
    done
    echo "Flatpak installation complete."
}

# Function to install NVIDIA Graphics drivers
install_nvidia() {
    echo "Starting NVIDIA graphics installation..."
    
    # Install required packages
    sudo dnf install -y kmodtool akmods mokutil openssl

    # Generate and import MOK (Machine Owner Key) for Secure Boot (if enabled)
    sudo kmodgenca -a
    echo "Please enter your password to proceed with MOK enrollment..."
    sudo mokutil --import /etc/pki/akmods/certs/public_key.der

    # Install NVIDIA drivers and CUDA
    sudo dnf install -y akmod-nvidia
    sudo dnf install -y xorg-x11-drv-nvidia-cuda

    # Confirm NVIDIA driver version
    echo "NVIDIA driver installation complete. Verifying version..."
    modinfo -F version nvidia
    echo "NVIDIA graphics installation complete."
}

# Function to install Brave browser
install_brave() {
    echo "Starting Brave browser installation..."
    curl -fsS https://dl.brave.com/install.sh | sh
    echo "Brave browser installation complete."
}

# Main script execution
echo "Select an operation:"
echo "1. Install system packages"
echo "2. Remove system packages"
echo "3. Install Flatpak packages"
echo "4. Install NVIDIA graphics drivers"
echo "5. Install Brave browser"
echo "6. Exit"

read -p "Enter your choice (1-6): " CHOICE

case $CHOICE in
    1)
        install_packages
        ;;
    2)
        remove_packages
        ;;
    3)
        install_flatpaks
        ;;
    4)
        install_nvidia
        ;;
    5)
        install_brave
        ;;
    6)
        echo "Exiting script. Goodbye!"
        ;;
    *)
        echo "Invalid choice. Exiting."
        ;;
esac
