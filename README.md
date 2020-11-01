# Running Knative on Raspberry Pi

This is a quick tutorial to setup Knative on Raspberry Pi

## Hardware

- Get [Raspberry 4](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/?resellerType=home), pick one that has 2GB or more of RAM. I would recommend getting the 8GB.
- Accesories:
    - Micro SD Card
    - Raspberry Power Supply (USB-C)
- Extras:
    - Fan, heat sinks, case

## Setup Operating System (OS)

This instructions are based on [Ubuntu Post](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#1-overview)

- You will need a 64 bit OS, you can use Ubuntu or Raspberry OS. I will be using Ubuntu 20.10 64bit
- Get an application to image the OS into the SD Card, you can use RaspBerry Imager or any other tool. Choose [MacOS](https://downloads.raspberrypi.org/imager/imager.dmg) or [Windows](https://downloads.raspberrypi.org/imager/imager.exe)
    1. Select Ubuntu Server 20.10 64bit (RPi 3/4)
    2. Select SD Card
    3. WRITE
    4. WAIT for ~10 minutes

Configure some environment variables based on your operating system, you can use the template provided
```bash
cp template.env .env
```
Enter the values based on your Operating system in to the `.env` file
```bash
BOOT_DRIVE=/Volumes/system-boot/
WIFI_SSID=SSID
WIFI_PASSWORD=PASSWORD
```
Load the environment variables
```bash
source .env
```


### Configure Wifi

After the SD Card is imaged, remove the card and re-insert.
The boot filesystem should be visible from example on MacOS under `/Volumes/system-boot/`

Create a file `network-config` with the wifi info, replace the values for SSID and PASSWORD below
```bash
source .env
cat <<EOF >${BOOT_DRIVE}/network-config
wifis:
  wlan0:
  dhcp4: yes
  optional: true
  access-points:
    "${WIFI_SSID}":
      password: "${WIFI_PASSWORD}"
EOF
```

test 2
```bash
source .env
cat <<EOF >${BOOT_DRIVE}/network-config
network:
  version: 2
  renderer: networkd
wifis:
  wlan0:
  dhcp4: yes
  optional: true
  access-points:
    "${WIFI_SSID}":
      password: "${WIFI_PASSWORD}"
EOF
```

Check that the file is correctly created
```bash
source .env
cat ${BOOT_DRIVE}/network-config
```

### Enable cgroups for the kernel

Enable cgroups for the kernel by appending to the `cmdline.txt` file
- Append to the one line, do not add a new line, a backup copy `cmdline.txt.bak` is made.
```bash
BOOT_DRIVE=/Volumes/system-boot/
sed -i .bak 's/$/ cgroup_memory=1 cgroup_enable=memory/' ${BOOT_DRIVE}/cmdline.txt
cat ${BOOT_DRIVE}/cmdline.txt
```

### Boot

Umount/Eject SD Card from your computer, insert into raspberry pi and power on the raspberry pi.

You can discover the IP via your router, or plug a monitor and keyboard and use the command `ip a` to get the ip address.

This would be something like `192.168.x.x` in my case is `192.168.7.217`


### Setup ssh

Check if you have a local ssh, if not then create a new one with `ssh-keygen`
```bash
ls ~/.ssh/id_rsa.pub
```

Copy your public ssh key to the server
```bash
ssh-copy-id ubuntu@192.168.7.217
```

Now you can ssh into the pi without a password
```bash
ssh ubuntu@192.168.7.217
```


## Install Kubernetes

Install the [k3sup](https://github.com/alexellis/k3sup#download-k3sup-tldr) command line tool, check that you have latest version I'm using `0.9.7`
```bash
k3sup version
```


## Related Posts
- https://blog.alexellis.io/test-drive-k3s-on-raspberry-pi/
- https://blog.alexellis.io/raspberry-pi-homelab-with-k3sup/
- https://itsmurugappan.medium.com/knative-on-raspberry-pi-1106984de5b8
