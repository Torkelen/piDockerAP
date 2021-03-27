#Added for PiNet
interface=${WIFI_INTERFACE}
no-dhcp-interface=lo
bind-interfaces
server=${DHCP_DNS_SERVER}
domain-needed
bogus-priv
dhcp-range=${DHCP_RANGE}
