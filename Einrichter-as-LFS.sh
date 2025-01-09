#!/bin/bash

main() {
    echo "Einrichter is designed to work as an install script where you can resume where you left off. Do NOT skip anything if you have not ran the step yet."
    read -p "Pending step: Setting up environment. Run, skip or quit?" OPT
    case in "$OPT"
        R)
            eal.setup.env
            ;;
        S)
            echo "Step skipped."
            ;;
        Q)
            exit
            ;;
        *)
            echo "Unknown command. Repeating questions."
            ;;
    esac
    read -p "Pending step: Setting up toolchain. Run, skip or quit?" OPT
    case in "$OPT"
        R)
            eal.setup.toolchain
            ;;
        S)
            echo "Step skipped."
            ;;
        Q)
            exit
            ;;
        *)
            echo "Unknown command. Repeating questions."
            ;;
    esac
    read -p "Pending step: Installing cross toolchain and packages. Run, skip or quit?" OPT
    case in "$OPT"
        R)
            eal.install.cross-toolchain
            ;;
        S)
            echo "Step skipped."
            ;;
        Q)
            exit
            ;;
        *)
            echo "Unknown command. Repeating questions."
            ;;
    esac
    echo "Done!"
    exit
}

function eal.setup.env() {
    echo "The installer is about to begin setting up the environment. Please wait..."
    sleep 2

    cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

    cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
MAKEFLAGS=-j$(nproc)
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE MAKEFLAGS 
EOF

source ~/.bash_profile
}

function eal.notification.buildconf() {
    echo "I: -- The installer is now configuring the build options --" && sleep 0.2
    }
function eal.notification.compiling() {
    echo "I: -- The installer is now compiling the package $EIR_PKG --" && sleep 0.2
}
function eal.notification.installing() {
    echo "I: -- The installer is now installing the package $EIR_PKG --" && sleep 0.2
}
function eal.notification.extracting() {
    echo "I: -- The installer is now extracting the necessary archives for $EIR_PKG --" && sleep 0.2
}
function eal.emergencyAlert() {
    echo -e "\a" && sleep 0.1 && echo -e "\07" && sleep 0.1 && tput bel
}

function eal.setup.toolchain() {
    echo -e "I: The detected system triplet is $(/usr/bin/gcc -dumpmachine)."
    export LFS_TGT=$(/usr/bin/gcc -dumpmachine)
    echo 
}

function eal.install.cross-toolchain() {
    cd $LFS/sources/
    EIR_PKG=binutils
    eal.notification.extracting
    sleep 0.5
    tar -xvf $LFS/sources/binutils-2.43.1.tar.xz
    mv binutils-2.43.1 binutils
    cd $LFS/sources/binutils/
    mkdir -v build
    cd       build
    eal.notification.buildconf
    sleep 0.5
    ../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS      \
             --target=$LFS_TGT         \
             --disable-nls              \
             --enable-gprofng=no         \
             --disable-werror             \
             --enable-new-dtags            \
             --enable-default-hash-style=gnu
    eal.notification.compiling
    make
    eal.notification.installing
    make install
    eal.notification.extracting
    pushd $LFS/sources/
        tar -xvf gcc-14.2.0.tar.xz 
        mv -v gcc-14.2.0 gcc
        pushd $LFS/sources/gcc/
            tar -xf ../mpfr-4.2.1.tar.xz
            mv -v mpfr-4.2.1 mpfr
            tar -xf ../gmp-6.3.0.tar.xz
            mv -v gmp-6.3.0 gmp
            tar -xf ../mpc-1.3.1.tar.gz
            mv -v mpc-1.3.1 mpc
            case $(uname -m) in
                x86_64)
                    sed -e '/m64=/s/lib64/lib/' \
                    -i.orig gcc/config/i386/t-linux64
            ;;
            esac
            mkdir -v build
            cd       build
            eal.notification.buildconf
            ../configure                  \
                --target=$LFS_TGT          \
                --prefix=$LFS/tools         \
                --with-glibc-version=2.40    \
                --with-sysroot=$LFS           \
                --with-newlib                  \
                --without-headers               \
                --enable-default-pie             \
                --enable-default-ssp              \
                --disable-nls                      \
                --disable-shared                    \
                --disable-multilib                   \
                --disable-threads                     \
                --disable-libatomic                    \
                --disable-libgomp                       \
                --disable-libquadmath                    \
                --disable-libssp                          \
                --disable-libvtv                           \
                --disable-libstdcxx                         \
                --enable-languages=c,c++
            eal.notification.compiling
            make
            eal.notification.installing
            make install
            cd ..
            cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
                `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
        popd
        EIR_PKG=linux
        eal.notification.extracting
        tar -xvf linux-6.10.5.tar.xz
        mv -v linux-6.10.5 linux
        pushd $LFS/sources/linux/
            make mrproper
            make headers
            find usr/include -type f ! -name '*.h' -delete
            cp -rv usr/include $LFS/usr
        popd
        EIR_PKG=glibc
        eal.notification.extracting
        tar -xvf glibc-2.40.tar.xz
        mv -v glibc-2.40 glibc
        echo -e "I: -- The installer is creating a symbolic link for LSB compliance. Depending on architecture, it may also create a compatibility symbolic link for proper operation of the dynamic library loader. --"
        case $(uname -m) in
            i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
            ;;
            x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
                    ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
            ;;
        esac
        pushd $LFS/sources/glibc/
            echo -e "I: -- The installer is now patching glibc. --"
            patch -Np1 -i ../glibc-2.40-fhs-1.patch
            mkdir -v build
            cd       build
            echo "rootsbindir=/usr/sbin" > configparms
            eal.notification.buildconf
            ../configure                           \
                --prefix=/usr                       \
                --host=$LFS_TGT                      \
                --build=$(../scripts/config.guess)    \
                --enable-kernel=4.19                   \
                --with-headers=$LFS/usr/include         \
                --disable-nscd                           \
                libc_cv_slibdir=/usr/lib
            eal.notification.compiling
            make
            eal.emergencyAlert
            echo -e "\033[0;31mW: -- Before installing the package, make sure that the variable LFS is CORRECTLY SET to have the value of the target LFS system. If it doesn't, and you're running this script as root, despite the recommendations, this will install the newly built glibc to the HOST SYSTEM, rendering it almost certainly unusable. Please make sure that this variable is correctly set: --"
            echo -e "\$LFS: ${LFS}"
            echo -e "If this is incorrect, exit the installer immediately by pressing CTRL + C, wipe the target LFS partition and restart the entire installation process. If the variable is correct, press Enter"
            read
            eal.notification.installing
            make DESTDIR=$LFS install
            sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
            echo "I: -- The next output you'll receive needs to start with \"[Requesting program interpreter:\". If the output is not similar to this, or not shown at all, something is wrong. Please confirm that there is an output by pressing enter. If the output is wrong, type \"R\" without the quotation marks to drop into the shell. --"
            echo 'int main(){}' | $LFS_TGT-gcc -xc -
            readelf -l a.out | grep ld-linux
            read -p "->" TEMP_OUTPUT
            case "$TEMP_OUTPUT" in
                R)
                    echo "Fix issues by checking the LFS 12.2-systemd book. Once you fixed everything, clean up the test file by running \"rm -v a.out\"."
                    sh
                ;;
                *)
                    echo "OK"
                ;;
            esac
        popd
        pushd $LFS/sources/gcc/
            mkdir -v build-libstdcpp
            cd       build-libstdcpp
            EIR_PKG=libstdcpp
            eal.notification.buildconf
            ../libstdc++-v3/configure           \
                --host=$LFS_TGT                  \
                --build=$(../config.guess)        \
                --prefix=/usr                      \
                --disable-multilib                  \
                --disable-nls                        \
                --disable-libstdcxx-pch               \
                --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
            rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
        popd
        EIR_PKG=M4
        tar -xvf m4-1.4.19.tar.xz
        mv m4-1.4.19 m4
        pushd $LFS/sources/m4/
            eal.notification.buildconf
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT \
                        --build=$(build-aux/config.guess)
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
        popd
        EIR_PKG=ncurses
        tar -xvf ncurses-6.5.tar.gz
        mv ncurses-6.5 ncurses
        pushd $LFS/sources/ncurses
            sed -i s/mawk// configure
            mkdir build
            cd build
            ../configure
            make -C include
            make -C progs tic
            cd ..
            eal.notification.buildconf
            ./configure --prefix=/usr                \
                        --host=$LFS_TGT               \
                        --build=$(./config.guess)      \
                        --mandir=/usr/share/man         \
                        --with-manpage-format=normal     \
                        --with-shared                     \
                        --without-normal                   \
                        --with-cxx-shared                   \
                        --without-debug                      \
                        --without-ada                         \
                        --disable-stripping
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
            ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
            sed -e 's/^#if.*XOPEN.*$/#if 1/' \
               -i $LFS/usr/include/curses.h
        popd
        EIR_PKG=bash
        tar -xvf bash-5.2.32.tar.gz
        mv bash-5.2.32 bash
        pushd $LFS/soruces/bash
            eal.notification.buildconf
            ./configure --prefix=/usr                      \
                        --build=$(sh support/config.guess)  \
                        --host=$LFS_TGT                      \
                        --without-bash-malloc                 \
                        bash_cv_strtold_broken=no
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
            ln -sv bash $LFS/bin/sh
        popd
        EIR_PKG=coreutils
        eal.notification.extracting
        tar -xvf coreutils-9.5.tar.xz
        mv coreutils-9.5 coreutils
        pushd $LFS/sources/coreutils
            eal.notification.buildconf
            ./configure --prefix=/usr                     \
                        --host=$LFS_TGT                    \
                        --build=$(build-aux/config.guess)   \
                        --enable-install-program=hostname    \
                        --enable-no-install-program=kill,uptime
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
            mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
            mkdir -pv $LFS/usr/share/man/man8
            mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
            sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8
        popd
        EIR_PKG=diffutils
        echo "Install notifications will not be shown for small packages, as it will be obvious which action will be executed." && sleep 10
        tar -xvf diffutils-3.10.tar.xz
        mv diffutils-3.10 diffutils
        pushd $LFS/sources/diffutils
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(./build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        tar -xvf file-5.45.tar.gz
        mv file-5.45 file
        pushd $LFS/sources/file
        mkdir build
        pushd build
            ../configure --disable-bzlib      \
                        --disable-libseccomp   \
                        --disable-xzlib         \
                        --disable-zlib
            make
        popd
        ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
        make FILE_COMPILE=$(pwd)/build/src/file
        make DESTDIR=$LFS install
        rm -v $LFS/usr/lib/libmagic.la
        tar -xvf findutils-4.10.0.tar.xz
        mv findutils-4.10.0.tar.xz findutils
        pushd $LFS/sources/findutils
            ./configure --prefix=/usr                   \
                        --localstatedir=/var/lib/locate  \
                        --host=$LFS_TGT                   \
                        --build=$(build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        tar -xvf gawk-5.3.0.tar.*z
        mv gawk-5.3.0 gawk
        pushd $LFS/sources/gawk
            sed -i 's/extras//' Makefile.in
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        tar -xvf grep-3.11.tar.*z
        mv grep-3.11 grep
        pushd $LFS/sources/grep
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(./build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        tar -xvf gzip-1.13.tar.*z
        mv gzip-1.13 gzip
        pushd $LFS/sources/gzip
            ./configure --prefix=/usr --host=$LFS_TGT
            make
            make DESTDIR=$LFS install
        popd
        tar -xvf make-4.4.1.tar.*z
        mv make-4.4.1 make
        pushd $LFS/sources/make
            ./configure --prefix=/usr   \
                        --without-guile  \
                        --host=$LFS_TGT   \
                        --build=$(build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        tar -xvf patch-2.7.6.tar.*z
        mv patch-2.7.6 patch
        pushd $LFS/sources/patch
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd

        tar -xvf sed-4.9.tar.*z
        mv sed-4.9 sed
        # From here on I got lazy with the script to get it over with Chapter 6 faster, I'll fix all of this when TylkoLinux is in last Beta stage
        pushd sed
            ./configure --prefix=/usr   \
                        --host=$LFS_TGT  \
                        --build=$(./build-aux/config.guess)
            make
            make DESTDIR=$LFS install
        popd
        tar -xvf tar-1.35*
        mv tar-1.35 tar
        pushd tar
            ./configure --prefix=/usr                     \
                        --host=$LFS_TGT                    \
                        --build=$(build-aux/config.guess) 
            make
            make DESTDIR=$LFS install
        popd
        tar -xvf xz-5.6.2.tar.*z
        mv xz-5.6.2 xz
        pushd $LFS/sources/xz
            ./configure --prefix=/usr                     \
                        --host=$LFS_TGT                    \
                        --build=$(build-aux/config.guess)   \
                        --disable-static                     \
                        --docdir=/usr/share/doc/xz-5.6.2
            make
            make DESTDIR=$LFS install
            rm -v $LFS/usr/lib/liblzma.la
        popd
        pushd $LFS/sources/binutils
            sed '6009s/$add_dir//' -i ltmain.sh
            yes | rm -r build
            mkdir -v build
            cd       build
            ../configure                   \
                --prefix=/usr               \
                --build=$(../config.guess)   \
                --host=$LFS_TGT               \
                --disable-nls                  \
                --enable-shared                 \
                --enable-gprofng=no              \
                --disable-werror                  \
                --enable-64-bit-bfd                \
                --enable-new-dtags                  \
                --enable-default-hash-style=gnu
            make
            make DESTDIR=$LFS install
            rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
        popd
        EIR_PKG=GCC
        pushd $LFS/sources/gcc
            case $(uname -m) in
                x86_64)
                    sed -e '/m64=/s/lib64/lib/' \
                        -i.orig gcc/config/i386/t-linux64
                ;;
            esac
            sed '/thread_header =/s/@.*@/gthr-posix.h/' \
                -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
            yes | rm -r build
            mkdir -v build            
            cd       build
            eal.notification.buildconf
            ../configure                                       \
                --build=$(../config.guess)                      \
                --host=$LFS_TGT                                  \
                --target=$LFS_TGT                                 \
                LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc          \
                --prefix=/usr                                       \
                --with-build-sysroot=$LFS                            \
                --enable-default-pie                                  \
                --enable-default-ssp                                   \
                --disable-nls                                           \
                --disable-multilib                                       \
                --disable-libatomic                                       \
                --disable-libgomp                                          \
                --disable-libquadmath                                       \
                --disable-libsanitizer                                       \
                --disable-libssp                                              \
                --disable-libvtv                                               \
                --enable-languages=c,c++
            eal.notification.compiling
            make
            eal.notification.installing
            make DESTDIR=$LFS install
            ln -sv gcc $LFS/usr/bin/cc
        popd
    popd
    echo "Operations as LFS user are now over. Switching to chroot"
}           


main