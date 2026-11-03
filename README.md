# USB Mic

The phone shows up as a USB microphone on the PC it's plugged into. An app plays music or soundboard effects into it. Built and tested on a Furi FLX1s (FuriOS, kernel 4.19).

- `usb-mic`: the GTK app. Plays through GStreamer into the gadget's PulseAudio sink.
- `usb-mic-helper`: root helper, run through polkit (`local.usbmic.policy`). `on` adds a UAC1 function to the running gadget `g1`; `off` removes it. Nothing persists across a reboot.
- `install.sh`: installs both for the current user.
- `mic-on.sh`, `mic-off.sh`, `tone.py`: test scripts used while working this out.

While the mic is on it is the gadget's only function, and the device reports product "Terminal Microphone", serial `TM0001`, `bcdDevice` 0x0303. On this kernel the CDC ACM function has an IAD and f_uac1 doesn't, and Windows then splits the mic's interfaces and fails to start it. `off` restores the earlier functions, names and `bcdDevice`.

Tested 2026-11-03: Linux (PipeWire) and Windows 10 22H2 (usbaudio) both record a clean 440 Hz tone.

Known: playback only flows while the PC is recording; enabling the gadget makes PulseAudio switch the phone's own defaults to it, which the app undoes; Windows names the input "Capture Input terminal", fixed in this kernel's f_uac1.
