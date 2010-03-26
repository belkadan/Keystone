#!/bin/sh

containing_folder=$(dirname "$(dirname "$(dirname "$(dirname "$0")")")")
SIMBL_folder=$HOME/'Library/Application Support/SIMBL/Plugins'

mkdir -p "$SIMBL_folder"
cp -RPf "$containing_folder/Keystone.bundle" "$SIMBL_folder"
