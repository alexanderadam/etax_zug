#!/bin/bash
set -e

ETAX_DIR=${ETAX_DIR:-$(pwd)/etax}

# Backup existing non-empty directory
if [ -d "$ETAX_DIR" ] && [ "$(ls -A $ETAX_DIR)" ]; then
    TIMESTAMP=$(date +"%Y_%m_%d_-_%H_%M")
    BACKUP_DIR="${ETAX_DIR}_${TIMESTAMP}"
    echo "📦 Backing up existing directory to: $BACKUP_DIR"
    mv "$ETAX_DIR" "$BACKUP_DIR"
fi

mkdir -p "$ETAX_DIR"

if ! command -v podman &> /dev/null
then
    docker rmi localhost/etax_zug 2>/dev/null || true
    docker build --build-arg HOST_GID=$(id -g) --build-arg HOST_UID=$(id -u) -t etax_zug -f Containerfile .
else
    podman rmi localhost/etax_zug 2>/dev/null || true
    podman build --build-arg HOST_GID=$(id -g) --build-arg HOST_UID=$(id -u) -t etax_zug -f Containerfile .
fi

if [ $? -eq 0 ]; then
    ETAX_DIR="$ETAX_DIR" ./run.sh
else
    echo "Build failed. Exiting."
    exit 1
fi
