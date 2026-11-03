#!/bin/bash
G=/sys/kernel/config/usb_gadget/g1; cd $G || exit 1
UDC=$(cat UDC); echo "" > UDC
for f in configs/c.1/uac*.mic; do [ -e "$f" ] && rm "$f"; done
for f in functions/uac*.mic; do [ -d "$f" ] && rmdir "$f"; done
echo "${UDC:-usb0}" > UDC; echo "UDC: $(cat UDC); linked: $(ls configs/c.1 | grep '\.' | tr '\n' ' ')"
