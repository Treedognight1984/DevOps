#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Function to set temporary passwords and expire them
set_temp_password() {
  user=$1

  # Prompt the admin for a temporary password for the user
  read -s -p "Enter temporary password for $user: " temp_password
  echo # Move to a new line after password entry

  # Set the temporary password for the user
  echo -e "$temp_password\n$temp_password" | passwd $user

  # Expire the temporary password to force a reset upon next login
  passwd -e $user
}

# Set temporary passwords for each user
set_temp_password "dev_user"
set_temp_password "ops_user"
set_temp_password "test_user"

echo "Temporary passwords set for users. Users will be prompted to reset their password upon next login."
