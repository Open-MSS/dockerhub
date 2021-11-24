##################################################################################
# Dockerfile to run Memcached Containers
# Based on mambaforge Image
# docker image build -t openmss/mss:x.y.z .
# docker container run --net=host --name mswms openmss/stable mswms --port 80
# docker container run --net=host --name mscolab openmss/stable mscolab start
# docker run  --net=host -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix openmss/stable bash
# xhost +local:docker
# docker container run -d --net=host -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix \
# --name mss openmss/stable mss
# runs mswms with demodata, mscolab and the msui
# docker run   --net=host -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix openmss/stable MSS
# docker exec replace_by_container /bin/sh -c "/scripts/script.sh"
#
# --- Read Capabilities ---
# curl "http://localhost:8081/?service=WMS&request=GetCapabilities&version=1.1.1"
# --- Verify Mscolab ---
# curl "http://localhost:8083/status"
#
# docker ps
# CONTAINER ID        IMAGE          COMMAND                  CREATED             STATUS          NAMES
# 8c3ee656736e        mss     "/opt/conda/envs/mss…"   45 seconds ago      Up 43 seconds   mss
# b1f1ea480ebc        mss     "/opt/conda/envs/mss…"    4 minutes ago      Up 4 minutes    mscolab
# 1fecac3fd2d7        mss     "/opt/conda/envs/mss…"   5 minutes ago       Up 5 minutes    mswms
#
# --- from the dockerhub ---
# For the mss ui:
# xhost +local:docker
# docker run -d --net=host -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix \
# openmss/stable mss
#
#
##################################################################################


# Set the base image ubuntu with mamba
FROM condaforge/mambaforge

# Make RUN commands use `bash --login`:
SHELL ["/bin/bash", "--login", "-c"]

MAINTAINER Reimar Bauer <rb.proj@gmail.com>

# install packages for qt X
RUN apt-get update --yes && apt-get --yes upgrade && apt-get --yes install \
  libgl1-mesa-glx \
  libx11-xcb1 \
  libxi6 \
  xfonts-scalable \
  netbase

# get keyboard working for mss gui
RUN apt-get --yes update && DEBIAN_FRONTEND=noninteractive \
  apt-get --yes install xserver-xorg-video-dummy \
  && apt-get --yes upgrade \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Set up conda-forge channel
RUN conda config --add channels conda-forge && conda config --add channels defaults &&\
  conda update -n base -c defaults conda


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
