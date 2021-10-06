#! /bin/bash

PAUSE_SEC=4 # secs to wait for Ctr-C before final umount

TARGET_NAME="$1"

# shellcheck disable=2027,2086
eval "TAR_FILE="${TAR_FILE_TEMPLATE}""
MASH_USER_HOME="/home/${MASH_USER}"

check_target_name() {
    [ -n "$TARGET_NAME" ] || {
        echo "$(basename "$0"): Missing required argument: TARGET_NAME"
        exit 2
    }
    case "${TARGET_NAME}" in
        headless | mate-desktop) ;;

        *)
            echo "$(basename "$0"): Illegal required argument: TARGET_NAME='$TARGET_NAME'! Terminating."
            exit 2
            ;;
    esac
}

print_variables() {
    printf "TARGET_NAME=%s\n" "${TARGET_NAME}"
    printf "TAR_FILE=%s\n" "${TAR_FILE}"
    printf "FOCAL_HEADLESS_TAR=%s\n" "${FOCAL_HEADLESS_TAR}"  # "$(TARGET_NAME=headless eval echo "$TAR_FILE_TEMPLATE")"
    printf "MATE_DESKTOP_TAR=%s\n" "${MATE_DESKTOP_TAR}" # "$(eval echo "$TAR_FILE_TEMPLATE")"
    printf "CHROOT=%s\n" "${CHROOT}"
    printf "MASH_USER_HOME=%s\n" "${MASH_USER_HOME}"
    printf "CODENAME=%s\n" "${CODENAME}"
    printf "MIRROR_URL=%s\n" "${MIRROR_URL}"
    printf "MASH_PSSWD_HASH=%s\n" "${MASH_PSSWD_HASH}"
}

create_chroot_tree() {
    if [ "$TARGET_NAME" = headless ]; then
        ./4make/ensure-free-mem.sh 2G
        sudo mount -t tmpfs -o size=768M mash-ramdisk "${CHROOT}"
        sudo debootstrap "${CODENAME}" "${CHROOT}" "${MIRROR_URL}"
        # A shortcut for testing; TODO: remove when stable
        # sudo tar xf ${BUILD_DIR}/OLD-focal-headless.tgz -C "${CHROOT}"
    else
        ./4make/ensure-free-mem.sh 8G
        sudo mount -t tmpfs -o size=6G mash-ramdisk "${CHROOT}"
        #sudo tar -xf "${BUILD_DIR}/${CODENAME}-headless.tgz" -g /dev/null -C "${CHROOT}"
        sudo tar -xf "${BUILD_DIR}/${CODENAME}-headless.tgz" -C "${CHROOT}"
    fi
}

fixes_for_headless() {
    #: Copy the vnc passwd file into the chroot (only for headless target).

    if [ "$TARGET_NAME" = headless ]; then
        ./4make/fix-locales.sh
        ./4make/fix-apt-sources.sh
    fi
}

copy_vnc_psswd() {
    #: Copy the vnc passwd file into the chroot (for desktop environment targets).
    # TODO: Consider moving this to post-chroot-build setup (?).

    if [ "$TARGET_NAME" != headless ]; then
        sudo mkdir -p "${CHROOT}${MASH_USER_HOME}/.vnc"
        echo '>>> Copying ./resources/passwd to '"${CHROOT}${MASH_USER_HOME}/.vnc/"
        sudo cp -p ./resources/passwd "${CHROOT}${MASH_USER_HOME}/.vnc/"
        sudo chown "${MASH_UID}:${MASH_UID}" "${CHROOT}${MASH_USER_HOME}/.vnc/passwd"
        sudo chmod 600 "${CHROOT}${MASH_USER_HOME}/.vnc/passwd"
    else
        # printf '\n\n\n'
        echo '>>> NOT copying ./resources/passwd -- not a desktop target.'
        # printf '\n\n\n'
    fi
}

work_inside_chroot() {
    target_path="/root/inside-${CODENAME}-${TARGET_NAME}-chroot.sh"

    ./mount-chroot.sh "${CHROOT}"
    sudo cp -p "./4make/inside-chroot/${CODENAME}-${TARGET_NAME}".sh "${CHROOT}${target_path}"
    printf '\n\n===== BEGIN %s =========================================\n\n' "${target_path}"
    sudo \
        MASH_USER="${MASH_USER}" \
        MASH_UID="${MASH_UID}" \
        MASH_PSSWD_HASH="${MASH_PSSWD_HASH}" \
        chroot "${CHROOT}" "${target_path}"
    printf '\n\n===== END %s ===========================================\n\n' "${target_path}"
    sleep 1
    ./umount-chroot.sh "${CHROOT}" keep-root
}

create_final_tarball() {
    # shellcheck disable=2027,2086
    printf '\nTAR_FILE=<<%s>>\n\n' "$TAR_FILE"
    [ -e "${TAR_FILE}" ] && rm "${TAR_FILE}"
    mkdir -p "$(dirname "${TAR_FILE}")"
    # _LEVEL_OPT="--level=$([ "$TARGET_NAME" = headless ] && printf '0' || printf '1' )"
    if [ "$TARGET_NAME" = headless ]; then rm -f "${TAR_METADATA_FILE}"; fi
    #sudo tar -czf "${TAR_FILE}" -g "${TAR_METADATA_FILE}" -C "${CHROOT}/" . #  "${_LEVEL_OPT}"
    sudo tar -czf "${TAR_FILE}" -C "${CHROOT}/" .
    # tar --listed-incremental=snapshot.file -cvzf backup.1.tar.gz /path/to/dir
    sudo chown "${USER}:${USER}" "${TAR_FILE}"
    # sudo chown "${USER}:${USER}" "${TAR_METADATA_FILE}"
}

main() {
    set +x
    print_variables
    check_target_name
    set -xe

    create_chroot_tree
    fixes_for_headless
    copy_vnc_psswd
    work_inside_chroot
    create_final_tarball

    echo "==> Press Ctrl-C within ${PAUSE_SEC} sec. to stop before unmounting the chroot..."
    sleep "${PAUSE_SEC}"
    sudo umount "${CHROOT}"

    set +x
    echo "** DONE creating ${TAR_FILE}. **"
}

main
