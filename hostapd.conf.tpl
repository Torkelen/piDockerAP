ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
interface=${WIFI_INTERFACE}
ssid=${AP_SSID}
wpa_passphrase=${AP_PASSPHRASE}
hw_mode=${AP_HW_MODE}
channel=${AP_CHANNEL}
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=${AP_WPA}
wpa_key_mgmt=${AP_KEY}
wpa_pairwise=${AP_WPA_PAIR}
rsn_pairwise=${AP_RSN_PAIR}
