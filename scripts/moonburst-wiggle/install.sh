#!/bin/bash
echo Please enter your sudo password if you are prompted to do so.
echo Installing the moonburst-wiggle theme...
sudo mkdir /usr/share/plymouth/themes/moonburst-wiggle
sudo cp -rf ./ /usr/share/plymouth/themes/moonburst-wiggle
sudo plymouth-set-default-theme -R /usr/share/plymouth/themes/moonburst-wiggle
echo Done!
echo Done!
echo Reboot your system to see the changes... hopefully...echo Have a nice day!