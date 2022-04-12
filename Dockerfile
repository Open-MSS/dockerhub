# Set the base image debian with miniconda
FROM continuumio/miniconda3

# Sets which branch to fetch requirements from
ARG BRANCH=develop

# Make RUN commands use `bash --login`:
SHELL ["/bin/bash", "--login", "-c"]

MAINTAINER Reimar Bauer <rb.proj@gmail.com>

# install packages for qt X
RUN  apt-get --yes update \
  && apt-get --yes upgrade \
  && apt-get --yes install \
      libgl1-mesa-glx \
      libx11-xcb1 \
      libxi6 \
      xfonts-scalable \
      git \
      xvfb \
      netbase \
  && apt-get clean all

# Set up conda-forge channel
RUN  conda config --add channels conda-forge \
  && conda update -n base -c defaults conda

# Create environment
RUN conda create -n mssenv python=3.9 \
  && conda init bash

# Install requirements, fetched from the specified branch
RUN conda activate mssenv \
  && wget -O /meta.yaml -q https://raw.githubusercontent.com/Open-MSS/MSS/${BRANCH}/localbuild/meta.yaml \
  && wget -O /development.txt -q https://raw.githubusercontent.com/Open-MSS/MSS/${BRANCH}/requirements.d/development.txt \
  && cat /meta.yaml \
   | sed -n '/^requirements:/,/^test:/p' \
   | sed -e "s/.*- //" \
   | sed -e "s/menuinst.*//" \
   | sed -e "s/.*://" > reqs.txt \
  && conda install mamba \
  && mamba install --file reqs.txt \
  && mamba install --file /development.txt \
  && mamba install pyvirtualdisplay \
  && conda clean --all \
  && rm reqs.txt
