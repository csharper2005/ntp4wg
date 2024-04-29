#!/bin/sh
#
#   ntp4wg.sh
#
#   Set correct system time before WG starting
#
#   Copyright (C) 2023 csharper2005
#
#   1. Place this file in /root/scripts
#   2. Run "chmod a+x /root/scripts/ntp4wg.sh"
#   3. Add "/root/scripts/ntp4wg.sh" line to the /etc/rc.local
#
logger "[${0##*/}] Stopping wireguard/amneziawg interfaces..."
for iface in $(uci show network | grep ".proto=" | grep "wireguard\|amneziawg" | awk -F'.' '{print $2}'); do
	[ -z "$(uci -q get network."$iface".disabled)" ] && \
		ubus call network.interface."$iface" down && \
		logger "[${0##*/}] Interface $iface was stopped"
done

logger "[${0##*/}] Starting time sync using ntpd..."

# NTP servers
set -- "162.159.200.123" "216.239.35.0"

while true; do
	for ntp in "$@"; do
		ntpd -nqN -p $ntp >/dev/null 2>&1
		[ "$?" -eq 0 ] && \
			logger "[${0##*/}] Time was successfully synced with $ntp. Exiting loop..." && \
			synced=1 && break
		logger "[${0##*/}] Time synchronization with $ntp failed"
	done
	[ "$synced" -eq 1 ] && break
	sleep 5
done

logger "[${0##*/}] Starting wireguard/amneziawg interfaces..."
for iface in $(uci show network | grep ".proto=" | grep "wireguard\|amneziawg" | awk -F'.' '{print $2}'); do
	[  -z "$(uci -q get network."$iface".disabled)" ] && \
		ubus call network.interface."$iface" up && \
		logger "[${0##*/}] Interface $iface was started"
done
