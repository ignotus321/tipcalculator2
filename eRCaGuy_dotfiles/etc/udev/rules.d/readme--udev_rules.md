**This file is part of eRCaGuy_dotfiles: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles**

# udev rules readme

Linux udev (possibly stands for "USB device") rules are the rules which control the access and configuration of USB devices as they are hot-plugged into or removed from a system. 

1. Udev rules should be placed in your Ubuntu "/etc/udev/rules.d" directory. 
2. Each rule ends with ".rules". Other types of files are apparently ignored.
3. Rules are read in alphabetically, with higher priority rules being alphabetically first, so it is common practice to precede rule names with a two-digit number, such as "99-", as a means of alphabetically sorting them to set rule precedence. Again, higher-precedence/more important rules should go first. 

Once you add or update any .rules file, reload the udev rules likes this (source: https://askubuntu.com/questions/1048870/permission-denied-to-non-root-user-for-usb-device/1187646#1187646):

    sudo udevadm control --reload-rules
    sudo udevadm trigger

Then unplug and plug back in the device. 

