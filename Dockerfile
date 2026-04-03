FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=user
ENV PASS=1234
ENV DISPLAY=:1
ENV RESOLUTION=1920x1080

# Install everything
RUN apt-get update && apt-get install -y \
    cinnamon \
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

# Create xstartup
RUN echo '#!/bin/bash\n\
export XDG_SESSION_DESKTOP=cinnamon\n\
export XDG_SESSION_TYPE=x11\n\
export XDG_CURRENT_DESKTOP=Cinnamon\n\
export DISPLAY=:1\n\
dbus-launch cinnamon-session\n' > /home/$USER/.vnc/xstartup && \
    chmod +x /home/$USER/.vnc/xstartup && \
    chown -R $USER:$USER /home/$USER/.vnc

# Startup script
RUN echo '#!/bin/bash\n\
vncserver :1 -geometry 1920x1080 -depth 24\n\
/opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 8080\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]
