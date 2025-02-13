#!/bin/bash
if [ "$EUID" -ne 0 ]
then echo "Please run Einrichter (TylkoLinux) using administrative permissions."
exit
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
EINRICHTER_VER=0.1.0

function booter() {
    einrichter.colours
    echo "Einrichter - TylkoLinux Installer Shell $EINRICHTER_VER
The script is located at $SCRIPT_DIR
Run einrichter.help for commands"
	main
}

function main() {
    read -p "einrichter> " Command_Input
    $Command_Input
    main
}

function einrichter.help() {
    echo "Einrichter commands:
einrichter.installer.pkgs - Prepare packages for installation
einrichter.installer.DirLayout - Set up the directories at the target system
einrichter.installer.SafeUser - Set up LFS user on host and starting package compilation
einrichter.installer.chroot - Enter the environment using chroot
einrichter.help - Show this help dialog
einrichter.backup.create - Create a backup of the system to the home folder
einrichter.backup.restore - Restore the aforementioned backup
einrichter.xr - Extracts everything in $LFS/sources/ and renames them to the same package name without the version number
einrichter.add.fs - Adds the required stuff aswell
exit - Exit the script
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
    echo -e "${Purple}[i] The colour variables have been set.${Color_Off}"
}

function einrichter.installer.pkgs() {
    echo -e "[i] Preparing TylkoLinux for installation..."
    mkdir $LFS/sources
    echo -e "${BPurple}[1/6] Downloading package list..."
    wget https://www.linuxfromscratch.org/lfs/view/stable-systemd/wget-list-systemd --continue --directory-prefix=$LFS/sources    
    echo -e "[2/6] Copying md5sums to $LFS/sources/ (It's already been downloaded)"
    cp $SCRIPT_DIR/md5sums $LFS/sources/
    # wget $SCRIPT_DIR/md5sums --continue --directory-prefix=$LFS/sources
    echo -e "[3/6] Download packages..."
    wget --input-file=$SCRIPT_DIR/wget-list-systemd --continue --directory-prefix=$LFS/sources
    echo -e "[4/6] Verifying packages..."
    pushd $LFS/sources
        function einrichter.installer.pkgs.verify() {
            md5sum -c $LFS/sources/md5sums || einrichter.error PKG_VER_ERR
        }
        einrichter.installer.pkgs.verify
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
    chown -v lfs $LFS
    chown -vR lfs $LFS/sources
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
    echo -e "${BBlue}[i] ${Blue}From here on, you no longer need the installer to log in to the lfs user. In the future, just run \"su - lfs\", either in Einrichter or in shell. Only run this again if you want to re-own everything under the lfs user.${Color_Off}"
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
    einrichter.installer.chroot.end

}

function einrichter.installer.chroot.end() {
    echo -e "[i] Unmounting virtual file system..."
    mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
    umount $LFS/dev/pts
    umount $LFS/{sys,proc,run,dev}
    echo -e "[i] Finished section installer.chroot"

}

function einrichter.backup.create() {
    echo -e "${BRed}[?] Variable LFS points to ${LFS}. This needs to point to the target LFS system.
If this does NOT point to the LFS directory, EXIT NOW AND SET THE VARIABLE. This will otherwise
DESTROY THE ENTIRE HOST SYSTEM. YOU ARE WARNED.${Color_Off}"
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
    echo -e "${BRed}[?] Variable LFS points to ${LFS}. This needs to point to the target LFS system.
If this does NOT point to the LFS directory, EXIT NOW AND SET THE VARIABLE. This will otherwise
DESTROY THE ENTIRE HOST SYSTEM. YOU ARE WARNED.${Color_Off}"
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

function einrichter.xr() {
    echo "[i] Extracting and renaming ALL packages..."
    sleep 0.5
    pushd $LFS/sources/ || einrichter.error DIR404_SRC
        tar -xvf gcc-14.2.0.tar.xz 
        mv -v gcc-14.2.0 gcc
        pushd $LFS/sources/gcc
            tar -xf ../mpfr-4.2.1.tar.xz
            mv -v mpfr-4.2.1 mpfr
            tar -xf ../gmp-6.3.0.tar.xz
            mv -v gmp-6.3.0 gmp
            tar -xf ../mpc-1.3.1.tar.gz
            mv -v mpc-1.3.1 mpc
        popd
        tar -xvf $LFS/sources/binutils-2.43.1.tar.xz
        mv binutils-2.43.1 binutils
        tar -xvf linux-6.10.5.tar.xz
        mv -v linux-6.10.5 linux
        tar -xvf glibc-2.40.tar.xz
        mv -v glibc-2.40 glibc
        tar -xvf coreutils-9.5.tar.xz
        mv coreutils-9.5 coreutils
        tar -xvf diffutils-3.10.tar.xz
        mv diffutils-3.10 diffutils
        tar -xvf file-5.45.tar.gz
        mv file-5.45 file
        tar -xvf m4-1.4.19.tar.xz
        mv m4-1.4.19 m4
        tar -xvf ncurses-6.5.tar.gz
        mv ncurses-6.5 ncurses
        tar -xvf bash-5.2.32.tar.gz
        mv bash-5.2.32 bash
        tar -xvf findutils-4.10.0.tar.xz
        mv findutils-4.10.0 findutils
        tar -xvf gawk-5.3.0.tar.*z
        mv gawk-5.3.0 gawk
        tar -xvf grep-3.11.tar.*z
        mv grep-3.11 grep
        tar -xvf gzip-1.13.tar.*z
        mv gzip-1.13 gzip
        tar -xvf make-4.4.1.tar.*z
        mv make-4.4.1 make
        tar -xvf patch-2.7.6.tar.*z
        mv patch-2.7.6 patch
        tar -xvf sed-4.9.tar.*z
        mv sed-4.9 sed
        tar -xvf tar-1.35*
        mv tar-1.35 tar
        tar -xvf xz-5.6.2.tar.*z
        mv xz-5.6.2 xz
        tar -xvf gettext*xz
        mv gettext-0.22.5 gettext
        tar -xvf bison*xz
        mv bison-3.8.2 bison
        tar -xvf perl*xz
        mv perl-5.40.0 perl
        tar -xvf Python*xz
        mv Python-3.12.5 python
        tar -xvf texinfo*xz
        mv texinfo-7.1 texinfo
        tar -xvf util-linux*.xz
        mv util-linux-2.40.2 util-linux
        tar -xvf man-pages-6.9.1.tar.xz
        mv man-pages-6.9.1.tar.xz man-pages
        tar -xvf iana-etc-20240806.tar.gz
        tar -xvf zlib-1.3.1.tar.gz
        mv zlib-1.3.1 zlib
        tar -xvf bzip2-1.0.8.tar.gz
        mv bzip2-1.0.8 bzip2
        tar -xvf lz4-1.10.0.tar.gz
        mv lz4-1.10.0 lz4
        tar -xvf zstd-1.5.6.tar.gz
        mv zstd-1.5.6 zstd
        tar -xvf readline-8.2.13.tar.gz
        mv readline-8.2.13 readline
        tar -xvf bc-6.7.6.tar.xz
        mv bc-6.7.6 bc
        tar -xvf flex-2.6.4.tar.gz
        mv flex-2.6.4 flex
        tar -xvf tcl8.6.14-src.tar.gz
        mv tcl8.6.14 tcl
        tar -xvf expect5.45.4.tar.gz
        mv expect5.45.4 expect
        tar -xvf dejagnu-1.6.3.tar.gz
        mv dejagnu-1.6.3 dejagnu
        tar -xvf pkgconf-2.3.0.tar.xz
        mv pkgconf-2.3.0 pkgconf
        tar -xvf gmp-6.3.0.tar.xz
        mv gmp-6.3.0 gmp
        tar -xvf mpfr-4.2.1.tar.xz
        mv mpfr-4.2.1 mpfr
        tar -xvf mpc-1.3.1.tar.gz
        mv mpc-1.3.1 mpc
        tar -xvf attr-2.5.2.tar.gz
        mv attr-2.5.2 attr
        tar -xvf acl-2.3.2.tar.xz
        mv acl-2.3.2 acl
        tar -xvf libcap-2.70.tar.xz 
        mv libcap-2.70 libcap
        tar -xvf libxcrypt-4.4.36.tar.xz
        mv libxcrypt-4.4.36 libxcrypt
        tar -xvf shadow-4.16.0.tar.xz
        mv shadow-4.16.0 shadow
        tar -xvf psmisc-23.7.tar.xz
        mv psmisc-23.7 psmisc
        tar -xvf libtool-2.4.7.tar.xz
        mv libtool-2.4.7 libtool
        tar -xvf gdbm-1.24.tar.gz 
        mv gdbm-1.24 gdbm
        tar -xvf gperf-3.1.tar.gz; 
        mv gperf-3.1 gperf
        tar -xvf expat-2.6.2.tar.xz; 
        mv expat-2.6.2 expat
        tar -xvf inetutils-2.5.tar.xz 
        mv inetutils-2.5 inetutils
        tar -xvf less-661.tar.gz; 
        mv less-661 less
        tar -xvf XML-Parser-2.47.tar.gz; 
        mv XML-Parser-2.47 XML-Parser
        tar -xvf intltool-0.51.0.tar.gz; 
        mv intltool-0.51.0 intltool
        tar -xvf autoconf-2.72.tar.xz; 
        tar -xvf automake-1.17.tar.xz; 
        mv autoconf-2.72 autoconf; 
        mv automake-1.17 automake
        tar -xvf openssl-3.3.1.tar.gz; 
        mv openssl-3.3.1 openssl
        tar -xvf kmod-33.tar.xz; 
        mv kmod-33 kmod
        tar -xvf elfutils-0.191.tar.bz2; 
        mv elfutils-0.191 elfutils
        tar -xvf libffi-3.4.6.tar.gz; 
        mv libffi-3.4.6 libffi
        tar -xvf flit_core-3.9.0.tar.gz; 
        mv flit_core-3.9.0 flit_core
        tar -xvf wheel-0.44.0.tar.gz; 
        mv wheel-0.44.0 wheel
        tar -xvf setuptools-72.2.0.tar.gz; 
        mv setuptools-72.2.0 setuptools
        tar -xvf ninja-1.12.1.tar.gz; 
        mv ninja-1.12.1 ninja
		tar -xvf meson-1.5.1.tar.gz; 
		mv meson-1.5.1 meson
		tar -xvf check-0.15.2.tar.gz; 
		mv check-0.15.2 check
        tar -xvf groff-1.23.0.tar.gz; 
        mv groff-1.23.0 groff
        tar -xvf grub-2.12.tar.xz; 
        mv grub-2.12 grub
        tar -xvf iproute2-6.10.0.tar.xz; 
        mv iproute2-6.10.0 iproute2
        tar -xvf kbd-2.6.4.tar.xz; 
        mv kbd-2.6.4 kbd
        tar -xvf libpipeline-1.5.7.tar.gz; 
        mv libpipeline-1.5.7 libpipeline
        tar -xvf nano-8.1.tar.xz; 
        mv nano-8.1 nano
        tar -xvf MarkupSafe-2.1.5.tar.gz; 
        mv MarkupSafe-2.1.5 MarkupSafe
        tar -xvf jinja2-3.1.4.tar.gz; 
        mv jinja2-3.1.4 jinja
        tar -xvf systemd-256.4.tar.gz; 
        mv systemd-256.4 systemd
        tar -xvf dbus-1.14.10.tar.xz; 
        mv dbus-1.14.10 dbus
        tar -xvf man-db-2.12.1.tar.xz; 
        mv man-db-2.12.1 man-db
        tar -xvf procps-ng-4.0.4.tar.xz; 
        mv procps-ng-4.0.4 procps-ng
        tar -xvf e2fsprogs-1.47.1.tar.gz; 
        mv e2fsprogs-1.47.1 e2fsprogs
        tar -xvf git-2.48.1.tar.xz
        mv git-2.48.1 git
        tar -xvf wget-1.24.5.tar.gz
        mv wget-1.24.5 wget
        tar -xvf p11-kit-0.25.5.tar.xz
        mv p11-kit-0.25.5 p11-kit
        tar -xvf make-ca-1.14.tar.gz
        mv make-ca-1.14 make-ca
        tar -xvf libtasn1-4.19.0.tar.gz
        mv libtasn1-4.19.0 libtasn1
        tar -xvf cpio-2.15.tar.bz2
        mv cpio-2.15 cpio
        tar -xvf hwdata-0.385.tar.gz
        mv hwdata-0.385 hwdata
        tar -xvf pciutils-3.13.0.tar.gz
        mv pciutils-3.13.0 pciutils
        tar -xvf libgpg-error-1.50.tar.bz2
        mv libgpg-error-1.50 libgpg-error
        tar -xvf libassuan-3.0.1.tar.bz2
        mv libassuan-3.0.1 libassaun
        tar -xvf gpgme-1.23.2.tar.bz2
        mv gpgme-1.23.2 gpgme
}

function einrichter.add.fs() {
    cp -vR $SCRIPT_DIR/add/fs/* $LFS/
}

function einrichter.error() {
    echo -e "${BBlue}[i] ${Blue}The installer has encountered a critical error and needs to quit.${Color_Off}"
    case "$@" in
        "PKG_VER_ERR")
            echo -e "${BRed}[!] ${Red}The verification of the packages has failed. This could be an issue on either your side of the Installer's. Please report this error to the github.com/kevadesu/TylkoLinux repository.${Color_Off}"
        ;;
        "PKG_DWD_FAIL")
            echo -e "${BRed}[!] ${Red}Downloading packages, patches and/or the package list . This could be an issue on either your side of the Installer's. Please report this error to the github.com/kevadesu/TylkoLinux repository.${Color_Off}"
        ;;
        D404_SRC)
            echo "[!] Directory /sources/ does NOT exist!"
        ;;
        *)
            echo -e "${BRed}[!] ${Red}The installation failed due to an unknown error.${Color_Off}"
        ;;
    esac
    exit 1
}

booter
