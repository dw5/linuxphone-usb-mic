# Roadmap

The plan for USB Mic, kept here so it survives between sessions. Update it as things
land: tick the box, add the commit, and note anything learned. Newest decisions win.

The app has two uses (see `README.md`):

- **Into the PC:** the phone is a microphone for the PC. Music, soundboard, talking.
- **From the PC:** the phone is the PC's speaker. Listen on the phone, or record to FLAC.

## Working rules

- Test on the `testdom` install, never the daily rootfs (`findmnt -no SOURCE /`).
- Test from the phone side and, when the phone is on this laptop, from the PC side:
  play or record "Terminal Headset" with `pacat` / `parecord` and measure.
- Running the helper outside the app leaves PulseAudio's defaults on the headset. Put
  them back afterwards: `pactl set-default-sink audio-manager-output` and
  `pactl set-default-source audio-manager-input`.
- Have Codex review larger changes (`codex exec -s read-only ... < /dev/null`).
- The user wants no automatic changes they can make themselves (e.g. no auto-ducking).

## Waiting on the user

- [ ] Record real PC audio through **Record the PC**, and listen with **Listen to the PC**.
- [ ] Windows with the stereo speaker side (`bcdDevice` 0x0305): do the mic and the
      speaker both appear and work? Set "Terminal Headset" output volume to 100%.
- [ ] A Bluetooth headset on the phone: shows up under Phone audio? Talk and listen?
- [ ] The talk meter with real speech: is the yellow/green point (-40 dB) right?
- [ ] An hour of music into the PC: any dropouts from clock drift? (Codex estimate:
      possibly after about 30 minutes.)

## Phase 1: voice effects on the phone (done 2026-11-03)

Everything here is already installed on the phone (GStreamer good/bad).

- [x] Effect picker under **Talk through the phone**: None, Deep, Chipmunk, Robot
      (rough: pitch + short metallic echo), Cave, Hall, Phone call, Walkie-talkie,
      Megaphone. Tested: a 400 Hz tone reached the PC at 300 Hz (Deep), 640 Hz
      (Chipmunk), 368 Hz (Robot).
- [x] Switching effect while talking swaps it in place, no restart or gap.
- [x] **Clean up my voice**: WebRTC noise suppression (`webrtcdsp`), no auto gain.
- [x] **Echo cancelling**: `webrtcdsp` with a `webrtcechoprobe` in the listen output;
      on only while listening. Starting or stopping listening rebuilds the talk side.
- [x] The meter measures the raw microphone ("am I loud enough"), before effects.
- [ ] Delay per effect: unmeasured. The pipeline latency query reads 0 because the PC
      output doesn't sync to the clock; needs a click-through measurement.
- [ ] Does echo cancelling actually help on the speaker? Needs a real try.
- [ ] Test note: `webrtcdsp` stalled with an 8 kHz null-sink monitor as the test
      "microphone", but works with the real one.

## Phase 2: better effects with small packages

- [ ] `swh-plugins` (ring modulator): a real robot / Dalek voice.
- [ ] `rubberband-ladspa`: pitch shift that keeps the voice natural (male to female and
      back) instead of the chipmunk effect. `librubberband3` is already installed.
- [ ] Check GStreamer's `ladspa` element picks them up (no ladspa/lv2 elements yet).

## Phase 3: AI voice changer on another machine

Too heavy for the phone (RVC-style models want a GPU for real time). The phone streams
the voice to a server, gets the converted voice back, and sends it into the PC. The PC
it's plugged into needs no software: a hardware voice changer for locked-down PCs.

- [ ] Ask the user which machine has a usable GPU.
- [ ] Server: an existing real-time voice changer (e.g. w-okada voice-changer, RVC).
- [ ] Transport: Opus or PCM over WebSocket or RTP; aim for 0.2 to 0.5 s end to end.
- [ ] Fallback when the server is unreachable: plain voice, with a notice.
- [ ] Voices: generic or the user's own models, not imitations of real people.

## Later ideas

- [ ] Type to speak: text to speech (Piper runs on phones) straight into the PC.
- [ ] Push-to-talk: a big hold-to-talk button.
- [ ] Effects volume (soundboard has no volume of its own).
- [ ] Recording: also record your own side (mic going to the PC) as a second track.
- [ ] Sound effects triggered by your voice (e.g. a laugh track after you stop).

## Technical debt

- [ ] Helper: derive the headset serial from the phone's, so two phones don't share
      `TH0001`.
- [ ] App: `pactl` still runs on the GTK thread (3 s limit, cached); an asynchronous
      PulseAudio client would remove the last freezes.
- [ ] Recording can't tell an unplugged PC from a silent one; it stays armed.
- [ ] Check what `usb-config` does to the gadget when switching USB mode in settings.
- [ ] Proper fix for naming and keeping the ACM serial port: an out-of-tree kernel module
      with a patched UAC1/UAC2 function under a new name (IAD, own strings, no OUT
      endpoint). Unsigned modules load; `linux-headers-4.19.325-furiphone-radon` is
      packaged.

## Done

- `ec66320` UAC1 microphone on Linux and Windows, app with music and soundboard.
- `00f4fd1` Why UAC2 doesn't work on Windows with this kernel.
- `20a24a9` Seek bar, talk, listen to the PC, device pickers, "Terminal Headset".
- `d37a246` Record the PC, working music volume, safer helper (Codex review).
- `dcf4940` The phone's own speaker is never the headset.
