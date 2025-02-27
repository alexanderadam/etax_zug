#!/bin/bash
set -e

DEFAULT_UID=1000
DEFAULT_GID=1000

if [ -z "$TAXPAYER_UID" ]; then
  echo -e "\e[33m⚠️  TAXPAYER_UID is not set. Falling back to default UID: $DEFAULT_UID.\e[0m"
  TAXPAYER_UID=$DEFAULT_UID
fi
if [ -z "$TAXPAYER_GID" ]; then
  echo -e "\e[33m⚠️  TAXPAYER_GID is not set. Falling back to default GID: $DEFAULT_GID.\e[0m"
  TAXPAYER_GID=$DEFAULT_GID
fi
CURRENT_UID=$(id -u taxpayer)
CURRENT_GID=$(id -g taxpayer)

if [ "$TAXPAYER_UID" -ne "$CURRENT_UID" ]; then
  usermod -u "$TAXPAYER_UID" taxpayer
fi

if [ "$TAXPAYER_GID" -ne "$CURRENT_GID" ]; then
  groupmod -g "$TAXPAYER_GID" taxpayer
fi

change_ownership() {
  local path=$1
  local current_uid=$(stat -c %u "$path")
  local current_gid=$(stat -c %g "$path")
  if [ "$current_uid" -eq "$TAXPAYER_UID" ] && [ "$current_gid" -eq "$TAXPAYER_GID" ]; then
    return
  fi
  chown -R taxpayer:taxpayer "$path" 2>/tmp/chown_errors || {
    echo -e "\e[31m😞 Failed to change ownership of $path.\e[0m"
    echo -e "\e[31mCurrent user: $(whoami) (UID: $(id -u), GID: $(id -g))\e[0m"
    echo -e "\e[31mDirectory UID: $(stat -c %u "$path"), GID: $(stat -c %g "$path")\e[0m"
    cat /tmp/chown_errors
  }
}

change_ownership /home/taxpayer
if [ ! -f "$ETAX_INSTALL_DIR/eTax.zug ${ETAX_YEAR} nP.desktop" ]; then
  ETAX_BASE_URL="https://etaxdownload.zg.ch/${ETAX_YEAR}/eTaxZGnP${ETAX_YEAR}_64bit"
  ETAX_SH_URL="${ETAX_BASE_URL}.sh"
  ETAX_ZIP_URL="${ETAX_BASE_URL}.zip"

  echo -e "\e[34m📥 Trying to download \e[4m${ETAX_SH_URL}\e[24m\e[0m"
  HTTP_RESPONSE=$(curl -w "%{http_code}" -o "$ETAX_INSTALLER_SCRIPT" "$ETAX_SH_URL")

  if [ "$HTTP_RESPONSE" = "404" ]; then
    echo -e "\e[33m⚠️  .sh not found, trying .zip version\e[0m"
    HTTP_RESPONSE=$(curl -w "%{http_code}" -o "${ETAX_INSTALLER_SCRIPT}.zip" "$ETAX_ZIP_URL")

    if [ "$HTTP_RESPONSE" != "200" ]; then
      echo -e "\e[31m❌ Download failed with HTTP status $HTTP_RESPONSE\e[0m"
      exit 1
    fi

    # Create temp directory and unzip
    TMP_DIR=$(mktemp -d)
    if ! unzip -q "${ETAX_INSTALLER_SCRIPT}.zip" -d "$TMP_DIR"; then
      echo -e "\e[31m❌ Failed to unzip archive\e[0m"
      rm -rf "$TMP_DIR" "${ETAX_INSTALLER_SCRIPT}.zip"
      exit 1
    fi

    # Look for the installer script
    EXTRACTED_SCRIPT="$TMP_DIR/eTaxZGnP${ETAX_YEAR}_64bit.sh"
    if [ ! -f "$EXTRACTED_SCRIPT" ]; then
      echo -e "\e[31m❌ Could not find installer script in zip archive\e[0m"
      rm -rf "$TMP_DIR" "${ETAX_INSTALLER_SCRIPT}.zip"
      exit 1
    fi

    # Move the script to the expected location
    mv "$EXTRACTED_SCRIPT" "$ETAX_INSTALLER_SCRIPT"
    rm -rf "$TMP_DIR" "${ETAX_INSTALLER_SCRIPT}.zip"
  fi

  # Check if file is a shell script
  FILE_TYPE=$(file -b "$ETAX_INSTALLER_SCRIPT")
  if [[ ! "$FILE_TYPE" =~ "shell script" ]]; then
    echo -e "\e[31m❌ Downloaded file is not a shell script (detected: $FILE_TYPE)\e[0m"
    rm "$ETAX_INSTALLER_SCRIPT"
    exit 1
  fi

  chmod 0755 "$ETAX_INSTALLER_SCRIPT"
  echo -e "\e[34m💯 finished\e[0m"

  # We're using expect here to simulate keypresses
  expect <<EOF
  log_user 1
  set timeout 30
  spawn bash "$ETAX_INSTALLER_SCRIPT"
  expect {
    "OK \[o, Eingabe\], Abbrechen \[c\]" {
      send "o\r"
      exp_continue
    }
    "Wohin soll eTax.zug ${ETAX_YEAR} nP installiert werden?" {
      send "\r"
      exp_continue
    }
    "existiert bereits. Wollen Sie trotzdem in diesen Ordner installieren?" {
      send "j\r"
      exp_continue
    }
    "eTax.zug ${ETAX_YEAR} nP starten?" {
      send "y\r"
      exp_continue
    }
    timeout {
      puts "⏳ Timeout reached, continuing..."
      exp_continue
    }
    eof
  }
EOF

  if [ $? -eq 0 ]; then
    echo -e "\e[34m🥳 The installation was successful.\e[0m"
  else
    echo -e "\e[34m😞 The 'expect' script failed.\e[0m"
    exit 1
  fi
  change_ownership "$ETAX_INSTALLER_SCRIPT"
  change_ownership "$ETAX_INSTALL_DIR"
  if [ "$1" != "bash" ]; then
    rm "./$ETAX_INSTALLER_SCRIPT"
  fi
fi
shopt -s nullglob
desktop_files=("$ETAX_INSTALL_DIR"/*.desktop)
shopt -u nullglob
if [ ${#desktop_files[@]} -eq 0 ]; then
  echo -e "\e[31mNo .desktop files found in $ETAX_INSTALL_DIR\e[0m"
  echo "Files in the directory:"
  for file in "$ETAX_INSTALL_DIR"/*; do
    echo -e "\e[33m$file\e[0m"
  done
fi
if [ "$1" != "bash" ]; then
  if [ ${#desktop_files[@]} -eq 0 ]; then
    echo -e "\e[31mNo .desktop files found in $ETAX_INSTALL_DIR.\e[0m"
    exit 1
  fi
  ETAX_START_FILE="${desktop_files[0]}"
  ETAX_START_FILE=${ETAX_START_FILE%.desktop}
  echo -e "\e[34m🚀 Starting '${ETAX_START_FILE}'.\e[0m"
  if [ "$(whoami)" = "taxpayer" ]; then
    "$ETAX_START_FILE" 2>&1 | grep -v '] discovered and registered\.'
  else
    su -s /bin/bash - taxpayer -c "${ETAX_START_FILE} 2>&1 | grep -v '] discovered and registered\.'"
  fi
else
  echo -e "\e[34m⏩ Skipping execution of .desktop files as 'bash' argument was provided.\e[0m"
  exec bash
fi
