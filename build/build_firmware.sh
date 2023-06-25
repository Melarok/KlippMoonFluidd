#! /bin/bash

BASE=$(pwd)
if [[ $(basename $BASE) != "build" ]]; then
    echo "This script needs to be run from inside KlippMoonFluidd/build, cd into it and try again!"
    exit 1
else
    ### build the builder container
    docker build --pull --rm -f "klipper/builder.Dockerfile" -t  klipper-builder:latest "klipper"
    ### setup paths
    BUILD_DIR=${BASE}/firmware/build
    CONFIG_PATH=${BUILD_DIR}/klipper-make.config
    touch ${CONFIG_PATH}
    ### run the build
    CONTAINER=$(docker run -d -v ${CONFIG_PATH}:/home/klippy/klipper/.config klipper-builder sleep infinity)
    docker exec -it ${CONTAINER} make menuconfig
    docker exec ${CONTAINER} make
    docker stop ${CONTAINER}
    docker rm ${CONTAINER}
