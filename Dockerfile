# You can change the base image to any other image you want.
FROM kalilinux/kali-rolling

LABEL version="2.0" \
    author="Braunbearded" \
    description="Custom Kali Linux docker container"

# install offical packages
RUN echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://ftp2.nluug.nl/os/Linux/distr/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list && \
    # echo "deb http://http.kali.org/kali kali-bleeding-edge main contrib non-free" >> /etc/apt/sources.list && \
    apt -y update && apt -y upgrade && \
    echo "wireshark-common wireshark-common/install-setuid boolean true" | \
    debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends \
    # basic
    man-db software-properties-common wget build-essential git unzip curl atool \
    file build-essential ssh tree vim unrar less fuse psmisc htop \
    # shells
    zsh zsh-autosuggestions zsh-syntax-highlighting bash-completion \
    # programming
    python3 python3-pip python2 cargo python3-dev default-jdk npm golang shfmt shellcheck php pipx \
    python-is-python3 python3-neovim \
    # recon / web
    gobuster dirb dirbuster nikto whatweb wkhtmltopdf burpsuite zaproxy ffuf \
    nmap wfuzz finalrecon sqlmap wpscan sslscan smtp-user-enum feroxbuster \
    # cracking / bruteforce
    hcxtools hashcat hashcat-utils john hydra name-that-hash \
    # binary exploitation
    strace ltrace binwalk ghidra \
    # exploitation
    metasploit-framework exploitdb pwncat nuclei \
    # gui/vnc
    kali-desktop-xfce dbus-x11 x11vnc xvfb \
    # network
    nfs-common netcat-traditional tnftp lftp iproute2 iputils-ping telnet net-tools snmp \
    wireshark traceroute tcpdump chisel tor proxychains \
    # dns
    dnsrecon whois dnsutils \
    # windows
    crackmapexec python3-impacket enum4linux passing-the-hash samba smbclient \
    smbmap responder impacket-scripts bloodhound rlwrap evil-winrm nbtscan windows-binaries \
    # other
    firefox-esr seclists wordlists grc ranger \
    xclip fzf ripgrep cewl jq redis-tools default-mysql-server freerdp2-x11 okular redeye \
    # TODO check
    swaks libssl-dev libffi-dev tnscmd10g \
    onesixtyone && \ 
    # clear apt cache/packages
    apt -y autoclean && apt -y autoremove && apt -y clean

# General
RUN setcap cap_net_raw,cap_net_admin=eip /usr/bin/nmap && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen && \
    # setup metasploit database
    service postgresql start && msfdb init && \
    # create user
    echo "kali ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd --create-home --shell /bin/zsh --user-group --groups sudo kali && \
    echo "kali:kali" | chpasswd && \
    mkdir -p /etc/zsh/zshrc.d && \
    printf 'if [ -d /etc/zsh/zshrc.d ]; then\n  for i in /etc/zsh/zshrc.d/*; do\n    if [ -r $i ]; then\n      . $i\n    fi\n  done\n  unset i\nfi' >> /etc/zsh/zshrc && \
    tar -xf /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz \
    -C /usr/share/seclists/Passwords/Leaked-Databases/ && \
    git clone https://github.com/wolfcw/libfaketime /tmp/libfaketime && make -C /tmp/libfaketime/src install && rm -rf /tmp/libfaketime

# TODO Remove/check later
# pipx install ciphey && \
# pipx install git+https://github.com/calebstewart/paramiko && \
# pipx install pyopenssl

# RUN python3 -m pip install updog search-that-hash pwntools pyftpdlib virtualenv && \
#     python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git && \
#     python3 -m pip install git+https://github.com/calebstewart/paramiko && \
#     # python3 -m pip install ciphey --upgrade && \
#     wget -O /tmp/get-pip.py "https://bootstrap.pypa.io/pip/2.7/get-pip.py" && python2 /tmp/get-pip.py && rm /tmp/get-pip.py && \
#     python3 -m pip install -U pyopenssl

RUN wget -O /tmp/get-pip.py "https://bootstrap.pypa.io/pip/2.7/get-pip.py" && python2 /tmp/get-pip.py && rm /tmp/get-pip.py

# clone usefull repos
RUN mkdir -p /opt/repos && \
    git clone https://github.com/swisskyrepo/PayloadsAllTheThings.git /opt/repos/PayloadsAllTheThings && \
    git clone https://github.com/samratashok/nishang.git /opt/repos/nishang && \
    git clone https://github.com/FireFart/dirtycow.git /opt/repos/dirtycow && \
    git clone https://github.com/dirkjanm/krbrelayx.git /opt/repos/krbrelayx && \
    git clone https://github.com/rebootuser/LinEnum.git /opt/repos/LinEnum && \
    git clone https://github.com/mzet-/linux-exploit-suggester.git /opt/repos/linux-exploit-suggester && \
    git clone https://github.com/diego-treitos/linux-smart-enumeration.git /opt/repos/linux-smart-enumeration && \
    git clone https://github.com/CISOfy/lynis.git /opt/repos/lynis && \
    git clone https://github.com/ivan-sincek/php-reverse-shell.git /opt/repos/php-reverse-shell && \
    git clone https://github.com/mostaphabahadou/postenum.git /opt/repos/postenum && \
    git clone https://github.com/PowerShellMafia/PowerSploit.git /opt/repos/PowerSploit && \
    git clone https://github.com/diegocr/netcat.git /opt/repos/netcat && \
    git clone https://github.com/Greenwolf/ntlm_theft /opt/repos/ntlm_theft && \
    git clone https://github.com/bitsadmin/wesng /opt/repos/wesng

# files for external usage
RUN mkdir -p /opt/external && \ 
    wget -O /tmp/chisel_linux64.gz "$(curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | jq -r '.assets[].browser_download_url' | grep 'chisel_.*_linux_amd64')" && gunzip /tmp/chisel_linux64.gz && mv /tmp/chisel_linux64 /opt/external && \
    wget -O /tmp/chisel_linux86.gz "$(curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | jq -r '.assets[].browser_download_url' | grep 'chisel_.*_linux_386')" && gunzip /tmp/chisel_linux86.gz && mv /tmp/chisel_linux86 /opt/external && \
    wget -O /tmp/chisel_win64.gz "$(curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | jq -r '.assets[].browser_download_url' | grep 'chisel_.*_windows_amd64')" && gunzip /tmp/chisel_win64.gz && mv /tmp/chisel_win64 /opt/external/chisel_win64.exe && \
    wget -O /tmp/chisel_win86.gz "$(curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | jq -r '.assets[].browser_download_url' | grep 'chisel_.*_windows_386')" && gunzip /tmp/chisel_win86.gz && mv /tmp/chisel_win86 /opt/external/chisel_win86.exe && \
    wget -O /opt/external/pspy32 "$(curl -s https://api.github.com/repos/DominicBreuker/pspy/releases/latest | jq -r '.assets[].browser_download_url' | grep 'pspy32$')" && \
    wget -O /opt/external/pspy32s "$(curl -s https://api.github.com/repos/DominicBreuker/pspy/releases/latest | jq -r '.assets[].browser_download_url' | grep 'pspy32s')" && \
    wget -O /opt/external/pspy64 "$(curl -s https://api.github.com/repos/DominicBreuker/pspy/releases/latest | jq -r '.assets[].browser_download_url' | grep 'pspy64$')" && \
    wget -O /opt/external/pspy64s "$(curl -s https://api.github.com/repos/DominicBreuker/pspy/releases/latest | jq -r '.assets[].browser_download_url' | grep 'pspy64s')" && \
    wget -O /opt/external/linpeas.sh "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'linpeas.sh')" && \
    wget -O /opt/external/linpeas_linux_386 "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'linpeas_linux_386')" && \
    wget -O /opt/external/linpeas_linux_amd64 "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'linpeas_linux_amd64')" && \
    wget -O /opt/external/winPEAS.bat "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'winPEAS.bat')" && \
    wget -O /opt/external/winPEASany.exe "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'winPEASany.exe')" && \
    wget -O /opt/external/winPEASany_ofs.exe "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'winPEASany_ofs.exe')" && \
    wget -O /opt/external/winPEASx64.exe "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'winPEASx64.exe')" && \
    wget -O /opt/external/winPEASx64_ofs.exe "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'winPEASx64_ofs.exe')" && \
    wget -O /opt/external/winPEASx86.exe "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'winPEASx86.exe')" && \
    wget -O /opt/external/winPEASx86_ofs.exe "$(curl -s https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest | jq -r '.assets[].browser_download_url' | grep 'winPEASx86_ofs.exe')" && \
    wget -O /tmp/sysint.zip 'https://download.sysinternals.com/files/SysinternalsSuite.zip' && unzip /tmp/sysint.zip -d /opt/external && rm /opt/external/*.chm /opt/external/*.txt /tmp/sysint.zip && \
    mkdir /tmp/mimi && wget -O /tmp/mimi/mimikatz.zip "$(curl -s https://api.github.com/repos/gentilkiwi/mimikatz/releases/latest | jq -r '.assets[].browser_download_url' | grep 'mimikatz_.*.zip')" && \
    unzip /tmp/mimi/mimikatz.zip -d /tmp/mimi && cp /tmp/mimi/Win32/mimikatz.exe /opt/external/mimikatz32.exe && cp /tmp/mimi/Win32/mimilove.exe /opt/external/mimilove.exe && cp /tmp/mimi/x64/mimikatz.exe /opt/external/mimikatz64.exe && rm -rf /tmp/mimi && \
    wget -O /opt/external/traitor-386 "$(curl -s https://api.github.com/repos/liamg/traitor/releases/latest | jq -r '.assets[].browser_download_url' | grep 'traitor-386')" && \
    wget -O /opt/external/traitor-amd64 "$(curl -s https://api.github.com/repos/liamg/traitor/releases/latest | jq -r '.assets[].browser_download_url' | grep 'traitor-amd64')" && \
    wget -O /opt/external/SharpWeb.exe "$(curl -s https://api.github.com/repos/djhohnstein/SharpWeb/releases/latest | jq -r '.assets[].browser_download_url' | grep '.*.exe')" && \
    mkdir -p /opt/external/SharpCollection && git clone https://github.com/Flangvik/SharpCollection /opt/external/SharpCollection && \
    wget -O /opt/external/PrivescCheck.ps1 https://raw.githubusercontent.com/itm4n/PrivescCheck/master/PrivescCheck.ps1 && \
    wget -O /opt/external/SharpHound.exe https://github.com/BloodHoundAD/BloodHound/raw/master/Collectors/SharpHound.exe && \
    wget -O /opt/external/JuicyPotato.exe https://github.com/ohpe/juicy-potato/releases/download/v0.1/JuicyPotato.exe && \
    wget -O /opt/external/nmap-setup.exe https://nmap.org"$(curl --silent https://nmap.org/dist/ | grep "installer for Windows" | cut -d '"' -f 4)" && \
    wget -O /opt/external/putty32.exe https://the.earth.li/~sgtatham/putty/latest/w32/putty.exe && \
    wget -O /opt/external/putty64.exe https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe && \
    git clone https://github.com/expl0itabl3/Toolies /opt/external/Toolies && \
    wget -O /opt/external/PrintSpoofer32.exe "$(curl -s https://api.github.com/repos/itm4n/PrintSpoofer/releases/latest | jq -r '.assets[].browser_download_url' | grep 'PrintSpoofer32.exe')" && \
    wget -O /opt/external/PrintSpoofer64.exe "$(curl -s https://api.github.com/repos/itm4n/PrintSpoofer/releases/latest | jq -r '.assets[].browser_download_url' | grep 'PrintSpoofer64.exe')" 

# other tools
RUN mkdir -p /usr/local/bin && \
    wget -O /tmp/rustscan.deb "$(curl -s https://api.github.com/repos/RustScan/RustScan/releases/tags/2.0.1 | jq -r '.assets[].browser_download_url' | grep 'rustscan_.*_amd64')" && apt install /tmp/rustscan.deb && rm /tmp/rustscan.deb && \
    wget -O /tmp/findomain.zip https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-linux.zip && unzip /tmp/findomain.zip -d /usr/local/bin && rm /tmp/findomain.zip && chmod +x /usr/local/bin/findomain && \
    wget -O /usr/local/bin/gitdumper.sh https://raw.githubusercontent.com/internetwache/GitTools/master/Dumper/gitdumper.sh && chmod +x /usr/local/bin/gitdumper.sh && \
    wget -O /usr/local/bin/extractor.sh https://raw.githubusercontent.com/internetwache/GitTools/master/Extractor/extractor.sh && chmod +x /usr/local/bin/extractor.sh && \
    wget -O /usr/local/bin/gitfinder.py https://raw.githubusercontent.com/internetwache/GitTools/master/Finder/gitfinder.py && chmod +x /usr/local/bin/gitfinder.py && \
    wget -O /usr/local/bin/enum4linux-ng.py https://raw.githubusercontent.com/cddmp/enum4linux-ng/master/enum4linux-ng.py && chmod +x /usr/local/bin/enum4linux-ng.py && \
    wget -O /usr/local/bin/kerbrute "$(curl -s https://api.github.com/repos/ropnop/kerbrute/releases/latest | jq -r '.assets[].browser_download_url' | grep 'linux_amd64')" && chmod +x /usr/local/bin/kerbrute && \
    wget -O /usr/local/bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim.appimage && chmod +x /usr/local/bin/nvim && \
    npm install -g yarn && \
    git clone https://github.com/pwndbg/pwndbg /home/kali/.pwndbg && cd /home/kali/.pwndbg && \ 
    echo "source /home/kali/.pwndbg/gdbinit.py" >> /home/kali/.gdbinit && \
    chown -R kali:kali /home/kali /usr/share/zaproxy && \
    apt -y autoclean && apt -y autoremove && apt -y clean

WORKDIR /home/kali

# install python packages
USER kali
RUN pipx install updog && \
    pipx install search-that-hash && \
    pipx install pwntools && \
    pipx install pyftpdlib && \
    pipx install git+https://github.com/Tib3rius/AutoRecon.git

# Tools not installed by default
# https://github.com/zardus/ctf-tools.git   # ctf tools
# https://github.com/noraj/haiti            # hashidentifier
# Nessus
# mariadb-client # currently broken
# remmina remmina-plugin-rdp remmina-plugin-vnc novnc # removed in 2024 


# Environment Variables

# Proxychains config
RUN echo "dynamic_chain" > /etc/proxychains.conf && \
  echo "proxy_dns" >> /etc/proxychains.conf && \
  echo "tcp_read_time_out 15000" >> /etc/proxychains.conf && \
  echo "tcp_connect_time_out 8000" >> /etc/proxychains.conf && \
  echo "[ProxyList]" >> /etc/proxychains.conf && \
  echo "socks5 127.0.0.1 9050" >> /etc/proxychains.conf

# Common commands (aliases)
RUN echo "alias myip='dig +short myip.opendns.com @resolver1.opendns.com'" >> ~/.zshrc

# ZSH config
RUN sed -i 's^ZSH_THEME="robbyrussell"^ZSH_THEME="bira"^g' ~/.zshrc && \
  sed -i 's^# DISABLE_UPDATE_PROMPT="true"^DISABLE_UPDATE_PROMPT="true"^g' ~/.zshrc && \
  sed -i 's^# DISABLE_AUTO_UPDATE="true"^DISABLE_AUTO_UPDATE="true"^g' ~/.zshrc && \
  sed -i 's^plugins=(git)^plugins=(tmux nmap)^g' ~/.zshrc && \
  echo 'export EDITOR="nano"' >> ~/.zshrc && \
  git config --global oh-my-zsh.hide-info 1

# Clean up space - remove version control
RUN cd $HOME && find . -name '.git' -type d -exec rm -rf {} + && \
  cd $TOOLS && find . -name '.git' -type d -exec rm -rf {} + && \
  cd $ADDONS && find . -name '.git' -type d -exec rm -rf {} + && \
  cd $WORDLISTS && find . -name '.git' -type d -exec rm -rf {} + && \
  rm -rf /root/.cache

# Install packages and set locale
RUN apt-get update \
    && apt-get install -y locales nano ssh proxychains sudo python3 curl wget \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
ARG NGROK_AUTH_TOKEN
ENV SSH_PASS=${SSH_PASS}
ENV NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN}
ENV NGROK_TIMEOUT=$NGROK_TIMEOUT}
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

EXPOSE 80 8888 3443 8080 443 5130-5135 3306 7860 9050 3128 9051 443 53
CMD ["/bin/bash", "/docker.sh"]

