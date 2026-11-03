#!/bin/bash
# Add a USB microphone to the running gadget. In memory only: a reboot undoes it.
# Usage: mic-on.sh [uac1|uac2]   (uac1 by default: Windows' oldest built-in driver handles it)
set -e
KIND=${1:-uac1}; G=/sys/kernel/config/usb_gadget/g1
[ "$(findmnt -no SOURCE /)" = /dev/furios/testdom ] || { echo "not testdom, stopping"; exit 1; }
cd $G
UDC=$(cat UDC); echo "" > UDC || true
for f in configs/c.1/uac*.mic; do [ -e "$f" ] && rm "$f"; done
for f in functions/uac*.mic; do [ -d "$f" ] && rmdir "$f"; done
F=functions/$KIND.mic; mkdir $F
# p_* is the gadget's playback, which the PC sees as a microphone. The c_* side (PC speaker)
# stays on with one channel, as this kernel advertises a broken endpoint when it's off.
echo 3 > $F/p_chmask; echo 48000 > $F/p_srate; echo 2 > $F/p_ssize
echo 1 > $F/c_chmask; echo 48000 > $F/c_srate; echo 2 > $F/c_ssize
ln -s $F configs/c.1/
echo "${UDC:-usb0}" > UDC
sleep 1; echo "$KIND on, UDC $(cat UDC), linked: $(ls configs/c.1 | grep '\.' | tr '\n' ' ')"; grep -i gadget /proc/asound/cards
