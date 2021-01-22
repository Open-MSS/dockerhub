# Set the base image debian with miniconda
FROM continuumio/miniconda3

# Sets which branch to fetch requirements from
ARG BRANCH=develop

# Make RUN commands use `bash --login`:
SHELL ["/bin/bash", "--login", "-c"]

MAINTAINER Reimar Bauer <rb.proj@gmail.com>

# install packages for qt X
RUN apt-get --yes update && apt-get --yes upgrade && apt-get --yes install \
  libgl1-mesa-glx \
  libx11-xcb1 \
  libxi6 \
  xfonts-scalable

# update git to latest version, and install xvfb
RUN echo "deb http://ftp.us.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y git \
  && apt-get install -y xvfb \
  && apt-get clean all

# Set up conda-forge channel
RUN conda config --add channels conda-forge && conda config --add channels defaults &&\
  conda update -n base -c defaults conda

# Create environment
RUN conda create -n mssenv python=3

# Install requirements, fetched from the specified branch
RUN wget -O /meta.yaml -q https://raw.githubusercontent.com/Open-MSS/MSS/${BRANCH}/localbuild/meta.yaml \
  && cat /meta.yaml \
   | sed -n '/^requirements:/,/^test:/p' \
   | sed -e "s/.*- //" \
   | sed -e "s/menuinst.*//" \
   | sed -e "s/.*://" > reqs.txt \
  && conda install -n mssenv --file reqs.txt \
  && conda install -n mssenv --file https://raw.githubusercontent.com/Open-MSS/MSS/${BRANCH}/requirements.d/development.txt \
  && conda install -n mssenv pyvirtualdisplay \
  && conda clean --all \
  && rm reqs.txt
