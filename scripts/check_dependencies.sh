#!/usr/bin/env bash
#
# Copyright (C) 2024 ata-kaner
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# [

DEP_DIR="$SRC_DIR/unica/dependencies"

# Detect package manager
if command -v apt &>/dev/null; then
    PACKAGE_MANAGER="apt"
    INSTALL_CMD="sudo apt update && sudo apt install -y"
    DEP_FILE="$DEP_DIR/dependencies_debian.txt"
elif command -v pacman &>/dev/null; then
    PACKAGE_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -Syu --needed"
    DEP_FILE="$DEP_DIR/dependencies_arch.txt"
    # Enable multilib repository if not enabled
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo "Enabling multilib repository..."
        sudo sed -i '/#\[multilib\]/,+1s/^#//' /etc/pacman.conf
        echo "Multilib repository enabled. Updating package database..."
        sudo pacman -Syu
    fi
else
    echo "Unsupported package manager. Only apt and pacman are supported."
    return 1
fi

# Function to check if a binary exists
check_dependency() {
    command -v "$1" &>/dev/null
}

# ]

if [[ ! -f "$OUT_DIR/.dependencies_check" ]] || grep -q "0" "$OUT_DIR/.dependencies_check"; then
    echo "1" > "$OUT_DIR/.dependencies_check"
    echo "First run detected. Checking for missing dependencies..."
fi

# Read dependencies from the appropriate file
readarray -t dep_list < "$DEP_FILE"

# Check each dependency
missing_dep=()
for package in "${dep_list[@]}"; do
    if ! check_dependency "$package"; then
        missing_dep+=("$package")
    fi
done

# Handle missing dependencies
if (( ${#missing_dep[@]} != 0 )); then
    echo "Missing packages found: ${missing_dep[@]}"
    echo "Installing..."
    $INSTALL_CMD "${missing_dep[@]}"
else
    echo "All dependencies are already installed."
fi

exit 0
