FROM centos:stream10-development

# Install the needed software
RUN dnf -y install epel-release dnf-plugins-core policycoreutils
RUN dnf -y upgrade epel-release
RUN crb enable
RUN dnf -y install kiwi qemu-img gdisk dosfstools xfsprogs e2fsprogs xz isomd5sum erofs-utils xorriso

# Run container until stopped
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
