#!/bin/bash

# Function to create a group with a user and assign necessary permissions
create_group_with_user() {
  group=$1
  user=$2
  permission=$3
  directory=$4

  # Check if group already exists
  if grep -q ${group} /etc/group; then
    echo "Error: Group ${group} already exists."
  else
    # Create group
    groupadd ${group}
    echo "Group ${group} has been created."
  fi

  # Check if user already exists
  if id ${user} &>/dev/null; then
    echo "Error: User ${user} already exists."
  else
    # Create user and add to group
    useradd -m -g ${group} ${user}
    echo "User ${user} has been created and added to group ${group}."
  fi

  # Set directory permissions based on permission type
  case ${permission} in
  755)
    chmod -R 755 ${directory}
    ;;
  775)
    chmod -R 775 ${directory}
    chgrp -R ${group} ${directory}
    ;;
  *)
    echo "Invalid permission set. Skipping permission assignment."
    ;;
  esac
}

# Create groups, users, and set permissions
create_group_with_user "Dev" "dev_user" 775 "/var/www/html"
create_group_with_user "Ops" "ops_user" 755 "/"
create_group_with_user "Test" "test_user" 755 "/var/www/html"
