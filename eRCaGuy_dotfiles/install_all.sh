#!/bin/bash

# Author: Gabriel Staples

# This file is part of eRCaGuy_dotfiles: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles

# Install all scripts!
# - Edit this file manually, as desired, if you only want to install some scripts. 
# - Just comment out what you don't want to install.

# Goal: Have this script automatically install (by creating symlinks in ~/bin) all scripts herein!
# For the sake of making it super easy to find all custom scripts, prepend each symbolic link in ~/bin with 
# the user's initials, like this: "gs_myscript".

# Optional: this will be prepended to every symbolic link created in ~/bin in order to make it super easy to 
# find all of your custom scripts. I recommend you set it to your initials, followed by an underscore. Set it
# to "" to not prepend anything.
CMD_PREFIX="gs_" # set to your initials
# CMD_PREFIX="" # or use this one to use nothing

# See my own ans here: https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself/60157372#60157372
THIS_PATH="$(realpath "$0")"
echo "Full path to this install script = \"$THIS_PATH\""
THIS_DIR="$(dirname "$THIS_PATH")"
# echo "THIS_DIR = \"$THIS_DIR\"" # for debugging 

mkdir -p ~/bin
cd "$THIS_DIR"

echo ""
echo "= Installing eRCaGuy_dotfiles. ="

echo "-----------------------------------------------------------------------------------------"
echo "Beginning installation. All copy ('cp -i') and symbolic link ('ln -si') calls herein are"
echo "interactive (hence the '-i' option), which means if the file already exists in the"
echo "destination it will *ask you* if you'd like to overwrite it! When it asks if you'd like"
echo "to \"overwrite\" or \"replace\" a file, simply pressing Enter will default to \"No\","
echo "which is the safe option to take. To overwrite these files in the destination, simply"
echo "type in \"y\" or \"yes\"."
echo "-----------------------------------------------------------------------------------------"

echo "sudo apt update"
sudo apt update 

# In alphabetical order by folder name

# arduino
echo ""
echo "= Arduino stuff ="
echo "See \"arduino/readme--arduino.md\""
echo "Adding user to \"dialout\" group."
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "***If this is your first time running this script, please log out and log back in afterwards"
echo "  for this to take effect.***"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
sudo usermod -a -G dialout $USERNAME
echo "Adding USBasp udev rules."
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "***When done, unplug and plug back in any USBasp programmer, if applicable.***"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
sudo cp -i etc/udev/rules.d/99-USBasp.rules /etc/udev/rules.d
sudo udevadm control --reload-rules
sudo udevadm trigger

# Desktop_launchers
echo ""
echo "= Desktop_launchers stuff ="

echo "1. Copying \"Desktop_launchers\" files to ~/Desktop_launchers"
mkdir -p ~/Desktop_launchers
cp -i Desktop_launchers/*.desktop ~/Desktop_launchers
cp -i Desktop_launchers/*.md ~/Desktop_launchers
echo "Installing \"desktop_file_install\" & \"desktop_file_uninstall\" scripts"
ln -si "${PWD}/Desktop_launchers/desktop_file_install.sh" ~/bin/${CMD_PREFIX}desktop_file_install
ln -si "${PWD}/Desktop_launchers/desktop_file_uninstall.sh" ~/bin/${CMD_PREFIX}desktop_file_uninstall

echo "2. Installing select launchers"
echo "  - open_programming_tools.desktop"
# Use `sed` for string replacement in files; see:
# 1. Basic format: 
#    https://superuser.com/questions/723441/how-to-replace-line-in-file-with-pattern-with-sed/1012877#1012877
# 2. Use a different delimiter (such as `|`), when "/" is part of the string you are replacing:
#    https://unix.stackexchange.com/questions/259083/replace-unix-path-inside-a-file/259087#259087
# 3. You absolutely *must* use a different delimiter when "/" is part of the string you are replacing, 
#    or else sed will fail with "unknown option to `s'" error:
#    https://stackoverflow.com/questions/9366816/sed-fails-with-unknown-option-to-s-error/9366940#9366940
# Replace path for my username in this .desktop file with proper path for your username:
OPEN_PROG_TOOLS_PATH="$HOME/bin/${CMD_PREFIX}open_programming_tools"
# Replace a line in the .desktop file
echo "  Replacing the \"Exec=\" line in \"~/Desktop_launchers/open_programming_tools.desktop\""
sed -i "s|Exec=.*|Exec=${OPEN_PROG_TOOLS_PATH}|" ~/Desktop_launchers/open_programming_tools.desktop
${CMD_PREFIX}desktop_file_install ~/Desktop_launchers/open_programming_tools.desktop
echo "  - eclipse.desktop"
# Replace two lines in the .desktop file
echo "  Replacing the \"Exec=\" and \"Icon=\" lines in \"~/Desktop_launchers/eclipse.desktop\""
sed -i "s|Exec=.*|Exec=$HOME/eclipse/cpp-2019-12/eclipse/eclipse|" ~/Desktop_launchers/eclipse.desktop
sed -i "s|Icon=.*|Icon=$HOME/eclipse/cpp-2019-12/eclipse/icon.xpm|" ~/Desktop_launchers/eclipse.desktop
${CMD_PREFIX}desktop_file_install ~/Desktop_launchers/eclipse.desktop
echo "  - show-desktop.desktop"
echo "  sudo apt install xdotool"
sudo apt install xdotool
${CMD_PREFIX}desktop_file_install ~/Desktop_launchers/show-desktop.desktop

# eclipse
echo ""
echo "= eclipse stuff ="
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "***Do it manually***"
echo "Esp. see the \"eclipse\" folder as well as the detailed instructions in this PDF:"
echo "  \"eclipse/Eclipse setup instructions on a new Linux (or other OS) computer.pdf\""
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

# /etc folder
echo ""
echo "= /etc folder stuff ="
echo "The Arduino USBasp stuff was already done above."
echo "See also \"etc/udev/rules.d/readme--udev_rules.md\" for more info."

# git
echo ""
echo "= git stuff ="
echo "This will mostly be done in the \"home\" folder install below."
echo "Installing meld so you can use it as your 'git difftool'"
sudo apt install meld
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "***For anything else, do it manually.***"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

# home
echo ""
echo "= home folder (\"$HOME\") stuff ="
echo "Interactively copying everything inside the \"eRCaGuy_dotfiles/home\" dir to your home dir (\"$HOME\")."
echo "CAUTION: BE CAREFUL HERE *NOT* TO OVERWRITE ANY FILES IN YOUR HOME DIRECTORY THAT YOU DON'T WANT TO!"
# For the `cp` dot (folder/.) syntax used here, see: 
# https://askubuntu.com/questions/86822/how-can-i-copy-the-contents-of-a-folder-to-another-folder-in-a-different-directo/86824#86824
cp -ri home/. ~
echo "sudo apt install imwheel"
sudo apt install imwheel # For ~/.imwheelrc
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo -e "***Don't forget to manually update*** ~/.bashrc, ~/.gitconfig with your ***name*** and ***email***,\n"\
"~/.imwheelrc, ~/.sync_git_repo, etc."
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

# NoMachine
echo ""
echo "= NoMachine stuff ="
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "***Do it manually***"
echo "See: \"NoMachine/readme--NoMachine.md\""
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

# rsync
echo ""
echo "= rsync stuff ="
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "For sample usage, see my answers here:"
echo "https://superuser.com/questions/1271882/convert-ntfs-partition-to-ext4-how-to-copy-the-data/1464264#1464264"
echo "and here: https://unix.stackexchange.com/questions/65077/is-it-possible-to-see-cp-speed-and-percent-copied/567828#567828"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

# segger programmer
echo ""
echo "= Segger JTAG/SWD microcontroller/microprocessor programmer ="
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "***Do it manually***"
echo "See my answer here: https://stackoverflow.com/questions/57307738/is-there-anybody-using-keil-mdk-on-linux-through-wine/57313990#57313990"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

# Sublime Text 3 editor
echo ""
echo "= Sublime Text 3 editor ="
echo "Copying editor preferences file"
echo "Note: the \".git_editor.sublime-project\" file was previously copied to your home dir above."
SUBLIME_SETTINGS_PATH="$HOME/.config/sublime-text-3/Packages/User/Preferences.sublime-settings"
echo "Copying the \"Preferences.sublime-settings\" file to \"$SUBLIME_SETTINGS_PATH\""
cp -i Sublime_Text_editor/Preferences.sublime-settings "$SUBLIME_SETTINGS_PATH"

# Templates
echo ""
echo "= Templates stuff ="
echo "Copying \"Templates\" files to ~/Templates"
cp -ri Templates ~

# tmux
echo ""
echo "= tmux stuff ="
echo "The \".tmux.conf\" file was previously copied to your home dir above."

# useful_scripts
echo ""
echo "= useful_scripts stuff ="
echo "Here are the scripts this dir (\"$THIS_DIR/useful_scripts\") contains:"
tree useful_scripts
echo "Creating symbolic links for apt-cacher-server_proxy script."
ln -si "${PWD}/useful_scripts/apt-cacher-server_proxy_status.sh" ~/bin/${CMD_PREFIX}apt-cacher-status
ln -si "${PWD}/useful_scripts/apt-cacher-server_proxy_toggle.sh" ~/bin/${CMD_PREFIX}apt-cacher-toggle
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "Copying \"open_programming_tools\" script to ~/bin."
echo "***Go there and manually update this script when done!***"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
cp -i useful_scripts/open_programming_tools.sh "$OPEN_PROG_TOOLS_PATH"
echo "Symbolically linking \"sync_git_repo_from_pc1_to_pc2\" script to ~/bin"
ln -si "${PWD}/useful_scripts/sync_git_repo_from_pc1_to_pc2.sh" ~/bin/${CMD_PREFIX}sync_git_repo_from_pc1_to_pc2
echo "Symbolically linking \"tmux-session\" script to ~/bin"
echo "  Typical usage is 'tmux-session save' and 'tmux-session restore'."
echo "  Read more here: https://superuser.com/questions/440015/restore-tmux-session-after-reboot/615716#615716"
echo "  and here: https://github.com/mislav/dotfiles/blob/d2af5900fce38238d1202aa43e7332b20add6205/bin/tmux-session"
ln -si "${PWD}/useful_scripts/tmux-session.sh" ~/bin/${CMD_PREFIX}tmux-session
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
echo "Copying \"touchpad_toggle\" script to ~bin"
echo "***Go there and manually update this script when done! See the \"USER INPUTS\" section of the script.***"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
cp -i useful_scripts/touchpad_toggle.sh ~/bin/${CMD_PREFIX}touchpad_toggle

echo ""
echo "END of \"install_all.sh\" eRCaGuy_dotfiles installation script."




