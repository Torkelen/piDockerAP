# piDockerAP
How to create a docker container as wifi access point.
Target is Raspberry Pi and tested on 4B and Zero W.

Container is based on Alpine and contains hostapd and dnsmasq.

Reason for this small project is to create a mesh network based on batman-adv in the background on the actual hosts and adding AP's as dockers above.
To make this work on Raspberry you need a second wifi adapter.
In this project a mix has been used of an old Belkin adapter and more modern ALFA AWUS036ACH.

**Prequisites**
1. Raspberry Pi OS, (most proably other linux dists will work also but not tested).
2. Docker installed

**Installation**
1. clone repo: _git clone https://github.com/Torkelen/piDockerAP.git_
2. enter piDockerAP: cd _piDockerAP_
3. Copy piDockerAP.conf.tpl to piDockerAP.conf: _cp piDockerAP.conf.tpl piDockerAP.conf_
4. Edit piDockerAP.conf with needed settings like container names, ip, wifi etc
5. Create image by executing: _docker build -t pidockerap ._
Currently running Alpine:3.12, latest has some problems. Feel free to change to other dist in Dockerfile.
4. You can check that your images exists with: _docker image ls_
5. Create and/or start you docker with: _./runPiDocker.sh_
First run will create your docker container and using settings from your conf-file and start it.
Container will not restart automatically after reboot. That is not possible since wlan interface needs to added to existing process for the container.
To start after reboot add ./runPiDocker.sh in autostart like /etc/rc.local

**Tips and trix**

_docker exec -it "your container" bash_ to view your container and work with it.
use batctl and batman-adv to create a mesh network as backend for your AP's.

