#! /bin/sh

set -xe

# CHROOT needs to be exported.

[ -n "$CHROOT" ] || {
    echo "Missing mandatory variable: CHROOT"
    exit 2
}
[ -e "$CHROOT" ] || {
    echo "Wrong mandatory variable: CHROOT=$CHROOT"
    exit 2
}

{
    cat << EOS

# Fixing debian locales warning during apt installs
LANG="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
EOS
} | sudo tee -a "${CHROOT}/etc/default/locale"
