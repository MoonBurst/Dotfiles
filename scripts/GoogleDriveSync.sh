#!/bin/bash

/usr/bin/rclone sync --bwlimit 500 --update --verbose --transfers 1 --checkers 8 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --stats 1s "/mnt/WindowsFiles/Google Drive" "GoogleDrive:"
