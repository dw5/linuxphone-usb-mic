# USB Mic

The phone shows up as a USB microphone on the PC it's plugged into. An app plays music or soundboard effects into it. Built and tested on a Furi FLX1s (FuriOS, kernel 4.19).

- `usb-mic`: the GTK app. Plays through GStreamer into the gadget's PulseAudio sink.
  - Music has a seek bar with the time and length.
  - **Hear it on the phone** also plays music and effects on the phone, including while you talk.
  - **Talk through the phone** sends the phone's own microphone to the PC.
  - Press and hold a soundboard button to hear that sound on the phone only.
  - **Listen to the PC**: the PC also sees a speaker, "Terminal Headset" (mono). Whatever it plays there comes out of the phone. With **Talk** as well, a Bluetooth headset on the phone works like one plugged into the PC.
  - **On the phone** picks the phone's own microphone and speaker: phone's choice, built-in speaker or earpiece, or a Bluetooth headset once connected. Picking the earpiece switches the phone's output port while the app is open and puts it back on close. The choice is saved in `~/.config/usb-mic.json`.
  - A USB dock or USB headset adapter can't be used at the same time: the phone's single USB-C port is either a device for the PC or a host for the dock, not both.
  - Talking and listening on the phone's speaker at once loops the PC's sound back through the phone's microphone. Use the earpiece or a headset.
- `usb-mic-helper`: root helper, run through polkit (`local.usbmic.policy`). `on` adds a UAC1 function to the running gadget `g1`; `off` removes it. Nothing persists across a reboot.
- `install.sh`: installs both for the current user.
- `mic-on.sh`, `mic-off.sh`, `tone.py`: test scripts used while working this out.

While the mic is on it is the gadget's only function, and the device reports product "Terminal Headset", serial `TH0001`, `bcdDevice` 0x0304. On this kernel the CDC ACM function has an IAD and f_uac1 doesn't, and Windows then splits the mic's interfaces and fails to start it. `off` restores the earlier functions, names and `bcdDevice`.

Tested 2026-11-03: Linux (PipeWire) and Windows 10 22H2 (usbaudio) both record a clean 440 Hz tone.

Known: sound only reaches the PC while it's recording. The app drops sound rather than queueing it, so music keeps time and effects don't pile up; enabling the gadget makes PulseAudio switch the phone's own defaults to it, which the app undoes; Windows names the input "Capture Input terminal", fixed in this kernel's f_uac1.

## Why not UAC2

glkvm uses UAC2 with `c_chmask=0`, on a newer kernel. On this 4.19 kernel, tested on Windows 10 22H2 (2026-11-03), the ACM function kept alongside:

- `c_chmask=1`: usbaudio2 loads but fails to start, problem 10, status 0xC0440025. The OUT endpoint is async with no feedback endpoint.
- `c_chmask=0`: same, status 0xC0440022. This kernel still advertises the OUT endpoint, with `wMaxPacketSize` 0.

The status codes aren't documented by Microsoft, so these causes come from the descriptors, not the codes. Microsoft does document that its UAC2 driver needs explicit feedback for an async OUT endpoint, and that Windows stops grouping legacy audio interfaces once any IAD is on the device. Both would need f_uac2 changes from newer kernels: dropping the OUT interface when `c_chmask=0`, or a feedback endpoint. UAC1 needs neither. `mic-test.sh` sets up these variants.

## Next steps

- Helper: stop if unbinding fails, snapshot and roll back the whole gadget on error, take a lock, keep state files until restore succeeds, derive the mic serial from the phone's.
- App: handle helper failures; maybe echo cancellation for talk plus listen on the speaker. (Done: effects that never finish while the PC isn't recording are ended, play/pause goes by what was asked, pause drops sound queued for the PC, restore only defaults that point at the gadget, no queued effects, stop playing when the mic disappears, clean up on close, the hint.)
- Check what `usb-config` does to the gadget when switching USB mode in settings.
- Proper fix for naming and keeping ACM: an out-of-tree module with a patched UAC1/UAC2 function under a new name (IAD, own strings, no OUT endpoint). The kernel takes unsigned modules and `linux-headers-4.19.325-furiphone-radon` is packaged. Idea from a Codex review, 2026-11-03.
