# You can change the base image to any other image you want.
FROM kalilinux/kali-rolling:latest
#MAINTAINER Lorenzo "Palinuro" Faletra (palinuro@linux.it)
ENV DEBIAN_FRONTEND noninteractive
# Install components
RUN apt-get update \
    && apt-get install -y locales nano ssh sudo python3 curl wget \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*# Set locale to en_US.utf8
ENV LANG en_US.utf8

# Define arguments and environment variables
ARG AUTH_TOKEN
ARG Password
ENV Password=${Password}
ENV AUTH_TOKEN=${AUTH_TOKEN}

# Install ssh, wget, and unzip
RUN apt install ssh wget unzip -y > /dev/null 2>&1

# Download and unzip ngrok
RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip > /dev/null 2>&1
RUN unzip ngrok.zip

# Create shell script
RUN echo "./ngrok config add-authtoken ${NGROK_TOKEN} &&" >>/kali.sh
RUN echo "./ngrok tcp 22 &>/dev/null &" >>/kali.sh


# Create directory for SSH daemon's runtime files
RUN mkdir /run/sshd
RUN echo '/usr/sbin/sshd -D' >>/kali.sh
RUN echo 'PermitRootLogin yes' >>  /etc/ssh/sshd_config # Allow root login via SSH
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config  # Allow password authentication
RUN echo root:${Password}|chpasswd # Set root password
RUN service ssh start
RUN chmod 755 /kali.sh

# Expose port
EXPOSE 80 8888 8080 443 5130 5131 5132 5133 5134 5135 3306

# Start the shell script on container startup
CMD  /kali.sh

EXPOSE 80 8888 8080 443 5130-5135 3306 7860

COPY containerfiles/entrypoint.sh /entrypoint.sh
COPY containerfiles/bashrc.sh /bashrc.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/bin/bash", "/docker.sh"]






















