#!/bin/bash

set -euxo pipefail

#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]-[$kiwi_profiles]..."

#======================================
# Enable CRB repo by default
#--------------------------------------
dnf --assumeyes config-manager --set-enabled crb

#======================================
# Set SELinux booleans
#--------------------------------------
## Fixes KDE Plasma, see rhbz#2058657
setsebool -P selinuxuser_execmod 1

#======================================
# Clear machine specific configuration
#--------------------------------------
## Force generic hostname
echo "localhost" > /etc/hostname
## Clear machine-id on pre generated images
truncate -s 0 /etc/machine-id

#======================================
# Configure grub correctly
#--------------------------------------
## Works around issues with grub-bls
## See: https://github.com/OSInside/kiwi/issues/2198
echo "GRUB_DEFAULT=saved" >> /etc/default/grub

#======================================
# Delete & lock the root user password
#--------------------------------------
if [[ "$kiwi_profiles" == *"AWS"* ]] || [[ "$kiwi_profiles" == *"Azure"* ]] || [[ "$kiwi_profiles" == *"OpenStack"* ]] || [[ "$kiwi_profiles" == *"Live"* ]]; then
	passwd -d root
	passwd -l root
fi

#======================================
# Setup default services
#--------------------------------------

if [[ "$kiwi_profiles" == *"AWS"* ]] || [[ "$kiwi_profiles" == *"Azure"* ]] || [[ "$kiwi_profiles" == *"OpenStack"* ]]; then
	## Enable cloud-init
	systemctl enable cloud-config.service cloud-final.service cloud-init.service cloud-init-local.service cloud-init.target
fi

if [[ "$kiwi_profiles" == *"Azure"* ]]; then
	## Enable Azure service
	systemctl enable waagent.service
fi

if [[ "$kiwi_profiles" == *"Live"* ]]; then
	## Enable livesys services
	systemctl enable livesys.service livesys-late.service
	if [[ "$kiwi_profiles" == *"GNOME"* ]]; then
		echo 'livesys_session="gnome"' > /etc/sysconfig/livesys
	fi
	if [[ "$kiwi_profiles" == *"KDE"* ]]; then
		echo 'livesys_session="kde"' > /etc/sysconfig/livesys
	fi
fi

## Enable chrony
systemctl enable chronyd.service
## Enable oomd
systemctl enable systemd-oomd.service
## Enable resolved
systemctl enable systemd-resolved.service
## Enable persistent journal
mkdir -p /var/log/journal

#======================================
# Setup default target
#--------------------------------------
if [[ "$kiwi_profiles" == *"GNOME"* ]] || [[ "$kiwi_profiles" == *"KDE"* ]]; then
	systemctl set-default graphical.target
else
	systemctl set-default multi-user.target
fi

exit 0
