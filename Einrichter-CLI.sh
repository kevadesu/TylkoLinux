#!/bin/bash
if [ "$EUID" -ne 0 ]
then echo "Please run Einrichter (TylkoLinux) using administrative permissions."
exit
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
EINRICHTER_VER=0.1.0

function main() {

}

function einrichter.installer.pkgs() {
    echo "M: Preparing TylkoLinux for installation..."
    mkdir $LFS/sources
    echo "[1/6] Downloading package list..."
    wget https://www.linuxfromscratch.org/lfs/view/stable-systemd/wget-list-systemd --continue --directory-prefix=$LFS/sources    
    echo "[2/6] Downloading checksum of packages"
    wget https://www.linuxfromscratch.org/lfs/view/stable-systemd/md5sums --continue --directory-prefix=$LFS/sources
    echo "[3/6] Download packages..."
    wget --input-file=wget-list-systemd --continue --directory-prefix=$LFS/sources
    echo "[4/6] Verifying packages..."
    pushd $LFS/sources
        function einrichter.installer.pkgs.verify() {
            md5sum -c $LFS/sources/md5sums || FAILURE_CODE=ec12737
        }
        einrichter.installer.pkgs.verify || einrichter.installer.fail
    popd
    echo "[5/6] Downloading patches..."
    mkdir $LFS/sources/patches
    wget --input-file=lfs-patch-list --continue --directory-prefix=$LFS/sources/patches
    echo "[6/6] Verifying patches..."
    pushd $LFS/sources/patches
        function einrichter.installer.pkgs.verify.patches() {
            md5sum -c $SCRIPT_DIR/lfs-patch-list-checksum || FAILURE_CODE=ec12737
        }
        einrichter.installer.pkgs.verify.patches || einrichter.installer.fail
    popd
}

function einrichter.installer.bg() {
    
}

function einrichter.installer.fail() {
    case "$FAILURE_CODE" in
        "ec12737")
            echo "E: The verification of the packages has failed. This could be an issue on either your side of the Installer's. Please report this error to the github.com/kevadesu/TylkoLinux repository."
            ;;
        *)
            echo "E: The installation failed due to an unknown error."
            ;;
    esac
}
main

