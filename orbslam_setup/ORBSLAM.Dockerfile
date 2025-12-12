FROM rv_base:v1

WORKDIR /root/

COPY config /root/config
COPY orbslam_entrypoint.sh /root/orbslam_entrypoint.sh
RUN mkdir -p /root/memory_register/orbslam_data/trajectory &&\
    mkdir -p /root/memory_register/orbslam_data/map &&\
    chmod +x /root/orbslam_entrypoint.sh

ENTRYPOINT [ "/root/orbslam_entrypoint.sh" ]