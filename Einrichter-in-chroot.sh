#!/bin/bash

echo "[i] Verifying if /dev/null is a device"
if [ ! -c /dev/null ]; then
    echo "[!] /dev/null appears to NOT be a device! This issue will be repaired."
    rm -f /dev/null
    mknod -m 666 /dev/null c 1 3
    chown root:root /dev/null
    if [ ! -c /dev/null ]; then
        echo "[!] The issue could not be repaired. Manual intervention is required."
        /bin/sh
    fi
    echo "/dev/null has been fixed."
fi

chmod 755 /bin/bash
chown root:root /bin/bash

echo "Switched to Einrichter-in-chroot mode. Type eic.help for list of commands, exit to exit."

function main() {
    read -p "einrichter/eic>" OPT
    $OPT
    main
}

function eic.help() {
    echo "
    eic.dirs.create - set up directories
    eic.essentials.create - set up essentials
    eic.essentials.install - install essential tools
    eic.clean - clean up environment
    eic.system.build - build the system
    eic.system.build.gcc - build GCC. this has been put in a separate function because building GCC alone takes 46 SBU.
    eic.system.build.continue - continue building the system after successfully building GCC
    eic.help - show this message
    "
}

function eic.dirs.create() {
    mkdir -pv /{boot,home,mnt,opt,srv}
    mkdir -pv /etc/{opt,sysconfig}
    mkdir -pv /lib/firmware
    mkdir -pv /media/{floppy,cdrom}
    mkdir -pv /usr/{,local/}{include,src}
    mkdir -pv /usr/lib/locale
    mkdir -pv /usr/local/{bin,lib,sbin}
    mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
    mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
    mkdir -pv /usr/{,local/}share/man/man{1..8}
    mkdir -pv /var/{cache,local,log,mail,opt,spool}
    mkdir -pv /var/lib/{color,misc,locate}

    ln -sfv /run /var/run
    ln -sfv /run/lock /var/lock

    install -dv -m 0750 /root
    install -dv -m 1777 /tmp /var/tmp
}

function eic.essentials.create() {
    ln -s /bin/bash /bin/sh
    ln -sv /proc/self/mounts /etc/mtab
    cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF
    cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF
    cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF
    localedef -i C -f UTF-8 C.UTF-8
    echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
    echo "tester:x:101:" >> /etc/group
    install -o tester -d /home/tester
    touch /var/log/{btmp,lastlog,faillog,wtmp}
    chgrp -v utmp /var/log/lastlog
    chmod -v 664  /var/log/lastlog
    chmod -v 600  /var/log/btmp
}

function eic.essentials.install() {
    pushd /sources/
        tar -xvf gettext*xz
        mv gettext-0.22.5 gettext
        pushd gettext/
        ./configure --disable-shared
        make
        cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
        popd
        tar -xvf bison*xz
        mv bison-3.8.2 bison
        pushd bison/
        ./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
        make
        make install
        popd
        tar -xvf perl*xz
        mv perl-5.40.0 perl
        pushd perl/
        sh Configure -des                                 \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                           \
             -D useshrplib                                   \
             -D privlib=/usr/lib/perl5/5.40/core_perl         \
             -D archlib=/usr/lib/perl5/5.40/core_perl          \
             -D sitelib=/usr/lib/perl5/5.40/site_perl           \
             -D sitearch=/usr/lib/perl5/5.40/site_perl           \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl         \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl
        make
        make install
        popd
        tar -xvf Python*xz
        mv Python-3.12.5 python
        pushd python/
        ./configure --prefix=/usr   \
                --enable-shared      \
                --without-ensurepip
        make
        make install
        popd
        tar -xvf texinfo*xz
        mv texinfo-7.1 texinfo
        pushd texinfo/
        ./configure --prefix=/usr
        make
        make install
        popd
        tar -xvf util-linux*.xz
        mv util-linux-2.40.2 util-linux
        pushd util-linux/
        mkdir -pv /var/lib/hwclock
        ./configure --libdir=/usr/lib     \
            --runstatedir=/run             \
            --disable-chfn-chsh             \
            --disable-login                  \
            --disable-nologin                 \
            --disable-su                       \
            --disable-setpriv                   \
            --disable-runuser                    \
            --disable-pylibmount                  \
            --disable-static                       \
            --disable-liblastlog2                   \
            --without-python                         \
            ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --docdir=/usr/share/doc/util-linux-2.40.2
        make
        make install
        popd
    popd
}

function eic.clean() {
    rm -rf /usr/share/{info,man,doc}/*
    find /usr/{lib,libexec} -name \*.la -delete
    rm -rf /tools
}

function eic.system.build() {
    pushd /sources
        tar -xvf man-pages-6.9.1.tar.xz
        mv man-pages-6.9.1.tar.xz man-pages
        pushd man-pages
            rm -v man3/crypt*
            make prefix=/usr install
        popd
        tar -xvf iana-etc-20240806.tar.gz
        pushd iana-etc-20240806
            cp services protocols /etc
        popd
        pushd glibc/
            patch -Np1 -i ../glibc-2.40-fhs-1.patch
            rm -r    build
            mkdir -v build
            cd       build
            echo "rootsbindir=/usr/sbin" > configparms
            ../configure --prefix=/usr                            \
             --disable-werror                                      \
             --enable-kernel=4.19                                   \
             --enable-stack-protector=strong                         \
             --disable-nscd                                           \
             libc_cv_slibdir=/usr/lib
            make
            make check
            echo "[!] Please read!
There are cases where Glibc fails the test, and in SOME cases they may be safe to ignore!
Please read the recent output to see if only two to three test failed.
If io/tst-lchmod failed, that is normal. It is known to fail in the TylkoLinux live environment."
            echo "[i] Some tests, for example nss/tst-nss-files-hosts-multi and nptl/tst-thread-affinity\* are known to fail due to a timeout (especially when the system is relatively slow and/or running the test suite with multiple parallel make jobs). These tests can be identified with:

$ grep \"Timed out\" \$(find -name \*.out)

It is possible to re-run a single test with enlarged timeout with \"TIMEOUTFACTOR=<factor> make test t=<test name>\". For example, \"TIMEOUTFACTOR=10 make test t=nss/tst-nss-files-hosts-multi\" will re-run nss/tst-nss-files-hosts-multi with ten times the original timeout.

Additionally, some tests may fail with a relatively old CPU model (for example elf/tst-cpu-features-cpuinfo) or host kernel version (for example stdlib/tst-arc4random-thread).
"
            read -p "[i] To enter a shell and verify the test (or re-run), press enter now. " OPT
            echo "[i] Run \"exit\" to return to the installer when done."
            /bin/sh
            touch /etc/ld.so.conf
            sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
            make install
            sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
            localedef -i C -f UTF-8 C.UTF-8
            localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
            localedef -i de_DE -f ISO-8859-1 de_DE
            localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
            localedef -i de_DE -f UTF-8 de_DE.UTF-8
            localedef -i el_GR -f ISO-8859-7 el_GR
            localedef -i en_GB -f ISO-8859-1 en_GB
            localedef -i en_GB -f UTF-8 en_GB.UTF-8
            localedef -i en_HK -f ISO-8859-1 en_HK
            localedef -i en_PH -f ISO-8859-1 en_PH
            localedef -i en_US -f ISO-8859-1 en_US
            localedef -i en_US -f UTF-8 en_US.UTF-8
            localedef -i es_ES -f ISO-8859-15 es_ES@euro
            localedef -i es_MX -f ISO-8859-1 es_MX
            localedef -i fa_IR -f UTF-8 fa_IR
            localedef -i fr_FR -f ISO-8859-1 fr_FR
            localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
            localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
            localedef -i is_IS -f ISO-8859-1 is_IS
            localedef -i is_IS -f UTF-8 is_IS.UTF-8
            localedef -i it_IT -f ISO-8859-1 it_IT
            localedef -i it_IT -f ISO-8859-15 it_IT@euro
            localedef -i it_IT -f UTF-8 it_IT.UTF-8
            localedef -i ja_JP -f EUC-JP ja_JP
            localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
            localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
            localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
            localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
            localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
            localedef -i se_NO -f UTF-8 se_NO.UTF-8
            localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
            localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
            localedef -i zh_CN -f GB18030 zh_CN.GB18030
            localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
            localedef -i zh_TW -f UTF-8 zh_TW.UTF-8
            echo "[i] Add an additional locale you'd like to add by defining it in the shell below, using the localedef command. Exit when done."
            /bin/sh
            localedef -i C -f UTF-8 C.UTF-8
            localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
            cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files systemd
group: files systemd
shadow: files systemd

hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
            tar -xvf ../../tzdata2024a.tar.gz

            ZONEINFO=/usr/share/zoneinfo
            mkdir -pv $ZONEINFO/{posix,right}

            for tz in etcetera southamerica northamerica europe africa antarctica  \
                      asia australasia backward; do
                zic -L /dev/null   -d $ZONEINFO       ${tz}
                zic -L /dev/null   -d $ZONEINFO/posix ${tz}
                zic -L leapseconds -d $ZONEINFO/right ${tz}
            done

            cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
            zic -d $ZONEINFO -p America/New_York
            unset ZONEINFO
            eic.system.build.tz() {
                tzselect
                read -p "[i] Type the timezone that has been outputted: (with the slash) " TZ
                ln -sfv /usr/share/zoneinfo/$TZ /etc/localtime || eic.system.build.tz
            }
            eic.system-build.tz
            cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
            cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
            mkdir -pv /etc/ld.so.conf.d
        popd
        tar -xvf zlib-1.3.1.tar.gz
        mv zlib-1.3.1 zlib
        pushd zlib/
            ./configure --prefix=/usr
            make
            make check
            make install
            rm -fv /usr/lib/libz.a
        popd
        tar -xvf bzip2-1.0.8.tar.gz
        mv bzip2-1.0.8 bzip2
        pushd bzip2/
            patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
            sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
            sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
            make -f Makefile-libbz2_so
            make clean
            make
            make PREFIX=/usr install
            cp -av libbz2.so.* /usr/lib
            ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
            cp -v bzip2-shared /usr/bin/bzip2
            for i in /usr/bin/{bzcat,bunzip2}; do
              ln -sfv bzip2 $i
            done
            rm -fv /usr/lib/libbz2.a
        popd
        pushd xz/
            ./configure --prefix=/usr    \
                --disable-static          \
                --docdir=/usr/share/doc/xz-5.6.2
            make
            make check
            make install
        popd
        tar -xvf lz4-1.10.0.tar.gz
        mv lz4-1.10.0 lz4
        pushd lz4/
            make BUILD_STATIC=no PREFIX=/usr
            make -j1 check
            make BUILD_STATIC=no PREFIX=/usr install
        popd
        tar -xvf zstd-1.5.6.tar.gz
        mv zstd-1.5.6 zstd
        pushd zstd/
            make prefix=/usr
            make check
            make prefix=/usr install
            rm -v /usr/lib/libzstd.a
        popd
        pushd file/
            ./configure --prefix=/usr
            make
            make check
            make install
        popd
        tar -xvf readline-8.2.13.tar.gz
        mv readline-8.2.13 readline
        pushd readline/
            sed -i '/MV.*old/d' Makefile.in
            sed -i '/{OLDSUFF}/c:' support/shlib-install
            sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
            ./configure --prefix=/usr    \
                --disable-static          \
                --with-curses              \
                --docdir=/usr/share/doc/readline-8.2.13
            make SHLIB_LIBS="-lncursesw"
            make SHLIB_LIBS="-lncursesw" install
            install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2.13
        popd
        pushd m4/
            ./configure --prefix=/usr
            make
            make check
            make install
        popd
        tar -xvf bc-6.7.6.tar.xz
        mv bc-6.7.6 bc
        pushd bc/
            CC=gcc ./configure --prefix=/usr -G -O3 -r
            make
            make test
            make install
        popd
        tar -xvf flex-2.6.4.tar.gz
        mv flex-2.6.4 flex
        pushd flex/
            ./configure --prefix=/usr             \
                --docdir=/usr/share/doc/flex-2.6.4 \
                --disable-static
            make
            make check
            make install
            ln -sv flex   /usr/bin/lex
            ln -sv flex.1 /usr/share/man/man1/lex.1
        popd
        tar -xvf tcl8.6.14-src.tar.gz
        mv tcl8.6.14 tcl
        pushd tcl/
            SRCDIR=$(pwd)
            cd unix
            ./configure --prefix=/usr           \
                        --mandir=/usr/share/man  \
                        --disable-rpath
            make

            sed -e "s|$SRCDIR/unix|/usr/lib|" \
                -e "s|$SRCDIR|/usr/include|"   \
                -i tclConfig.sh

            sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.7|/usr/lib/tdbc1.1.7|" \
                -e "s|$SRCDIR/pkgs/tdbc1.1.7/generic|/usr/include|"    \
                -e "s|$SRCDIR/pkgs/tdbc1.1.7/library|/usr/lib/tcl8.6|" \
                -e "s|$SRCDIR/pkgs/tdbc1.1.7|/usr/include|"            \
                -i pkgs/tdbc1.1.7/tdbcConfig.sh

            sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.4|/usr/lib/itcl4.2.4|" \
                -e "s|$SRCDIR/pkgs/itcl4.2.4/generic|/usr/include|"    \
                -e "s|$SRCDIR/pkgs/itcl4.2.4|/usr/include|"            \
                -i pkgs/itcl4.2.4/itclConfig.sh

            unset SRCDIR

            make test
            make install
            chmod -v u+w /usr/lib/libtcl8.6.so
            make install-private-headers
            ln -sfv tclsh8.6 /usr/bin/tclsh
            mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
            cd ..
            tar -xf ../tcl8.6.14-html.tar.gz --strip-components=1
            mkdir -v -p /usr/share/doc/tcl-8.6.14
            cp -v -r  ./html/* /usr/share/doc/tcl-8.6.14
        popd
        tar -xvf expect5.45.4.tar.gz
        mv expect5.45.4 expect
        pushd expect/
            eic.system.build.expect.intervention() {
                if [[ $(python3 -c 'from pty import spawn; spawn(["echo", "ok"])') != "ok" ]]; then
                    echo "[i] PS: The error is caused by the chroot environment not being set up for proper PTY operation."
                    read -p "[!] Answer unexpected. Continue, enter shell or quit? [c/s/q] " OPT
                    case "$OPT" in
                        c)
                            echo "OK!"
                        ;;
                        s)
                            /bin/sh
                            eic.system.build.expect.intervention
                        ;;
                        q)
                            exit 1
                        ;;
                        *)
                            echo "Invalid command!"
                            eic.system.build.expect.intervention
                        ;;
                    esac
                fi
            }


            eic.system.build.expect.intervention
            patch -Np1 -i ../expect-5.45.4-gcc14-1.patch
            ./configure --prefix=/usr           \
                        --with-tcl=/usr/lib      \
                        --enable-shared           \
                        --disable-rpath            \
                        --mandir=/usr/share/man     \
                        --with-tclinclude=/usr/include
            make
            make test
            make install
            ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
        popd
        tar -xvf dejagnu-1.6.3.tar.gz
        mv dejagnu-1.6.3 dejagnu
        pushd dejagnu/
            mkdir -v build
            cd       build
            ../configure --prefix=/usr
            makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
            makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
            make check
            make install
            install -v -dm755  /usr/share/doc/dejagnu-1.6.3
            install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
        popd
        tar -xvf pkgconf-2.3.0.tar.xz
        mv pkgconf-2.3.0 pkgconf
        pushd pkgconf/
            ./configure --prefix=/usr              \
                        --disable-static            \
                        --docdir=/usr/share/doc/pkgconf-2.3.0
            make
            make install
            ln -sv pkgconf   /usr/bin/pkg-config
            ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
        popd
        pushd binutils/
            rm    -r build
            mkdir -v build
            cd       build
            ../configure --prefix=/usr       \
                         --sysconfdir=/etc    \
                         --enable-gold         \
                         --enable-ld=default    \
                         --enable-plugins        \
                         --enable-shared          \
                         --disable-werror          \
                         --enable-64-bit-bfd        \
                         --enable-new-dtags          \
                         --with-system-zlib           \
                         --enable-default-hash-style=gnu
            make tooldir=/usr
            make -k check
            grep '^FAIL:' $(find -name '*.log')
            make tooldir=/usr install
            rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
        popd
        tar -xvf gmp-6.3.0.tar.xz
        mv gmp-6.3.0 gmp
        pushd gmp/
            ./configure --prefix=/usr         \
                        --enable-cxx           \
                        --disable-static        \
                        --host=none-linux-gnu    \
                        --docdir=/usr/share/doc/gmp-6.3.0
            make
            make html
            make check 2>&1 | tee gmp-check-log
            GMP_CHECK=$(awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log)
            eic.system.build.gmp.intervention() {
                if [ ! "$GMP_CHECK" -ge "199" ]; then
                    echo "[i] PS: The check did not reach the minimum amount of passed tests required."
                    read -p "[!] Answer unexpected. Continue, enter shell or quit? [c/s/q] " OPT
                    case "$OPT" in
                        c)
                            echo "OK!"
                        ;;
                        s)
                            /bin/sh
                            eic.system.build.gmp.intervention
                        ;;
                        q)
                            exit 1 
                        ;;
                        *)
                            echo "Invalid command!"
                            eic.system.build.gmp.intervention
                        ;;
                    esac
                fi
            }

            eic.system.build.gmp.intervention
            make install
            make install-html
        popd
        tar -xvf mpfr-4.2.1.tar.xz
        mv mpfr-4.2.1 mpfr
        pushd mpfr/
            ./configure --prefix=/usr        \
                        --disable-static      \
                        --enable-thread-safe   \
                        --docdir=/usr/share/doc/mpfr-4.2.1
            make
            make html
            make check
            make install
            make install-html
        popd
        tar -xvf mpc-1.3.1.tar.gz
        mv mpc-1.3.1 mpc
        pushd mpc/
            ./configure --prefix=/usr    \
                        --disable-static  \
                        --docdir=/usr/share/doc/mpc-1.3.1
            make
            make html
            make check
            make install
            make install-html
        popd
        tar -xvf attr-2.5.2.tar.gz
        mv attr-2.5.2 attr
        pushd attr/
            ./configure --prefix=/usr     \
                        --disable-static   \
                        --sysconfdir=/etc   \
                        --docdir=/usr/share/doc/attr-2.5.2
            make
            make check
            make install
        popd
        tar -xvf acl-2.3.2.tar.xz
        mv acl-2.3.2 acl
        pushd acl/
            ./configure --prefix=/usr         \
                        --disable-static       \
                        --docdir=/usr/share/doc/acl-2.3.2
            make
            make install
        popd
        tar -xvf libcap-2.70.tar.xz 
        mv libcap-2.70 libcap
        pushd libcap/
            sed -i '/install -m.*STA/d' libcap/Makefile
            make prefix=/usr lib=lib
            make test
            make prefix=/usr lib=lib install
        popd
        tar -xvf libxcrypt-4.4.36.tar.xz
        mv libxcrypt-4.4.36 libxcrypt
        pushd libxcrypt/
            ./configure --prefix=/usr                \
                        --enable-hashes=strong,glibc  \
                        --enable-obsolete-api=no       \
                        --disable-static                \
                        --disable-failure-tokens
            make
            make check
            make install
            echo "[i] Reinstalling with ABIv1 features..."
            make distclean
            ./configure --prefix=/usr                \
                        --enable-hashes=strong,glibc  \
                        --enable-obsolete-api=glibc    \
                        --disable-static                \
                        --disable-failure-tokens
            make
            cp -av --remove-destination .libs/libcrypt.so.1* /usr/lib
        popd
        tar -xvf shadow-4.16.0.tar.xz; mv shadow-4.16.0 shadow
        pushd shadow/
            sed -i 's/groups$(EXEEXT) //' src/Makefile.in
            find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
            find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
            find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

            sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
            -e 's:/var/spool/mail:/var/mail:'                        \
            -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                        \
            -i etc/login.defs

            touch /usr/bin/passwd
            ./configure --sysconfdir=/etc   \
                        --disable-static     \
                        --with-{b,yes}crypt   \
                        --without-libbsd       \
                        --with-group-name-max-length=32

            make

            make exec_prefix=/usr install
            make -C man install-man
        
            pwconv
            grpconv

            mkdir -p /etc/default
            useradd -D --gid 999

            sed -i '/MAIL/s/yes/no/' /etc/default/useradd

            echo "[i] Set the new root password."
            passwd root
        popd
    popd
}

function eic.system.build.gcc() {
    pushd /sources/
        pushd gcc/
            case $(uname -m) in
                x86_64)
                    sed -e '/m64=/s/lib64/lib/' \
                        -i.orig gcc/config/i386/t-linux64
                ;;
            esac
            rm   -rv build
            mkdir -v build
            cd       build
            ../configure --prefix=/usr            \
                         LD=ld                     \
                         --enable-languages=c,c++   \
                         --enable-default-pie        \
                         --enable-default-ssp         \
                         --enable-host-pie             \
                         --disable-multilib             \
                         --disable-bootstrap             \
                         --disable-fixincludes            \
                         --with-system-zlib
            make
            ulimit -s -H unlimited
            sed -e '/cpython/d'               -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp
            sed -e 's/no-pic /&-no-pie /'     -i ../gcc/testsuite/gcc.target/i386/pr113689-1.c
            sed -e 's/300000/(1|300000)/'     -i ../libgomp/testsuite/libgomp.c-c++-common/pr109062.c
            sed -e 's/{ target nonpic } //' \
                -e '/GOTPCREL/d'              -i ../gcc/testsuite/gcc.target/i386/fentryname3.c

            eic.system.build.gcc.ask() {
                read -p "Pending step: Running test suite. Run, skip or quit?" OPT
                case in "$OPT"
                    R)
                        chown -R tester .
                        su tester -c "PATH=$PATH make -k check"
                        ../contrib/test_summary > /eilogs/8.29-gcc-test.log
                        ;;
                    S)
                        echo "Step skipped."
                        ;;
                    Q)
                        exit
                        ;;
                    *)
                        echo "Unknown command. Repeating questions."
                        eic.system.build.gcc.ask
                        ;;
                esac
            }
            eic.system.build.gcc.ask
            read -p "[i] Press enter to continue." ANY
            make install
            chown -v -R root:root \
                /usr/lib/gcc/$(gcc -dumpmachine)/14.2.0/include{,-fixed}
            ln -svr /usr/bin/cpp /usr/lib
            ln -sv gcc.1 /usr/share/man/man1/cc.1
            ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so \
                /usr/lib/bfd-plugins/
            echo 'int main(){}' > dummy.c
            cc dummy.c -v -Wl,--verbose &> dummy.log
            readelf -l a.out | grep ': /lib'
            grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log || read -p "[!] The toolchain did not find the correct start files. Press enter to continue." ANY
            grep -B4 '^ /usr/include' dummy.log || read -p "[!] The toolchain did not find the correct header files. Press enter to continue." ANY
            grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g' || read -p "[!] The toolchain was unable to verify that the new linker is being used with the correct search paths. Press enter to continue." ANY
            grep "/lib.*/libc.so.6 " dummy.log || read -p "[!] The toolchain did not find the correct libc. Press enter to continue." ANY
            grep found dummy.log || read -p "[!] The toolchain did not find the correct dynamic linker. Press enter to continue." ANY
            rm -v dummy.c a.out dummy.log
            mkdir -pv /usr/share/gdb/auto-load/usr/lib
            mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
        popd
    popd
    echo "[i] Finished building GCC"
}

main

function eic.system.build.continue() {
    pushd /sources/
        pushd ncurses/
            ./configure --prefix=/usr           \
                        --mandir=/usr/share/man  \
                        --with-shared             \
                        --without-debug            \
                        --without-normal            \
                        --with-cxx-shared            \
                        --enable-pc-files             \
                        --with-pkg-config-libdir=/usr/lib/pkgconfig
            make
            make DESTDIR=$PWD/dest install
            install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
            rm -v  dest/usr/lib/libncursesw.so.6.5
            sed -e 's/^#if.*XOPEN.*$/#if 1/' \
                -i dest/usr/include/curses.h
            cp -av dest/* /
            for lib in ncurses form panel menu ; do
                ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
                ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
            done
            ln -sfv libncursesw.so /usr/lib/libcurses.so
            cp -v -R doc -T /usr/share/doc/ncurses-6.5
        popd
        pushd sed/
            ./configure --prefix=/usr
            make 
            make html
            chown -R tester .
            su tester -c "PATH=$PATH make check"
            make install
            install -d -m755           /usr/share/doc/sed-4.9
            install -m644 doc/sed.html /usr/share/doc/sed-4.9
        popd
        tar -xvf psmisc-23.7.tar.xz
        mv psmisc-23.7 psmisc
        pushd psmisc/
            ./configure --prefix=/usr
            make
            make check
            make install
        popd
        pushd gettext/
            ./configure --prefix=/usr    \
                        --disable-static  \
                        --docdir=/usr/share/doc/gettext-0.22.5
            make 
            eic.system.build.continue.gettext.ask() {
                read -p "Pending step: Running test suite. Run, skip or quit? (~3 SBUs)" OPT
                case in "$OPT"
                    R)
                        make check > /eilogs/8.33-gettext-test.log
                        ;;
                    S)
                        echo "Step skipped."
                        ;;
                    Q)
                        exit
                        ;;
                    *)
                        echo "Unknown command. Repeating questions."
                        eic.system.build.continue.gettext.ask
                        ;;
                esac
            }
            eic.system.build.continue.gettext.ask
            make install
            chmod -v 0755 /usr/lib/preloadable_libintl.so
        popd
        pushd bison/
            ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
            make
            eic.system.build.continue.bison.ask() {
                read -p "Pending step: Running test suite. Run, skip or quit? (~3 SBUs)" OPT
                case in "$OPT"
                    R)
                        make check > /eilogs/8.34-bison-test.log
                        ;;
                    S)
                        echo "Step skipped."
                        ;;
                    Q)
                        exit
                        ;;
                    *)
                        echo "Unknown command. Repeating questions."
                        eic.system.build.continue.bison.ask
                        ;;
                esac
            }
            eic.system.build.continue.bison.ask
            make install
        popd
        pushd grep/
            sed -i "s/echo/#echo/" src/egrep.sh
            ./configure --prefix=/usr
            make
            make check
            make install
        popd
        pushd bash/
            ./configure --prefix=/usr             \
                        --without-bash-malloc      \
                        --with-installed-readline   \
                        bash_cv_strtold_broken=no    \
                        --docdir=/usr/share/doc/bash-5.2.32
            make
            eic.system.build.continue.bash.ask() {
                read -p "Pending step: Running test suite. Run, skip or quit? (~3 SBUs)" OPT
                case in "$OPT"
                    R)
                        chown -R tester .
                        su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF
                        ;;
                    S)
                        echo "Step skipped."
                        ;;
                    Q)
                        exit
                        ;;
                    *)
                        echo "Unknown command. Repeating questions."
                        eic.system.build.continue.bash.ask
                        ;;
                esac
            }
            eic.system.build.continue.bash.ask
            make install
        popd
        tar -xvf libtool-2.4.7.tar.xz
        mv libtool-2.4.7 libtool
        pushd libtool/
            ./configure --prefix=/usr
            make
            make -k check > /eilogs/8.37-libtool-test.log
            make install
            rm -fv /usr/lib/libltdl.a
        popd
}