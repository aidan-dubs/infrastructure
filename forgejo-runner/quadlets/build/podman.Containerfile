FROM quay.io/podman/stable

RUN rm -f \
    /etc/containers/storage.rootless.conf.d/20-image_build.conf \
    /etc/containers/storage.rootful.conf.d/20-image_build.conf

RUN printf '[storage]\ndriver = "overlay"\n' > /etc/containers/storage.conf
