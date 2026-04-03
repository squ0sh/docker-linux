FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=user
ENV PASS=1234
ENV DISPLAY=:1
ENV PORT=8080

# Install desktop + tools
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    xvfb x11vnc \
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

# Setup VNC password
RUN mkdir -p /home/$USER/.vnc && \
    x11vnc -storepasswd $PASS /home/$USER/.vnc/passwd && \
    chown -R $USER:$USER /home/$USER/.vnc

# Start script (new architecture)
RUN echo '#!/bin/bash\n\
echo "Starting virtual display..."\n\
Xvfb :1 -screen 0 1280x800x24 &\n\
sleep 2\n\
echo "Starting XFCE session..."\n\
su - user -c "DISPLAY=:1 startxfce4 &"\n\
sleep 2\n\
echo "Starting x11vnc..."\n\
x11vnc -display :1 -rfbport 5901 -passwd '$PASS' -forever -shared &\n\
sleep 2\n\
echo "Starting noVNC..."\n\
exec /opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:$PORT --web /opt/noVNC\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]
