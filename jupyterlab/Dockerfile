FROM ubuntu:20.04

# APT packages
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
    tzdata \
    sudo \
    git \
    vim \
    fonts-dejavu \
    python3 \
    python3-pip \
    gfortran \
    gcc \
    scilab \
    npm \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install jupyterlab notebook numpy pandas matplotlib scipy scikit-learn

RUN npm install -g tslab
RUN tslab install

RUN groupadd -g 999 user
RUN useradd -r -u 999 -g user -ms /bin/bash user
RUN usermod -aG sudo user && usermod -u 1000 user 
RUN echo "user:user" | chpasswd 
RUN echo "\nuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN usermod -a -G video user

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER user
WORKDIR /home/user
ARG JUPYTERLAB_PWD
ENV JUPYTERLAB_PWD=$JUPYTERLAB_PWD
ARG JUPYTERLAB_TOK
ENV JUPYTERLAB_TOK=$JUPYTERLAB_TOK

RUN jupyter notebook --generate-config

ENTRYPOINT ["/entrypoint.sh"]
