FROM python:3.12-bookworm

ARG DEBIAN_FRONTEND=noninteractive
ARG KLIPPER_BRANCH="master"

ARG USER=klippy
ARG HOME=/home/${USER}
ARG KLIPPER_VENV_DIR=${HOME}/klippy-env

RUN useradd -d ${HOME} -ms /bin/bash ${USER} && \
	apt-get update && \
	apt-get install -y \
	locales \
	git \
	libncurses-dev \
	libusb-dev \
	libusb-1.0 \
	pkg-config \
	build-essential \
	gcc-arm-none-eabi

RUN sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && locale-gen; \
	python -m pip install -U pip wheel

ENV LC_ALL en_GB.UTF-8 
ENV LANG en_GB.UTF-8  
ENV LANGUAGE en_GB:en   

USER ${USER}
WORKDIR ${HOME}

### Klipper setup ###
RUN git clone --single-branch --branch ${KLIPPER_BRANCH} https://github.com/Klipper3d/klipper.git klipper && \
	python3 -m venv ${KLIPPER_VENV_DIR} && \
	${KLIPPER_VENV_DIR}/bin/pip install wheel

WORKDIR ${HOME}/klipper

RUN sed -i 's/greenlet==.\+/greenlet==3.0.1/' scripts/klippy-requirements.txt && \
	${KLIPPER_VENV_DIR}/bin/pip install -r scripts/klippy-requirements.txt && \
	${KLIPPER_VENV_DIR}/bin/python klippy/chelper/__init__.py && \
	${KLIPPER_VENV_DIR}/bin/python -m compileall klippy

CMD ["bash"]
