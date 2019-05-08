#!/bin/bash

 #curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
#chmod a+x ~/bin/repo

#sudo apt-get update
sync


sync
ENTERCORRECTLY=0
while [ $ENTERCORRECTLY -ne 1 ]
do
    read -p "Would you install ***\"ia32-libs\"*** [Y/N] : " SIZECHECK
    ENTERCORRECTLY=1
    case $SIZECHECK in
	"y" | "Y")
	    sudo apt-get install ia32-libs
	    ;;
	"n" | "N")
	    ;;
	*)
	    echo "Please enter Y|y or N|n"
	    ENTERCORRECTLY=0
	    ;;
    esac
    echo ""
done
sync


sudo apt-get install vim ssh 
#sudo apt-get install meld
#sudo apt-get install terminator
#sudo apt-get install minicom
#sudo apt-get install wine
echo "====================================   > 1"
sync

sudo apt-get install build-essential
echo "====================================   > 2"
#sudo apt-get install g++-multilib
echo "====================================   > 3"
sync

sudo apt-get install git gitk \
    gnupg \
    flex \
    bison \
    gperf \
    zip \
    curl \
    libc6-dev \
    x11proto-core-dev \
    libx11-dev:i386 \
    libreadline6-dev:i386 \
    libgl1-mesa-dev \
    mingw32 \
    tofrodos \
    python-markdown \
    libxml2-utils \
    xsltproc \
    zlib1g-dev:i386

sudo apt-get install libncurses5-dev libncurses5-dev:i386
echo "====================================   > 4"
sync

sudo ln -s /usr/lib/i386-linux-gnu/mesa/libGL.so.1 /usr/lib/i386-linux-gnu/libGL.so
echo "====================================   > 5"

sudo apt-get install squashfs-tools \
    bc \
    ccache \
    tesseract-ocr \
    imagemagick \
    gettext \
    python-libxml2 \
    unzip \
    dosfstools \
    mtools \
    dos2unix

echo "====================================   > 6"
sync

#android O
sudo apt-get install libssl-dev


sudo apt-get install ubuntu-desktop
#sudo apt-get install ibus
#sudo apt-get install gnome-session-fallback
echo "====================================   > 7"
sync

#sudo apt-get install openjdk-7-jdk
#sudo apt-get install sun-java6-jdk
java -version
echo "====================================   > 8"
sync


# lxml
#sudo apt-get install libxml2-dev libxslt1-dev python-dev
#sudo apt-get install python-libxml2 python-libxslt1
#sudo apt-get install python-lxml
#sudo apt-get build-dep python-lxml
#sudo apt-get install python-setuptools
#sudo easy_install lxml

# google
#sudo apt-get install libappindicator1
# platformflashtool
#sudo apt-get install fping gdebi p7zip-full

# Android
#sudo apt-get install android-tools-adb android-tools-fastboot
#sudo apt-get install libxml-libxml-perl
echo "====================================   > 9"
sync

#sudo apt-get update
sync
