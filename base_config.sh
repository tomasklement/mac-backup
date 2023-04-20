#!/bin/bash

# Interval in which is checked the need of backup [seconds]
REFRESH_INTERVAL="60"

# Mac library directory path
readonly LIBRARY_DIR="/Library/LaunchDaemons"

# Directory with particular backups configurations
readonly BACKUPS_CONFIG_DIR="backup_config"

# File with custom config
readonly CUSTOM_CONFIG_FILE_NAME="config.sh"

# File with custom config
readonly LAST_BACKUP_TIME_FILE="./backup_times/%s.time.txt"

# App name for launchctl
readonly APP_NAME="application.com.tomasklement.backup"

# Timeout for rsync connection
RSYNC_TIMEOUT=60