# KlippMoonFluidd

Fully dockerized Klipper, Moonraker and Fluidd stack with optional reverse proxy integration with Traefik.


## Setup

### Obtain a klipper make .config file for your printer
- Either you copy your own .config from a previous klipper build to build/klipper-make.config
- Or you run the build_firmware.sh script in the root of this repo
    - It builds a docker container named "klipper-firmware", interactively generates the .config and removes the container afterwards
    - You'll only need to run this once, the .config will be saved under build/klipper-make.config for the main container build

### Set up udev rule for the serial port
- Create the file: /etc/udev/rules.d/99-KlippMoonFluidd-serial.rules
- Paste the following two lines and replace <usename> with your username

```
KERNEL=="ttyUSB[0-9]*",GROUP+="<username>"
KERNEL=="ttyACM[0-9]*",GROUP+="<username>"
```

### Optional: set up udev rules to restart the container on powering it on (same as plugging it in)
Add the following lines to the /etc/udev/rules.d/99-KlippMoonFluidd-serial.rules file:
- ENV{ID_VENDOR_ID} and ENV{ID_MODEL_ID} can be obtained by runing "lsusb"

```
ACTION=="add", KERNEL=="ttyACM[0-9]", SUBSYSTEM=="tty", ENV{ID_VENDOR_ID}=="<YourValueHere>", ENV{ID_MODEL_ID}=="<YourValueHere>", RUN+="<PathToGitRepo>/restart_on_plug-in.sh"
ACTION=="add", KERNEL=="ttyUSB[0-9]", SUBSYSTEM=="tty", ENV{ID_VENDOR_ID}=="<YourValueHere>", ENV{ID_MODEL_ID}=="<YourValueHere>", RUN+="<PathToGitRepo>/restart_on_plug-in.sh"
```

### Modify the docker-compose.yml according to your needs
- The "ports" section of klipper-moonraker needs your ip
- Get the serial id for your printer by running ```ls /dev/serial/by-id/``` while the printer is on and connected via usb
- If you're not using Traefik as reverse proxy you'll need to
    - uncomment the "ports" section of "fluidd"
    - comment the "labels" and "networks" section of "fluidd"
    - comment the "networks" section at the end of the file


### Customize your printer.cfg and moonraker.conf
- The supplied .example files are tailored to my printer / setup
- If you want to use my gcode-macros.cfg, test them carefully on your printer before using them


### Check the gecode-macros.cfg.example!!!
- The supplied gcode-macros.cfg.example contains macros I collected somewhere, so I can't guarantee that they'll work for your printer!
- Assume they'll destroy your printer, so test them carefully before using them


### Build and run the main container
docker compose up -d
