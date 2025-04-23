#!/bin/bash

set -e

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

# Main script execution
echo "Select an operation:"
echo "1. Install system packages"
echo "2. Remove system packages"
echo "3. Install Flatpak packages"
echo "4. Exit"

read -p "Enter your choice (1-4): " CHOICE

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
        echo "Exiting script. Goodbye!"
        ;;
    *)
        echo "Invalid choice. Exiting."
        ;;
esac
