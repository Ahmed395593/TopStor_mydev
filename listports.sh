#!/bin/bash
# This checks if the interface has a device directory in /sys/class/net/
for iface in $(ls /sys/class/net/); do
    if [ -d "/sys/class/net/$iface/device" ] && [ "$iface" != "lo" ]; then
        # Skip the BMC's virtual USB NIC (cdc_ether): it always reports link but only reaches the
        # management controller, so as a bond0 member it can take the node off the network.
        driver=$(basename "$(readlink "/sys/class/net/$iface/device/driver" 2>/dev/null)")
        [ "$driver" = "cdc_ether" ] && continue
        echo "$iface"
    fi
done
