#!/bin/bash

set -e

ETAX_DIR=`pwd`/etax
TAX_FILES_DIR=`pwd`/tax_files

mkdir -p $ETAX_DIR
mkdir -p $TAX_FILES_DIR
docker run -u 1000:1000 --rm --name etax_zug --hostname etax-zug \
                             -e HOME \
                             -e TIME_ZONE=Zurich \
                             -e DISPLAY=unix:0 \
                             -e XAUTHORITY=/tmp/xauth \
                             -v $XAUTHORITY:/tmp/xauth \
                             -v $TAX_FILES_DIR:/home/taxpayer/Steuerfaelle \
                             -v $ETAX_DIR:/home/taxpayer/etax_zug \
                             -v /tmp/.X11-unix:/tmp/.X11-unix etax_zug:latest
