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

## Phase 2: better effects with small packages (done 2026-11-03)

- [x] `swh-plugins` and `rubberband-ladspa` installed on `testdom` (2 packages, nothing
      removed). GStreamer's `ladspa` element picks up 115 plugins. One plugin crashed
      GStreamer's plugin scanner (`free(): invalid next size`); the rest registered.
- [x] **Robot**: ring modulator at 100 Hz plus a short echo. Falls back to the rough
      pitch-and-echo robot when `swh-plugins` is missing.
- [x] **Dalek**: ring modulator at 30 Hz.
- [x] **Higher, natural** / **Lower, natural**: Rubber Band live pitch shifter, +/-4
      semitones, formant preserving. About 7% of one core. Tested 504 Hz / 317 Hz from 400.
- [x] Effects needing a missing plugin are left out of the list.
- [ ] Rubber Band output measured about 10 dB quieter on a test tone; check with a real
      voice and add make-up gain if needed.
- [ ] Not on the daily rootfs yet: `install.sh` doesn't install these packages. Decide
      whether it should (optional, with a prompt).

Codex review of phase 1 (fixed in the same commit): effect swaps now hold the sound with
a blocking probe and change the graph on the main thread, with each step checked and
quick picks merged; talk and listen share one clock and time origin so the echo
canceller lines up; Robot and Cave got headroom.

## Phase 3: AI voice changer on another machine

On hold (2026-11-03): the user has no machine with a suitable GPU and no server setup
for it. Keep as a todo; pick it up if that changes.

Too heavy for the phone (RVC-style models want a GPU for real time). The phone streams
the voice to a server, gets the converted voice back, and sends it into the PC. The PC
it's plugged into needs no software: a hardware voice changer for locked-down PCs.

- [ ] Server: an existing real-time voice changer (e.g. w-okada voice-changer, RVC).
- [ ] Transport: Opus or PCM over WebSocket or RTP; aim for 0.2 to 0.5 s end to end.
- [ ] Fallback when the server is unreachable: plain voice, with a notice.
- [ ] Voices: generic or the user's own models, not imitations of real people.

## Type to speak and push to talk (done 2026-11-03)

- [x] **Push to talk**: a mute in the talk pipeline, before the effect (an echo can ring
      out), opened by a big hold button. A drag gesture, not a click, so moving the finger
      doesn't cut you off. Tested: silence on the PC muted, the tone while held.
- [x] **Type to speak** with eSpeak NG (`espeak-ng` installed on `testdom`, 15 ms per
      line) or Piper if present. Lines queue and play through the soundboard player.
      Tested: two lines in order on the PC, stop cuts the current one and drops the rest,
      preview on the phone only, temp files removed.
- [ ] Piper on the phone: untested. Running the downloaded release binary was blocked in
      the session; the user can install it (see README) and try a voice.
- [x] Found while testing: the PC missed the first second of every sound (soundboard,
      music start, after pause or seek). Fixed by queue sizes in `build_player`.
- [ ] Left: about 0.3 s missing at the end of a track replayed after a seek (seen with a
      2 s test tone). Not the rewind; cause unknown.
- [x] Codex review, fixed: push-to-talk started unmuted for a moment (the gate is now
      muted before the pipeline starts); the 2 s refresh cancelled phone-only lines while
      the headset was off; temp files left on close or failed launch; the live effect swap
      relied on `Bin.add` returning None (True on other PyGObject versions, which would have
      restarted talk on every change).
- [ ] From the same review: a blocking `pactl` could delay noticing the button's release.
      The 2 s refresh now skips while the button is held; the real fix is the asynchronous
      PulseAudio client under Technical debt.
- [ ] Ideas: recent lines to say again with one tap; a voice effect on the typed voice;
      a hardware key or Bluetooth button for push to talk.

## Later ideas

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
