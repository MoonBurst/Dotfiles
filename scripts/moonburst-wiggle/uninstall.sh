#!/usr/bin/env bash
echo Please enter your sudo password if you are prompted to do so.
echo Uninstalling the moonburst-wiggle theme...
sudo update-alternatives --quiet --remove default.plymouth /usr/share/plymouth/themes/moonburst-wiggle/moonburst-wiggle.plymouth
sudo rm -rf /usr/share/plymouth/themes/moonburst-wiggle
echo setting bgrt as the default bootscreensudo plymouth-set-default-theme -R bgrt
echo Done!
echo this should hopefully fix everything back to normal... i hope..echo Have a nice day!