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
# Function to change ownership and handle errors
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
  ETAX_URL="https://etaxdownload.zg.ch/${ETAX_YEAR}/eTaxZGnP${ETAX_YEAR}_64bit.sh"
  echo -e "\e[34m📥 No installation was found. Downloading \e[4m${ETAX_URL}\e[24m to ${ETAX_INSTALLER_SCRIPT}.\e[0m"
  curl -o "$ETAX_INSTALLER_SCRIPT" "$ETAX_URL"
  chmod 0755 "$ETAX_INSTALLER_SCRIPT"
  echo -e "\e[34m💯 finished\e[0m"
  # We're using expect here to simulate keypresses
  expect <<EOF
  log_user 1
  spawn bash "$ETAX_INSTALLER_SCRIPT"
  expect "OK \[o, Eingabe\], Abbrechen \[c\]"
  send "o\r"
  expect "Wohin soll eTax.zug ${ETAX_YEAR} nP installiert werden?"
  send "\r"
  expect "Der Ordner:\n\n/home/taxpayer/etax_zug\n\n existiert bereits. Wollen Sie trotzdem in diesen Ordner installieren?\nJa \[j, Eingabe\], Nein \[n\]"
  send "j\r"
  expect "eTax.zug ${ETAX_YEAR} nP starten?\nJa \[y, Eingabe\], Nein \[n\]"
  send "y\r"
  expect eof
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
    "$ETAX_START_FILE"
  else
    su -s /bin/bash - taxpayer -c "${ETAX_START_FILE}"
  fi
else
  echo -e "\e[34m⏩ Skipping execution of .desktop files as 'bash' argument was provided.\e[0m"
  exec bash
fi
