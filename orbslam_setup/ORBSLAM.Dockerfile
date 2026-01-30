FROM rv_base:humble

WORKDIR /root/

COPY config /root/config
COPY orbslam_entrypoint.sh /root/orbslam_entrypoint.sh
RUN mkdir -p /root/memory_register/orbslam_data/trajectory &&\
    mkdir -p /root/memory_register/orbslam_data/map &&\
    chmod +x /root/orbslam_entrypoint.sh

COPY bag_to_tum.py /root/colcon_ws/src/bag_to_tum.py
RUN chmod +x /root/colcon_ws/src/bag_to_tum.py

ENTRYPOINT [ "/root/orbslam_entrypoint.sh" ]