#!/bin/bash
if [ "$EUID" -ne 0 ]
then echo "Please run Einrichter (TylkoLinux) using administrative permissions."
exit
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
EINRICHTER_VER=0.1.0

function main() {
    einrichter.colours
    echo "Einrichter - TylkoLinux Installer Shell $EINRICHTER_VER
The script is located at $SCRIPT_DIR
Run einrichter.help for commands"
    read -p "einrichter>" Command_Input
    $Command_Input
    main
}

einrichter.help() {
    echo "Einrichter commands:
einrichter.installer.pkgs - Prepare packages for installation
einrichter.installer.DirLayout - Set up the directories at the target system
einrichter.installer.SafeUser - Set up LFS user on host and starting package compilation
einrichter.installer.chroot - Enter the environment using chroot
einrichter.help - Show this help dialog
For more information, see https://github.com/kevadesu/TylkoLinux"
}

function einrichter.colours() {
    # Reset
    Color_Off='\033[0m'       # Text Reset

    # Regular Colors
    export Black='\033[0;30m'        # Black
    export Red='\033[0;31m'          # Red
    export Green='\033[0;32m'        # Green
    export Yellow='\033[0;33m'       # Yellow
    export Blue='\033[0;34m'         # Blue
    export Purple='\033[0;35m'       # Purple
    export Cyan='\033[0;36m'         # Cyan
    export White='\033[0;37m'        # White
 
    # Bold
    export BBlack='\033[1;30m'       # Black
    export BRed='\033[1;31m'         # Red
    export BGreen='\033[1;32m'       # Green
    export BYellow='\033[1;33m'      # Yellow
    export BBlue='\033[1;34m'        # Blue
    export BPurple='\033[1;35m'      # Purple
    export BCyan='\033[1;36m'        # Cyan
    export BWhite='\033[1;37m'       # White
 
    # Underline
    export UBlack='\033[4;30m'       # Black
    export URed='\033[4;31m'         # Red
    export UGreen='\033[4;32m'       # Green
    export UYellow='\033[4;33m'      # Yellow
    export UBlue='\033[4;34m'        # Blue
    export UPurple='\033[4;35m'      # Purple
    export UCyan='\033[4;36m'        # Cyan
    export UWhite='\033[4;37m'       # White
 
    # Background
    export On_Black='\033[40m'       # Black
    export On_Red='\033[41m'         # Red
    export On_Green='\033[42m'       # Green
    export On_Yellow='\033[43m'      # Yellow
    export On_Blue='\033[44m'        # Blue
    export On_Purple='\033[45m'      # Purple
    export On_Cyan='\033[46m'        # Cyan
    export On_White='\033[47m'       # White

    # High Intensity
    export IBlack='\033[0;90m'       # Black
    export IRed='\033[0;91m'         # Red
    export IGreen='\033[0;92m'       # Green
    export IYellow='\033[0;93m'      # Yellow
    export IBlue='\033[0;94m'        # Blue
    export IPurple='\033[0;95m'      # Purple
    export ICyan='\033[0;96m'        # Cyan
    export IWhite='\033[0;97m'       # White

    # Bold High Intensity
    export BIBlack='\033[1;90m'      # Black
    export BIRed='\033[1;91m'        # Red
    export BIGreen='\033[1;92m'      # Green
    export BIYellow='\033[1;93m'     # Yellow
    export BIBlue='\033[1;94m'       # Blue
    export BIPurple='\033[1;95m'     # Purple
    export BICyan='\033[1;96m'       # Cyan
    export BIWhite='\033[1;97m'      # White

    # High Intensity backgrounds
    export On_IBlack='\033[0;100m'   # Black
    export On_IRed='\033[0;101m'     # Red
    export On_IGreen='\033[0;102m'   # Green
    export On_IYellow='\033[0;103m'  # Yellow
    export On_IBlue='\033[0;104m'    # Blue
    export On_IPurple='\033[0;105m'  # Purple
    export On_ICyan='\033[0;106m'    # Cyan
    export On_IWhite='\033[0;107m'   # White
    echo "[i] The colour variables have been set."
}

function einrichter.installer.pkgs() {
    echo -e "[i] Preparing TylkoLinux for installation..."
    mkdir $LFS/sources
    echo -e "${BPurple}[1/6] Downloading package list..."
    wget https://www.linuxfromscratch.org/lfs/view/stable-systemd/wget-list-systemd --continue --directory-prefix=$LFS/sources    
    echo -e "[2/6] Downloading checksum of packages"
    wget https://www.linuxfromscratch.org/lfs/view/stable-systemd/md5sums --continue --directory-prefix=$LFS/sources
    echo -e "[3/6] Download packages..."
    wget --input-file=wget-list-systemd --continue --directory-prefix=$LFS/sources
    echo -e "[4/6] Verifying packages..."
    pushd $LFS/sources
        function einrichter.installer.pkgs.verify() {
            md5sum -c $LFS/sources/md5sums || FAILURE_CODE=ec12737
        }
        einrichter.installer.pkgs.verify || einrichter.installer.fail
    popd
    echo -e "[5/6] Downloading patches..."
    mkdir $LFS/sources/patches
    wget --input-file=lfs-patch-list --continue --directory-prefix=$LFS/sources/patches
    echo -e "[6/6] Verifying patches..."
    pushd $LFS/sources/patches
        function einrichter.installer.pkgs.verify.patches() {
            md5sum -c $SCRIPT_DIR/lfs-patch-list-checksum || FAILURE_CODE=ec12737
        }
        einrichter.installer.pkgs.verify.patches || einrichter.installer.fail
    popd
    echo -e "[i] Finished section installer.pkgs"
}

function einrichter.installer.DirLayout() {

    echo -e "${BCyan}[i] ${Cyan}Making directories...${Color_Off}"
    mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

    echo -e "${BCyan}[i] ${Cyan}Linking directories...${Color_Off}"
    for i in bin lib sbin; do
        ln -sv usr/$i $LFS/$i
    done

    echo -e "${BCyan}[i] ${Cyan}Checking if this system is x64...${Color_Off}"
    case $(uname -m) in
        x86_64) mkdir -pv $LFS/lib64 ;;
    esac

    
    mkdir -pv $LFS/tools
}

function einrichter.installer.SafeUser() {
    
    groupadd lfs
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs

    echo -e "${BBlue}[i] ${Blue}Assign the lfs user a password.${Color_Off}"
    passwd lfs
    echo -e "${BBlue}[i] ${Blue}Granting the lfs user full access to all directories...${Color_Off}"
    chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
    case $(uname -m) in
        x86_64) chown -v lfs $LFS/lib64 ;;
    esac
    echo -e "${BBlue}[i] ${Blue}Copying second installer to home directory of the lfs user...${Color_Off}"
    cp $SCRIPT_DIR/Einrichter-as-LFS.sh /home/lfs/
    echo -e "${BBlue}[i] ${Blue}Changing the ownership of file to the lfs user...${Color_Off}"
    chown -v lfs /home/lfs/Einrichter-as-LFS.sh
    echo -e "${BBlue}[i] ${Blue}Making the installer executable...${Color_Off}"
    chmod -v +x /home/lfs/Einrichter-as-LFS.sh
    echo -e "${BBlue}[i] ${Blue}Moving the host's bash.bashrc file aside if found... (THIS WILL BE RESTORED AFTER THE END OF THE INSTALLATION!)${Color_Off}"
    [ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
    echo -e "${BBlue}[i] ${Blue}Assigning permissions to the user lfs for the drive ${LFS}...${Color_Off}"
    chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
    case $(uname -m) in
      x86_64) chown -v lfs $LFS/lib64 ;;
    esac
    echo -e "${BBlue}[i] ${Blue}Attempting login as lfs...${Color_Off}"
    echo -e "${BBlue}[i] ${Blue}You are about to switch to the LFS user. When you log in, run the Einrichter-as-LFS.sh script located in your home directory by typing \"./Einrichter-as-LFS.sh\".${Color_Off}"
    su - lfs
    einrichter.installer.SafeUser.End
}

function einrichter.installer.SafeUser.End() {
    echo -e "${BBlue}[i] ${Blue}Completed!${Color_Off}"
    echo -e "[i] Finished section installer.SafeUser"
}

function einrichter.installer.chroot() {
    chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
    case $(uname -m) in
        x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
    esac
    echo -e "${BBlue}[i] ${Blue}Copying third installer to the root of ${LFS}...${Color_Off}"
    cp $SCRIPT_DIR/Einrichter-in-chroot.sh $LFS/
    echo -e "${BBlue}[i] ${Blue}Making the installer executable...${Color_Off}"
    chmod +x $LFS/Einrichter-in-chroot.sh
    echo -e "${BBlue}[i] ${Blue}Preparing the Virtual Kernel File Systems...${Color_Off}"
    mkdir -pv $LFS/{dev,proc,sys,run}
    mount -v --bind /dev $LFS/dev
    mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
    mount -vt proc proc $LFS/proc
    mount -vt sysfs sysfs $LFS/sys
    mount -vt tmpfs tmpfs $LFS/run
    if [ -h $LFS/dev/shm ]; then
        install -v -d -m 1777 "$LFS$(realpath /dev/shm)"
    else
        mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
    fi
    echo -e "${BBlue}[i] ${Blue}Attempting chroot...${Color_Off}"
    echo -e "${BBlue}[i] ${Blue}You are about to switch to the chroot environment. When you enter the chroot environment, run the Einrichter-in-chroot.sh script located in the root of the filesystem by typing \"/Einrichter-in-chroot.sh\".${Color_Off}"
    chroot "$LFS" /usr/bin/env -i   \
        HOME=/root                   \
        TERM="$TERM"                  \
        PS1='(lfs chroot) \u:\w\$ '    \
        PATH=/usr/bin:/usr/sbin         \
        MAKEFLAGS="-j$(nproc)"           \
        TESTSUITEFLAGS="-j$(nproc)"       \
        /bin/bash --login

}

function einrichter.installer.chroot.end() {
    echo -e "[i] Unmounting virtual file system..."
    mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
    umount $LFS/dev/pts
    umount $LFS/{sys,proc,run,dev}
    echo -e "[i] Finished section installer.chroot"

}

function einrichter.backup.create() {
    echo -e "[?] Variable LFS points to $LFS. This needs to point to the target LFS system.
If this does NOT point to the LFS directory, EXIT NOW AND SET THE VARIABLE. This will otherwise
DESTROY THE ENTIRE HOST SYSTEM. YOU ARE WARNED."
    read -p "[?] Continue? (y/n) " OPT
    if [ "$OPT" = "y" ]; then echo "Continuing..."; else exit 1; fi
    echo "[i] Unmounting the virtual file systems..."
    mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
    umount $LFS/dev/pts
    umount $LFS/{sys,proc,run,dev}
    echo "[i] Making the backup archive..."
    cd $LFS
    tar -cJpf $HOME/lfs-temp-tools-12.2-systemd.tar.xz .
    echo "[i] OK!"

}

function einrichter.backup.restore() {
    echo -e "[?] Variable LFS points to $LFS. This needs to point to the target LFS system.
If this does NOT point to the LFS directory, EXIT NOW AND SET THE VARIABLE. This will otherwise
DESTROY THE ENTIRE HOST SYSTEM. YOU ARE WARNED."
    read -p "[?] Continue? (y/n) " OPT
    echo "[i] Restoring from backup..."
    cd $LFS
    rm -rf ./*
    tar -xpf $HOME/lfs-temp-tools-12.2-systemd.tar.xz
    echo "[i] OK!"
}

function einrichter.installer.bg() {
    echo "E"
}

function einrichter.installer.fail() {
    case "$FAILURE_CODE" in
        "ec12737")
            echo -e "${BRed}[!] ${Red}The verification of the packages has failed. This could be an issue on either your side of the Installer's. Please report this error to the github.com/kevadesu/TylkoLinux repository.${Color_Off}"
            ;;
        *)
            echo -e "${BRed}[!] ${Red}The installation failed due to an unknown error.${Color_Off}"
            ;;
    esac
}

main
