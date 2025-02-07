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
    read -p "einrichter/eic> " OPT
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
eic.strip - removes unnecessary debug symbols
eic.system.build.clean - clean up files after the build process
eic.config.network.devicenaming - sets up network interface names
eic.config.network.staticip - creates basic config for static ip
eic.config.network.dhcp - sets up a basic IPv4 DHCP config
eic.config.network.systemd.resolve <on/off/enable/disable> - enables/disables systemd-resolved service
eic.config.network.hostname <hostname> - writes hostname to /etc/hostname
eic.config.network.staticresolver - use static /etc/resolv.conf configuration after disabling systemd-resolved
eic.config.time.createAdj - adjust /etc/adjtime to local time if hardware clock is set to that
eic.config.time.clarifyUTC - tell systemd-timedated your hardware clock is set to UTC/Local Time
eic.config.time.set - enter the time to set in YYYY-MM-DD HH:MM:SS format
eic.config.time.tz <timezone> - set a timezone. use command 'timedatectl list-timezones' to get a list of all timezones
eic.config.time.nts <on/off/enable/disable> - switch systemd's Network Time Synchronisation on or off
eic.config.console.preset - wipe /etc/vconsole.conf and simply write 'FONT=Lat2-Terminus16' to it
eic.config.console.keymap <KEYMAP> - write default keymap to /etc/vconsole.conf
eic.config.create.inputrc - creates the simple but necessary /etc/inputrc file
eic.config.create.shells - creates the simple but necessary /etc/shells file
eic.config.systemd.disableScreenClearing <yes/no> - decide whether systemd should clear the screen at the end of the boot sequence or not
eic.config.systemd.limitCoreDumpSize <(Number)(G/M/K/B) - limits core dump size to value specified as argument
eic.linux.install - the final boss: install the Linux kernel to the system. can take 0.4-32 SBUs (typically 2.5), MIGHT also be heavy
eic.rpm.install - installs RPM
eic.zypper.install - installs openSUSE's RPM frontend, Zypper
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
    pushd /sources/ || eic.error D404_SRC
        pushd gettext/
            ./configure --disable-shared
            make
            cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
        popd
        pushd bison/
            ./configure --prefix=/usr \
                --docdir=/usr/share/doc/bison-3.8.2
            make
            make install
        popd
        pushd perl/
            sh Configure -des                                 \
                -D prefix=/usr                                 \
                -D vendorprefix=/usr                            \
                -D useshrplib                                    \
                -D privlib=/usr/lib/perl5/5.40/core_perl          \
                -D archlib=/usr/lib/perl5/5.40/core_perl           \
                -D sitelib=/usr/lib/perl5/5.40/site_perl            \
                -D sitearch=/usr/lib/perl5/5.40/site_perl            \
                -D vendorlib=/usr/lib/perl5/5.40/vendor_perl          \
                -D vendorarch=/usr/lib/perl5/5.40/vendor_perl 
            make
            make install
        popd
        pushd python/
            ./configure --prefix=/usr   \
                    --enable-shared      \
                    --without-ensurepip
            make
            make install
        popd
        pushd texinfo/
            ./configure --prefix=/usr
            make
            make install
        popd
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
        pushd man-pages
            rm -v man3/crypt*
            make prefix=/usr install
        popd
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
        pushd zlib/
            ./configure --prefix=/usr
            make
            make check
            make install
            rm -fv /usr/lib/libz.a
        popd
        pushd bzip2/
            patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
            sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
            sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
            make -f Makefile-libbz2_so
            make clean
            make CFLAGS="-fPIC" LDFLAGS="-fPIC"
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
        pushd lz4/
            make BUILD_STATIC=no PREFIX=/usr
            make -j1 check
            make BUILD_STATIC=no PREFIX=/usr install
        popd
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
        pushd bc/
            CC=gcc ./configure --prefix=/usr -G -O3 -r
            make
            make test
            make install
        popd
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
        pushd attr/
            ./configure --prefix=/usr     \
                        --disable-static   \
                        --sysconfdir=/etc   \
                        --docdir=/usr/share/doc/attr-2.5.2
            make
            make check
            make install
        popd
        pushd acl/
            ./configure --prefix=/usr         \
                        --disable-static       \
                        --docdir=/usr/share/doc/acl-2.3.2
            make
            make install
        popd
        pushd libcap/
            sed -i '/install -m.*STA/d' libcap/Makefile
            make prefix=/usr lib=lib
            make test
            make prefix=/usr lib=lib install
        popd
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
                case "$OPT" in
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
                case "$OPT" in
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
                case "$OPT" in
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
                case "$OPT" in
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
        pushd libtool/
            ./configure --prefix=/usr
            make
            make -k check > /eilogs/8.37-libtool-test.log
            make install
            rm -fv /usr/lib/libltdl.a
        popd
        pushd gdbm/
            ./configure --prefix=/usr    \
                        --disable-static  \
                        --enable-libgdbm-compat
            make
            make check
            make install
        popd
        pushd gperf/
            ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
            make
            make -j1 check
            make install
        popd
        pushd expat/
            ./configure --prefix=/usr    \
                        --disable-static  \
                        --docdir=/usr/share/doc/expat-2.6.2
            make
            make check
            make install
            install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.2
        popd
        pushd inetutils/
            sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
            ./configure --prefix=/usr        \
                        --bindir=/usr/bin     \
                        --localstatedir=/var   \
                        --disable-logger        \
                        --disable-whois          \
                        --disable-rcp             \
                        --disable-rexec            \
                        --disable-rlogin            \
                        --disable-rsh                \
                        --disable-servers
            make
            make check
            make install
            mv -v /usr/{,s}bin/ifconfig
        popd
        pushd less/
            ./configure --prefix=/usr --sysconfdir=/etc
            make
            make check
            make install
        popd
        pushd perl/
            export BUILD_ZLIB=False
            export BUILD_BZIP2=0
            sh Configure -des                                          \
                         -D prefix=/usr                                 \
                         -D vendorprefix=/usr                            \
                         -D privlib=/usr/lib/perl5/5.40/core_perl         \
                         -D archlib=/usr/lib/perl5/5.40/core_perl          \
                         -D sitelib=/usr/lib/perl5/5.40/site_perl           \
                         -D sitearch=/usr/lib/perl5/5.40/site_perl           \
                         -D vendorlib=/usr/lib/perl5/5.40/vendor_perl         \
                         -D vendorarch=/usr/lib/perl5/5.40/vendor_perl         \
                         -D man1dir=/usr/share/man/man1                         \
                         -D man3dir=/usr/share/man/man3                          \
                         -D pager="/usr/bin/less -isR"                            \
                         -D useshrplib                                             \
                         -D usethreads
            make
            make install
            eic.system.build.continue.perl.ask() {
                read -p "Pending step: Running test suite. Run, skip or quit? (~3 SBUs)" OPT
                case "$OPT" in
                    R)
                        TEST_JOBS=$(nproc) make test_harness > /eilogs/8.43-perl-test.log
                        ;;
                    S)
                        echo "Step skipped."
                        ;;
                    Q)
                        exit
                        ;;
                    *)
                        echo "Unknown command. Repeating questions."
                        eic.system.build.continue.perl.ask
                        ;;
                esac
            }
            eic.system.build.continue.perl.ask
            make install
            unset BUILD_ZLIB BUILD_BZIP2
        popd
        pushd XML-Parser/
            perl Makefile.PL
            make
            make test
            make install
        popd
        pushd intltool/
            sed -i 's:\\\${:\\\$\\{:' intltool-update.in
            ./configure --prefix=/usr
            make
            make check
            make install
            install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
        popd
        pushd autoconf/
            ./configure --prefix=/usr
            make
            eic.system.build.continue.autoconf.ask() {
                read -p "Pending step: Running test suite. Run, skip or quit? (~3 SBUs)" OPT
                case "$OPT" in
                    R)
                        make check > /eilogs/8.46-autoconf-test.log
                        ;;
                    S)
                        echo "Step skipped."
                        ;;
                    Q)
                        exit
                        ;;
                    *)
                        echo "Unknown command. Repeating questions."
                        eic.system.build.continue.autoconf.ask
                        ;;
                esac
            }
            eic.system.build.continue.autoconf.ask
            make install
        popd
        pushd automake/
            ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.17
            make
            eic.system.build.continue.automake.ask() {
                read -p "Pending step: Running test suite. Run, skip or quit? (~3 SBUs)" OPT
                case "$OPT" in
                    R)
                        make -j$(($(nproc)>4?$(nproc):4)) check > /eilogs/8.47-automake-test.log
                        ;;
                    S)
                        echo "Step skipped."
                        ;;
                    Q)
                        exit
                        ;;
                    *)
                        echo "Unknown command. Repeating questions."
                        eic.system.build.continue.automake.ask
                        ;;
                esac
            }
            eic.system.build.continue.automake.ask
            make install
        popd
        pushd openssl/
            ./config --prefix=/usr         \
                    --openssldir=/etc/ssl   \
                    --libdir=lib             \
                    shared                    \
                    zlib-dynamic
            make
            HARNESS_JOBS=$(nproc) make test > /eilogs/8.48-openssl-test.log
            sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
            make MANSUFFIX=ssl install
            mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.3.1
            cp -vfr doc/* /usr/share/doc/openssl-3.3.1
        popd
        pushd kmod
            ./configure --prefix=/usr     \
                        --sysconfdir=/etc  \
                        --with-openssl      \
                        --with-xz            \
                        --with-zstd           \
                        --with-zlib            \
                        --disable-manpages
            make
            make install

            for target in depmod insmod modinfo modprobe rmmod; do
                ln -sfv ../bin/kmod /usr/sbin/$target
                rm -fv /usr/bin/$target
            done
        popd
        pushd elfutils/
            ./configure --prefix=/usr                \
                        --disable-debuginfod          \
                        --enable-libdebuginfod=dummy
            make
            make check
            make -C libelf install
            install -vm644 config/libelf.pc /usr/lib/pkgconfig
            rm /usr/lib/libelf.a
        popd
        pushd libffi/
        	./configure --prefix=/usr          \
        	            --disable-static        \
        	            --with-gcc-arch=native
        	make
        	make check
        	make install
        popd
        pushd python/
            ./configure --prefix=/usr        \
                        --enable-shared       \
                        --with-system-expat    \
                        --enable-optimizations
            make
            eic.system.build.continue.python.ask() {
                read -p "Pending step: Running test suite. Run, skip or quit? (~3 SBUs)" OPT
                case "$OPT" in
                    R)
                        make test TESTOPTS="--timeout 120" > /eilogs/8.52-python-test.log
                        ;;
                    S)
                        echo "Step skipped."
                        ;;
                    Q)
                        exit
                        ;;
                    *)
                        echo "Unknown command. Repeating questions."
                        eic.system.build.continue.python.ask
                        ;;
                esac
            }
            eic.system.build.continue.python.ask
            make install
            cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
            install -v -dm755 /usr/share/doc/python-3.12.5/html

            tar --no-same-owner \
                -xvf ../python-3.12.5-docs-html.tar.bz2
            cp -R --no-preserve=mode python-3.12.5-docs-html/* \
                /usr/share/doc/python-3.12.5/html
        popd
        pushd flit_core/
        	pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
        	pip3 install --no-index --no-user --find-links dist flit_core
        popd
        pushd wheel/
        	pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
        	pip3 install --no-index --find-links=dist wheel
        popd
        pushd setuptools/
        	pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
        	pip3 install --no-index --find-links dist setuptools
        popd
        pushd ninja/
        	export NINJAJOBS=4
        	sed -i '/int Guess/a \
int   j = 0;\
char* jobs = getenv( "NINJAJOBS" );\
if ( jobs != NULL ) j = atoi( jobs );\
if ( j > 0 ) return j;\
' src/ninja.cc
			python3 configure.py --bootstrap
			install -vm755 ninja /usr/bin/
			install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
			install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
		popd
		pushd meson/
			pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
			pip3 install --no-index --find-links dist meson
			install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
			install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
		popd
		pushd coreutils/
			patch -Np1 -i ../coreutils-9.5-i18n-2.patch
			autoreconf -fiv
			FORCE_UNSAFE_CONFIGURE=1 ./configure \
			            --prefix=/usr             \
			            --enable-no-install-program=kill,uptime
			make
			make install
			mv -v /usr/bin/chroot /usr/sbin
			mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
			sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
		popd
		pushd check/
			./configure --prefix=/usr --disable-static
			make
			make docdir=/usr/share/doc/check-0.15.2 install
		popd
		pushd diffutils/
			./configure --prefix=/usr
			make
			make install
		popd
		pushd gawk/
			sed -i 's/extras//' Makefile.in
			./configure --prefix=/usr
			rm -f /usr/bin/gawk-5.3.0
			make install
			ln -sv gawk.1 /usr/share/man/man1/awk.1
			mkdir -pv                                   /usr/share/doc/gawk-5.3.0
			cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.3.0
		popd
        pushd findutils/
            ./configure --prefix=/usr --localstatedir=/var/lib/locate
            make
            make install
        popd
        pushd groff/
            PAGE=A4 ./configure --prefix=/usr # European standard
            make
            make install
        popd
        pushd grub/
            unset {C,CPP,CXX,LD}FLAGS
            echo depends bli part_gpt > grub-core/extra_deps.lst
            ./configure --prefix=/usr          \
                        --sysconfdir=/etc       \
                        --disable-efiemu         \
                        --disable-werror
            make
            make install
            mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
        popd
        pushd gzip/
            ./configure --prefix=/usr
            make
            make install
        popd
        pushd iproute/
            sed -i /ARPD/d Makefile
            rm -fv man/man8/arpd.8
            make NETNS_RUN_DIR=/run/netns
            make SBINDIR=/usr/sbin install
            mkdir -pv             /usr/share/doc/iproute2-6.10.0
            cp -v COPYING README* /usr/share/doc/iproute2-6.10.0
        popd
        pushd kbd/
            patch -Np1 -i ../kbd-2.6.4-backspace-1.patch
            sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
            sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
            ./configure --prefix=/usr --disable-vlock
            make
            make check
            make install
            cp -R -v docs/doc -T /usr/share/doc/kbd-2.6.4
        popd
        pushd libpipeline/
            ./configure --prefix=/usr
            make
            make check
            make install
        popd
        pushd make/
            ./configure --prefix=/usr
            make
            eic.system.build.continue.make.ask() {
                read -p "Pending step: Running test suite. Run, skip or quit? (~3 SBUs)" OPT
                case "$OPT" in
                    R)
                        chown -R tester .
                        su tester -c "PATH=$PATH make check" > /eilogs/8.69-make-test.log
                        ;;
                    S)
                        echo "Step skipped."
                        ;;
                    Q)
                        exit
                        ;;
                    *)
                        echo "Unknown command. Repeating questions."
                        eic.system.build.continue.make.ask
                        ;;
                esac
            }
            eic.system.build.continue.make.ask
            make install
        popd
        pushd patch/
            ./configure --prefix=/usr
            make
            make check
            make install
        popd
        pushd tar/
            FORCE_UNSAFE_CONFIGURE=1  \
            ./configure --prefix=/usr
            make
            make install
            make -C doc install-html docdir=/usr/share/doc/tar-1.35
        popd
        pushd texinfo/
            ./configure --prefix=/usr
            make
            make check
            make install
            make TEXMF=/usr/share/texmf install-tex
        popd
        pushd nano/
            ./configure --prefix=/usr     \
                        --sysconfdir=/etc  \
                        --enable-utf8       \
                        --docdir=/usr/share/doc/nano-8.1
            make
            make install
            install -v -m644 doc/{nano.html,sample.nanorc} /usr/share/doc/nano-8.1
        popd
        pushd MarkupSafe/
            pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
            pip3 install --no-index --no-user --find-links dist Markupsafe
        popd
        pushd jinja/
            pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
            pip3 install --no-index --no-user --find-links dist Jinja2
        popd
        pushd systemd/
            sed -i -e 's/GROUP="render"/GROUP="video"/' \
                   -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
            mkdir -p build
            cd       build

            meson setup ..                \
                  --prefix=/usr            \
                  --buildtype=release       \
                  -D default-dnssec=no       \
                  -D firstboot=false          \
                  -D install-tests=false       \
                  -D ldconfig=false             \
                  -D sysusers=false              \
                  -D rpmmacrosdir=no              \
                  -D homed=disabled                \
                  -D userdb=false                   \
                  -D man=disabled                    \
                  -D mode=release                     \
                  -D pamconfdir=no                     \
                  -D dev-kvm-mode=0660                  \
                  -D nobody-group=nogroup                \
                  -D sysupdate=disabled                   \
                  -D ukify=disabled                        \
                  -D docdir=/usr/share/doc/systemd-256.4
            ninja
            echo 'NAME="TylkoLinux"' > /etc/os-release
            ninja test
            ninja install
            tar -xf ../../systemd-man-pages-256.4.tar.xz \
                --no-same-owner --strip-components=1      \
                -C /usr/share/man
            systemd-machine-id-setup
            systemctl preset-all
        popd
        pushd dbus/
            ./configure --prefix=/usr                        \
                        --sysconfdir=/etc                     \
                        --localstatedir=/var                   \
                        --runstatedir=/run                      \
                        --enable-user-session                    \
                        --disable-static                          \
                        --disable-doxygen-docs                     \
                        --disable-xml-docs                          \
                        --docdir=/usr/share/doc/dbus-1.14.10         \
                        --with-system-socket=/run/dbus/system_bus_socket
            make
            make check
            make install
            ln -sfv /etc/machine-id /var/lib/dbus
        popd
        pushd man-db/
            ./configure --prefix=/usr                         \
                        --docdir=/usr/share/doc/man-db-2.12.1  \
                        --sysconfdir=/etc                       \
                        --disable-setuid                         \
                        --enable-cache-owner=bin                  \
                        --with-browser=/usr/bin/lynx               \
                        --with-vgrind=/usr/bin/vgrind               \
                        --with-grap=/usr/bin/grap
            make
            make check
            make install
        popd
        pushd procps-ng/
            ./configure --prefix=/usr                           \
                        --docdir=/usr/share/doc/procps-ng-4.0.4  \
                        --disable-static                          \
                        --disable-kill                             \
                        --with-systemd
            make src_w_LDADD='$(LDADD) -lsystemd'
            chown -R tester .
            su tester -c "PATH=$PATH make check"
            make install
        popd
        pushd util-linux/
            ./configure --bindir=/usr/bin       \
                        --libdir=/usr/lib        \
                        --runstatedir=/run        \
                        --sbindir=/usr/sbin        \
                        --disable-chfn-chsh         \
                        --disable-login              \
                        --disable-nologin             \
                        --disable-su                   \
                        --disable-setpriv               \
                        --disable-runuser                \
                        --disable-pylibmount              \
                        --disable-liblastlog2              \
                        --disable-static                    \
                        --without-python                     \
                        ADJTIME_PATH=/var/lib/hwclock/adjtime \
                        --docdir=/usr/share/doc/util-linux-2.40.2
            make
            make install
        popd
        pushd e2fsprogs/
            mkdir -v build
            cd       build
            ../configure --prefix=/usr           \
                         --sysconfdir=/etc        \
                         --enable-elf-shlibs       \
                         --disable-libblkid         \
                         --disable-libuuid           \
                         --disable-uuidd              \
                         --disable-fsck
            make
            make check
            make install
            rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
            gunzip -v /usr/share/info/libext2fs.info.gz
            install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
            makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
            install -v -m644 doc/com_err.info /usr/share/info
            install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
        popd
		pushd curl/
			./configure --prefix=/usr                           \
			            --disable-static                        \
			            --with-openssl                          \
			            --enable-threaded-resolver              \
			            --with-ca-path=/etc/ssl/certs           \
			            --without-libpsl
			make
			make install &&
			
			rm -rf docs/examples/.deps &&
			
			find docs \( -name Makefile\* -o  \
			             -name \*.1       -o  \
			             -name \*.3       -o  \
			             -name CMakeLists.txt \) -delete &&
			
			cp -v -R docs -T /usr/share/doc/curl-8.9.1
		popd
        pushd git/
            ./configure --prefix=/usr \
                        --with-gitconfig=/etc/gitconfig \
                        --with-python=python3 &&
            make
            make perllibdir=/usr/lib/perl5/5.40/site_perl install
            ## Prone to certificate errors
            tar -xvf ../git-manpages-2.48.1.tar.xz \
                -C /usr/share/man --no-same-owner --no-overwrite-dir
            mkdir -vp   /usr/share/doc/git-2.48.1 &&
            tar   -xvf   ../git-htmldocs-2.48.1.tar.xz \
                  -C    /usr/share/doc/git-2.48.1 --no-same-owner --no-overwrite-dir &&

            find        /usr/share/doc/git-2.48.1 -type d -exec chmod 755 {} \; &&
            find        /usr/share/doc/git-2.48.1 -type f -exec chmod 644 {} \;
            mkdir -vp /usr/share/doc/git-2.48.1/man-pages/{html,text}         &&
            mv        /usr/share/doc/git-2.48.1/{git*.txt,man-pages/text}     &&
            mv        /usr/share/doc/git-2.48.1/{git*.,index.,man-pages/}html &&

            mkdir -vp /usr/share/doc/git-2.48.1/technical/{html,text}         &&
            mv        /usr/share/doc/git-2.48.1/technical/{*.txt,text}        &&
            mv        /usr/share/doc/git-2.48.1/technical/{*.,}html           &&

            mkdir -vp /usr/share/doc/git-2.48.1/howto/{html,text}             &&
            mv        /usr/share/doc/git-2.48.1/howto/{*.txt,text}            &&
            mv        /usr/share/doc/git-2.48.1/howto/{*.,}html               &&

            sed -i '/^<a href=/s|howto/|&html/|' /usr/share/doc/git-2.48.1/howto-index.html &&
            sed -i '/^\* link:/s|howto/|&html/|' /usr/share/doc/git-2.48.1/howto-index.txt
        popd
        pushd wget/
            ./configure --prefix=/usr      \
                        --sysconfdir=/etc  \
                        --with-ssl=openssl &&
            make
            make install
        popd
        pushd libtasn1/
            ./configure --prefix=/usr --disable-static &&
            make
            make install
        popd
        pushd p11-kit/
            sed '20,$ d' -i trust/trust-extract-compat &&

            cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF
            mkdir p11-build &&
cd    p11-build &&

            meson setup ..            \
                  --prefix=/usr       \
                  --buildtype=release \
                  -D trust_paths=/etc/pki/anchors &&
            ninja
            ninja install &&
            ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
                    /usr/bin/update-ca-certificates
            ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
        popd
        pushd make-ca/
            make install &&
            install -vdm755 /etc/ssl/local
            /usr/sbin/make-ca -g
            wget http://www.cacert.org/certs/root.crt &&
            wget http://www.cacert.org/certs/class3.crt &&
            openssl x509 -in root.crt -text -fingerprint -setalias "CAcert Class 1 root" \
                    -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
                    > /etc/ssl/local/CAcert_Class_1_root.pem &&
            openssl x509 -in class3.crt -text -fingerprint -setalias "CAcert Class 3 root" \
                    -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
                    > /etc/ssl/local/CAcert_Class_3_root.pem &&
            /usr/sbin/make-ca -r
        popd
        pushd cpio/
            ./configure --prefix=/usr \
                        --enable-mt   \
                        --with-rmt=/usr/libexec/rmt &&
            make &&
            makeinfo --html            -o doc/html      doc/cpio.texi &&
            makeinfo --html --no-split -o doc/cpio.html doc/cpio.texi &&
            makeinfo --plaintext       -o doc/cpio.txt  doc/cpio.texi
            make install &&
            install -v -m755 -d /usr/share/doc/cpio-2.15/html &&
            install -v -m644    doc/html/* \
                                /usr/share/doc/cpio-2.15/html &&
            install -v -m644    doc/cpio.{html,txt} \
                                /usr/share/doc/cpio-2.15
        popd
        pushd hwdata/
            ./configure --prefix=/usr --disable-blacklist
            make install
        popd
        pushd pciutils/
            sed -r '/INSTALL/{/PCI_IDS|update-pciids /d; s/update-pciids.8//}' \
                -i Makefile
            make PREFIX=/usr                \
                 SHAREDIR=/usr/share/hwdata \
                 SHARED=yes
            make PREFIX=/usr                \
                 SHAREDIR=/usr/share/hwdata \
                 SHARED=yes                 \
                 install install-lib        &&

            chmod -v 755 /usr/lib/libpci.so
        popd
        cat > /usr/bin/which << "EOF"
#!/bin/bash
type -pa "$@" | head -n 1 ; exit ${PIPESTATUS[0]}
EOF
        chmod -v 755 /usr/bin/which
        chown -v root:root /usr/bin/which
    popd
    echo "[i] The system build has successfully finished."
}

function eic.strip() {
	save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
	             libc.so.6
	             libthread_db.so.1
	             libquadmath.so.0.0.0
	             libstdc++.so.6.0.33
	             libitm.so.1.0.0
	             libatomic.so.1.2.0"
	
	cd /usr/lib
	
	for LIB in $save_usrlib; do
	    objcopy --only-keep-debug --compress-debug-sections=zlib $LIB $LIB.dbg
	    cp $LIB /tmp/$LIB
	    strip --strip-unneeded /tmp/$LIB
	    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
	    install -vm755 /tmp/$LIB /usr/lib
	    rm /tmp/$LIB
	done
	
	online_usrbin="bash find strip"
	online_usrlib="libbfd-2.43.1.so
	               libsframe.so.1.0.0
	               libhistory.so.8.2
	               libncursesw.so.6.5
	               libm.so.6
	               libreadline.so.8.2
	               libz.so.1.3.1
	               libzstd.so.1.5.6
	               $(cd /usr/lib; find libnss*.so* -type f)"
	
	for BIN in $online_usrbin; do
	    cp /usr/bin/$BIN /tmp/$BIN
	    strip --strip-unneeded /tmp/$BIN
	    install -vm755 /tmp/$BIN /usr/bin
	    rm /tmp/$BIN
	done
	
	for LIB in $online_usrlib; do
	    cp /usr/lib/$LIB /tmp/$LIB
	    strip --strip-unneeded /tmp/$LIB
	    install -vm755 /tmp/$LIB /usr/lib
	    rm /tmp/$LIB
	done
	
	for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
	         $(find /usr/lib -type f -name \*.a)                 \
	         $(find /usr/{bin,sbin,libexec} -type f); do
	    case "$online_usrbin $online_usrlib $save_usrlib" in
	        *$(basename $i)* )
	            ;;
	        * ) strip --strip-unneeded $i
	            ;;
	    esac
	done
	
	unset BIN LIB save_usrlib online_usrbin online_usrlib
}

function eic.system.build.clean() {
	rm -rfv /tmp/{*,.*}
	find /usr/lib /usr/libexec -name \*.la -delete
	find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
	userdel -r tester
}

function eic.config.network.devicenaming() {
    ln -s /dev/null /etc/systemd/network/99-default.link
    read -p "[i] Enter MAC address of desired device: " OPT_MAC
    read -p "[i] Enter the desired name of your interface: " OPT_NET_INT
    
    echo -e "[Match]
# Change the MAC address as appropriate for your network device
MACAddress=${OPT_MAC}

[Link]
Name=${OPT_NET_INT}" > /etc/systemd/network/10-ether0.link
}

function eic.config.network.staticip() {
    read -p "[i] Enter the name of the configured interface: " OPT_NET_INT
	echo -e "[Match]
Name=${OPT_NET_INT}

[Network]
Address=192.168.0.2/24
Gateway=192.168.0.1" > /etc/systemd/network/10-eth-static.network
	echo "[?] Add DNS? If no, type N. If yes, type DNS address."
	read -p "> " OPT_NET_DNS
	case "$OPT_NET_DNS" in
		N|n|No|no|nO|NO)
			echo "[i] Skipped DNS addition."
		;;
		*)
			echo -e "DNS=${OPT_NET_DNS}" >> /etc/systemd/network/10-eth-static.network
		;;
	esac
	echo "[?] Add domain? If no, type N. If yes, type domain name."
	read -p "> " OPT_NET_DOMAIN
	case "$OPT_NET_DOMAIN" in
		N|n|No|no|nO|NO)
			echo "[i] Skipped domain addition."
		;;
		*)
			echo -e "Domains=${OPT_NET_DOMAIN}" >> /etc/systemd/network/10-eth-static.network
		;;
	esac
}

function eic.config.network.dhcp() {
    read -p "[i] Enter the name of the configured interface: " OPT_NET_INT
	echo -e "
[Match]
Name=${OPT_NET_INT}

[Network]
DHCP=ipv4

[DHCPv4]
UseDomains=true" > /etc/systemd/network/10-eth-dhcp.network
}



function eic.config.network.systemd.resolve() {
	case "$@" in
		on|enable)
			echo "[i] Enabling systemd-resolved..."
			systemctl enable systemd-resolved
		;;
		off|disable)
			echo "[i] Disabling systemd-resolved..."
			systemctl disable systemd-resolved
		;;
		*)
			echo "[!] Unrecognised (or empty) argument."
			echo "[i] Syntax: eic.config.network.systemd.resolve (on/off/enable/disable)"
		;;
	esac
}
			
function eic.config.network.staticresolver() {
	echo "[?] Add domain? If no, type N. If yes, type domain name."
	read -p "> " OPT_NET_DOMAIN
	case "$OPT_NET_DOMAIN" in
		N|n|No|no|nO|NO)
			echo "[i] Skipped domain addition."
		;;
		*)
			echo -e "domain ${OPT_NET_DOMAIN}" >> /etc/resolv.conf
		;;
	esac
	echo "[?] Add primary nameserver? If no, type N. If yes, type nameserver name."
	read -p "> " OPT_NET_NS1
	case "$OPT_NET_NS1" in
		N|n|No|no|nO|NO)
			echo "[i] Skipped primary nameserver addition."
		;;
		*)
			echo -e "nameserver ${OPT_NET_NS1}" >> /etc/resolv.conf
		;;
	esac
	echo "[?] Add secondary nameserver? If no, type N. If yes, type nameserver name."
	read -p "> " OPT_NET_NS2
	case "$OPT_NET_NS2" in
		N|n|No|no|nO|NO)
			echo "[i] Skipped secondary nameserver addition."
		;;
		*)
			echo -e "nameserver ${OPT_NET_NS2}" >> /etc/resolv.conf
		;;
	esac
#	echo -e "
## Begin /etc/resolv.conf
#
#domain ${OPT_NET_DOMAIN}
#nameserver ${OPT_NET_NS1}
#nameserver ${OPT_NET_NS2}

## End /etc/resolv.conf
#" > /etc/resolv.conf
}


function eic.config.network.hostname() {
	echo "$@" > /etc/hostname
}

function eic.config.time.createAdj() {
	cat > /etc/adjtime << "EOF"
0.0 0 0.0
0
LOCAL
EOF
	echo "[i] Adjusted /etc/adjtime according to LFS instructions."
}

function eic.config.time.clarifyUTC() {
	timedatectl set-local-rtc 1
}

function eic.config.time.set() {
	read -p "[i] Enter year in 4 digits (no spaces): " YEAR
	read -p "[i] Enter month number in 2 digits (no spaces): " MONTH
	read -p "[i] Enter day number in 2 digits (no spaces): " DAY
	read -p "[i] Enter hour in 2 digits (no spaces) (24-hour format): " HOUR
	read -p "[i] Enter minute in 2 digits (no spaces): " MINUTE
	read -p "[i] Enter second in 2 digits (no spaces): " SECOND
	timedatectl set-time $YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND
}

function eic.config.time.tz() {
	timedatectl set-timezone "$@"
}

function eic.config.time.nts() {
	case "$@" in
		on|enable)
			echo "[i] Enabling Network Time Synchronisation..."
			systemctl enable systemd-timesyncd
		;;
		off|disable)
			echo "[i] Disabling Network Time Synchronisation..."
			systemctl disable systemd-timesyncd
		;;
		*)
			echo "[!] Unrecognised (or empty) argument."
			echo "[i] Syntax: eic.config.time.nts (on/off/enable/disable)"
		;;
	esac
}

function eic.config.console.preset() {
	echo FONT=Lat2-Terminus16 > /etc/vconsole.conf
}

function eic.config.console.keymap() {
	echo "KEYMAP=$*" >> /etc/vconsole.conf
}

function eic.config.locale.set() {
	read -p "[i] Enter language code (for example de): " LANGUAGE
	read -p "[i] Enter country code (for example CH): " COUNTRY
	read -p "[i] Enter character map code (for example UTF-8): " CHARACTERMAP
	read -p "[i] Enter modifiers, leave empty if none (needs to start with @): " MODIFIERS
	echo -e "LANG=${LANGUAGE}_${COUNTRY}.${CHARACTERMAP}${MODIFIERS}" > /etc/locale.conf
	cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  source /etc/locale.conf

  for i in $(locale); do
    key=${i%=*}
    if [[ -v $key ]]; then
      export $key
    fi
  done
fi

# End /etc/profile
EOF
}

function eic.config.create.inputrc() {
	cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF
}

function eic.config.create.shells() {
	cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF
}

function eic.config.systemd.disableScreenClearing() {
	case "$@" in
		yes|YES|Yes)
			mkdir -pv /etc/systemd/system/getty@tty1.service.d
			
			cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf << EOF
[Service]
TTYVTDisallocate=no
EOF
			;;
			no|NO|No)
				rm /etc/systemd/system/getty@tty1.service.d/noclear.conf
			;;
			*)
				echo "[!] Unrecognised (or empty) argument."
				echo "[i] Syntax: eic.config.systemd.disableScreenClearing (yes/no)"
			;;
	esac
}

function eic.config.systemd.limitCoreDumpSize() {
		mkdir -pv /etc/systemd/coredump.conf.d || echo "[i] Great, the directory already exists!"
		echo -e "
[Coredump]
MaxUse=$*" > /etc/systemd/coredump.conf.d/maxuse.conf
}

function eic.linux.install() {
    pushd /sources/linux/
        read -p "[i] In this section, it is recommended to have the TylkoLinux build/installation guide open and ready. [ENTER]"
        make mrproper
        make menuconfig
        make
        make modules_install
		read -p "[i] Mount boot partition? <Y/N>: " OPT
		case $OPT in
			Y|y|Yes|yes|YES)
		        mount /boot
		    ;;
		    *)
		        echo "[i] Skipped mount."
		    ;;
		esac
        cp -iv arch/x86/boot/bzImage /boot/vmlinuz-6.10.5-lfs-12.2-systemd
        cp -iv System.map /boot/System.map-6.10.5
        cp -iv .config /boot/config-6.10.5
        cp -r Documentation -T /usr/share/doc/linux-6.10.5
        install -v -m755 -d /etc/modprobe.d
        cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
    popd
}

function eic.plus() {
    pushd /sources/
        tar -xvf NetworkManager-1.48.8.tar.xz
        mv NetworkManager-1.48.8 NetworkManager
        tar -xvf polkit-125.tar.gz
        mv polkit-125 polkit
        tar -xvf glib-2.80.4.tar.xz
        mv glib-2.80.4 glib
        tar -xvf packaging-24.1.tar.gz
        mv packaging-24.1 packaging
        tar -xvf newt-0.52.24.tar.gz
        mv newt-0.52.24 newt
        tar -xvf slang-2.3.3.tar.bz2
        mv slang-2.3.3 slang
        tar -xvf gpm-1.20.7.tar.bz2
        mv gpm-1.20.7 gpm
        tar -xvf icu4c-76_1-src.tgz
        tar -xvf libxml2-2.13.5.tar.xz
        mv libxml2-2.13.5 libxml2
        tar -xvf libxslt-1.1.42.tar.xz
        mv libxslt-1.1.42 libxslt
        pushd icu/
            cd source                 &&

            ./configure --prefix=/usr &&
            make
            make install
        popd
        pushd libxml2/
            ./configure --prefix=/usr           \
                        --sysconfdir=/etc       \
                        --disable-static        \
                        --with-history          \
                        --with-icu              \
                        PYTHON=/usr/bin/python3 \
                        --docdir=/usr/share/doc/libxml2-2.13.5 &&
            make
            make install
            rm -vf /usr/lib/libxml2.la &&
            sed '/libs=/s/xml2.*/xml2"/' -i /usr/bin/xml2-config
        popd
        pushd libxslt/
            ./configure --prefix=/usr                          \
                        --disable-static                       \
                        --docdir=/usr/share/doc/libxslt-1.1.42 &&
            make
            make install
        popd
        pushd gpm/
            patch -Np1 -i ../gpm-1.20.7-consolidated-1.patch                &&
            ./autogen.sh                                                    &&
            ./configure --prefix=/usr --sysconfdir=/etc ac_cv_path_emacs=no &&
            make            
            make install                                          &&

            install-info --dir-file=/usr/share/info/dir           \
                         /usr/share/info/gpm.info                 &&

            rm -fv /usr/lib/libgpm.a                              &&
            ln -sfv libgpm.so.2.1.0 /usr/lib/libgpm.so            &&
            install -v -m644 conf/gpm-root.conf /etc              &&

            install -v -m755 -d /usr/share/doc/gpm-1.20.7/support &&
            install -v -m644    doc/support/*                     \
                                /usr/share/doc/gpm-1.20.7/support &&
            install -v -m644    doc/{FAQ,HACK_GPM,README*}        \
                                /usr/share/doc/gpm-1.20.7
        popd
        pushd slang/
            ./configure --prefix=/usr \
                        --sysconfdir=/etc \
                        --with-readline=gnu &&
            make -j1 RPATH=
            make install_doc_dir=/usr/share/doc/slang-2.3.3   \
                    SLSH_DOC_DIR=/usr/share/doc/slang-2.3.3/slsh \
                    RPATH= install
        popd
        if [ -d "/sources/popt" ]; then
            echo "[i] popt has already been extracted, it seems.";
        else
            tar -xvf popt-*.tar.gz
		    mv popt-1.19 popt
        fi
        pushd popt/
            ./configure --prefix=/usr --disable-static &&
            make
            make install
        popd
        pushd newt/
            sed -e '/install -m 644 $(LIBNEWT)/ s/^/#/' \
                -e '/$(LIBNEWT):/,/rv/ s/^/#/'          \
                -e 's/$(LIBNEWT)/$(LIBNEWTSH)/g'        \
                -i Makefile.in                          &&

            ./configure --prefix=/usr           \
                        --with-gpm-support      \
                        --with-python=python3.12 &&
            make
            make install
        popd
        pushd packaging/
            pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
            pip3 install --no-index --find-links=dist --no-cache-dir --no-user packaging
        popd
        pushd glib/
            patch -Np1 -i ../glib-skip_warnings-1.patch
            if [ -e /usr/include/glib-2.0 ]; then
                rm -rf /usr/include/glib-2.0.old &&
                mv -vf /usr/include/glib-2.0{,.old}
            fi
            mkdir build
            cd    build &&
            
            meson setup ..                  \
                  --prefix=/usr             \
                  --buildtype=release       \
                  -D introspection=disabled #\
                  # -D man-pages=enabled      
            ninja
            ninja install
            tar xf ../../gobject-introspection-1.80.1.tar.xz &&

            meson setup gobject-introspection-1.80.1 gi-build \
                        --prefix=/usr --buildtype=release     &&
            ninja -C gi-build
            ninja -C gi-build install

            meson configure -D introspection=enabled &&
            ninja
            ninja install
        popd
        tar -xvf duktape-2.7.0.tar.xz
        mv duktape-2.7.0 duktape
        pushd duktape/
            sed -i 's/-Os/-O2/' Makefile.sharedlibrary
            make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr
            make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr install
        popd
        tar -xvf Linux-PAM-1.6.1.tar.xz
        mv Linux-PAM-1.6.1 Linux-PAM
        pushd Linux-PAM/
            autoreconf -fi
            tar -xvf ../Linux-PAM-1.6.1-docs.tar.xz --strip-components=1
            ./configure --prefix=/usr                        \
                        --sbindir=/usr/sbin                  \
                        --sysconfdir=/etc                    \
                        --libdir=/usr/lib                    \
                        --enable-securedir=/usr/lib/security \
                        --docdir=/usr/share/doc/Linux-PAM-1.6.1 &&

            make
            install -v -m755 -d /etc/pam.d &&

            make install &&
            chmod -v 4755 /usr/sbin/unix_chkpwd

            install -vdm755 /etc/pam.d &&
            cat > /etc/pam.d/system-account << "EOF" &&
# Begin /etc/pam.d/system-account

account   required    pam_unix.so

# End /etc/pam.d/system-account
EOF

            cat > /etc/pam.d/system-auth << "EOF" &&
# Begin /etc/pam.d/system-auth

auth      required    pam_unix.so

# End /etc/pam.d/system-auth
EOF

            cat > /etc/pam.d/system-session << "EOF" &&
# Begin /etc/pam.d/system-session

session   required    pam_unix.so

# End /etc/pam.d/system-session
EOF

            cat > /etc/pam.d/system-password << "EOF"
# Begin /etc/pam.d/system-password

# use yescrypt hash for encryption, use shadow, and try to use any
# previously defined authentication token (chosen password) set by any
# prior module.
password  required    pam_unix.so       yescrypt shadow try_first_pass

# End /etc/pam.d/system-password
EOF
            cat > /etc/pam.d/other << "EOF"
# Begin /etc/pam.d/other

auth        required        pam_warn.so
auth        required        pam_deny.so
account     required        pam_warn.so
account     required        pam_deny.so
password    required        pam_warn.so
password    required        pam_deny.so
session     required        pam_warn.so
session     required        pam_deny.so

# End /etc/pam.d/other
EOF
        popd
        pushd shadow/
            sed -i 's@DICTPATH.*@DICTPATH\t/lib/cracklib/pw_dict@' etc/login.defs
            sed -i 's/groups$(EXEEXT) //' src/Makefile.in          &&

            find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \; &&
            find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \; &&
            find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \; &&

            sed -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD YESCRYPT@' \
                -e 's@/var/spool/mail@/var/mail@'                   \
                -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
                -i etc/login.defs                                   &&

            ./configure --sysconfdir=/etc   \
                        --disable-static    \
                        --without-libbsd    \
                        --with-{b,yes}crypt &&
            make
            make exec_prefix=/usr pamddir= install
            install -v -m644 /etc/login.defs /etc/login.defs.orig &&
            for FUNCTION in FAIL_DELAY               \
                            FAILLOG_ENAB             \
                            LASTLOG_ENAB             \
                            MAIL_CHECK_ENAB          \
                            OBSCURE_CHECKS_ENAB      \
                            PORTTIME_CHECKS_ENAB     \
                            QUOTAS_ENAB              \
                            CONSOLE MOTD_FILE        \
                            FTMP_FILE NOLOGINS_FILE  \
                            ENV_HZ PASS_MIN_LEN      \
                            SU_WHEEL_ONLY            \
                            CRACKLIB_DICTPATH        \
                            PASS_CHANGE_TRIES        \
                            PASS_ALWAYS_WARN         \
                            CHFN_AUTH ENCRYPT_METHOD \
                            ENVIRON_FILE
            do
                sed -i "s/^${FUNCTION}/# &/" /etc/login.defs
            done
            cat > /etc/pam.d/login << "EOF"
# Begin /etc/pam.d/login

# Set failure delay before next prompt to 3 seconds
auth      optional    pam_faildelay.so  delay=3000000

# Check to make sure that the user is allowed to login
auth      requisite   pam_nologin.so

# Check to make sure that root is allowed to login
# Disabled by default. You will need to create /etc/securetty
# file for this module to function. See man 5 securetty.
#auth      required    pam_securetty.so

# Additional group memberships - disabled by default
#auth      optional    pam_group.so

# include system auth settings
auth      include     system-auth

# check access for the user
account   required    pam_access.so

# include system account settings
account   include     system-account

# Set default environment variables for the user
session   required    pam_env.so

# Set resource limits for the user
session   required    pam_limits.so

# Display the message of the day - Disabled by default
#session   optional    pam_motd.so

# Check user's mail - Disabled by default
#session   optional    pam_mail.so      standard quiet

# include system session and password settings
session   include     system-session
password  include     system-password

# End /etc/pam.d/login
EOF
            cat > /etc/pam.d/passwd << "EOF"
# Begin /etc/pam.d/passwd

password  include     system-password

# End /etc/pam.d/passwd
EOF
            cat > /etc/pam.d/su << "EOF"
# Begin /etc/pam.d/su

# always allow root
auth      sufficient  pam_rootok.so

# Allow users in the wheel group to execute su without a password
# disabled by default
#auth      sufficient  pam_wheel.so trust use_uid

# include system auth settings
auth      include     system-auth

# limit su to users in the wheel group
# disabled by default
#auth      required    pam_wheel.so use_uid

# include system account settings
account   include     system-account

# Set default environment variables for the service user
session   required    pam_env.so

# include system session settings
session   include     system-session

# End /etc/pam.d/su
EOF
            cat > /etc/pam.d/chpasswd << "EOF"
# Begin /etc/pam.d/chpasswd

# always allow root
auth      sufficient  pam_rootok.so

# include system auth and account settings
auth      include     system-auth
account   include     system-account
password  include     system-password

# End /etc/pam.d/chpasswd
EOF

            sed -e s/chpasswd/newusers/ /etc/pam.d/chpasswd >/etc/pam.d/newusers
            cat > /etc/pam.d/chage << "EOF"
# Begin /etc/pam.d/chage

# always allow root
auth      sufficient  pam_rootok.so

# include system auth and account settings
auth      include     system-auth
account   include     system-account

# End /etc/pam.d/chage
EOF
            for PROGRAM in chfn chgpasswd chsh groupadd groupdel \
                           groupmems groupmod useradd userdel usermod
            do
                install -v -m644 /etc/pam.d/chage /etc/pam.d/${PROGRAM}
                sed -i "s/chage/$PROGRAM/" /etc/pam.d/${PROGRAM}
            done
            if [ -f /etc/login.access ]; then mv -v /etc/login.access{,.NOUSE}; fi
            if [ -f /etc/limits ]; then mv -v /etc/limits{,.NOUSE}; fi
        popd
        pushd elfutils/
            make -C libdwelf install
            make -C libdwfl install
        popd
        pushd systemd/
            sed -i -e 's/GROUP="render"/GROUP="video"/' \
                -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
            rm -r build
            mkdir build &&
            cd    build &&

            meson setup ..                 \
                  --prefix=/usr            \
                  --buildtype=release      \
                  -D default-dnssec=no     \
                  -D firstboot=false       \
                  -D install-tests=false   \
                  -D ldconfig=false        \
                  -D man=auto              \
                  -D sysusers=false        \
                  -D rpmmacrosdir=no       \
                  -D homed=disabled        \
                  -D userdb=false          \
                  -D mode=release          \
                  -D pam=enabled           \
                  -D pamconfdir=/etc/pam.d \
                  -D dev-kvm-mode=0660     \
                  -D nobody-group=nogroup  \
                  -D sysupdate=disabled    \
                  -D ukify=disabled        \
                  -D docdir=/usr/share/doc/systemd-256.4 &&

            ninja
            ninja install
            grep 'pam_systemd' /etc/pam.d/system-session ||
            cat >> /etc/pam.d/system-session << "EOF"
# Begin Systemd addition

session  required    pam_loginuid.so
session  optional    pam_systemd.so

# End Systemd addition
EOF

            cat > /etc/pam.d/systemd-user << "EOF"
# Begin /etc/pam.d/systemd-user

account  required    pam_access.so
account  include     system-account

session  required    pam_env.so
session  required    pam_limits.so
session  required    pam_loginuid.so
session  optional    pam_keyinit.so force revoke
session  optional    pam_systemd.so

auth     required    pam_deny.so
password required    pam_deny.so

# End /etc/pam.d/systemd-user
EOF
            systemctl daemon-reexec
        popd
        pushd polkit/
            groupadd -fg 27 polkitd &&
            useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
                    -g polkitd -s /bin/false polkitd
            mkdir build &&
            cd    build &&

            meson setup ..                   \
                  --prefix=/usr              \
                  --buildtype=release        \
                  -D session_tracking=logind
            ninja
            ninja install
        popd
        tar -xvf libndp-1.9.tar.gz
        mv libndp-1.9 libndp
        pushd libndp/
            ./configure --prefix=/usr        \
                        --sysconfdir=/etc    \
                        --localstatedir=/var \
                        --disable-static     &&
            make
            make install
        popd
        systemctl disable --now systemd-networkd
        pushd NetworkManager
            sed -i "s/option('libpsl', type: 'boolean', value: true, description: 'Link against libpsl')/option('libpsl', type: 'boolean', value: false, description: 'Link against libpsl')/g" meson_options.txt
            grep -rl '^#!.*python$' | xargs sed -i '1s/python/&3/'
            CXXFLAGS+="-O2 -fPIC"             \
            meson setup ..                    \
                  --prefix=/usr               \
                  --buildtype=release         \
                  -D libaudit=no              \
                  -D nmtui=true               \
                  -D ovs=false                \
                  -D ppp=false                \
                  -D selinux=false            \
                  -D qt=false                 \
                  -D session_tracking=systemd \
                  -D tests=no                 \
                  -D modem_manager=false      \
                  -D crypto=null              &&
            ninja
        popd
    popd
}

function eic.rpm.install() {
	# Enter /sources/ directory
	pushd /sources/
		# Extract needed packages for compiling RPM
		bunzip2 -v -v rpm-4.18.0.tar.bz2
		tar -xvf rpm-4.18.0*.tar
		mv rpm-4.18.0 rpm
		tar -xvf debugedit*.tar.xz
		mv debugedit-0.3 debugedit
		tar -xvf lua*.gz
		mv lua-5.4.7 lua
		tar -xvf popt-*.tar.gz
		mv popt-1.19 popt
		tar -xvf curl-*.tar.xz
		mv curl-8.9.1 curl
		tar -xvf libarchive-3.7.4.tar.xz
		mv libarchive-3.7.4 libarchive
		tar -xvf nghttp2-*.xz
		mv nghttp2-1.64.0 nghttp2
		tar -xvf libuv-*.gz
		mv libuv-v1.50.0 libuv
        tar -xvf sqlite-autoconf-3480000.tar.gz
		tar -xvf libgcrypt-1.11.0.tar.bz2
		tar -xvf libgpg-error-1.50.tar.bz2
		mv libgcrypt-1.11.0 libgcrypt
		mv libgpg-error-1.50 libgpg-error
		pushd libgpg-error/
		    ./configure --prefix=/usr &&
		    make
		    make install
		    install -v -m644 -D README /usr/share/doc/libgpg-error-1.50/README
		popd
		pushd libgcrypt/
		    ./configure --prefix=/usr &&
		    make                      &&
		
		    make -C doc html                                                       &&
		    makeinfo --html --no-split -o doc/gcrypt_nochunks.html doc/gcrypt.texi &&
		    makeinfo --plaintext       -o doc/gcrypt.txt           doc/gcrypt.texi
		    make install &&
		    install -v -dm755   /usr/share/doc/libgcrypt-1.11.0 &&
		    install -v -m644    README doc/{README.apichanges,fips*,libgcrypt*} \
		                    /usr/share/doc/libgcrypt-1.11.0 &&
		
		    install -v -dm755   /usr/share/doc/libgcrypt-1.11.0/html &&
		    install -v -m644 doc/gcrypt.html/* \
		                    /usr/share/doc/libgcrypt-1.11.0/html &&
		    install -v -m644 doc/gcrypt_nochunks.html \
		                    /usr/share/doc/libgcrypt-1.11.0      &&
		    install -v -m644 doc/gcrypt.{txt,texi} \
		                    /usr/share/doc/libgcrypt-1.11.0
		popd
		pushd libarchive/
			./configure --prefix=/usr --disable-static &&
			make
			make install
		popd
		pushd nghttp2/
			./configure --prefix=/usr     \
			            --disable-static  \
			            --enable-lib-only \
			            --docdir=/usr/share/doc/nghttp2-1.64.0 &&
			make
			make install
		popd
		pushd libuv/
			sh autogen.sh                              &&
			./configure --prefix=/usr --disable-static &&
			make
			make install
		popd
		pushd debugedit/
			./configure --prefix=/usr 
			make
			make install
		popd
		pushd lua/
			cat > lua.pc << "EOF"
V=5.4
R=5.4.7

prefix=/usr
INSTALL_BIN=${prefix}/bin
INSTALL_INC=${prefix}/include
INSTALL_LIB=${prefix}/lib
INSTALL_MAN=${prefix}/share/man/man1
INSTALL_LMOD=${prefix}/share/lua/${V}
INSTALL_CMOD=${prefix}/lib/lua/${V}
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include
			
Name: Lua
Description: An Extensible Extension Language
Version: ${R}
Requires:
Libs: -L${libdir} -llua -lm -ldl
Cflags: -I${includedir}
EOF
			patch -Np1 -i ../lua-5.4.7-shared_library-1.patch
			make linux
			make all install
			make INSTALL_TOP=/usr                \
			     INSTALL_DATA="cp -d"            \
			     INSTALL_MAN=/usr/share/man/man1 \
			     TO_LIB="liblua.so liblua.so.5.4 liblua.so.5.4.7" \
			     install &&
			
			mkdir -pv                      /usr/share/doc/lua-5.4.7 &&
			cp -v doc/*.{html,css,gif,png} /usr/share/doc/lua-5.4.7 &&
			
			install -v -m644 -D lua.pc /usr/lib/pkgconfig/lua.pc
		popd
		pushd popt/
			./configure --prefix=/usr --disable-static
			make
			make install
		popd
		pushd /sources/elfutils/
			make -C libdw install
            install -vm644 config/libdw.pc /usr/lib/pkgconfig
            rm /usr/lib/libdw.a

		popd
        pushd sqlite-autoconf-3480000/
            ./configure --prefix=/usr     \
                        --disable-static  \
                        --enable-fts{4,5} \
                        CPPFLAGS="-D SQLITE_ENABLE_COLUMN_METADATA=1 \
                                  -D SQLITE_ENABLE_UNLOCK_NOTIFY=1   \
                                  -D SQLITE_ENABLE_DBSTAT_VTAB=1     \
                                  -D SQLITE_SECURE_DELETE=1"         &&
            make
            make install
        popd
		pushd /sources/rpm
			./autogen.sh --noconfigure
			./configure --prefix=/usr
			make
			make install
		popd
	popd
}

function eic.zypper.install() {
	pushd /sources/
        tar -xvf boost-1.86.0-b2-nodocs.tar.xz
        mv boost-1.86.0 boost
        pushd boost/
            patch -Np1 -i ../boost-1.86.0-upstream_fixes-1.patch
            case $(uname -m) in
               i?86)
                  sed -e "s/defined(__MINGW32__)/& || defined(__i386__)/" \
                      -i ./libs/stacktrace/src/exception_headers.h ;;
            esac
            ./bootstrap.sh --prefix=/usr --with-python=python3 &&
            ./b2 stage $MAKEFLAGS threading=multi link=shared
            rm -rf /usr/lib/cmake/[Bb]oost*
            ./b2 install threading=multi link=shared
        popd
        mv 1.14.81.tar.gz zypper-1.14.81.tar.gz
        tar -xvf zypper-1.14.81.tar.gz
        mv zypper-1.14.81 zypper
        git clone https://github.com/jbeder/yaml-cpp.git
        pushd yaml-cpp/
            mkdir build && cd build
            cmake .. -DCMAKE_INSTALL_PREFIX=/usr
            make -j$(nproc)
            make install
        popd
        git clone https://github.com/openSUSE/libsolv.git
        pushd libsolv/
            mkdir build
            cd build
            cmake .. -DCMAKE_INSTALL_PREFIX=/usr &&
            make
            make install
        popd
        git clone https://github.com/openSUSE/libzypp
        pushd libzypp/
            git checkout tags/17.35.19
            mkdir build
            cd    build
            cmake .. -D CMAKE_INSTALL_PREFIX:PATH=/usr -D ENABLE_BUILD_DOCS:BOOL=OFF

            # not done
        popd
        mkdir build
        cd    build
    popd
}

function eic.signoff() {
    echo 12.2-systemd-tylux > /etc/lfs-release
    cat > /etc/lsb-release << "EOF"
DISTRIB_ID="TylkoLinux"
DISTRIB_RELEASE="25.01"
DISTRIB_CODENAME="snyx"
DISTRIB_DESCRIPTION="TylkoLinux Snyx"
EOF
    cat > /etc/os-release << "EOF"
NAME="TylkoLinux"
VERSION="25.01"
ID=tylux
PRETTY_NAME="TylkoLinux 25.01 Snyx (LFS 12.2-systemd)"
VERSION_CODENAME="snyx"
HOME_URL="https://github.com/kevadesu/TylkoLinux"
EOF
}

function eic.error() {
    echo "[i] The installer has encountered a critical error and needs to quit."
    case "$@" in
        D404_SRC)
            echo "[!] Directory /sources/ does NOT exist!"
        ;;
        *)
            echo "[!] We were unable to determine the error."
        ;;
    esac
}

main
