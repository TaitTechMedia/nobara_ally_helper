#!/bin/bash

# Specifies which kernel and rogue-enemy version to download
KERNEL_FILE="kernel-6.6.7-202.fsync.ally.fc38.x86_64.tar.gz"
KERNEL_URL="https://github.com/jlobue10/ALLY_Nobara_fixes/releases/download/v2.2.0/kernel-6.6.7-202.fsync.ally.fc38.x86_64.tar.gz"
ROGUE_ENEMY_FILE="rogue-enemy-1.5.1-1.fc38.x86_64.rpm"
ROGUE_ENEMY_URL="https://github.com/jlobue10/ALLY_Nobara_fixes/releases/download/v2.2.0/rogue-enemy-1.5.1-1.fc38.x86_64.rpm"

# Obtain elevated priviledges
sudo -v

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

# Disable udev rule for generic xbox controller by adding .backup, can simply remove this to re-enable - /etc/udev/rules.d/50-generic-xbox360-controller.rules
sudo mv /etc/udev/rules.d/50-generic-xbox360-controller.rules /etc/udev/rules.d/50-generic-xbox360-controller.rules.backup

# Add new rule to completely block xbox controllers - /etc/udev/rules.d/49-xbox-blocker.rules
echo 'ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="028e", RUN+="/bin/sh -c '\''echo 0 >/sys/$devpath/authorized'\''"' > /etc/udev/rules.d/49-xbox-blocker.rules

# Remove rogue-enemy.service and re-create with ExecStartPre sleep of 10 seconds
sudo rm /etc/systemd/system/rogue-enemy.service

cat << 'EOF' > /etc/systemd/system/rogue-enemy.service
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
EOF

# Reboot the system
reboot
