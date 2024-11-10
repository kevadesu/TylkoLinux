#!/bin/bash
if [ "$EUID" -ne 0 ]
then echo "Please run Einrichter (TylkoLinux) using administrative permissions."
exit
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
EINRICHTER_VER=0.1.0

function main() {
    einrichter.colours
    einrichter.installer.pkgs
    einrichter.installer.DirLayout
    einrichter.installer.SafeUser
    einrichter.installer.SafeUser.end
}

function einrichter.colours() {
    # Reset
    Color_Off='\033[0m'       # Text Reset

    # Regular Colors
    Black='\033[0;30m'        # Black
    Red='\033[0;31m'          # Red
    Green='\033[0;32m'        # Green
    Yellow='\033[0;33m'       # Yellow
    Blue='\033[0;34m'         # Blue
    Purple='\033[0;35m'       # Purple
    Cyan='\033[0;36m'         # Cyan
    White='\033[0;37m'        # White

    # Bold
    BBlack='\033[1;30m'       # Black
    BRed='\033[1;31m'         # Red
    BGreen='\033[1;32m'       # Green
    BYellow='\033[1;33m'      # Yellow
    BBlue='\033[1;34m'        # Blue
    BPurple='\033[1;35m'      # Purple
    BCyan='\033[1;36m'        # Cyan
    BWhite='\033[1;37m'       # White

    # Underline
    UBlack='\033[4;30m'       # Black
    URed='\033[4;31m'         # Red
    UGreen='\033[4;32m'       # Green
    UYellow='\033[4;33m'      # Yellow
    UBlue='\033[4;34m'        # Blue
    UPurple='\033[4;35m'      # Purple
    UCyan='\033[4;36m'        # Cyan
    UWhite='\033[4;37m'       # White

    # Background
    On_Black='\033[40m'       # Black
    On_Red='\033[41m'         # Red
    On_Green='\033[42m'       # Green
    On_Yellow='\033[43m'      # Yellow
    On_Blue='\033[44m'        # Blue
    On_Purple='\033[45m'      # Purple
    On_Cyan='\033[46m'        # Cyan
    On_White='\033[47m'       # White

    # High Intensity
    IBlack='\033[0;90m'       # Black
    IRed='\033[0;91m'         # Red
    IGreen='\033[0;92m'       # Green
    IYellow='\033[0;93m'      # Yellow
    IBlue='\033[0;94m'        # Blue
    IPurple='\033[0;95m'      # Purple
    ICyan='\033[0;96m'        # Cyan
    IWhite='\033[0;97m'       # White

    # Bold High Intensity
    BIBlack='\033[1;90m'      # Black
    BIRed='\033[1;91m'        # Red
    BIGreen='\033[1;92m'      # Green
    BIYellow='\033[1;93m'     # Yellow
    BIBlue='\033[1;94m'       # Blue
    BIPurple='\033[1;95m'     # Purple
    BICyan='\033[1;96m'       # Cyan
    BIWhite='\033[1;97m'      # White

    # High Intensity backgrounds
    On_IBlack='\033[0;100m'   # Black
    On_IRed='\033[0;101m'     # Red
    On_IGreen='\033[0;102m'   # Green
    On_IYellow='\033[0;103m'  # Yellow
    On_IBlue='\033[0;104m'    # Blue
    On_IPurple='\033[0;105m'  # Purple
    On_ICyan='\033[0;106m'    # Cyan
    On_IWhite='\033[0;107m'   # White

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
    echo -e "${BBlue}[i] ${Blue}Attempting chroot...${Color_Off}"
    echo -e "${BBlue}[i] ${Blue}You are about to switch to the chroot environment. When you enter the chroot environment, run the Einrichter-in-chroot.sh script located in the root of the filesystem by typing \"/Einrichter-in-chroot.sh\".${Color_Off}"
    chroot $LFS
}
# NEEDS REVIEW!!!
## chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
##     case $(uname -m) in
##       x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
##     esac
## }

function einrichter.installer.bg() {
    
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
