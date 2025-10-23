FROM kalilinux/kali-rolling:latest

ARG KALI_METAPACKAGE=core
ARG KALI_DESKTOP=xfce
ARG BASE_PACKAGES="vim less iputils-ping net-tools"  # Core set of tools
ENV DEBIAN_FRONTEND noninteractive
ENV USER root
ENV VNCEXPOSE 1
ENV VNCWEB 0
ENV VNCPORT 5900
ENV VNCDISPLAY 1920x1080
ENV VNCDEPTH 16
ENV NOVNCPORT 8080

# Base packages
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends \
    kali-linux-${KALI_METAPACKAGE} \
    kali-tools-top10 \
    kali-desktop-${KALI_DESKTOP} \
    tightvncserver xfonts-base autocutsel \
    dbus dbus-x11 \
    novnc \
    ${BASE_PACKAGES} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Common tools
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
    burpsuite \
    wordlists && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Extra packages for specific challenges
ARG EXTRA_PACKAGES=""
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
    ${EXTRA_PACKAGES} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*



# Extra packages for specific challenges
ARG EXTRA_PACKAGES=""
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
    ${EXTRA_PACKAGES} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh






# Configure SSH tunnel using ngrok
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8

RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3.5-stable-linux-amd64.zip \
    && unzip ngrok.zip \
    && rm /ngrok.zip \
    && mkdir /run/sshd \
    && echo "/ngrok tcp --authtoken ${AUTH_TOKEN} 22 &" >>/docker.sh \
    && echo "sleep 5" >> /docker.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"SSH Info:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\\nROOT Password:${PASSWORD}\\\")\" || echo \"\nError：AUTH_TOKEN，Reset ngrok token & try\n\"" >> /docker.sh \
    && echo '/usr/sbin/sshd -D' >>/docker.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo root:${PASSWORD}|chpasswd \
    && chmod 755 /docker.sh

EXPOSE 80 8888 8080 443 5130-5135 3306 7860
CMD ["/bin/bash", "/docker.sh"]
ENTRYPOINT [ "/entrypoint.sh" ]
