# Base Image
FROM kalilinux/kali-rolling

# Environment Settings
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

# Install Packages
RUN apt-get update && apt-get install -y \
    tzdata \
    net-tools \
    firefox-esr \
    vim \
    man \
    file \
    kali-linux-headless \
    perl \
    wget \
    tar \
    sudo \
    curl \
    w3m \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    dbus \
    dbus-x11 \
    matchbox-keyboard \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create /var/run/dbus directory
RUN mkdir -p /var/run/dbus

# Create User 'kali' with sudo access
RUN useradd -m -s /bin/bash kali && \
    usermod -aG sudo kali && \
    echo "kali ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kali && \
    chmod 0440 /etc/sudoers.d/kali

# Switch to user 'kali'
USER kali
ENV USER=kali
WORKDIR /home/kali

# Setup VNC Password and Startup Script
RUN mkdir -p /home/kali/.vnc && \
    echo "kali" | vncpasswd -f > /home/kali/.vnc/passwd && \
    chmod 600 /home/kali/.vnc/passwd && \
    echo "#!/bin/bash\n\
startxfce4 &\n\
sleep 2\n\
matchbox-keyboard --xscale 0.6 --yscale 0.6 &\n\
" > /home/kali/.vnc/xstartup && \
    chmod +x /home/kali/.vnc/xstartup

# Add Virtual Keyboard Shortcut to Desktop
RUN mkdir -p /home/kali/Desktop && \
    echo "[Desktop Entry]\n\
Name=Virtual Keyboard\n\
Exec=matchbox-keyboard --xscale 0.6 --yscale 0.6\n\
Type=Application\n\
Icon=utilities-terminal\n\
Terminal=false\n\
Categories=Utility;\n" > /home/kali/Desktop/virtual-keyboard.desktop && \
    chmod +x /home/kali/Desktop/virtual-keyboard.desktop

# Expose Ports for VNC and noVNC
EXPOSE 5901 6080

# Start D-Bus, VNC Server, and noVNC Proxy
CMD ["bash", "-c", "sudo mkdir -p /var/run/dbus && sudo dbus-daemon --system --fork && vncserver :1 -geometry 1280x800 -depth 24 && websockify --web /usr/share/novnc/ 6080 localhost:5901"]
