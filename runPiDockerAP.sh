#!/usr/bin/env bash
# set -x

_usage() {
	echo "Could not find config file."
	echo "Usage: $0 [/path/to/piDockerAP.conf]"
	exit 1
}

SCRIPT_DIR=$(cd $(dirname $0) && pwd )
DEFAULT_CONFIG_FILE=$SCRIPT_DIR/piDockerAP.conf
CONFIG_FILE=${1:-$DEFAULT_CONFIG_FILE}
source $CONFIG_FILE 2>/dev/null || { _usage; exit 1; }

_nmcli() {
	type nmcli >/dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		echo "* setting interface '$WIFI_INTERFACE' to unmanaged"
		nmcli dev set $WIFI_INTERFACE managed no
		nmcli radio wifi on
	fi
}

_get_phy_from_dev() {
	#test $WIFI_ENABLED = 'true' || return
	test -z $WIFI_PHY || return
	if [[ -f /sys/class/net/$WIFI_INTERFACE/phy80211/name ]]; then
		WIFI_PHY=$(cat /sys/class/net/$WIFI_INTERFACE/phy80211/name 2>/dev/null)
		echo "* got '$WIFI_PHY' for device '$WIFI_INTERFACE'"
	else
		echo "$WIFI_INTERFACE is not a valid phy80211 device"
		exit 1
	fi
}

_cleanup() {
	echo -e "\n* cleaning up..."
	echo "* stopping container"
	sudo docker stop $CONTAINER >/dev/null
	#echo "* cleaning up netns symlink"
	#sudo rm -rf /var/run/netns/$CONTAINER
	#echo "* removing host $LAN_DRIVER interface"
	#if [[ $LAN_DRIVER != "bridge" ]] ; then
		#sudo ip link del dev $LAN_IFACE
	#elif [[ $LAN_PARENT =~ \. ]] ; then
		#sudo ip link del dev $LAN_PARENT
	#fi
	echo -ne "* finished"
}

_gen_config() {
	echo "* generating config"
	set -a
	#_get_phy_from_dev
	source $CONFIG_FILE
	for file in *.tpl; do
		#echo ${file}	
		envsubst <${file} >${file%.tpl}
		#docker cp ${file%.tpl} $CONTAINER:/${file%.tpl}
	done
	#* copy config files (hostapd & dnsmasq) 
	docker cp hostapd.conf $CONTAINER:/etc/hostapd/hostapd.conf	
	docker cp dnsmasq.conf $CONTAINER:/etc/dnsmasq.conf	
	set +a
}

_create_or_start_container() {
	if ! docker inspect $IMAGE:$TAG >/dev/null 2>&1; then
		echo "no image '$IMAGE:$TAG' found"
		exit 1

	elif docker inspect $CONTAINER >/dev/null 2>&1; then
		echo "* starting container '$CONTAINER'"
		docker start $CONTAINER || exit 1

	else
		#_init_network
		echo "* creating container $CONTAINER"
		docker create \
			--cap-add NET_ADMIN \
			--cap-add NET_RAW \
			--hostname $HOSTNAME \
			--sysctl net.netfilter.nf_conntrack_acct=1 \
			--sysctl net.ipv6.conf.all.disable_ipv6=0 \
			--sysctl net.ipv6.conf.all.forwarding=1 \
			--name $CONTAINER -it $IMAGE:$TAG /bin/bash >/dev/null
		#docker network connect $WAN_NAME $CONTAINER

		_gen_config
		docker start $CONTAINER
	fi
}

_prepare_wifi() {
	#test $WIFI_ENABLED = 'true' || return
	test -z $WIFI_INTERFACE && _usage
	_get_phy_from_dev
	_nmcli
	echo "* moving device $WIFI_PHY to docker network namespace"
	sudo iw phy "$WIFI_PHY" set netns $PID
	#_set_hairpin $WIFI_INTERFACE
}

_prepare_network() {
	docker exec -i $CONTAINER sh -c "ip addr add ${WIFI_IP} dev ${WIFI_INTERFACE}"
	docker exec -i $CONTAINER sh -c "ip link set dev ${WIFI_INTERFACE} up"
}

_reload_fw() {
	docker exec -i $CONTAINER sh -c "iptables -t nat -F"	
	docker exec -i $CONTAINER sh -c "iptables -t nat -A POSTROUTING -s ${WIFI_NET} ! -d ${WIFI_NET} -j MASQUERADE"
	docker exec -i $CONTAINER sh -c "echo 1 /proc/sys/net/ipv4/ip_forward"
}

_start_servers() {
	docker exec -i $CONTAINER sh -c '/usr/sbin/hostapd /etc/hostapd/hostapd.conf &'
	docker exec -i $CONTAINER sh -c '/usr/sbin/dnsmasq'
}

main() {
	cd "${SCRIPT_DIR}"
	_create_or_start_container

	PID=$(sudo docker inspect -f '{{.State.Pid}}' $CONTAINER)

	echo "* creating netns symlink '$CONTAINER'"
	sudo mkdir -p /var/run/netns
	sudo ln -sf /proc/$PID/ns/net /var/run/netns/$CONTAINER
	
	_prepare_wifi
	_prepare_network	
	
	_reload_fw
	_start_servers	
	echo "* ready"
}

main
#trap "_cleanup" EXIT
#tail --pid=$pid -f /dev/null
