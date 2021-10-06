#! /bin/sh

set -xe

# CHROOT, CODENAME, MIRROR_URL need to be exported.

[ -n "$CHROOT" ] || {
    echo "Missing mandatory argument: CHROOT"
    printf "Usage:\n  %s CHROOT CODENAME MIRROR_URL\n" "$(basename "${0}")"
    exit 2
}

[ -n "$CODENAME" ] || {
    echo "Missing mandatory argument: CODENAME"
    printf "Usage:\n  %s CHROOT CODENAME MIRROR_URL\n" "$(basename "${0}")"
    exit 2
}

[ -n "$MIRROR_URL" ] || {
    echo "Missing mandatory argument: MIRROR_URL"
    printf "Usage:\n  %s CHROOT CODENAME MIRROR_URL\n" "$(basename "${0}")"
    exit 2
}

{
    cat << EOS
# Set appropriate apt sources
deb ${MIRROR_URL} ${CODENAME} main
deb ${MIRROR_URL} ${CODENAME}-updates main
deb ${MIRROR_URL} ${CODENAME} universe
deb ${MIRROR_URL} ${CODENAME}-updates universe
deb ${MIRROR_URL} ${CODENAME} multiverse
deb ${MIRROR_URL} ${CODENAME}-updates multiverse
EOS
} | sudo tee "${CHROOT}/etc/apt/sources.list"
