#! /bin/sh

# Umount all chroot-related mounts

set -x

# . ./common.sh

CHROOT="${1:-${CHROOT}}"

[ -n "$CHROOT" ] || {
    echo "$(basename "$0"): Missing mandatory argument: CHROOT"
    exit 2
}

# Anything other than 'false' would make it keep it
# (and false is the default)
KEEP_CHROOT_MOUNTED=${2:-false}

#sudo umount "${CHROOT}/run/user/1000"
#sudo umount "${CHROOT}/run/lock"
#sudo umount "${CHROOT}/run"

#sudo umount "${CHROOT}/sys/fs/cgroup"

sudo umount "${CHROOT}/dev/shm"
sudo umount "${CHROOT}/dev/pts"

sudo umount "${CHROOT}/dev"
sudo umount "${CHROOT}/sys"
sudo umount  "${CHROOT}/proc"

if [ "${KEEP_CHROOT_MOUNTED}" = false ]; then
    sudo umount  "${CHROOT}"
else
    echo "Keeping ${CHROOT} mounted (e.g. for archiving)."
fi
