#!/bin/bash

echo "Orphan packages:"
pacman -Qdtq
var=$(whoami)
echo -e "\033[1m$var\033[0m \033[32m1.0.0\033[0m"


read -p "Do you want to destroy the child? 
This action can't be undone. (y/n): " answer
if [[ $answer == [Yy] ]]; then
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm
    echo "The orphanage has been burned to the ground. No survivors..."
elif [[ $answer != [Nn] ]]; then
    echo "This was one question long... How did you get this wrong?"
else
    echo "No orphan packages were removed."
fi
