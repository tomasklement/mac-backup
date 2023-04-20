#!/bin/bash

# Loads main configuration
# Globals:
#   CUSTOM_CONFIG_FILE_NAME Name of custom config file
# Arguments:
#   None
# Returns:
#   None (globals from config file are set)
function bkp::load_main_config {
  source base_config.sh
  if [[ -n "${CUSTOM_CONFIG_FILE_NAME}" ]] && \
    [[ -f "${CUSTOM_CONFIG_FILE_NAME}" ]]; then
    source "${CUSTOM_CONFIG_FILE_NAME}"
  fi
}

# Returns relative paths to backup configurations
# Globals:
#   BACKUPS_CONFIG_DIR Relative path to backup configurations directory
# Arguments:
#   None
# Returns:
#   Array of relative paths to particular configuration files
function bkp::get_backup_configs {
  local directories

  for file_path in $BACKUPS_CONFIG_DIR/*; do
    # Ignore sample file
    if [[ "${file_path}" == "${BACKUPS_CONFIG_DIR}/sample.conf" ]]; then
      continue
    fi

    # Ignore files which doesn't end ".conf"
    if ! [[ "${file_path}" =~ .conf$ ]]; then
      continue
    fi

    directories+=( "${file_path}" )
  done

  echo "${directories[@]}"
}

# Resets all configuration variables
# Globals:
#   Config vars: SOURCE_DIR, DESTINATION_DIR, INTERVAL
# Arguments:
#   None
# Returns:
#   None
function bkp::unset_config_vars {
  SOURCE_DIR=""
  DESTINATION_DIR=""
  INTERVAL=""
  NAME=""
}

# Validates configuration variables
# Globals:
#   Config vars: SOURCE_DIR, DESTINATION_DIR, INTERVAL, NAME
# Arguments:
#   None
# Returns:
#   None
function bkp::validate_config {
  local empty_variables
  local error_text

  empty_variables=(
    $( val::filter_empty_variable_names "SOURCE_DIR" "DESTINATION_DIR" "NAME" "INTERVAL" )
  )

  if [[ "${#empty_variables[@]}" -gt 0 ]]; then
    error_text=$( arr::join ", " "${empty_variables[@]}" )
    error_text="Missing configuration variables: \"${error_text}\" in \"${1}\""
    err::throw 134 "${error_text}"
  fi

  if [[ ! -w "${SOURCE_DIR}" ]] || [[ ! -d "${SOURCE_DIR}" ]]; then
    err::throw 134 "Source dir \"${SOURCE_DIR}\" is not writable or not exist"
  fi

  if [[ ! -w "${DESTINATION_DIR}" ]] || [[ ! -d "${DESTINATION_DIR}" ]]; then
    err::throw 134 "Destination dir \"${DESTINATION_DIR}\" is not writable or not exist"
  fi
}

# Validates all backup configurations
# Globals:
#   BACKUPS_CONFIG_DIR Relative path to backup configurations directory
# Arguments:
#   None
# Returns:
#   None
function bkp::validate_all_configs {
  local config

  for config in $( bkp::get_backup_configs )
  do
    source "${config}"
    # Validate configured variables
    bkp::validate_config "${config}"
    # Unset configuration vars for next round
    bkp::unset_config_vars
  done
}

# Creates relative path to backup config file
# Globals:
#   Config vars: BACKUPS_CONFIG_DIR
# Arguments:
#   Config name
# Returns:
#   Path to config file
function bkp::get_config_path {
  echo "${BACKUPS_CONFIG_DIR}/${1}"
}

# Checks if configuration with given name exists
# Globals:
#   Config vars: BACKUPS_CONFIG_DIR
# Arguments:
#   Config name
# Returns:
#   Nothing
function bkp::check_config_exists {
  local config_path

  if [[ -z "${1}" ]]; then
    err::throw 1 "Backup name was not provided"
  fi

  config_path=$( bkp::get_config_path "${1}" )

  if [[ ! -r "${config_path}" ]]; then
    err::throw 5 "Cannot read configuration file \"${1}.conf\" in \""${BACKUPS_CONFIG_DIR}"\" dir"
  fi
}


# Checks if backup paths are readable/writable
# Globals:
#   Config vars: SOURCE_DIR, DESTINATION_DIR
# Arguments:
#   None
# Returns:
#   Nothing
function bkp::check_backup_paths {
  if [[ ! -w "${DESTINATION_DIR}" ]]; then
    err::throw 5 "Directory \""${DESTINATION_DIR}"\" is not writable"
  fi

  if [[ ! -r "${SOURCE_DIR}" ]]; then
    err::throw 5 "Directory \""${SOURCE_DIR}"\" is not readable"
  fi
}

# Returns path to last backup time file
# Globals:
#   LAST_BACKUP_TIME_FILE path to file where last backup time is stored
# Arguments:
#   Backup config file name
# Returns:
#   File path
function bkp::get_backup_time_file {
  printf "${LAST_BACKUP_TIME_FILE}" "${1}"
}

# Saves current time as last backup time for particular backup
# Globals:
#   LAST_BACKUP_TIME_FILE path to file where last backup time is stored
# Arguments:
#   Backup config file name
# Returns:
#   Nothing
function bkp::save_backup_time {
  local time_file_path
  time_file_path=$( bkp::get_backup_time_file "${1}" )
  date +%s > "${time_file_path}"
}

# Prints formatted date by timestamp
# Globals:
#   None
# Arguments:
#   Timestamp
# Returns:
#   Formatted date
function bkp::format_date {
  date -r "${1}" +'%Y-%m-%d %H:%M:%S'
}

# Returns next backup time for given backup
# Globals:
#   LAST_BACKUP_TIME_FILE path to file where last backup time is stored
#   INTERVAL backup interval [seconds]
# Arguments:
#   Backup config file name
# Returns:
#   Next backup time timestamp
function bkp::get_next_backup_time {
  local last_backup_time
  local next_backup_time

  last_backup_time=$( bkp::get_last_backup_time "${1}" )
  next_backup_time=$((last_backup_time + INTERVAL))

  echo "${next_backup_time}"
}

# Returns last backup time for given backup
# Globals:
#   LAST_BACKUP_TIME_FILE path to file where last backup time is stored
# Arguments:
#   Backup config file name
# Returns:
#   Last backup time timestamp, returns 0 when backup haven't been run yet
function bkp::get_last_backup_time {
  local time_file_path

  time_file_path=$( bkp::get_backup_time_file "${1}" )

  if [[ -f "${time_file_path}" ]]; then
    cat "${time_file_path}"
  else
    echo "0"
  fi
}

# Returns last backup time for given backup
# Globals:
#   LAST_BACKUP_TIME_FILE path to file where last backup time is stored
# Arguments:
#   Backup config file name
# Returns:
#   Formatted last backup time
function bkp::print_last_backup_time {
  local last_backup_time

  last_backup_time=$( bkp::get_last_backup_time "${1}" )

  if [[ "${last_backup_time}" -eq "0" ]]; then
    printf "not yet"
  else
    bkp::format_date "${last_backup_time}"
  fi
}

# Check if it is time for next backup (since the last backup)
# Globals:
#   LAST_BACKUP_TIME_FILE path to file where last backup time is stored
#   INTERVAL backup interval [seconds]
# Arguments:
#   Backup config file name
# Returns:
#   True or false
function bkp::should_backup_run {
    local next_backup_time
    local last_backup_time
    local current_time=$(date +%s)

    last_backup_time=$( bkp::get_last_backup_time "${1}" )
    next_backup_time=$((last_backup_time + INTERVAL))

    if [[ $current_time -lt $next_backup_time ]]; then
        false
        return
    fi

    true
}

# Runs particular backup
# Globals:
#   Config vars: BACKUPS_CONFIG_DIR
# Arguments:
#   Config file name
# Returns:
#   None
function bkp::backup {
  local config_path

  bkp::check_config_exists "${1}"
  config_path=$( bkp::get_config_path "${1}" )
  source "${config_path}"

  echo -e "${BLUE}Running backup \"${1}\"${NC}"

  bkp::check_backup_paths

  echo "Syncing \"${SOURCE_DIR}\" to \"${DESTINATION_DIR}\""
  rsync -az --timeout="${RSYNC_TIMEOUT}" --delete "${SOURCE_DIR}" "${DESTINATION_DIR}" &> /dev/null

  echo -e "${GREEN}Backup \"${1}\" finished${NC}"
}

# Runs all configured backups
# Globals:
#   BACKUPS_CONFIG_DIR Relative path to backups configurations directory
# Arguments:
#   None
# Returns:
#   None
function bkp::process {
  local config
  local output
  local config_file_name
  local errors=()
  local names=()
  local notification_title
  local notification_text
  local notification_sound
  local error_message
  local backup_time

  echo -e "${BLUE}Processing backups${NC}"

  for config in $( bkp::get_backup_configs )
  do
    source "${config}"

    config_file_name=$( basename -- "${config}" )

    backup_time=$( bkp::print_last_backup_time "${config_file_name}" )
    echo "Last run of backup \"${NAME}\" was at: ${backup_time}"
    if ! bkp::should_backup_run "${config_file_name}"; then
      backup_time=$( bkp::get_next_backup_time "${config_file_name}" )
      backup_time=$( bkp::format_date "${backup_time}" )
      echo "Skipping backup \"${NAME}\". Will run at: ${backup_time}"
      continue
    fi

    echo "Running backup \"${NAME}\""

    bkp::save_backup_time "${config_file_name}"

    output=$( ./backup "${config_file_name}" 2>&1 1>/dev/null )

    if [[  "$?" -gt 0 ]]; then
      error_message="Backup \"${NAME}\" failed with result: ${output}"
      echo "${error_message}"
      errors+=( "${error_message}" )
    else
      echo "Backup \"${NAME}\" finished"
    fi

    names+=( "${NAME}" )
  done

  if [[ "${#errors[@]}" -eq 0 ]]; then
    notification_title="✓ Backup was successful"
    notification_text=$( arr::join "\", \"" "${names[@]}" )
    notification_text="Successfully processed backups:  \"${notification_text}\""
    notification_sound="Submarine"
  else
    notification_title="⚠ Some backups failed"
    notification_text=$( arr::join $'\n' "${errors[@]}" )
    notification_sound="Basso"
  fi

  if [[ "${#names[@]}" -gt 0 ]]; then
    ntf::notify "${notification_title}" "${notification_text}" "${notification_sound}"
  fi

  echo -e "${GREEN}Backups finished${NC}"
}
