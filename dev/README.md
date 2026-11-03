# Development scripts

Used while working out the USB gadget, kept for reference. They are not part of the
app and don't share the helper's saved state: running them while the app's headset
is on can leave the gadget in a state the helper can't restore. Test install only.

- `mic-on.sh`, `mic-off.sh`: the first UAC2 experiment (mono PC side, ACM kept).
- `mic-test.sh KIND C_CHMASK KEEP_ACM BCD` / `mic-test.sh restore`: the Windows
  comparisons. `restore` puts back one specific phone's names and serial.
- `tone.py SECONDS`: a 440 Hz test tone, s16le stereo 48 kHz on stdout.
