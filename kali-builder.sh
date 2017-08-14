#!/bin/bash
#
# Kali-installer
VERSION="1.9.8.1"

# Kali Version
KALI="kali-rolling"

# Release Notes:
# This script installs additional tools that I like to have available.
# 1.9.8.1 - Fixed Fluxion repo
# 1.9.8 -   Removed Kate and yakuake. Added gnome-applets, gnome-screensaver, and gnome-shell-extension-pixelsaver
# 1.9.7.1 - Added terminaltables requirements for RTFM DB
# 1.9.7 -   Added RTFM DB by leostat
# 1.9.6 -   Added gnome-wallpaper-changer to "media" apps
# 1.9.5 -   Added EAPHammer
# 1.9.4 -   Added terminator
# 1.9.3 -   Added alacarte to edit menu items
# 1.9.2 -   Re-enabled ipv6 (too buggy) and added libreoffice
# 1.9.1 -   Added MailSniper
# 1.9   -   Added HoneySAP, SAP plugin for wireshark and impacket (great for honeypotting SMB shares)
# 1.8   -   Added konsole and tor-browser-bundle
# 1.7   -   Added package update and upgrade before installing stuffs
# 1.6   -   Added gpsd and fruitywifi (fixed GPSd by disabling localhost ipv6 binding since we disable ipv6 later on)
# 1.5   -   Added MorphAES and removed fruitywifi (for now)
# 1.4   -   Added Fruitywifi
# 1.3   -   Fixed VirtualBox and vbox notes and added handbrake instead of dvdrip
# 1.2   -   Added xdotool to support the media keys extension for gnome
# 1.1   -   Reworked flow, added choices
# 1.0   -   Ported Kubuntu-installer to Kali-Builder

# This is the folder where testing scripts and tools will be put. 
# Use /opt for a multi-user deployment
PROGRAMDIR="/opt"

#Programs to install
MEDIA_PROGRAMS="
vlc
browser-plugin-vlc
devede
acetoneiso
mplayer
smplayer
kodi
krename
kid3
rtorrent
ktorrent
xdotool
kodi
handbrake
"
SECURITY_PROGRAMS="
iodine
corkscrew
motion
bettercap
"
UTILITY_PROGRAMS="
network-manager-openvpn-gnome 
network-manager-pptp 
network-manager-pptp-gnome 
network-manager-strongswan 
network-manager-vpnc 
network-manager-vpnc-gnome
gnome-applets
gnome-screensaver
gnome-shell-extension-pixelsaver
docker
speedtest-cli
fail2ban
screen
terminator
build-essential
linux-headers-amd64
curl
libgconf2-4
cups-pdf
mc
sysstat
iftop
htop
sshfs
autofs
autossh
mtr
cifs-utils
exfat-utils
konsole
x2x
x2vnc
heirloom-mailx
aptitude
recoll
antiword
catdoc
xpdf
filelight
xrdp
tofrodos
pkg-config
software-properties-common
gnome-shell-extensions-gpaste
gnome-shell-extension-caffeine
libreoffice
alacarte
"

SOURCES="/etc/apt/sources.list"

# check Root
if [ "$UID" = "0" ]; then
echo "I have adequate permissions, continuing on..."
else echo "I am not root, lets try one more time with sudo..."
sudo $0
exit 0
fi

# Get the system up to date on packages
apt-get update
apt-get dist-upgrade -y

update_repos () {
apt-get update 2> .tmp.update.keys 1> /dev/null
KEYS_TO_ADD="`cat .tmp.update.keys 2> /dev/null`"

if [ "$KEYS_TO_ADD" ]; then
echo "Some of your repository keys need to be set up, I will retrieve the public keys and add them to your keyring..."
for EACH in `cat .tmp.update.keys | awk -F NO_PUBKEY\ {' print $2 '}`
do
echo "Adding key: $EACH ..."
gpg --keyserver hkp://subkeys.pgp.net --recv-keys $EACH
gpg --export --armor $EACH | apt-key add -
done
rm .tmp.update.keys
else echo "All your keys are good to go now..."
fi
}

install_vbox () {
read -r -p "Install VirtualBox?          [Y/n]? " schoice
case $schoice in
        [yY][eE][sS]|[yY]|'')

		VIRTUALBOX="`grep -i virtualbox /etc/apt/sources.list | grep -v \#`"

		if [ "$VIRTUALBOX" ]; then
			echo "VirtualBox sources have been enabled here:"
			echo "$VIRTUALBOX"
			else echo "VirtualBox sources are being added..."
			cp $SOURCES $SOURCES.backup.`date +%s`	
			sleep 2		
			echo "" >> $SOURCES
			echo "## VirtualBox Sources" >> $SOURCES
			echo "deb http://download.virtualbox.org/virtualbox/debian jessie contrib" >> $SOURCES
			wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
			wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
		fi
		update_repos
		apt-get install virtualbox
	;;
        [nN][oO]|[nN])
	    echo "Moving on..."           
	;;
esac

}

install_apps () {
BACKPORTS="`grep -i backports /etc/apt/sources.list | grep -v \#`"
if [ "$BACKPORTS" ]; then
echo "Backports sources have been enabled here:"
echo "$BACKPORTS"
else echo "Backports sources are being added..."
cp $SOURCES $SOURCES.backup.`date +%s`	
sleep 2		
echo "deb http://http.debian.net/debian jessie-backports main" >> $SOURCES
echo "" >> $SOURCES
echo "Updating Package List..."
update_repos
fi

echo "Installing Utilities..."
apt-get -yq install $UTILITY_PROGRAMS

if [  ! `which google-chrome` ]; then
echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb
apt-get -f install
echo 'Moving chrome package to /tmp...'
mv google-chrome-stable_current_amd64.deb /tmp/
update_repos
else echo "Chrome appears to be installed, skipping..."
fi

install_vbox




read -r -p "Install additional security tools?          [Y/n]? " schoice
case $schoice in
        [yY][eE][sS]|[yY]|'')
		echo "Installing Security Tools..."
		apt-get -yq install $SECURITY_PROGRAMS
		mkdir -p $PROGRAMDIR
		cd $PROGRAMDIR
		;;
			    [nN][oO]|[nN])
			    echo "Moving on..."    
		;;
		esac
		
		echo "Grabbing MorphAES..."
		git clone "https://github.com/cryptolok/MorphAES.git"
		echo ""
		
		echo "Grabbing EAPHammer..."
		git clone "https://github.com/s0lst1c3/eaphammer.git"
		echo ""
		
		echo "Grabbing MailSniper..."
		git clone "https://github.com/dafthack/MailSniper.git"
		echo ""

		echo "Grabbing Fluxion..."
		git clone "https://github.com/FluxionNetwork/fluxion"
		echo ""

		echo "Grabbing impacket..."
		git clone "https://github.com/CoreSecurity/impacket"
		echo ""

		echo "Grabbing SAP plugin for wireshark..."
		git clone "https://github.com/CoreSecurity/SAP-Dissection-plug-in-for-Wireshark"
		echo ""

		echo "Grabbing HoneySAP..."
		git clone "https://github.com/CoreSecurity/HoneySAP"
		echo ""

		echo "Grabbing WIFI Phisher..."
		git clone "https://github.com/sophron/wifiphisher.git"
		echo ""

		echo "Grabbing Automated Penetration Toolkit..."
		git clone "https://github.com/MooseDojo/apt2.git"
		echo ""

		echo "Grabbing EyeWitness..."
		git clone "https://github.com/ChrisTruncer/EyeWitness.git"
		echo ""

		echo "Grabbing Discover scripts..."
		git clone "https://github.com/leebaird/discover.git"
		echo ""

		echo "Grabbing WinPayloads scripts..."
		git clone "https://github.com/nccgroup/winpayloads.git"
		cd $PROGRAMDIR/winpayloads
		sudo ./setup.sh
		cd $PROGRAMDIR
		echo ""

		echo "Grabbing Responder, A LLMNR, NBT-NS and MDNS poisoner, with built-in HTTP/SMB/MSSQL/FTP/LDAP rogue authentication server supporting NTLMv1/NTLMv2/LMv2, Extended Security NTLMSSP and Basic HTTP authentication. Responder will be used to gain NTLM challenge/response hashes."
		git clone "https://github.com/SpiderLabs/Responder.git"
		echo ""

		echo "Grabbing Veil Toolkit..."
		git clone "https://github.com/Veil-Framework/Veil.git"
		cd $PROGRAMDIR/Veil
		./Install.sh -c
		cd $PROGRAMDIR
		echo ""

		echo "Grabbing RTFM database. This provides a searchable DB of the RTFM command references..."
		git clone "https://github.com/leostat/rtfm"
		cd rtfm
		pip install terminaltables
		chmod +x ./rtfm.py 
		./rtfm.py -u
		cd $PROGRAMDIR
		echo ""

		echo "Grabbing a forked versions of PowerSploit and Powertools used in \"The Hacker Playbook 2\"."
		git clone "https://github.com/cheetz/PowerSploit"
		git clone "https://github.com/cheetz/PowerTools"
		git clone "https://github.com/cheetz/nishang"
		echo ""

		echo "Grabbing a number of custom scripts written by the author of \"The Hacker Playbook 2\"."
		git clone "https://github.com/cheetz/Easy-P.git"
		git clone "https://github.com/cheetz/Password_Plus_One"
		git clone "https://github.com/cheetz/PowerShell_Popup"
		git clone "https://github.com/cheetz/icmpshock"
		git clone "https://github.com/cheetz/brutescrape"
		git clone "https://www.github.com/cheetz/reddit_xss"
		echo ""

		echo "Grabbing Automated Penetration Toolkit..."
		git clone "https://github.com/pentestgeek/smbexec.git"
		cd $PROGRAMDIR/smbexec
		echo "Starting smbexec install.sh..." 
		echo "PLEASE NOTE:" 
		echo "Select option 1 for Debian/Ubuntu."
		sleep 4
		chmod +x install.sh
		./install.sh
		cd $PROGRAMDIR/smbexec
		echo "1) Select 4 to compile smbexec binaries"
		sleep 4
		echo "2) After compilation, select 5 to exit"
		sleep 3
		./install.sh
		cd $PROGRAMDIR
		echo ""

		echo "Grabbing LALIN..."
		git clone "https://github.com/screetsec/Lalin.git"
		
		read -r -p "Do you want to run Lalin?          [Y/n]? " rlalin
		case $rlalin in
			    [yY][eE][sS]|[yY]|'')
			    echo "Running LALIN..."
			    echo "NOTE: The VirtualBox install option provided by Lalin is way out of date, use the kali-builder (this script) to install virtualbox and NOT Lalin."
			    cd $PROGRAMDIR/Lalin
			    chmod +x Lalin.sh
			    ./Lalin.sh
			    cd $PROGRAMDIR
		;;
			    [nN][oO]|[nN])
			    echo "Moving on..."    
		;;
		esac
        ;;
        [nN][oO]|[nN])
	    echo "Moving on..."           
        ;;
esac
echo ""


read -r -p "Install media apps?          [Y/n]? " schoice
case $schoice in
        [yY][eE][sS]|[yY]|'')
            echo "Installing Media Stuffs..."
	    git clone "https://github.com/Jomik/gnome-wallpaper-changer.git" "~/.local/share/gnome-shell/extensions/wallpaper-changer@jomik.org"
	    cd "~/.local/share/gnome-shell/extensions/wallpaper-changer@jomik.org"
	    glib-compile-schemas ./schemas/
	    
	    apt-get -yq install $MEDIA_PROGRAMS
        ;;
        [nN][oO]|[nN])
	    echo "Moving on..."           
        ;;
esac

echo "Updating ALL Installed Packages..."
apt-get -yq dist-upgrade

echo "Cleaning up package garbage..."
apt-get clean
apt-get autoclean
}

system_tweaks () {

#if [ "`cat /etc/sysctl.conf | grep net.ipv6.conf.all.disable_ipv6 | grep 1 | grep -v \#`" ]; then
#echo "IPv6 has been disabled, skipping..."
#else

#echo "Disabling IPv6 to speed up the internet..."
#echo 'Changing /etc/sysctl.conf...'
#echo '#Disable IPv6' >> /etc/sysctl.conf
#echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
#echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
#echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf

#apply settings
#sysctl -p

#fi

# Fix X11 forwarding over remote SSH connections.
if [ ! "`grep X11UseLocalhost /etc/ssh/sshd_config | grep -v \#`" ]; then
echo "Fixing X Forwarding by adding \"X11UseLocalhost no\" to the sshd_config file..."
echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
fi

echo "Setting up SSH service to start at boot..."
update-rc.d ssh defaults
}

install_apps
system_tweaks
echo "We are done, reboot and enjoy."

exit 0
