#! /bin/bash

MASH_USER='mash'

set -xe

# Executed inside the chroot after it has been built.

export DEBIAN_FRONTEND=noninteractive

. '/etc/environment'
. '/etc/default/locale'

install_mate_desktop_env() {
    #: Install mate-desktop-environment. Make three attempts as this very
    #: often fails (possibly due to unusually high ramdisk speed) this way:
    #:   E: Failed to fetch http://bg.archive.ubuntu.com/ubuntu/pool/main/libp/libpng1.6/libpng16-16_1.6.37-2_amd64.deb  Undetermined Error [IP: 195.85.215.252 80]
    #:   E: Unable to fetch some archives, maybe run apt-get update or try with --fix-missing?

    apt-get update
    if ! apt-get install -y mate-desktop-environment-core; then
        echo "First mate-desktop install attempt FAILED; trying again..."
        sleep 2
        if ! apt-get install -y mate-desktop-environment-core; then
            echo "Second (!) mate-desktop install attempt FAILED; trying again..."
            sleep 4
            if ! apt-get install -y mate-desktop-environment-core; then
                echo "THIRD (!!) mate-desktop install attempt FAILED !! Terminating."
                exit 11
            fi
        fi
    fi
}

ensure_x11_packages() {
    #: Make sure these x11 packages are all available (they are but just in case).
    apt-get install -y xorg x11-xserver-utils x11-utils
}

install_vnc_server() {
    #: Install the VNC server.
    apt-get install -y tigervnc-standalone-server xfonts-100dpi xfonts-75dpi
}

# Seems there's no need of this - TODO: remove when stable
# setup_proper_display_manager() {
#     #: Tune default display manager setting.
#     true

#     # https://askubuntu.com/questions/1114525/reconfigure-the-display-manager-non-interactively
#     # https://phoenixnap.com/kb/how-to-install-a-gui-on-ubuntu
#     #which lightdm > /dev/null && echo "$(which lightdm)" > /etc/X11/default-display-manager
# }

create_xstartup() {
    #: Create `~/.vnc/xstartup` script.

    set +e

    mkdir -p /home/mash/.vnc
    [ -e /home/mash/.vnc/xstartup ] && mv /home/mash/.vnc/xstartup /home/mash/.vnc/xstartup.bak

    cat > /home/mash/.vnc/xstartup << EOS
#!/bin/sh
# http://simostro.synology.me/simone/2018/02/09/installing-a-vnc-server-on-linux-ubuntu-mate/

unset DBUS_SESSION_BUS_ADDRESS
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r \$HOME/.Xresources ] && xrdb \$HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
x-terminal-emulator -geometry 120x43+10+10 -ls -title "$VNCDESKTOP Desktop" &
x-window-manager &
mate-session &
EOS

    test -e /home/mash/.vnc/xstartup.bak && chmod -x /home/mash/.vnc/xstartup.bak
    chmod +x /home/mash/.vnc/xstartup
    chown -R mash:mash /home/mash/.vnc
    set -e
}

# TODO: remove if not needed
# setup_aliases() {
#     #: Setup useful aliases. (E.g. start and stop the VNC server as mash user.)

#     cat >> '/root/.bashrc' << EOS

# # mash-chroot: aliases to ease vncserver run and stop:
# alias vnc-start='sudo -u mash vncserver -localhost no :2'
# alias vnc-stop='sudo -u mash vncserver -kill :2'
# EOS
# }

create_vnc_scripts() {
    cat >> /usr/local/bin/start-vnc.sh << EOS
#! /bin/sh
# chroot-setup: script for starting vnc server
. /etc/environment
. /etc/default/locale
sudo -u mash vncserver -localhost no :2
EOS

    cat >> /usr/local/bin/stop-vnc.sh << EOS
#! /bin/sh
# chroot-setup: script for stopping vnc server
. /etc/environment
. /etc/default/locale
sudo -u mash vncserver -kill :2
EOS

    chmod +x /usr/local/bin/start-vnc.sh
    chmod +x /usr/local/bin/stop-vnc.sh
}

cleanup() {
    #: Do apt-related cleanup.

    # sudo -u mash ln -s /home/mash/mashmallow-0/src ~/.local/opt/mash
    apt-get autoremove -y
    apt-get autoclean
    apt-get clean
}

main() {
    install_mate_desktop_env
    ensure_x11_packages
    install_vnc_server
    # setup_proper_display_manager
    create_xstartup
    # setup_aliases
    create_vnc_scripts
    cleanup
}

main
