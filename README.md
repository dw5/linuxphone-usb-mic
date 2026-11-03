# USB Mic

The phone shows up as a USB headset ("Terminal Headset") on the PC it's plugged into. Built and tested on a Furi FLX1s (FuriOS, kernel 4.19). Two uses:

- **Into the PC** (a fake microphone, for April Fools or anything else): play music or soundboard effects into it, or talk through the phone.
- **From the PC** (a recorder): listen on the phone to what the PC plays, or record it to FLAC.

- `usb-mic`: the GTK app, two tabs. Plays and records through GStreamer and the gadget's PulseAudio devices.
  - **Into the PC**
    - Music has a seek bar with the time and length, and a volume.
    - **Talk through the phone** sends the phone's own microphone to the PC. A bar under it shows how loud your voice is, straight from the phone's microphone: empty in silence, yellow when quiet (below -40 dB), green for speech, and red for a second when peaks get near clipping.
    - **Voice effect** for talking: None, Deep, Chipmunk, Higher and Lower (natural), Robot, Dalek, Cave, Hall, Phone call, Walkie-talkie, Megaphone. Higher, Lower and Dalek, and the better Robot, need `swh-plugins` and `rubberband-ladspa`; without them they're left out (Robot falls back to a rougher version). Changes take effect while you talk, without a break. The meter still shows your own voice, before the effect.
    - **Clean up my voice**: WebRTC noise suppression. **Cancel echo**: WebRTC echo cancelling against what **Listen to the PC** plays, for talking and listening on the phone's speaker. No automatic gain: you set your own level.
    - **Hear it on the phone** also plays music and effects on the phone, including while you talk.
    - Press and hold a soundboard button to hear that sound on the phone only.
  - **From the PC** (pick "Terminal Headset" as the PC's speaker; stereo, 48 kHz)
    - The PC's own volume for "Terminal Headset" sets the level. PipeWire starts a new device at 40% (about -24 dB): set it to 100% so recordings get the PC's sound unchanged.
    - **Listen to the PC**: what the PC plays comes out of the phone. With **Talk** as well, a Bluetooth headset on the phone works like one plugged into the PC.
    - **Record the PC**: saves what the PC plays to `~/Music/PC recordings/PC <date> <time>.flac`, 48 kHz stereo. The row shows the length actually received and says when no sound is coming from the PC. A PC only sends while something plays to the device, so silent stretches may be left out. Nothing received means no file.
  - **Phone audio** (gear button) picks the phone's own microphone and speaker: phone's choice, built-in speaker or earpiece, or a Bluetooth headset once connected. Picking the earpiece switches the phone's output port while the app is open and puts it back on close. The choice is saved in `~/.config/usb-mic.json`.
  - A USB dock or USB headset adapter can't be used at the same time: the phone's single USB-C port is either a device for the PC or a host for the dock, not both.
  - Talking and listening on the phone's speaker at once loops the PC's sound back through the phone's microphone. Use the earpiece or a headset.
- `usb-mic-helper`: root helper, run through polkit (`local.usbmic.policy`). `on` adds a UAC1 function to the running gadget `g1`; `off` removes it. Nothing persists across a reboot. Each run takes a lock, snapshots the gadget first, stops if USB can't be unbound, and on any failure puts the snapshot back and rebinds. The phone's own setup is kept in root-only `/run/usb-mic/` until `off` has put it back.
- `install.sh`: installs both for the current user.
- `dev/`: scripts used while working this out. Not part of the app; see `dev/README.md`.

While the mic is on it is the gadget's only function, and the device reports product "Terminal Headset", serial `TH0001`, `bcdDevice` 0x0305. On this kernel the CDC ACM function has an IAD and f_uac1 doesn't, and Windows then splits the mic's interfaces and fails to start it. `off` restores the earlier functions, names and `bcdDevice`.

Tested 2026-11-03: Linux (PipeWire) and Windows 10 22H2 (usbaudio) both record a clean 440 Hz tone.

Known: sound only reaches the PC while it's recording. The app drops sound rather than queueing it, so music keeps time and effects don't pile up; enabling the gadget makes PulseAudio switch the phone's own defaults to it, which the app undoes for any default still pointing at the gadget; Windows names the input "Capture Input terminal", fixed in this kernel's f_uac1.

## Why not UAC2

glkvm uses UAC2 with `c_chmask=0`, on a newer kernel. On this 4.19 kernel, tested on Windows 10 22H2 (2026-11-03), the ACM function kept alongside:

- `c_chmask=1`: usbaudio2 loads but fails to start, problem 10, status 0xC0440025. The OUT endpoint is async with no feedback endpoint.
- `c_chmask=0`: same, status 0xC0440022. This kernel still advertises the OUT endpoint, with `wMaxPacketSize` 0.

The status codes aren't documented by Microsoft, so these causes come from the descriptors, not the codes. Microsoft does document that its UAC2 driver needs explicit feedback for an async OUT endpoint, and that Windows stops grouping legacy audio interfaces once any IAD is on the device. Both would need f_uac2 changes from newer kernels: dropping the OUT interface when `c_chmask=0`, or a feedback endpoint. UAC1 needs neither. `dev/mic-test.sh` sets up these variants.

## Next steps

See `ROADMAP.md`.
