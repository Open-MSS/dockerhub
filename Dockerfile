##################################################################################
# Dockerfile to run Memcached Containers
# Based on mambaforge Image
# docker image build -t openmss/mss .
# xhost +local:docker
# runs mswms with demodata, mscolab and the msui
# docker run   --net=host -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix openmss/mss  MSS
#
# --- Read Capabilities ---
# curl "http://localhost:8081/?service=WMS&request=GetCapabilities&version=1.1.1"
# --- Verify Mscolab ---
# curl "http://localhost:8083/status"
#
##################################################################################


# Set the base image ubuntu with mamba
FROM condaforge/mambaforge

# Make RUN commands use `bash --login`:
SHELL ["/bin/bash", "--login", "-c"]

MAINTAINER Reimar Bauer <rb.proj@gmail.com>

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# install packages for qt X
RUN  apt-get -yqq update --fix-missing \
  && apt-get -yqq upgrade \
  && apt-get -yqq install \
      apt-utils \
      libgl1-mesa-glx \
      libx11-xcb1 \
      libxi6 \
      xserver-xorg-video-dummy \
      xfonts-scalable \
      x11-apps \
      netbase \
  && apt-get -yqq clean all \
  && rm -rf /var/lib/apt/lists/*


# create some desktop user directories
# if there is no data attached e.g. demodata /srv/mss is the preferred dir
RUN mkdir -p /root/.local/share/applications/ \
  && mkdir -p /root/.local/share/icons/hicolor/48x48/apps/ \
  && mkdir /srv/mss

# Install Mission Support System Software
RUN mamba create -n mssenv mss -y
ENV PATH=/opt/conda/envs/mssenv/bin:$PATH

# path for data and mss_wms_settings config
ENV PYTHONPATH="/srv/mss:/root/mss"
ENV PROJ_LIB="/opt/conda/envs/mssenv/share/proj"

# In the script is an initialisation of demodata and
# the mswms and mscolab server is started
# server based on demodata until you mount a data volume on /srv/mss
# also you can replace the data in the demodata dir /root/mss.
RUN mkdir -p /scripts
COPY script.sh /scripts
WORKDIR /scripts
RUN chmod +x script.sh

ENTRYPOINT ["bash", "/scripts/script.sh"]

EXPOSE 8081 8083
