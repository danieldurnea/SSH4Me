# catub/core:bullseye  You can change the base image to any other image you want.
FROM kalilinux/kali-rolling:latest AS base
LABEL maintainer="Artis3n <dev@artis3nal.com>"
ARG AUTH_TOKEN
ARG PASSWORD
# Install dgoss
RUN curl -fsSL https://goss.rocks/install | sh
# Install Python common dependencies
WORKDIR /root
# ------------------------------
# --- Config ---
# ------------------------------

# Set timezone
RUN ln -fs /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
  dpkg-reconfigure --frontend noninteractive tzdata

# ------------------------------
# --- Finished ---
# ------------------------------

# Start up commands

# [Option] Upgrade OS packages to their latest versions

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install curl

# Start up commands
# Install dgoss
RUN curl -fsSL https://goss.rocks/install | sh
# Install packages and set locale
RUN apt-get update \
    && apt-get install -y locales nano golang  ssh sudo python3-pip python3  curl wget \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH tunnel using ngrok
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8

# --- Finished ---
ENV TERM=xterm-256color



# Start up commands
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

EXPOSE 80 22533 8888 8080 443 5130-5135 3306 7860 53 9050
CMD ["/bin/bash", "/docker.sh"]
CMD [ "sleep", "infinity" ]
ENTRYPOINT ["/bin/bash"]
