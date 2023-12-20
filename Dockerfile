# aa
FROM kalilinux/kali-rolling

MAINTAINER qeeqbox

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y aircrack-ng amass apt-utils arping arp-scan axel bash-completion binwalk bsdmainutils bulk-extractor cewl commix crackmapexec creddump7 crunch cryptcat curl dirb dirbuster dmitry dnschef dnsenum dnsrecon dnsutils dos2unix enum4linux ethtool exiv2 expect exploitdb fierce fping ftp gcc git gobuster golang hashcat hashdeep hashid hash-identifier hotpatch hping3 hydra iputils-ping john joomscan kpcli lbd libffi-dev magicrescue make man-db masscan metasploit-framework mimikatz mlocate nasm nbtscan ncat ncrack netcat netcat-traditional netmask netsniff-ng net-tools ngrep nikto nmap nodejs npm onesixtyone oscanner passing-the-hash patator php powershell powersploit proxychains proxychains4 ptunnel pwnat python2 python3 python3-pip python3-setuptools python-dev python-setuptools rebind recon-ng responder ruby-dev samba samdump2 seclists set sipvicious skipfish sleuthkit smbclient smbmap smtp-user-enum snmp snmpcheck socat spike sqlmap ssh-audit sslscan sslsplit sslyze statsprocessor stunnel4 swaks tcpdump tcpick tcpreplay testssl.sh theharvester tnscmd10g tor udptunnel uniscan unix-privesc-check upx-ucl vim voiphopper wafw00f webshells weevely wfuzz wget whatweb whois windows-binaries winexe wordlists wpscan yersinia firefox-esr gosu armitage


ENV DEBIAN_FRONTEND=noninteractive
ARG AUTH_TOKEN
ARG PASSWORD=rootuser

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
