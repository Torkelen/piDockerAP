FROM alpine:3.12

MAINTAINER Daniel Wilén <daniel@algorythm.se>

RUN apk update 
RUN apk add --no-cache bash hostapd dnsmasq wireless-tools iptables procps vim sudo 
ADD startServers.sh /bin/startServers.sh

#ENTRYPOINT [ "/bin/startServers.sh" ]
