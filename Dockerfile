ARG TAG=trixie
FROM debian:$TAG

# Default (run-time) environment variables
ENV USERNAME=user
ENV USER_ID=1000

# Build arguments
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# -----------------------------
# Required packages for building
# -----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential python3 python3-dev \
        dpkg-dev pkg-config git ca-certificates \
        libx11-dev libxrender1 libxrender-dev libxcb1 libx11-xcb-dev \
        libcairo2 libcairo2-dev tcl8.6 tcl8.6-dev tk8.6 tk8.6-dev flex bison libxpm4 \
        libxpm-dev libjpeg-dev libgtk-3-dev gettext \
        libxaw7 libxaw7-dev libx11-dev libreadline8 libxmu6 \
        libtool gperf libxml2 libxml2-dev libxml-libxml-perl libgd-perl \
        g++ gfortran make cmake libfl-dev libfftw3-dev automake libreadline-dev \
        qtbase5-dev qttools5-dev libqt5xmlpatterns5-dev qtmultimedia5-dev \
        libqt5multimediawidgets5 libqt5svg5-dev \
        ruby ruby-dev libz-dev libgit2-dev \
    && git config --global http.sslVerify false \
    && git config --global core.autocrlf false

# -----------------------------
# Compile and install toolchain
# -----------------------------
# Install XSCHEM
RUN git clone https://github.com/StefanSchippers/xschem.git xschem_git \
    && cd xschem_git \
    && ./configure \
    && make \
    && make install

# Install Magic
RUN git clone https://github.com/RTimothyEdwards/magic magic_git \
    && cd magic_git \
    && ./configure \
    && make \
    && make install

# Install Netgen
RUN git clone https://github.com/RTimothyEdwards/netgen netgen_git \
    && cd netgen_git \
    && ./configure \
    && make \
    && make install

# Install NGSPICE
RUN git clone https://git.code.sf.net/p/ngspice/ngspice ngspice_git \
    && cd ngspice_git \
    && mkdir release \
    && ./autogen.sh \
    && cd release \
    && ../configure --with-x --enable-xspice --disable-debug --enable-cider --with-readline=yes --enable-openmp --enable-osdi --enable-float --enable-sse \
    && make \
    && make install

# Install GAW
RUN git clone https://github.com/StefanSchippers/xschem-gaw.git xschem_gaw_git \
    && cd xschem_gaw_git \
    && sed -i 's/^GETTEXT_MACRO_VERSION = .*/GETTEXT_MACRO_VERSION = 0.22/' po/Makefile.in.in \
    && aclocal \
    && autoconf \
    && autoheader \
    && automake --add-missing \
    && ./configure \
    && make \
    && make install

# Install KLayout
RUN git clone https://github.com/KLayout/klayout.git klayout_git \
    && cd klayout_git \
    && ./build.sh -j$(nproc) -prefix /usr/local/share/klayout -python /usr/bin/python3 \
    && cd build-release \
    && make install \
    && ln -s /usr/local/share/klayout/klayout /usr/local/bin/klayout

# -----------------------------
# Desktop environment setup
# -----------------------------
## First install basic required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    dirmngr gnupg gnupg-l10n \
    gnupg-utils gpg gpg-agent \
    gpg-wks-client gpg-wks-server gpgconf \
    gpgsm libksba8 \
    libldap2 libldap-common libnpth0 \
    libreadline8 libsasl2-2 libsasl2-modules \
    libsasl2-modules-db libsqlite3-0 libssl3 \
    lsb-base pinentry-curses readline-common \
    apt-transport-https ca-certificates curl \
    apt-utils net-tools

## Add additional repositories/components (software-properties-common is required to be installed)
# Copy our own Debian sources file with contrib & non-free instead of apt-add-repository
COPY ./configs/debian.sources /etc/apt/sources.list.d/debian.sources

# Retrieve third party GPG keys from keyserver
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 302F0738F465C1535761F965A6616109451BBBF2 972FD88FA0BAFB578D0476DFE1F958385BFE2B6E

# Add Linux Mint GPG keyring file (for the Mint-Y-Dark theme)
RUN gpg --export 302F0738F465C1535761F965A6616109451BBBF2 | tee /etc/apt/trusted.gpg.d/linuxmint-archive-keyring.gpg >/dev/null

# Add Linux Mint Faye repo source file
COPY ./configs/linuxmint-faye.list /etc/apt/sources.list.d/linuxmint-faye.list

# Add X2Go GPG keyring file
RUN gpg --export 972FD88FA0BAFB578D0476DFE1F958385BFE2B6E | tee /etc/apt/trusted.gpg.d/x2go-archive-keyring.gpg >/dev/null

# Add X2Go repo source file
COPY ./configs/x2go.list /etc/apt/sources.list.d/x2go.list

## Install X2Go server and session
RUN apt update && apt-get install -y x2go-keyring && apt-get update
RUN apt-get install -y x2goserver x2goserver-xsession

## Install important (or often used) dependency packages
RUN apt-get install -y --no-install-recommends \
    openssh-server ffmpeg pulseaudio pavucontrol \
    dbus-x11 locales git wget sudo nano xterm \
    zip bzip2 unzip unrar geany \
    pwgen cron at-spi2-core \
    file dialog util-linux coreutils \
    xdg-utils xz-utils x11-utils x11-xkb-utils \
    latexmk texlive-base texlive-publishers \
    texlive-lang-french texlive-science

## Add themes & fonts
RUN apt-get install -y --no-install-recommends fonts-ubuntu breeze-gtk-theme mint-themes

# Add LibreOffice
RUN apt install -y libreoffice-base libreoffice-base-core libreoffice-common libreoffice-core libreoffice-base-drivers \
    libreoffice-nlpsolver libreoffice-script-provider-bsh libreoffice-script-provider-js libreoffice-script-provider-python libreoffice-style-colibre \
    libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-draw libreoffice-math

## Install XFCE4
# Install XFCE4, including XFCE panels, terminal, screenshooter, task manager, notify daemon, dbus, locker and plugins.
# ! But we do NOT install xfce4-goodies; since this will install xfburn (not needed) and xfce4-statusnotifier-plugin (deprecated) !
RUN apt-get upgrade -y && apt-get install -y --no-install-recommends \
    xfwm4 xfce4-session default-dbus-session-bus xfdesktop4 light-locker \
    xfce4-panel xfce4-terminal librsvg2-common \
    xfce4-dict xfce4-screenshooter xfce4-appfinder \
    xfce4-taskmanager xfce4-notifyd xfce4-whiskermenu-plugin \
    xfce4-pulseaudio-plugin xfce4-clipman-plugin xfce4-indicator-plugin

# Install additional apps including recommendations, mainly: file manager, archive manager and image viewer
RUN apt-get install -y \
    ristretto tumbler xarchiver \
    thunar thunar-archive-plugin thunar-media-tags-plugin

## Add more applications
# Most importantly: browser, calculator, file editor, video player, profile manager
RUN apt-get install -y --no-install-recommends \
    firefox-esr htop qalculate-gtk \
    mousepad celluloid mugshot

# Update locales, generate new SSH host keys and clean-up (keep manpages)
RUN update-locale
RUN rm -rf /etc/ssh/ssh_host_* && ssh-keygen -A
RUN apt-get clean -y && rm -rf /usr/share/doc/* /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apk/*

# Update timezone to Paris
RUN echo 'Europe/Paris' >/etc/timezone
RUN unlink /etc/localtime && ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime

# Start default XFCE4 panels (don't ask for it)
RUN mv -f /etc/xdg/xfce4/panel/default.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
# Use mice as default Splash
COPY ./configs/xfconf/xfce4-session.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
# Add XFCE4 settings to start-up
COPY ./configs/xfce4-settings.desktop /etc/xdg/autostart/
# Enable Clipman by default during start-up
RUN sed -i "s/Hidden=.*/Hidden=false/" /etc/xdg/autostart/xfce4-clipman-plugin-autostart.desktop
# Remove unnecessary existing start-up apps
RUN rm -rf /etc/xdg/autostart/light-locker.desktop /etc/xdg/autostart/xscreensaver.desktop
# Change default terminal to xfce4-terminal
RUN update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper

# Disable root shell
RUN usermod -s /usr/sbin/nologin root

## Create worker user (instead of root user)
RUN useradd -d /app -s /bin/bash -u 1001 worker
RUN echo "Defaults!/app/setup.sh setenv" >>/etc/sudoers
# Limit the execute of the following commands of the worker user
RUN echo "worker ALL=(root) NOPASSWD:/usr/sbin/service dbus start, /usr/sbin/service cron start, /usr/sbin/sshd, /usr/bin/ssh-keygen, /app/setup.sh" >>/etc/sudoers

# Copy worker scripts
COPY ./scripts/setup.sh ./
COPY ./configs/terminalrc ./
COPY ./configs/whiskermenu-1.rc ./
COPY ./scripts/xfce_settings.sh ./
COPY ./scripts/run.sh ./

# Run as worker
USER worker

EXPOSE 22/tcp

CMD ["/app/run.sh"]
