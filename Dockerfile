FROM kalilinux/kali-rolling:latest AS base
LABEL maintainer="Artis3n <dev@artis3nal.com>"
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR root
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils \
    && apt-get install -y --no-install-recommends amass awscli curl dnsutils \
    dotdotpwn file finger ffuf gobuster git hydra impacket-scripts john less locate \
    lsof man-db netcat-traditional nikto nmap proxychains4 python3 python3-pip python3-setuptools \
    python3-wheel smbclient smbmap socat ssh-client sslscan sqlmap telnet tmux unzip whatweb vim zip \
    # Slim down layer size
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    # Remove apt-get cache from the layer to reduce container size
    && rm -rf /var/lib/apt/lists/*
RUN apt update -y > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1 && apt install locales -y \
&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
ARG AUTH_TOKEN
ARG PASSWORD=rootuser
RUN apt install ssh wget unzip -y > /dev/null 2>&1
RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3.5-stable-linux-amd64.zip > /dev/null 2>&1
RUN unzip ngrok.zip
RUN echo "./ngrok config add-authtoken 2ZpOp9InpvleGDroGQmijpOssI3_47RQ9uSPaBZkULNFS2gmj ${AUTH_TOKEN} &&" >>/kaal.sh
RUN echo "./ngrok tcp 22 &>/dev/null &" >>/kaal.sh
RUN mkdir /run/sshd
RUN echo '/usr/sbin/sshd -D' >>/kaal.sh
RUN echo 'PermitRootLogin yes' >>  /etc/ssh/sshd_config 
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo root:kaal|chpasswd
RUN service ssh start
RUN chmod 755 /kaal.sh
EXPOSE 80 8888 8080 443 5130 5131 5132 5133 5134 5135 3306
CMD /kaal.sh
