FROM ubuntu:jammy-20230425


RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
        cinnamon locales sudo \
        tigervnc-standalone-server tigervnc-common \
        virtualgl mesa-utils mesa-vulkan-drivers \
        dbus-x11 xterm wget && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Create user
# Enter the below username and passoword in xrdp login screen
ARG USER=user
ARG PASS=1234
RUN useradd -m $USER -p $(openssl passwd $PASS) && \
    usermod -aG sudo $USER && \
    chsh -s /bin/bash $USER

# Environment for Cinnamon
RUN echo "#!/bin/sh\n\
export XDG_SESSION_DESKTOP=cinnamon\n\
export XDG_SESSION_TYPE=x11\n\
export XDG_CURRENT_DESKTOP=X-Cinnamon\n\
export LIBGL_ALWAYS_INDIRECT=0\n\
exec cinnamon-session" > /home/$USER/.xinitrc && \
    chown $USER:$USER /home/$USER/.xinitrc && chmod +x /home/$USER/.xinitrc

# Setup VNC password
RUN mkdir -p /home/$USER/.vnc && \
    echo $PASS | vncpasswd -f > /home/$USER/.vnc/passwd && \
    chmod 0600 /home/$USER/.vnc/passwd && \
    chown -R $USER:$USER /home/$USER/.vnc

# Start script
RUN echo "#!/bin/bash\n\
export DISPLAY=:1\n\
Xvnc :1 -geometry 1920x1080 -depth 24 -SecurityTypes VncAuth -rfbport 5901 -localhost no &\n\
sleep 2\n\
sudo -u $USER startx &\n\
tail -f /dev/null" > /start && chmod +x /start

EXPOSE 5901

CMD ["/start"]

