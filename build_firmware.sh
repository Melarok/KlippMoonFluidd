#! /bin/bash

BASE=$(pwd)

if [[ -f ./build/firmware.Dockerfile ]]; then
    BASE="$BASE/build"
elif [[ -f ./firmware.Dockerfile ]]; then
    BASE="$BASE"
else
    echo "ERROR: Could not find firmware.Dockerfile in $(pwd) or $(pwd)/build!"
    echo "Rerun this script either from the root of the repository, or from within the build subdirectory."
    exit 1
fi


### build the container
docker buildx build --rm -f "$BASE"/firmware.Dockerfile -t klipper-firmware:latest "$BASE"

### if a config file from a previous build is present, use it it as a template for the next build
if [[ -f ./klipper-make.config ]]; then
    CONTAINER=$(docker run -d -v "$BASE"/klipper-make.config:/home/klippy/klipper/.config \
                                 klipper-firmware:latest sleep infinity)
else
    CONTAINER=$(docker run -d klipper-firmware:latest sleep infinity)
fi

### run the build
docker exec -w /home/klippy/klipper -it "$CONTAINER" make menuconfig
docker exec -w /home/klippy/klipper "$CONTAINER" make
docker stop "$CONTAINER"

### get the firmware and its config
if [[ $BASE == *build ]]; then
    OUT="$BASE"
else
    OUT="$BASE/build"
fi

docker cp "$CONTAINER":/home/klippy/klipper/.config "$OUT"/klipper-make.config
docker cp "$CONTAINER":/home/klippy/klipper/out/klipper.bin "$OUT"/firmware.bin

### cleanup
docker rm "$CONTAINER"
docker rmi klipper-firmware:latest
