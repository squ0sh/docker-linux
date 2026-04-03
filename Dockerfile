FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=user
ENV PASS=1234
ENV DISPLAY=:1

# Install desktop + tools
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server tigervnc-common \
    dbus-x11 xterm wget curl git sudo \
    python3 python3-pip \
    net-tools \
    && apt-get clean

# Install noVNC + websockify
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Create user
RUN useradd -m $USER && \
    echo "$USER:$PASS" | chpasswd && \
    usermod -aG sudo $USER

# Setup VNC password
RUN mkdir -p /home/$USER/.vnc && \
    echo $PASS | vncpasswd -f > /home/$USER/.vnc/passwd && \
    chown -R $USER:$USER /home/$USER/.vnc && \
    chmod 600 /home/$USER/.vnc/passwd

# XFCE startup (more reliable than Cinnamon)
RUN echo '#!/bin/bash\n\
xrdb $HOME/.Xresources\n\
startxfce4 &\n' > /home/$USER/.vnc/xstartup && \
    chmod +x /home/$USER/.vnc/xstartup && \
    chown -R $USER:$USER /home/$USER/.vnc

# Start script
RUN echo '#!/bin/bash\n\
vncserver :1 -geometry 1280x800 -depth 24\n\
/opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 8080 --web /opt/noVNC\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]
