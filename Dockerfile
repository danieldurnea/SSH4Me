FROM ubuntu:mantic
WORKDIR /root 
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y locales nano ssh sudo python3 curl wget \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV TERM=xterm-256color
# Copyright © 2018 - 2024 PhotoPrism UG. All rights reserved.
#
# Questions? Email us at hello@photoprism.app or visit our website to learn
# more about our team, products and services: https://www.photoprism.app/

# Add Open Container Initiative (OCI) annotations.
# See: https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="PhotoPrism® Build Image (Ubuntu 23.10)"
LABEL org.opencontainers.image.description="Ubuntu 23.10 (Mantic Minotaur)"
LABEL org.opencontainers.image.url="https://hub.docker.com/repository/docker/photoprism/develop"
LABEL org.opencontainers.image.source="https://github.com/photoprism/photoprism"
LABEL org.opencontainers.image.documentation="https://docs.photoprism.app/developer-guide/setup/"
LABEL org.opencontainers.image.authors="PhotoPrism UG <hello@photoprism.app>"
LABEL org.opencontainers.image.vendor="PhotoPrism UG"
    apt-get update && apt-get -qq dist-upgrade && \
    apt-get -qq install \
        libc6 ca-certificates bash sudo nano avahi-utils jq lsof lshw libebml5 libgav1-bin libatomic1 \
        exiftool sqlite3 tzdata gpg make zip unzip wget curl rsync imagemagick libvips-dev rawtherapee \
        ffmpeg libffmpeg-nvenc-dev libswscale-dev libavfilter-extra libavformat-extra libavcodec-extra \
        x264 x265 libde265-dev libaom3 libvpx7 libwebm1 libjpeg8 libmatroska7 libdvdread8 \
    && \
    apt-get -qq install \
        apt-utils pkg-config software-properties-common \
        build-essential gcc g++ git gettext davfs2 chrpath apache2-utils \
        autoconf automake cmake libtool libjpeg-dev libpng-dev libwebp-dev \
        libx264-dev libx265-dev libaom-dev libvpx-dev libwebm-dev libxft-dev \
        libc6-dev libhdf5-serial-dev libzmq3-dev libssl-dev libnss3 \
        libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev fonts-roboto \
        librsvg2-bin ghostscript gsfonts pdf2svg ps2eps \
    && \


# Download models and testdata.
RUN mkdir /tmp/photoprism && \
    wget "https://dl.photoprism.app/tensorflow/nsfw.zip?${BUILD_TAG}" -O /tmp/photoprism/nsfw.zip && \
    wget "https://dl.photoprism.app/tensorflow/nasnet.zip?${BUILD_TAG}" -O /tmp/photoprism/nasnet.zip && \
    wget "https://dl.photoprism.app/tensorflow/facenet.zip?${BUILD_TAG}" -O /tmp/photoprism/facenet.zip && \
    wget "https://dl.photoprism.app/qa/testdata.zip?${BUILD_TAG}" -O /tmp/photoprism/testdata.zip

# Default working directory.
WORKDIR "/go/src/github.com/photoprism/photoprism"

# Expose the following container ports:
# - 2342 (HTTP)
# - 2343 (Acceptance Tests)
# - 2442 (HTTP)
# - 2443 (HTTPS)
# - 9515 (Chromedriver)
# - 40000 (Go Debugger)


# Install Seclis
# Prepare rockyou wordlis

# install base packages
RUN apt update -y > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1 && apt install locales -y \
&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# configure locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8 
ENV LC_ALL C.UTF-8
# Easier to access list of nmap scripts
ARG AUTH_TOKEN
ARG PASSWORD
ENV PASSWORD=${PASSWORD}
ENV AUTH_TOKEN=${AUTH_TOKEN}

# Install ssh, wget, and unzip
RUN apt install ssh  wget unzip -y > /dev/null 2>&1

# Download and unzip ngrok
RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3.5-stable-linux-amd64.zip > /dev/null 2>&1
RUN unzip ngrok.zip

# Create shell script
RUN echo "./ngrok config add-authtoken ${AUTH_TOKEN} &&" >>/kali.sh
RUN echo "./ngrok tcp 22 &>/dev/null &" >>/kali.sh


# Create directory for SSH daemon's runtime files
RUN mkdir /run/sshd
RUN echo '/usr/sbin/sshd -D' >>/kali.sh
RUN echo 'PermitRootLogin yes' >>  /etc/ssh/sshd_config # Allow root login via SSH
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config  # Allow password authentication
RUN echo root:${PASSWORD}|chpasswd # Set root password
RUN service ssh start
RUN chmod 755 /kali.sh

# Expose port
EXPOSE 80 443 53 5900 53 2342 2343 2442 2443 9515 40000
CMD /kali.sh
