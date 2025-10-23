#!/usr/bin/env bash

# Update ClamAV
echo "Updating ClamAV..."
freshclam

# Check if the update was successful
if [ $? -ne 0 ]; then
    echo "Failed to update ClamAV. Aborting scan."
    exit 1
fi

# Check if the location argument is provided
if [ -z "$1" ]; then
    echo "Please provide a directory to scan."
    exit 1
fi

# Run the virus scan using ClamAV
echo "Initiating virus scan..."
clamscan -r "$1"

# Check the scan results
if [ $? -eq 0 ]; then
    echo "No infected files found."
else
    echo "Infected files were found. Please review the scan results."
fi
