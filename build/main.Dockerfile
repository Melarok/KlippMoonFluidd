###########
# BUILDER #
###########

FROM --platform=linux/arm64 python:3.12-bookworm as builder

ARG DEBIAN_FRONTEND=noninteractive
ARG KLIPPER_BRANCH="master"
ARG MOONRAKER_BRANCH="master"

ARG USER=klippy
ARG HOME=/home/${USER}
ARG KLIPPER_VENV_DIR=${HOME}/klippy-env
ARG MOONRAKER_VENV_DIR=${HOME}/moonraker-env

ENV WHEELS=/wheels
ENV PYTHONUNBUFFERED=1

RUN useradd -d ${HOME} -ms /bin/bash ${USER} && \
    apt-get update && \
    apt-get install -y \
    locales \
    git \
    sudo \
    wget \
    curl \
    gzip \
    tar \
    libffi-dev \
    build-essential \
    libncurses-dev \
    libusb-dev \
    gpiod \
    libopenjp2-7 \
    liblmdb-dev \
    libsodium-dev \
    gcc-arm-none-eabi && \
    sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

RUN python -m pip install -U pip wheel && \
    pip wheel --no-cache-dir -w ${WHEELS} supervisord-dependent-startup gpiod numpy matplotlib

ENV LC_ALL en_GB.UTF-8 
ENV LANG en_GB.UTF-8  
ENV LANGUAGE en_GB:en   

### Klipper setup ###
USER ${USER}
WORKDIR ${HOME}

RUN git clone --single-branch --branch ${KLIPPER_BRANCH} https://github.com/Klipper3d/klipper.git klipper && \
    python3 -m venv ${KLIPPER_VENV_DIR}

WORKDIR ${HOME}/klipper

RUN sed -i 's/greenlet==.\+/greenlet==3.0.1/' scripts/klippy-requirements.txt

RUN ${KLIPPER_VENV_DIR}/bin/pip install wheel && \
    ${KLIPPER_VENV_DIR}/bin/pip install --no-cache-dir -f ${WHEELS} -r scripts/klippy-requirements.txt

RUN ${KLIPPER_VENV_DIR}/bin/python klippy/chelper/__init__.py && \
    ${KLIPPER_VENV_DIR}/bin/python -m compileall klippy

COPY klipper-make.config ${HOME}/klipper/.config
WORKDIR ${HOME}/klipper
RUN make

### Moonraker setup ###
WORKDIR ${HOME}

RUN git clone --single-branch --branch ${MOONRAKER_BRANCH} https://github.com/Arksine/moonraker.git moonraker && \
    python3 -m venv ${MOONRAKER_VENV_DIR}

WORKDIR ${HOME}/moonraker

RUN ${MOONRAKER_VENV_DIR}/bin/pip install wheel gpiod && \
    ${MOONRAKER_VENV_DIR}/bin/pip install --no-cache-dir -f ${WHEELS} -r scripts/moonraker-requirements.txt

RUN ${MOONRAKER_VENV_DIR}/bin/python -m compileall moonraker

#########
# IMAGE #
#########

FROM --platform=linux/arm64 python:3.12-slim-bookworm as image

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt install -y \
    sed \
    curl \
    git \
    gpiod \
    iproute2 \
    libcurl4-openssl-dev \
    libjpeg-dev \
    liblmdb-dev \
    libopenjp2-7 \
    libsodium-dev \
    libssl-dev \
    libtiff6 \
    locales \
    rsync \
    supervisor \
    zlib1g-dev && \
    sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/g' /etc/locale.gen && \
    locale-gen && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

ENV LC_ALL en_GB.UTF-8 
ENV LANG en_GB.UTF-8  
ENV LANGUAGE en_GB:en   

ARG USER=klippy
ARG HOME=/home/${USER}
ARG DEVICE_GROUP=device
ARG DEVICE_GID=987
ENV DATA_DIR=${HOME}/printer_data
ENV CONFIG_DIR=${DATA_DIR}/config
ENV KLIPPER_VENV_DIR=${HOME}/klippy-env
ENV MOONRAKER_VENV_DIR=${HOME}/moonraker-env

ENV WHEELS=/wheels
ENV PYTHONUNBUFFERED=1

RUN useradd --user-group --no-log-init --shell /bin/false -m -d ${HOME} ${USER} && \
    groupadd -g ${DEVICE_GID} ${DEVICE_GROUP} && \
    usermod -a -G ${DEVICE_GROUP} ${USER} && \
    usermod -a -G tty ${USER} && \
    usermod -a -G dialout ${USER} && \
    usermod -a -G uucp ${USER} && \
    mkdir -p /var/log/supervisor ${HOME}/.cache/pip && \
    touch /var/log/supervisor/supervisord.log && \
    chown -R root:${USER} /var/log/supervisor && \
    chmod -R g=u /var/log/supervisor && \
    mkdir -p /var/log/klipper && \
    chown -R ${USER}:${USER} /var/log/klipper ${HOME}

COPY --chown=${USER}:${USER} --from=builder ${WHEELS} ${WHEELS}

RUN pip install --no-index -f ${WHEELS} supervisord-dependent-startup gpiod numpy matplotlib && \
    mkdir -p /usr/lib/python3 && \
    ln -s /usr/local/lib/python3.11/site-packages /usr/lib/python3/dist-packages && \
    rm -Rf ${WHEELS}

USER ${USER}
WORKDIR ${HOME}

RUN mkdir -p ${CONFIG_DIR} ${HOME}/.moonraker ${HOME}/.klipper_repo_backup ${HOME}/.moonraker_repo_backup

EXPOSE 7125

USER root

COPY --chown=${USER}:${USER} --from=builder ${HOME}/klipper/out/klipper.elf /usr/local/bin/klipper_mcu
COPY --chown=${USER}:${USER} --from=builder ${HOME}/klipper/out/klipper.bin ${DATA_DIR}/firmware.bin
COPY --chown=${USER}:${USER} --from=builder ${HOME}/klipper ${HOME}/klipper
COPY --chown=${USER}:${USER} --from=builder ${KLIPPER_VENV_DIR} ${KLIPPER_VENV_DIR}
COPY --chown=${USER}:${USER} --from=builder ${HOME}/moonraker ${HOME}/moonraker
COPY --chown=${USER}:${USER} --from=builder ${MOONRAKER_VENV_DIR} ${MOONRAKER_VENV_DIR}
COPY --chown=${USER}:${USER} run_in_venv.sh /usr/local/bin/run_in_venv

COPY supervisord/supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisord/*.ini /etc/supervisor/conf.d/
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
