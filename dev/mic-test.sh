#!/bin/sh
# Test variants of the mic gadget. Usage: mic-test.sh KIND C_CHMASK KEEP_ACM BCD
# e.g. mic-test.sh uac2 1 yes 0x0310. Undo with: usb-mic-helper off (after this, run
# mic-test.sh restore first, which puts acm.0 back and the phone's own names).
set -e
G=/sys/kernel/config/usb_gadget/g1; cd $G
[ "$(findmnt -no SOURCE /)" = /dev/furios/testdom ] || { echo "not testdom"; exit 1; }
udc=$(cat UDC); [ -n "$udc" ] || udc=usb0
trap '[ -n "$(cat UDC)" ] || echo "$udc" > UDC' EXIT
echo "" > UDC || true
for f in configs/c.1/*.*; do [ -L "$f" ] && rm "$f"; done
for f in functions/uac*.mic; do [ -d "$f" ] && rmdir "$f"; done
if [ "$1" = restore ]; then
    ln -s functions/acm.0 configs/c.1/; echo 0x0223 > bcdDevice
    echo FLX1s > strings/0x409/product; echo FLX1S5201272 > strings/0x409/serialnumber
else
    F=functions/$1.mic; mkdir $F
    echo 3 > $F/p_chmask; echo 48000 > $F/p_srate; echo 2 > $F/p_ssize
    echo "$2" > $F/c_chmask; echo 48000 > $F/c_srate; echo 2 > $F/c_ssize
    [ "$3" = yes ] && ln -s functions/acm.0 configs/c.1/
    ln -s $F configs/c.1/
    echo "$4" > bcdDevice
    echo "Terminal Headset" > strings/0x409/product; echo TH0001 > strings/0x409/serialnumber
fi
echo "$udc" > UDC
echo "bcd $(cat bcdDevice) product \"$(cat strings/0x409/product)\" linked: $(ls configs/c.1 | grep '\.' | tr '\n' ' ')"; grep -i gadget /proc/asound/cards || true
