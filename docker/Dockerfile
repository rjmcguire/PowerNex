FROM vlpro/arch-yaourt:latest

# create user and group
RUN groupadd -r yaourt
RUN useradd -r -g yaourt yaourt

# add root access
RUN echo "yaourt        ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/yaourt

# add better mirrorlist
COPY mirrorlist /etc/pacman.d/mirrorlist

USER yaourt
RUN yaourt --noconfirm -Syua dmd wget tar xz isl grub libisoburn

# remove user yaourt (for security reasons)
USER root
RUN userdel -r yaourt && rm /etc/sudoers.d/yaourt

WORKDIR /root/
RUN wget http://172.17.0.1/PowerNex-BuildTools.tar.xz
#RUN wget http://wild.tk/PowerNex-BuildTools.tar.xz
RUN tar xJvhf PowerNex-BuildTools.tar.xz && rm PowerNex-BuildTools.tar.xz

RUN ln -s /usr/lib/libisl.so.15.0.0 /usr/lib/libisl.so.13

COPY build.sh /root/

ENTRYPOINT ["/root/build.sh"]