#!/bin/bash
set -e
# https://github.com/containers/podman/discussions/13040

ETAX_DIR=$(pwd)/etax
TAX_FILES_DIR=$(pwd)/tax_files
TAXPAYER_UID=$(id -u)
TAXPAYER_GID=$(id -g)
mkdir -p $ETAX_DIR
mkdir -p $TAX_FILES_DIR

# Generate X11 authorization file
xauth_list=$(xauth list)
if [ -z "$xauth_list" ]; then
  xauth generate $DISPLAY . trusted
fi
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f /tmp/.docker.xauth nmerge -

# Common options
options="-e HOME
  -e TAXPAYER_UID=$TAXPAYER_UID
  -e TAXPAYER_GID=$TAXPAYER_GID
  -v $TAX_FILES_DIR:/home/taxpayer/Steuerfaelle:z
  -v $ETAX_DIR:/home/taxpayer/etax_zug:z
  -e XAUTHORITY=/tmp/.docker.xauth
  -v /tmp/.docker.xauth:/tmp/.docker.xauth:z"

if [ -n "$WAYLAND_DISPLAY" ]; then
  options="$options
    -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY
    -e QT_QPA_PLATFORM=wayland
    -e GDK_BACKEND=wayland
    -e CLUTTER_BACKEND=wayland
    -e SDL_VIDEODRIVER=wayland
    -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
    -e DISPLAY=$DISPLAY
    --ipc=host
    -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/run/user/$TAXPAYER_UID/$WAYLAND_DISPLAY:z
    -v $XDG_RUNTIME_DIR:/run/user/$TAXPAYER_UID:z"
else
  options="$options
    -e DISPLAY=$DISPLAY
    -v /tmp/.X11-unix:/tmp/.X11-unix:z"
fi

options="$(echo "$options" | tr -d '\n')"

if [ "$1" == "bash" ]; then
  command="bash"
else
  command=""
fi

if ! command -v podman &> /dev/null
then
  eval "docker run --rm --name etax_zug --hostname etax-zug --net=host -it ${options} etax_zug:latest ${command}"
else
  echo "podman run --rm --name etax_zug --hostname etax-zug --add-host=etax-zug:127.0.0.1 --userns=keep-id --network=host -it ${options} etax_zug:latest ${command}"
  eval "podman run --rm --name etax_zug --hostname etax-zug --add-host=etax-zug:127.0.0.1 --userns=keep-id --network=host -it ${options} etax_zug:latest ${command}"
fi
