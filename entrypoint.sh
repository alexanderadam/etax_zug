#!/bin/bash

set -e

if [ ! -f "$ETAX_INSTALL_DIR/eTax.zug ${ETAX_YEAR} nP.desktop" ]; then
  ETAX_URL="https://etaxdownload.zg.ch/${ETAX_YEAR}/eTaxZGnP${ETAX_YEAR}_64bit.sh"
  echo "No installation was found. Downloading ${ETAX_URL} to ${ETAX_INSTALLER_SCRIPT}."
  wget -O $ETAX_INSTALLER_SCRIPT -c $ETAX_URL
  chmod 0755 $ETAX_INSTALLER_SCRIPT
  bash $ETAX_INSTALLER_SCRIPT
  rm ./$ETAX_INSTALLER_SCRIPT
fi

if [ -f $ETAX_INSTALLER_SCRIPT ]; then
  echo "Removing installation script ${ETAX_INSTALLER_SCRIPT}."
  rm $ETAX_INSTALLER_SCRIPT
fi

for filename in $ETAX_INSTALL_DIR/*.desktop; do
  ETAX_START_FILE="$(printf %q "$filename")"
  ETAX_START_FILE=${ETAX_START_FILE%.desktop}
  echo "Starting '${ETAX_START_FILE}'."
  bash -c "${ETAX_START_FILE}"
done

echo "Bye!"
