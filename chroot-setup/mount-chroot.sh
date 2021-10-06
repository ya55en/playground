#! /bin/sh

# Umount all chroot-related mounts

set -x

# . ./common.sh

CHROOT="${1:-${CHROOT}}"

[ -n "$CHROOT" ] || {
    echo "$(basename "$0"): Missing mandatory argument: CHROOT"
    exit 2
}

for dir in /proc /sys /dev /dev/pts /dev/shm; do
    [ -e "${CHROOT}$dir" ] || {
        printf '%s: %s NOT found, terminating.\n' "$(basename "$0")" "${CHROOT}$dir"
        exit 7
    }
done

sudo mount -t proc /proc "${CHROOT}/proc"

sudo mount -o bind /sys "${CHROOT}/sys"
sudo mount -o bind /dev "${CHROOT}/dev"
sudo mount --make-rslave "${CHROOT}/sys"
sudo mount --make-rslave "${CHROOT}/dev"

sudo mount -o bind /dev/pts "${CHROOT}/dev/pts"
sudo mount -o bind /dev/shm "${CHROOT}/dev/shm"

#sudo mount -o bind /run "${CHROOT}/run"

#sudo mount -o bind /run/lock "${CHROOT}/run/lock"
#sudo mount -o bind /sys/fs/cgroup "${CHROOT}/sys/fs/cgroup"
#sudo mount -o bind /run/user/1000 "${CHROOT}/run/user/1000"
