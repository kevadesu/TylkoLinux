#!/bin/bash
if [ "$EUID" -ne 0 ]
then echo "Please run Einrichter (TylkoLinux) using administrative permissions."
exit
fi

function main() {

}

function einrichter.installer.pkgs() {
    echo "[1/ ] Downloading package list..."
    wget https://www.linuxfromscratch.org/lfs/view/stable-systemd/wget-list-systemd --continue --directory-prefix=$LFS/sources    
    echo "[2/ ] Downloading checksum of packages"
    wget https://www.linuxfromscratch.org/lfs/view/stable-systemd/md5sums --continue --directory-prefix=$LFS/sources
    echo "[3/ ] Installing packages
    wget --input-file=wget-list-systemd --continue --directory-prefix=$LFS/sources
    pushd $LFS/sources
        md5sum -c md5sums
    popd
}

function einrichter.installer.bg() {
    
}
main

