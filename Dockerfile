# Set the base image ubuntu with mamba
FROM condaforge/mambaforge

# Sets which branch to fetch requirements from
ARG BRANCH=develop

# Make RUN commands use `bash --login`:
SHELL ["/bin/bash", "--login", "-c"]

MAINTAINER Reimar Bauer <rb.proj@gmail.com>

# install packages for qt X
RUN  apt-get --yes update \
  && apt-get --yes upgrade \
  && apt-get --yes install \
      apt-utils \
      libgl1-mesa-glx \
      libx11-xcb1 \
      libxi6 \
      xfonts-scalable \
      x11-apps \
      netbase \
      git \
      xvfb \
  && apt-get clean all

ENV PATH=/opt/conda/envs/mssenv/bin:$PATH

# path for data and mss_wms_settings config
ENV PYTHONPATH="/srv/mss:/root/mss"
ENV PROJ_LIB="/opt/conda/envs/mssenv/share/proj"

# Install requirements, fetched from the specified branch
RUN wget -O /meta.yaml -q https://raw.githubusercontent.com/Open-MSS/MSS/${BRANCH}/localbuild/meta.yaml \
  && wget -O /development.txt -q https://raw.githubusercontent.com/Open-MSS/MSS/${BRANCH}/requirements.d/development.txt \
  && cat /meta.yaml \
   | sed -n '/^requirements:/,/^test:/p' \
   | sed -e "s/.*- //" \
   | sed -e "s/menuinst.*//" \
   | sed -e "s/.*://" > reqs.txt \
  && cat development.txt >> reqs.txt \
  && echo pyvirtualdisplay >> reqs.txt \
  && mamba create -y -n mssenv --file reqs.txt \
  && conda clean --all \
  && rm reqs.txt 

RUN mamba init bash
ADD entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
