# catub/core:bullseye  You can change the base image to any other image you want.
FROM catub/core:bullseye

ARG AUTH_TOKEN
ARG PASSWORD=rootuser
RUN apt-get update && \
  apt-get install -y --no-install-recommends --fix-missing \
  apt-utils \
  awscli \
  build-essential \
  curl \
  dnsutils \
  gcc \
  git \
  iputils-ping \
  jq \
  libgmp-dev \
  libpcap-dev \
  make \
  nano \
  netcat \
  net-tools \
  nodejs \
  npm \
  perl \
  php \
  proxychains \
  python3 \
  python3-pip \
  ssh \
  tor \
  tmux \
  tzdata \
  wget \
  whois \
  zip \
  unzip \
  zsh && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install tools & dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends --fix-missing \
  brutespray \
  crunch \
  dirb \
  ftp \
  hping3 \
  hydra \
  nikto \
  nmap \
  smbclient \
  sqlmap \
  # johntheripper
  libssl-dev \
  yasm \
  pkg-config \
  libbz2-dev \
  # Metasploit
  gnupg2 \
  # OpenVPN
  openvpn \
  easy-rsa \
  # wpscan
  libcurl4-openssl-dev \
  libxml2 \
  libxml2-dev \
  libxslt1-dev \
  ruby-dev \
  zlib1g-dev \
  # zsh
  fonts-powerline \
  powerline && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install go
RUN cd /opt && \
  ARCH=$( arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/ ) && \
  wget https://dl.google.com/go/go1.21.1.linux-${ARCH}.tar.gz && \
  tar -xvf go1.21.1.linux-${ARCH}.tar.gz && \
  rm -rf /opt/go1.21.1.linux-${ARCH}.tar.gz && \
  mv go /usr/local

# Install Python common dependencies
RUN python3 -m pip install --upgrade setuptools wheel paramiko

# Install ZSH
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
  chsh -s $(which zsh)

# ------------------------------
# --- Config ---
# ------------------------------

# Set timezone
RUN ln -fs /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
  dpkg-reconfigure --frontend noninteractive tzdata

# ZSH config
RUN sed -i 's^ZSH_THEME="robbyrussell"^ZSH_THEME="bira"^g' ~/.zshrc && \
  sed -i 's^# DISABLE_UPDATE_PROMPT="true"^DISABLE_UPDATE_PROMPT="true"^g' ~/.zshrc && \
  sed -i 's^# DISABLE_AUTO_UPDATE="true"^DISABLE_AUTO_UPDATE="true"^g' ~/.zshrc && \
  sed -i 's^plugins=(git)^plugins=(tmux nmap)^g' ~/.zshrc && \
  echo 'export EDITOR="nano"' >> ~/.zshrc && \
  git config --global oh-my-zsh.hide-info 1

# ------------------------------
# --- Finished ---
# ------------------------------

# Start up commands

# Install packages and set locale
RUN apt-get update \
    && apt-get install -y locales nano ssh sudo python3 curl wget \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH tunnel using ngrok
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8

RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
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
CMD ["/bin/zsh"]
