#!/bin/bash

## this part of the script runs in mac os ##
# check if homebrew installed
if [[ $(command -v brew) == "" ]]; then
    read -e -p  "Homebrew is not installed on your Mac; would you like to install it? [ y | N ] "  user_response
    if [ $user_response == "y" ] ; then
    echo -e "\n Installing Homebrew package manager \n" ;
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
    echo -e "\n Halting the script \n"  && exit ;
    fi
else
  echo -e "\n Homebrew is already installed. Checking for updates … \n " ;
  brew update
fi

brew=$(which brew) ;
echo -e "\n Installing the Multipass VM hosting environment \n" ;
$brew install --quiet qemu multipass && multi=$(which multipass) ;
mkdir -p ~/Desktop/shared ;

myDate=$(date +%Y-%m-%d-%H-%M-%S)
myHostName=$(whoami)-linux-vm-"$myDate"

$multi launch lts --name "$myHostName" --memory 2G --disk 12G --cpus 2 --mount  ~/Desktop/shared:/home/ubuntu/Desktop/shared
$multi set client.primary-name="$myHostName"

cat << EOF > ~/Desktop/shared/gui-setup.sh

#!/bin/bash

## this part of the script runs in ubuntu ##
if [ \$(whoami) != "root" ]; then echo -e "\n this script requires root permission. Please try: \n ---> sudo ~/Desktop/shared/gui-setup.sh" >&2; exit 1;
else
apt update && sudo apt upgrade -y ;
apt install -y net-tools xubuntu-core xrdp ; 
echo "xfce4-session" > /home/ubuntu/.xsession ;
echo -e "\n Please set a password for the default ubuntu user \n" ;
passwd ubuntu ; 
adduser xrdp ssl-cert ;
systemctl restart xrdp ; 
fi
exit 0 ;
EOF

chmod ug+x ~/Desktop/shared/gui-setup.sh ;

# tell user to allow full disk access for multipassd
osascript <<END
set buttonText to "To allow folder sharing between your Mac and the VM, 'multipassd' requires Full Disk Access."
if button returned of (display dialog buttonText with icon note buttons {"Open Security Prefs now","Cancel"} default button 1) = "Open Security Prefs now" then
tell application "System Settings"
	activate
	reveal anchor "Privacy_AllFiles" of pane id "com.apple.settings.PrivacySecurity.extension"
end tell
end if
END





exit 0 ;
