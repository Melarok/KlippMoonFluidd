# KlippMoonFluidd

Fully dockerized Klipper, Moonraker and Fluidd stack with optional reverse proxy integration with Traefik.


## Setup

### Obtain a klipper make .config file for your printer (build/firmware/klipper-make.config.example is for a BTT SKR v1.2)
- Eiter you copy your own .config from a previous klipper build to build/firmware/klipper-make.config
- Or you run the build_firmware.sh script inside build/
    - It builds a docker container named "klipper-builder", interactively generates the .config and builds the firmware once
    - You'll only need to run this once, afterwards the .config is saved under build/firmware/klipper-make.config for the main container
    - After generating the .config, you can remove the builder image from your pi as it's not needed anymore (```docker rmi klipper-builder```)

### Set up udev rule for the serial port
- Create the file: /etc/udev/rules.d/99-docker-serial.rules
- Paste the following two lines and replace <usename> with your username

```
    KERNEL=="ttyUSB[0-9]*",GROUP+="<username>"
    KERNEL=="ttyACM[0-9]*",GROUP+="<username>"
```

### Modify the docker-compose.yml according to your needs
- The "ports" section of klipper-moonraker needs your ip
- Get the serial id for your printer by running ```ls /dev/serial/by-id/``` while the printer is on and conncted via usb
- If you're not using Traefik as reverse proxy you'll need to
    - uncomment the "ports" section of "fluidd"
    - comment the "labels" and "networks" section of "fluidd"
    - comment the "networks" section at the end of the file

### Build the container and run it
docker compose build
docker compose up -d
