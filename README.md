```
__________.______   ____      .__    .__
\______   |__\   \ /   _____  |  |__ |__|
 |     ___|  |\   Y   /\__  \ |  |  \|  |
 |    |   |  | \     /  / __ \|   Y  |  |
 |____|   |__|  \___/  (____  |___|  |__|
                            \/     \/
```

# PiVahi

PiVahi is a script for automating the deployment of a Raspberry Pi for the purposes of adding Apple Airplay to a car or other automobile. 

## Why use PiVahi?

Traditionally a Raspberry Pi uses a read/write Linux Root Filesystem. This works fine if you have some means of clean shutdown that unmounts the filesystem first such as an interactive UPS or by simply running:
```bash
systemctl poweroff
```
In an environment such as a car, where ignition and therefore power are terminated abruptly, there is no provision for a controlled shutdown unless modifications are made to the car or device being installed.

PiVahi works around this problem by creating a fully read-only filesystem such that abrupt power loss will not destroy the filesystem. This also has the added advantage of extremely fast startup times.
On a Raspberry Pi 3 PiVahi averages a 9 second cold boot time.

## Prerequisites

- A Raspberry Pi 2/3
- A Pi compatible wireless adapter such as [this](http://au.element14.com/element14/wipi/dongle-wifi-usb-for-raspberry/dp/2133900) (If using Pi 2)
- An Ethernet cable for setup (Also for the Pi 2 if not using WiFi)
- A 2Amp (Minimum) micro USB charger
- A keyboard for setup
- An 8GB or larger micro SD card (Class 10)

PiVahi makes assumptions about the target system and as such your Pi should have a clean install of Raspbian on it.

## Getting Started

PiVahi is designed as a single script (dependencies are downloaded as needed) so deployment is as easy as downloading the script and running it.
Your Raspberry Pi will need an internet connection for the duration of the installation and as the wireless hardware will be reconfigured for access point use, it is better to use a cable for setup.

1. Write a fresh copy of Raspbian to your SD card (If your card came with NOOBS pre-loaded, simply select Raspbian (Lite))
    ### Windows
	  1. Download Win32DiskImager from [here](https://sourceforge.net/projects/win32diskimager/)
    2. Download Raspbian Lite from [here](https://downloads.raspberrypi.org/raspbian_lite_latest)
    3. Start Win32DiskImager and choose your SD card drive letter
    4. Click the folder icon and navigate to the downloaded Raspbian image
    5. Click "write" at the bottom of the window
    
    ### *nix (Linux, Mac OS X, macOS)
    1. Download Raspbian Lite from [here](https://downloads.raspberrypi.org/raspbian_lite_latest)
    2. Open a new terminal window
    3. Identify the device node of the SD card with
        - Linux - `lsblk`
        - Mac - `diskutil list`
    4. Change to the directory of your downloaded Raspbian image (below assumes it's in Downloads)
        `cd ~/Downloads`
    5. Write the image to the SD card
        `dd if=(raspbian image name.img) of=/dev/(device node number)`
2. Boot the Raspberry Pi with the new SD card inserted
3. Login with user `pi` and password `raspberry`

At this point you could move on and install PiVahi but it is recommended to configure some settings on the Pi first so that life is easier in the future. Use `sudo raspi-config` to load the setup program and tweak anything you feel is important, any critical settings such as audio ouput or GPU memory split are set by PiVahi.

4. Download a copy of the PiVahi setup script
    ```bash
    cd ~
    curl -sSL https://github.com/agent-squirrel/PiVahi/raw/master/setup.sh > pivahi_setup.sh
    ```
5. Make the script executable
    ```bash
    chmod +x pivahi_setup.sh
    ```
6. At this point you can inspect the code or continue to install with
    ```bash
    sudo ./pivahi_setup.sh
    ```
The install will kick off with a brief banner and explanation followed by a prompt to continue. Answering with 'y' will result in the install process beginning.

If installing on a Pi 2 without wireless hardware, hostapd (The access point server) and dnsmasq (The DHCP server) will not be installed. The installer will ask for confirmation before beginning to ensure this ok.

Once installed and rebooted, connect your iPad/iPhone/iPod to the PiVahi network using password `p1vah1pass` and then in control center choose PiVahi as the audio output device.


# Post-Install

To make changes to the system after installing PiVahi you can login as normal and run the command `rw` to put the file system into read-write mode. Either issue the command `ro` when the changes are complete or simply logout to reset the filesystem state to read-only.

By default the DHCP client service is disabled on PiVahi as this speeds up the boot time considerably and normally the Pi doesn't need an IP as it is designed to be standalone. If you wish to attach the Pi to a network for remote administration purposes over SSH or for other reasons follow the steps below.

  1. Attach a display and keyboard to the Pi
  2. Login as normal
  3. Put PiVahi into read-write mode with `rw`
  4. Enable the dhcpcd service with `sudo systemctl start dhcpcd`
  5. To auto start the service on boot issue the command `sudo systemctl enable dhcpcd`
  6. Set the filesystem back to read-only with `ro`
  7. `exit` 

If shell access is needed but not remotely, the SSH service is enabled by default and can be accessed over the PiVahi wireless network at IP: `172.16.0.1`.


# Features

- Access point broadcasting
- Read-Only filesystem
- Incredibly fast boot time
- Startup chime when fully booted
- Easily switch to read-write mode for quick changes 
- Based on well tested software such as Avahi mDNSResponder and Shairport Airplay Service



## Built With

* [Atom](https://atom.io/) - Advanced Text Editor
* [Bash](https://tiswww.case.edu/php/chet/bash/bashtop.html) - Shell and Script Language


## Authors

* **Adam Heathcote**

## Based On Code and Ideas From:

* [Raspberry-pi-geek](http://www.raspberry-pi-geek.com/Archive/2015/09/Using-the-Raspberry-Pi-as-an-AirPlay-server)
* [Charles' Blog](https://hallard.me/raspberry-pi-read-only/)
* [Frillip](https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/)
* [k3a](http://k3a.me/how-to-make-raspberrypi-truly-read-only-reliable-and-trouble-free/)
