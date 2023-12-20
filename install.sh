#!/bin/bash

# Specifies which kernel and rogue-enemy version to download
KERNEL_URL="https://github.com/jlobue10/ALLY_Nobara_fixes/releases/download/v2.2.0/kernel-6.6.7-203.fsync.ally.fc38.x86_64.tar.gz"
ROGUE_ENEMY_URL="https://github.com/jlobue10/ALLY_Nobara_fixes/releases/download/v2.2.0/rogue-enemy-1.5.1-1.fc38.x86_64.rpm"
KERNEL_FILE="${KERNEL_URL##*/}"
KERNEL_NAME="${KERNEL_FILE%.tar.gz}"
ROGUE_ENEMY_FILE="${ROGUE_ENEMY_URL##*/}"

# Obtain elevated priviledges
password=$(kdialog --password "Enter your sudo password")

if [ -z "$password" ]; then
    kdialog --error "No password entered. Exiting."
    exit 1
fi

# Pass the password to sudo -v
echo "$password" | sudo -Sv

# Check if the password was correct
if [ $? -eq 0 ]; then
    kdialog --msgbox "Sudo authenticated successfully."
else
    kdialog --error "Sudo authentication failed."
fi

# Optional install of auto-cpu freq set variable
echo "EXPERIMENTAL: DISABLE POWER CONTROL IF USING THIS, IT WILL CAUSE ISSUES!"
echo "If you do not know whether to install this or not, please select N, this is for advanced users."
echo " "
echo "wo you want to install auto-cpu freq? This tool will override certain controls associated with Power Control."
echo "wf you enable this tool, please do not adjust any of the Power Control specific settings in Decky Loader."
echo "we still install Power Control as this unlocks the full TDP slider in GameScope which you CAN still use, however,"
echo "it is highly recommended to NOT install this package if you intend to use Power Control"
read -p "Do you want to install this package? (y/n): " auto_cpu_freq

# Change to Downloads directory
cd ~/Downloads

# Download files using wget
wget $KERNEL_URL --content-disposition
wget $ROGUE_ENEMY_URL --content-disposition

# Extract tar.gz file
tar xvf $KERNEL_FILE

# Update Rogue Enemy
sudo rpm -e rogue-enemy
sudo dnf install --assumeyes ~/Downloads/$ROGUE_ENEMY_FILE

# Change into RPM directory and install RPMs
cd RPM
sudo dnf install -y *.rpm

# Clean up file
cd ~/Downloads
rm -rf RPM
rm $KERNEL_FILE
rm $ROGUE_ENEMY_FILE

# Install asusctl package
sudo dnf install -y asusctl 

# Install decky loader
curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh

# Install mengmeet's Power Control plugin
curl -L https://raw.githubusercontent.com/mengmeet/PowerControl/main/install.sh | sh

# Remove rogue-enemy.service and re-create with ExecStartPre sleep of 10 seconds
sudo rm /etc/systemd/system/rogue-enemy.service

sudo bash -c 'cat << 'EOF' > /etc/systemd/system/rogue-enemy.service
[Unit]
Description=ROGueENEMY service

[Service]
Type=simple
Nice=-5
IOSchedulingClass=best-effort
IOSchedulingPriority=0
Restart=always
RestartSec=5
WorkingDirectory=/usr/bin
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/rogue-enemy

[Install]
WantedBy=multi-user.target
EOF'

# Check the user input for auto-cpu freq install
if [[ $auto_cpu_freq == "y" || $auto_cpu_freq == "Y" ]]; then
    cd ~/Downloads
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && sudo ./auto-cpufreq-installer
    rm ~/Downloads/auto-cpufreq
fi

# Wifi speed improvement
echo "@nClientDownloadEnableHTTP2PlatformLinux 0" | sudo tee -a ~/.steam/steam/steam_dev.cfg > /dev/null
echo "@fDownloadRateImprovementToAddAnotherConnection 1.0" | sudo tee -a ~/.steam/steam/steam_dev.cfg > /dev/null

# Set grub order to second kernel as the curren Nobara installation uses 1 version newer than patched kernel
sudo awk 'NR==1 {$0="GRUB_DEFAULT=1"} {print}' /etc/default/grub > temp_file && sudo mv temp_file /etc/default/grub
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

# Reboot the system
read -p "Are you ready to reboot your Ally? (y/n): " ready_reboot
if [[ $ready_reboot == "y" || $ready_reboot == "Y" ]]; then
    reboot
fi