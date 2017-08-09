#!/bin/bash

#Check for super user
if [ "$EUID" -ne 0 ]
  then echo 'This script can only be run as the super user.
Try rerunning with sudo.'
[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

clear
#Begin environment setup.
apd=yes
wifihw=""
release=""
distro=""

release=$(cat /etc/*release | grep NAME)
if [[ $release == *Debian* ]] || [[ $release == *Raspbian* ]]; then
  distro=Debian
else
  distro=Other
fi

echo '###################################################################
#                                                                 #
#                                                                 #
#                                                                 #
#          __________.______   ____      .__    .__               #
#          \______   |__\   \ /   _____  |  |__ |__|              #
#           |     ___|  |\   Y   /\__  \ |  |  \|  |              #
#           |    |   |  | \     /  / __ \|   Y  |  |              #
#           |____|   |__|  \___/  (____  |___|  |__|              #
#                                      \/     \/                  #
#                                                                 #
#                    Welcome to PiVahi                            #
#                                                                 #
#  This script is intended as a fast and easy way to configure a  #
#  Raspberry Pi SBC as a standalone Airplay compatible receiver   #
#  for use in a car or other automobile.                          #
#  This script will also work for those who just need an Airplay  #
#  compatible standalone receiver to attach to a speaker system.  #
###################################################################'
echo
echo                  Operating System: $distro
echo
if [[ $distro != Debian ]]; then
  echo "This script can only run on Debian and it's derivatives."
  [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi
read -p "Shall we begin?" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi
echo
echo 'Checking for Wireless Hardware'
echo
wifihw=$(ls /sys/class/net | grep -e wlan -e wlp)
if [[ $wifihw == "" ]]; then
  echo '  Looks like you have no wireless hardware installed.
  Installation can continue but this Pi will need to
  be cabled in to a network.'
  echo
  read -p "Would you like to keep going?" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
  fi
  echo
  echo
  echo '  Continuing without access point services (hostapd, dnsmasq).'
  apd=no
fi
echo
echo 'Setting Raspberry Pi parameters.'
echo 'gpu_mem=16' >> /boot/config.txt
rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf
mkdir /etc/sounds
wget -q https://theway.duckdns.org/repo/pivahi/beep.mp3 -P /etc/sounds/
sed -i.bak '0,/^exit.*/s-^exit.*-mpg123 /etc/sounds/beep.mp3\n&-' /etc/rc.local
sed -i.bak 's/^BLANK_TIME=.*/BLANK_TIME=0/' /etc/kbd/config
sed -i.bak 's/^POWERDOWN_TIME=.*/POWERDOWN_TIME=0/' /etc/kbd/config
systemctl restart kbd
echo
echo 'Enabling SSH.'
{ systemctl start ssh; systemctl enable ssh; } > /dev/null 2>&1 &
pid=$!
while kill -0 $pid > /dev/null 2>&1
do
  echo -n "."
  sleep 1
done
echo
echo
echo 'Setting system hostname.'
echo 'pivahi' > /etc/hostname
sed -i.bak 's/raspberrypi/pivahi/' /etc/hosts
echo
echo 'Configuring MOTD.'
rm -f /etc/motd
cat <<EOT >> /etc/motd

__________.______   ____      .__    .__
\______   |__\   \ /   _____  |  |__ |__|
 |     ___|  |\   Y   /\__  \ |  |  \|  |
 |    |   |  | \     /  / __ \|   Y  |  |
 |____|   |__|  \___/  (____  |___|  |__|
                            \/     \/

PiVahi uses a read-only filesystem.
To make changes use the command 'rw'
'ro' will set the filesystem back to
read-only.

EOT
echo
echo 'Attempting to update all packages (this can take some time).'
{ apt-get -y update; apt-get -y upgrade; } >/tmp/pivahi-apt-get.log 2>&1 &
pid=$!
while kill -0 $pid > /dev/null 2>&1
do
  echo -n "."
  sleep 1
done
echo
echo
echo 'Update complete.'
echo
echo 'Removing unneeded packages.'
{ apt-get -y remove --purge wolfram-engine triggerhappy anacron logrotate dphys-swapfile xserver-common lightdm; dpkg --purge rsyslog; } >/tmp/pivahi-apt-get.log 2>&1 &
pid=$!
while kill -0 $pid > /dev/null 2>&1
do
  echo -n "."
  sleep 1
done
{ insserv -r x11-common; apt-get -y autoremove --purge; } >/tmp/pivahi-apt-get.log 2>&1 &
pid=$!
while kill -0 $pid > /dev/null 2>&1
do
  echo -n "."
  sleep 1
done
echo
echo
echo 'Remove complete.'
echo
echo 'Installing needed packages.'
apt-get -y install git make mpg123 wget build-essential busybox-syslogd libssl-dev libavahi-client-dev libasound2-dev avahi-daemon vim >/tmp/pivahi-apt-get.log 2>&1 &
pid=$!
while kill -0 $pid > /dev/null 2>&1
do
  echo -n "."
  sleep 1
done
echo
echo
if [[ $apd == yes ]]; then
  echo 'Installing access point services.'
  apt-get -y install dnsmasq hostapd >/tmp/pivahi-apt-get.log 2>&1 &
  pid=$!
  while kill -0 $pid > /dev/null 2>&1
  do
    echo -n "."
    sleep 1
  done
fi
echo
echo 'Install complete.'
echo
echo
echo '######## Begin Shairport Setup ########'
echo
echo 'Adding PiVahi user.'
useradd -M pivahi -s /bin/false -g audio
echo
cd /tmp
echo 'Cloning Shairport from Github.'
git clone https://github.com/abrasive/shairport.git
cd shairport
echo
echo 'Compiling Shairport.'
{ ./configure && make && make install; } > /dev/null 2>&1 &
pid=$!
while kill -0 $pid > /dev/null 2>&1
do
  echo -n "."
  sleep 1
done
echo
echo 'Configuring Shairport.'
cp scripts/debian/init.d/shairport /etc/init.d/
cp scripts/debian/default/shairport /etc/default/
sed -i.bak 's/#USER=shairport/USER=pivahi/' /etc/default/shairport
sed -i.bak 's/#GROUP=audio/GROUP=nogroup/' /etc/default/shairport
sed -i.bak 's/#AP_NAME=/AP_NAME=PiVahi/' /etc/default/shairport
sed -i.bak 's/# MDNS=avahi/MDNS=avahi/' /etc/default/shairport
echo
echo 'Enabling Shairport.'
{ update-rc.d shairport defaults; service shairport start; } > /dev/null 2>&1 &
pid=$!
while kill -0 $pid > /dev/null 2>&1
do
  echo -n "."
  sleep 1
done
echo
echo 'Setting volume to maximum.'
amixer sset 'PCM' 100%
amixer cset numid=3 1
alsactl store
echo
echo '######## End Shairport Setup ########'
echo
if [[ $wifihw != "" ]]; then
  echo '######## Begin Access Point Setup ########'
  echo
  echo 'Statically assigning IP to wireless interface.'
  echo 'denyinterfaces' $wifihw >> /etc/dhcpcd.conf
  sed -i.bak "/$wifihw/d" /etc/network/interfaces
  cat <<EOT >> /etc/network/interfaces
  allow-hotplug $wifihw
  iface $wifihw inet static
    address 172.16.1.1
    netmask 255.255.255.0
    network 172.16.1.0
    broadcast 172.16.1.255
    # wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOT
  echo
  echo 'Configuring hostapd.'
  cat <<EOT >> /etc/hostapd/hostapd.conf
  # Interface Name
  interface=$wifihw
  # Use the nl80211 driver with the brcmfmac driver
  driver=nl80211
  # Network Name
  ssid=PiVahi
  # Use the 2.4GHz band
  hw_mode=g
  # Use channel 6
  channel=6
  # Enable 802.11n
  ieee80211n=1
  # Enable WMM
  wmm_enabled=1
  # Enable 40MHz channels with 20ns guard interval
  ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
  # Accept all MAC addresses
  macaddr_acl=0
  # Use WPA authentication
  auth_algs=1
  ignore_broadcast_ssid=0
  # Use WPA2
  wpa=2
  # Use a pre-shared key
  wpa_key_mgmt=WPA-PSK
  # The network passphrase
  wpa_passphrase=p1vah1pass
  # Use AES, instead of TKIP
  rsn_pairwise=CCMP
EOT
  sed -i.bak 's-^#DAEMON_CONF .*$-DAEMON_CONF="/etc/hostapd/hostapd.conf"-' /etc/default/hostapd
  echo
  echo 'Configuring DHCP Server.'
  mv /etc/dnsmasq.conf /etc/dnsmasq.conf
  echo "" > /etc/dnsmasq.conf
  cat <<EOT >> /etc/hostapd/hostapd.conf
  interface=$wifihw
  listen-address=172.16.1.1
  bind-interfaces
  server=127.0.0.1
  bogus-priv
  dhcp-range=172.16.1.50,172.16.1.150,12h
  dhcp-option=3
EOT
  sed -i.bak 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
  echo
  echo 'Starting services.'
  { systemctl start dnsmasq; systemctl enable dnsmasq; systemctl start hostapd; systemctl enable hostapd; } > /dev/null 2>&1 &
  pid=$!
  while kill -0 $pid > /dev/null 2>&1
  do
    echo -n "."
    sleep 1
  done
  echo
  echo 'Disabling DHCP Client'
  { systemctl stop dhcpcd; systemctl disable dhcpcd; } > /dev/null 2>&1 &
  pid=$!
  while kill -0 $pid > /dev/null 2>&1
  do
    echo -n "."
    sleep 1
  done
  echo
  echo '######## End Access Point Setup ########'
fi
echo
echo '######## Begin Read-Only FS Setup ########'
echo
echo 'Disabling swap and filesystem checks.'
sed -i.bak '1s/$/ fastboot noswap ro consoleblank=0/' /boot/cmdline.txt
echo
echo
echo 'Moving dhcp, run, spool, and lock to a temporary filesystem.'
rm -rf /var/lib/dhcp/ /var/run /var/spool /var/lock /etc/resolv.conf
ln -s /tmp /var/lib/dhcp
ln -s /tmp /var/run
ln -s /tmp /var/spool
ln -s /tmp /var/lock
touch /tmp/dhcpcd.resolv.conf; ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf
echo
echo
echo "Moving dhcpcd lock file location."
sed -i.bak -e 's-/run/-/var/run/-g' /etc/systemd/system/dhcpcd5
echo
echo
echo 'Moving random-seed location.'
rm /var/lib/systemd/random-seed
ln -s /tmp/random-seed /var/lib/systemd/random-seed
sed -i '/RemainAfterExit=yes/a ExecStartPre=/bin/echo "" > /tmp/random-seed' /lib/systemd/system/systemd-random-seed.service
echo
echo
echo 'Reloading systemd.'
systemctl daemon-reload &
pid=$!
while kill -0 $pid > /dev/null 2>&1
do
  echo -n "."
  sleep 1
done
echo
echo
echo 'Moving ntp driftfile location.'
sed -i.bak 's-^driftfile .*$-driftfile /var/tmp/ntp.drift-' /etc/ntp.conf
echo
echo
echo 'Removing startup scripts.'
insserv -r bootlogs; insserv -r console-setup
echo
echo
echo 'Modifiying file system table.'
sed -i.bak 's-.*/boot.*-/dev/mmcblk0p1  /boot           vfat    defaults,ro          0       2-' /etc/fstab
sed -i.bak 's-.*noatime.*-/dev/mmcblk0p2  /             ext4    defaults,noatime,ro          0       1-' /etc/fstab
cat <<EOT >> /etc/fstab
# For Debian
tmpfs           /tmp            tmpfs   nosuid,nodev         0       0
tmpfs           /var/log        tmpfs   nosuid,nodev         0       0
tmpfs           /var/tmp        tmpfs   nosuid,nodev         0       0
EOT
echo
echo
echo 'Configuring bashrc.'
cat <<"EOT" >> /etc/bash.bashrc
# set variable identifying the filesystem you work in (used in the prompt below)
set_bash_prompt(){
    fs_mode=$(mount | sed -n -e "s/^\/dev\/.* on \/ .*(\(r[w|o]\).*/\1/p")
    PS1='\[\033[01;32m\]\u@\h${fs_mode:+($fs_mode)}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

alias ro='sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot ; "Now in Read-Only Mode"'
alias rw='sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot ; "Caution! Now in Read-Write Mode!"'

# setup fancy prompt
PROMPT_COMMAND=set_bash_prompt
EOT
echo
echo
echo 'Creating bash_logout.'
cat <<EOT >> /etc/bash.bash_logout
sudo mount -o remount,rw /
history -a
sudo fake-hwclock save
sudo mount -o remount,ro /
sudo mount -o remount,ro /boot
EOT
echo
echo
echo 'Setting kernel panic reboot interval to 5 seconds.'
echo 'kernel.panic = 5' >> /etc/sysctl.conf
echo
echo
echo '######## End Read-Only FS Setup ########'
echo
echo
echo
echo
echo "Looks like you're all set!"
echo
echo '------------------------------------------'
if [[ $wifihw != "" ]]; then
  echo 'Network Name: PiVahi'
  echo 'Network Pass: p1vah1pass'
fi
echo 'Airplay Name: PiVahi'
echo
echo '------------------------------------------'
echo
read -p "Press enter to reboot"
reboot
exit
