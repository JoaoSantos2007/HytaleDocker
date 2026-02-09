#!/bin/bash

download_server() {
  echo "Iniciando download do servidor Hytale..."
  
  DOWNLOADER_DIR="/home/hytale/downloader"
  local DOWNLOADER_CMD="./hytale_downloader"
  local CREDENTIALS_FILE="$DOWNLOADER_DIR/.hytale-downloader-credentials.json"
  local latest_version=""
  local current_version=""

  mkdir -p "$DATA_DIR"
  mkdir -p "$DOWNLOADER_DIR"
  mkdir -p "$GAME_SERVER_DIR"

  # Copiar downloader do container para o volume
  if [ ! -f "$DOWNLOADER_DIR/hytale_downloader" ]; then
    echo "Copyng downloader to volume..."

    cp /home/hytale/server/hytale_downloader "$DOWNLOADER_DIR/"

    chmod +x "$DOWNLOADER_DIR/hytale_downloader"
  fi
  
  if [ ! -f "$CREDENTIALS_FILE" ]; then
    # First boot - no credentials yet, skip version check
    echo "First time setup - authentication required"
  else
    # Check latest available version
    echo "Checking latest version..."
    if latest_version=$(eval "$DOWNLOADER_CMD -print-version" 2>/dev/null) && [ -n "$latest_version" ]; then
      echo "Latest available version: $latest_version"
    else
      echo "Failed to get latest version"
      return 1
    fi
    
    # Check current installed version
    if [ -f "$VERSION_FILE" ]; then
      current_version=$(cat "$VERSION_FILE")
      echo "Current installed version: $current_version"
    fi
    
    # Compare versions
    if [ -f "$SERVER_FILES/Server/HytaleServer.jar" ] && [ "$current_version" = "$latest_version" ]; then
      echo "Server is up to date (version $latest_version)"
      return 0
    fi
    
    # Download needed
    if [ -f "$SERVER_FILES/Server/HytaleServer.jar" ]; then
      echo "Update available: $current_version -> $latest_version"
    fi
  fi
  
  echo "Downloading server files (this may take a while)..."
  cd "$DOWNLOADER_DIR" || exit 1
  eval "$DOWNLOADER_CMD -download-path '$DOWNLOADER_DIR/game.zip'" || {
    echo "Failed to download server files"
    return 1
  }
  
  # Check if authentication was successful
  if [ -f "$CREDENTIALS_FILE" ]; then
    echo "Hytale Authentication Successful"
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

  # Get version if we don't have it yet (first boot or version check was skipped)
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