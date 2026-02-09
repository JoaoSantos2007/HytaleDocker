#!/bin/bash

DOWNLOADER_DIR="/home/hytale/downloader"
DOWNLOADER_CMD="./hytale_downloader"
CREDENTIALS_FILE_SERVER="$SERVER_DIR/.hytale-downloader-credentials.json"
CREDENTIALS_FILE_DOWNLOADER="$DOWNLOADER_DIR/.hytale-downloader-credentials.json"
VERSION_FILE_SERVER="$SERVER_DIR/.server-version"
VERSION_FILE_DOWNLOADER="$DOWNLOADER_DIR/.server-version"
latest_version=""
current_version=""

download_server() {
  echo "Downloading server files (this may take a while)..."
  cd "$DOWNLOADER_DIR" || exit 1

  eval "$DOWNLOADER_CMD -download-path '$DOWNLOADER_DIR/game.zip'" || {
    echo "Failed to download server files"
    return 1
  }
  
  # Check if authentication was successful
  if [ -f "$CREDENTIALS_FILE_DOWNLOADER" ]; then
    echo "Hytale Authentication Successful"
    cp -f "$CREDENTIALS_FILE_DOWNLOADER" "$CREDENTIALS_FILE_SERVER"
  fi
  
  # Extract the files
  echo "Extracting server files..."
  unzip -o -q game.zip || {
    echo "Failed to extract server files"
    return 1
  }
  rm game.zip
  
  # Verify files exist
  if [ ! -f "$SERVER_FILES/Server/HytaleServer.jar" ]; then
    LogError "HytaleServer.jar not found after download"
    return 1
  fi

  # Get version if we don't have it yet (first boot)
  if [ -z "$latest_version" ]; then
    cd "$(dirname "$DOWNLOADER_EXEC")" || exit 1
    if latest_version=$(eval "$DOWNLOADER_CMD -print-version" 2>/dev/null) && [ -n "$latest_version" ]; then
      LogInfo "Server version: $latest_version"
    fi
  fi

  # Remove outdated AOT cache only if this was an update
  if [ -n "$current_version" ] && [ "$current_version" != "$latest_version" ]; then
    if [ -f "$SERVER_FILES/Server/HytaleServer.aot" ]; then
      LogWarn "Removing outdated AOT cache file (HytaleServer.aot) after update"
      rm -f "$SERVER_FILES/Server/HytaleServer.aot"
    fi
  fi

  # Save version
  if [ -n "$latest_version" ]; then
    echo "$latest_version" > "$VERSION_FILE"
    LogSuccess "Server download completed (version $latest_version)"
  else
    LogSuccess "Server download completed"
  fi
}

check_server() {
  echo "Checking server version..."

  mkdir -p "$DOWNLOADER_DIR"
  mkdir -p "$SERVER_DIR"

  # Sync credentials file in volume with container downloader
  if [ -f "$CREDENTIALS_FILE_SERVER" ]; then
    cp -f "$CREDENTIALS_FILE_SERVER" "$CREDENTIALS_FILE_DOWNLOADER"
  else
    rm -f "$CREDENTIALS_FILE_DOWNLOADER"
  fi

  # Sync version file in volume with container downloader
  if [ -f "$VERSION_FILE_SERVER" ]; then
    cp -f "$VERSION_FILE_SERVER" "$VERSION_FILE_DOWNLOADER"
  else
    rm -f "$VERSION_FILE_DOWNLOADER"
  fi

  # First boot
  if [ ! -f "$CREDENTIALS_FILE_DOWNLOADER" ]; then
    echo "First time, authentication is required!"
    download_server || return 1
    return 0
  fi

  cd "$DOWNLOADER_DIR" || exit 1

  # Get latest version
  if ! latest_version=$(eval "$DOWNLOADER_CMD -print-version" 2>/dev/null) && [ -n "$latest_version" ]; then
    echo "Failed to get latest version"
    return 1
  fi

  # Get current installed version
  if [ -f "$VERSION_FILE_DOWNLOADER" ]; then
    current_version=$(cat "$VERSION_FILE_DOWNLOADER")
  else
    current_version=""
  fi

  # Already up to date
  if [ -f "$SERVER_DIR/HytaleServer.jar" ] && [ "$current_version" = "$latest_version" ]; then
    echo "Server is up to date (version $latest_version)"
    return 0
  fi

  # Needs install/update
  if [ -f "$SERVER_DIR/HytaleServer.jar" ]; then
    echo "Update available: $current_version -> $latest_version"
  else
    echo "Server not installed"
  fi

  download_server || return 1
  return 0
}