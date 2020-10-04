FROM ubuntu:18.04

# Docker ARG Setting
ARG root_password="root"
ARG user_name="ubuntu"
ARG user_password="ubuntu"

ENV DEBIAN_FRONTEND=noninteractive \
    HOSTNAME=DeskTop

# Locale and Language setting
RUN apt-get update && apt-get install -y \
    ibus-mozc language-pack-ja-base language-pack-ja fonts-takao \
    && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
ENV LANG="ja_JP.UTF-8" \
    TZ="Asia/Tokyo"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && locale-gen $LANG \
    && echo LANG=$LANG >> /etc/default/locale

# User setting
RUN echo root:$root_password | chpasswd \
    && apt-get update && apt-get install -y openssl sudo \
    && useradd -m -G sudo $user_name -p $(openssl passwd -1 $user_password) --shell /bin/bash \
    && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# RDP setting
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-terminal xfce4-goodies xrdp \
    && adduser xrdp ssl-cert \
    && update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper \
    && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
COPY ./config/xrdp/sesman.ini /etc/xrdp/sesman.ini
COPY ./config/xrdp/xrdp.ini /etc/xrdp/xrdp.ini
COPY ./config/xrdp/default.pa /etc/xrdp/pulse/default.pa
EXPOSE 3389

# Startup setting
RUN apt-get update \
    && apt-get install -y supervisor \
    && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
ADD ./config/supervisord/* /etc/supervisor/conf.d/

# Install Preferred package
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    build-essential \
    curl \
    chromium-browser \
    g++ \
    gedit \
    git \
    libtool \
    make \
    mosquitto \
    mosquitto-clients \
    net-tools \
    nano \
    pkg-config \
    software-properties-common \
    tig \
    unzip \
    wget \
    && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# Install Custom Package
# [cmake 3.18]
COPY ./config/cmake-3.18.1-Linux-x86_64 /opt/cmake-3.18.1-Linux-x86_64
RUN ln -s /opt/cmake-3.18.1-Linux-x86_64/bin/* /usr/bin

# gcc-9
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test \ 
    && apt-get update \
    && apt-get install -y g++-9-multilib \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 30 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 30 \
    && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# Clean up
RUN apt-get clean && apt-get autoremove && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

CMD ["bash", "-c", "/usr/bin/supervisord -c /etc/supervisor/supervisord.conf"]
