FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=user
ENV PASS=1234
ENV DISPLAY=:1
ENV PORT=8080

# Install desktop + tools
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server tigervnc-common \
    dbus-x11 xterm wget curl git sudo \
    net-tools \
    && apt-get clean

# Install noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Create user
RUN useradd -m $USER && \
    echo "$USER:$PASS" | chpasswd && \
    usermod -aG sudo $USER

# Setup VNC + XFCE for user
RUN mkdir -p /home/$USER/.vnc && \
    echo $PASS | vncpasswd -f > /home/$USER/.vnc/passwd && \
    chmod 600 /home/$USER/.vnc/passwd && \
    echo '#!/bin/bash\n\
xrdb $HOME/.Xresources\n\
startxfce4 &\n' > /home/$USER/.vnc/xstartup && \
    chmod +x /home/$USER/.vnc/xstartup && \
    chown -R $USER:$USER /home/$USER/.vnc

# Start script (RUN AS USER)
RUN echo '#!/bin/bash\n\
echo "Starting VNC as user..."\n\
su - user -c "vncserver -kill :1 > /dev/null 2>&1 || true"\n\
su - user -c "vncserver :1 -geometry 1280x800 -depth 24"\n\
sleep 3\n\
echo "Starting noVNC..."\n\
exec /opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:$PORT --web /opt/noVNC\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]
