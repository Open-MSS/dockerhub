##################################################################################
# Dockerfile to run Memcached Containers
# Based on miniconda3 Image
# docker image build -t openmss/mss:x.y.z .
# docker container run --net=host --name mswms openmss/mss:x.y.z mswms --port 80
# docker container run --net=host --name mscolab openmss/mss:x.y.z mscolab start
# docker run  --net=host -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix openmss/mss:x.y.z bash
# xhost +local:docker
# docker container run -d --net=host -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix \
# --name mss openmss/mss:x.y.z mss
# runs mswms with demodata, mscolab and the msui
# docker run   --net=host -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix openmss/mss:x,y,z MSS
# docker exec replace_by_container /bin/sh -c "/scripts/script.sh"
#
# --- Read Capabilities ---
# curl "http://localhost:8081/?service=WMS&request=GetCapabilities&version=1.1.1"
# --- Verify Mscolab ---
# curl "http://localhost:8083/status"
#
# docker ps
# CONTAINER ID        IMAGE          COMMAND                  CREATED             STATUS          NAMES
# 8c3ee656736e        mss:x.y.z     "/opt/conda/envs/mss…"   45 seconds ago      Up 43 seconds   mss
# b1f1ea480ebc        mss:x.y.z     "/opt/conda/envs/mss…"    4 minutes ago      Up 4 minutes    mscolab
# 1fecac3fd2d7        mss:x.y.z     "/opt/conda/envs/mss…"   5 minutes ago       Up 5 minutes    mswms
#
# --- from dockerhub ---
# For the mss ui:
# xhost +local:docker
# docker run -d --net=host -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix \
# openmss/mss mss
#
#
##################################################################################


# Set the base image debian with miniconda
FROM continuumio/miniconda3

# Make RUN commands use `bash --login`:
SHELL ["/bin/bash", "--login", "-c"]

MAINTAINER Reimar Bauer <rb.proj@gmail.com>

# install packages for qt X
RUN echo "deb http://ftp.us.debian.org/debian stable main contrib non-free" >> /etc/apt/sources.list \
  && apt-get update --yes && apt-get --yes upgrade && apt-get --yes install \
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
RUN conda config --add channels conda-forge &&\
  conda update -n base -c defaults conda

# create some desktop user directories
# if there is no data attached e.g. demodata /srv/mss is the preferred dir
RUN mkdir -p /root/.local/share/applications/ \
  && mkdir -p /root/.local/share/icons/hicolor/48x48/apps/ \
  && mkdir /srv/mss

# install conda-build
RUN conda install conda-build -y

# fetch localbuild from mss branch develop, build and install mss, cleanup
RUN wget https://github.com/Open-MSS/MSS/archive/develop.tar.gz \
  && conda update python \
  && mkdir /localbuild \
  && tar -C /localbuild --strip-components=2 -xvf develop.tar.gz MSS-develop/localbuild \
  && sed -i "s@path: ../@git_url: https://github.com/Open-MSS/MSS.git\n  git_tag: develop@" /localbuild/meta.yaml \
  && rm develop.tar.gz \
  && conda build /localbuild \
  && conda install mamba \
  && mamba create -n mssenv mss=alpha --use-local \
  && conda build purge-all \
  && conda clean --all

# path for data and mss_wms_settings config
ENV PYTHONPATH="/srv/mss:/root/mss"
ENV PROJ_LIB="/opt/conda/envs/mssenv/share/proj"
ENV PATH=/opt/conda/envs/mssenv/bin:$PATH

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
