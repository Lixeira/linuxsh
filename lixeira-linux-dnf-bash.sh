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
)

# Function to install packages
install_packages() {
    echo "Starting installation of packages..."
    for PACKAGE in "${INSTALL_PACKAGES[@]}"; do
        echo "Installing $PACKAGE..."
        sudo dnf install -y "$PACKAGE" || echo "Failed to install $PACKAGE"
    done
    echo "Installation complete."
}

# Function to remove packages
remove_packages() {
    echo "Starting removal of packages..."
    for PACKAGE in "${REMOVE_PACKAGES[@]}"; do
        echo "Removing $PACKAGE..."
        sudo dnf remove -y "$PACKAGE" || echo "Failed to remove $PACKAGE"
    done
    echo "Removal complete."
}

