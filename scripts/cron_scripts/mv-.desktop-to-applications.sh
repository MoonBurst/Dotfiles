#!/bin/bash

# Move .desktop files from home directory to ~/.local/share/applications
find ~ -maxdepth 1 -name "*.desktop" -type f -exec mv {} ~/.local/share/applications/ \;
