#! /bin/bash
#: Execute certain tasks inside the chroot after it has been built via bootstrap.

set -xe

TEMP_LOG="/tmp/$(basename "$0").log"

# shellcheck disable=SC1091
. '/etc/environment'
export DEBIAN_FRONTEND=noninteractive

# Fix locales issue as soon as we enter the chroot; source env after that
/usr/sbin/locale-gen en_US.UTF-8
# shellcheck disable=SC1091
. '/etc/default/locale'

dump_vars() {
    printf "MASH_USER=%s\n" "${MASH_USER}"
    printf "MASH_UID=%s\n" "${MASH_UID}"
    cat /etc/environment
}

do_distupgrade() {
    apt-get update >> "$TEMP_LOG"
    apt-get dist-upgrade -y >> "$TEMP_LOG"
}

install_apt_packages() {
    packages="
        curl
        rsync
        vim
    "
    # shellcheck disable=2086
    apt-get install -y $packages >> "$TEMP_LOG"
}

create_mash_user() {
    echo "MASH_PSSWD_HASH=$MASH_PSSWD_HASH"
    useradd \
        -l -u "${MASH_UID}" \
        -UG sudo \
        -md "/home/${MASH_USER}" \
        -s /bin/bash \
        -p "$MASH_PSSWD_HASH" \
        "${MASH_USER}"
}

setup_mashuser_sudo() {
    mashuser_sudo_file="/etc/sudoers.d/${MASH_USER}-nopass"
    cat > "$mashuser_sudo_file" << EOS
# mash: setup p_sswdless sudo for $MASH_USER
$MASH_USER ALL=(ALL) NOPASSWD:ALL
EOS

    chown "${MASH_UID}:${MASH_UID}" "$mashuser_sudo_file"
    chmod 440 "$mashuser_sudo_file"
}

add_source_locale_snippet() {
    for file in '/root/.bashrc' "/home/${MASH_USER}/.bashrc"; do
        cat >> "$file" << EOS

# $(basename "$0"): sourcing locale:
source /etc/default/locale
cd ~
EOS

    done
}

create_runtests_script() {
    # Note that we do not source /etc/environment in this one, as this
    # eliminates the mash PATH addition and mash cannot be found.
    script_path="/home/${MASH_USER}/run-tests.sh"

    cat >> "$script_path" << EOS
#! /bin/sh
. /etc/default/locale

#: mash: sourcing initializing scripts from ~/.bashrc.d/*.sh
for file in "/home/$MASH_USER/.bashrc.d/"*.sh; do
    . "\$file"
done

cd /home/${MASH_USER}/ && ./test/e2e/smoke-e2e.sh "\$1"
EOS

    chown "${MASH_UID}:${MASH_UID}" "$script_path"
    chmod u+x "$script_path"
}

set_hostname() {
    # hostnamectl set-hostname "${CODENAME}-headless-chrooted"
    # set but doesn't take effect on the chroot prompt :(
    # TODO: try modifying PS1 for the chroot
    printf "%s-headless-chrooted\n" focal > /etc/hostname
}

do_cleanup() {
    apt-get update
    apt-get autoremove -y
    apt-get autoclean
    apt-get clean
}

main() {
    dump_vars

    do_distupgrade
    install_apt_packages
    create_mash_user
    setup_mashuser_sudo
    add_source_locale_snippet
    create_runtests_script
    set_hostname
    do_cleanup
}

main
