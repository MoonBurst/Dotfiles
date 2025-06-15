#!/bin/bash

# Variables
NEXTCLOUD_USERNAME="MoonBurst"
NEXTCLOUD_PASSWORD="MoonIsBullyable:3"
NEXTCLOUD_URL="https://cloud.valeindustries.net/"


FOLDER_TO_UPLOAD1="$HOME/scripts2"

# Run nextcloudcmd to upload the folder
nextcloudcmd -u "$NEXTCLOUD_USERNAME" -p "$NEXTCLOUD_PASSWORD" "$FOLDER_TO_UPLOAD1" "$NEXTCLOUD_URL"

