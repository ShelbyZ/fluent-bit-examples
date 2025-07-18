#!/bin/bash

# Script to manage systemd-journald settings:
# - SYSTEMD_JOURNAL_KEYED_HASH environment variable
# - Compress option in journald.conf
# This script requires sudo privileges

set -e

CONFIG_DIR="/etc/systemd/system/systemd-journald.service.d"
CONFIG_FILE="${CONFIG_DIR}/journal-keyed-hash.conf"
JOURNALD_CONF="/etc/systemd/journald.conf"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if script is run with sudo
check_sudo() {
  if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo privileges${NC}"
    exit 1
  fi
}

# Enable SYSTEMD_JOURNAL_KEYED_HASH (set to 1)
enable_keyed_hash() {
  check_sudo
  
  echo -e "${YELLOW}Enabling SYSTEMD_JOURNAL_KEYED_HASH...${NC}"
  
  # Create config directory if it doesn't exist
  mkdir -p "${CONFIG_DIR}"
  
  # Create or update the config file
  cat > "${CONFIG_FILE}" << EOF
[Service]
Environment=SYSTEMD_JOURNAL_KEYED_HASH=1
EOF
  
  # Reload systemd and restart journald
  systemctl daemon-reload
  systemctl restart systemd-journald
  
  echo -e "${GREEN}SYSTEMD_JOURNAL_KEYED_HASH has been enabled${NC}"
}

# Disable SYSTEMD_JOURNAL_KEYED_HASH (set to 0)
disable_keyed_hash() {
  check_sudo
  
  echo -e "${YELLOW}Disabling SYSTEMD_JOURNAL_KEYED_HASH...${NC}"
  
  # Create config directory if it doesn't exist
  mkdir -p "${CONFIG_DIR}"
  
  # Create or update the config file
  cat > "${CONFIG_FILE}" << EOF
[Service]
Environment=SYSTEMD_JOURNAL_KEYED_HASH=0
EOF
  
  # Reload systemd and restart journald
  systemctl daemon-reload
  systemctl restart systemd-journald
  
  echo -e "${GREEN}SYSTEMD_JOURNAL_KEYED_HASH has been disabled${NC}"
}

# Remove the configuration (use systemd defaults)
reset_to_default() {
  check_sudo
  
  echo -e "${YELLOW}Resetting SYSTEMD_JOURNAL_KEYED_HASH to system default...${NC}"
  
  # Remove the config file if it exists
  if [ -f "${CONFIG_FILE}" ]; then
    rm "${CONFIG_FILE}"
    
    # Remove the directory if it's empty
    rmdir --ignore-fail-on-non-empty "${CONFIG_DIR}"
    
    # Reload systemd and restart journald
    systemctl daemon-reload
    systemctl restart systemd-journald
    
    echo -e "${GREEN}SYSTEMD_JOURNAL_KEYED_HASH has been reset to system default${NC}"
  else
    echo -e "${YELLOW}No custom configuration found. System is using defaults.${NC}"
  fi
}

# Check the current status of SYSTEMD_JOURNAL_KEYED_HASH
check_hash_status() {
  echo -e "${YELLOW}Checking SYSTEMD_JOURNAL_KEYED_HASH status...${NC}"
  
  # Check if the environment variable is set in the service
  ENV_VALUE=$(systemctl show systemd-journald.service -p Environment | grep -o "SYSTEMD_JOURNAL_KEYED_HASH=[01]" || echo "")
  
  # Check if the config file exists
  if [ -f "${CONFIG_FILE}" ]; then
    echo -e "${GREEN}Configuration file exists:${NC} ${CONFIG_FILE}"
    echo -e "${YELLOW}Content:${NC}"
    cat "${CONFIG_FILE}"
    echo ""
  else
    echo -e "${YELLOW}No custom configuration file found.${NC}"
  fi
  
  # Display the current environment setting
  if [ -n "${ENV_VALUE}" ]; then
    VALUE=${ENV_VALUE#*=}
    if [ "${VALUE}" = "0" ]; then
      echo -e "${GREEN}Status:${NC} SYSTEMD_JOURNAL_KEYED_HASH is explicitly ${RED}disabled${NC} (${VALUE})"
    else
      echo -e "${GREEN}Status:${NC} SYSTEMD_JOURNAL_KEYED_HASH is explicitly ${GREEN}enabled${NC} (${VALUE})"
    fi
  else
    echo -e "${GREEN}Status:${NC} SYSTEMD_JOURNAL_KEYED_HASH is not explicitly set (using system default)"
    
    # Check systemd version to provide more context
    SYSTEMD_VERSION=$(systemctl --version | head -n 1 | awk '{print $2}')
    echo -e "${GREEN}Systemd version:${NC} ${SYSTEMD_VERSION}"
    
    if [ "${SYSTEMD_VERSION}" -ge 246 ]; then
      echo -e "${YELLOW}Note:${NC} Your systemd version likely has this feature enabled by default."
    else
      echo -e "${YELLOW}Note:${NC} Your systemd version may not support this feature."
    fi
  fi
}

# Check the current status of all settings
check_status() {
  # Check hash status
  check_hash_status
  
  # Add a separator
  echo -e "\n${YELLOW}----------------------------------------${NC}\n"
  
  # Check compression status
  check_compression_status
  
  # Check journal file properties
#   echo -e "\n${YELLOW}Checking journal file properties:${NC}"
#   JOURNAL_INFO=$(journalctl --header 2>/dev/null | grep -i "compression\|file\|hash" || echo "Could not retrieve journal header information")
#   echo -e "${JOURNAL_INFO}"
}

# Enable journal compression
enable_compression() {
  check_sudo
  
  echo -e "${YELLOW}Enabling journal compression...${NC}"
  
  # Check if journald.conf exists
  if [ ! -f "${JOURNALD_CONF}" ]; then
    # Create the file if it doesn't exist
    mkdir -p "$(dirname "${JOURNALD_CONF}")"
    touch "${JOURNALD_CONF}"
  fi
  
  # Check if Compress is already set
  if grep -q "^Compress=" "${JOURNALD_CONF}"; then
    # Replace existing setting
    sed -i 's/^Compress=.*/Compress=yes/' "${JOURNALD_CONF}"
  else
    # Add new setting
    echo "Compress=yes" >> "${JOURNALD_CONF}"
  fi
  
  # Restart journald to apply changes
  systemctl restart systemd-journald
  
  echo -e "${GREEN}Journal compression has been enabled${NC}"
}

# Disable journal compression
disable_compression() {
  check_sudo
  
  echo -e "${YELLOW}Disabling journal compression...${NC}"
  
  # Check if journald.conf exists
  if [ ! -f "${JOURNALD_CONF}" ]; then
    # Create the file if it doesn't exist
    mkdir -p "$(dirname "${JOURNALD_CONF}")"
    touch "${JOURNALD_CONF}"
  fi
  
  # Check if Compress is already set
  if grep -q "^Compress=" "${JOURNALD_CONF}"; then
    # Replace existing setting
    sed -i 's/^Compress=.*/Compress=no/' "${JOURNALD_CONF}"
  else
    # Add new setting
    echo "Compress=no" >> "${JOURNALD_CONF}"
  fi
  
  # Restart journald to apply changes
  systemctl restart systemd-journald
  
  echo -e "${GREEN}Journal compression has been disabled${NC}"
}

# Reset compression setting to default
reset_compression() {
  check_sudo
  
  echo -e "${YELLOW}Resetting journal compression to system default...${NC}"
  
  # Check if journald.conf exists and contains Compress setting
  if [ -f "${JOURNALD_CONF}" ] && grep -q "^Compress=" "${JOURNALD_CONF}"; then
    # Comment out the Compress line
    sed -i 's/^Compress=/#Compress=/' "${JOURNALD_CONF}"
    
    # Restart journald to apply changes
    systemctl restart systemd-journald
    
    echo -e "${GREEN}Journal compression has been reset to system default${NC}"
  else
    echo -e "${YELLOW}No custom compression setting found. System is using defaults.${NC}"
  fi
}

# Check compression status
check_compression_status() {
  echo -e "${YELLOW}Checking journal compression status...${NC}"
  
  # Check if journald.conf exists and contains Compress setting
  if [ -f "${JOURNALD_CONF}" ] && grep -q "^Compress=" "${JOURNALD_CONF}"; then
    COMPRESS_SETTING=$(grep "^Compress=" "${JOURNALD_CONF}")
    echo -e "${GREEN}Compression setting:${NC} ${COMPRESS_SETTING}"
    
    if [[ "${COMPRESS_SETTING}" == *"=yes"* ]]; then
      echo -e "${GREEN}Status:${NC} Journal compression is explicitly ${GREEN}enabled${NC}"
    else
      echo -e "${GREEN}Status:${NC} Journal compression is explicitly ${RED}disabled${NC}"
    fi
  else
    echo -e "${GREEN}Status:${NC} Journal compression is not explicitly set (using system default)"
    echo -e "${YELLOW}Note:${NC} The default is typically 'yes' (compression enabled)"
  fi
}

# Display usage information
show_help() {
  echo "Usage: $0 [OPTION]"
  echo "Manage systemd-journald settings"
  echo ""
  echo "Options for SYSTEMD_JOURNAL_KEYED_HASH:"
  echo "  enable-hash       Enable SYSTEMD_JOURNAL_KEYED_HASH (set to 1)"
  echo "  disable-hash      Disable SYSTEMD_JOURNAL_KEYED_HASH (set to 0)"
  echo "  reset-hash        Remove custom hash configuration (use system defaults)"
  echo ""
  echo "Options for journal compression:"
  echo "  enable-compress   Enable journal compression"
  echo "  disable-compress  Disable journal compression"
  echo "  reset-compress    Reset compression to system default"
  echo ""
  echo "General options:"
  echo "  status            Check current status of all settings"
  echo "  help              Display this help message"
  echo ""
  echo "This script requires sudo privileges for enable, disable, and reset operations."
}

# Main script execution
case "$1" in
  enable-hash)
    enable_keyed_hash
    ;;
  disable-hash)
    disable_keyed_hash
    ;;
  reset-hash)
    reset_to_default
    ;;
  enable-compress)
    enable_compression
    ;;
  disable-compress)
    disable_compression
    ;;
  reset-compress)
    reset_compression
    ;;
  status)
    check_status
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    show_help
    exit 1
    ;;
esac

exit 0
