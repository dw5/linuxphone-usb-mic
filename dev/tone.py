# 440 Hz stereo tone, 16-bit 48 kHz, written to stdout as raw PCM for aplay.
import math,struct,sys
sec=float(sys.argv[1]) if len(sys.argv)>1 else 10
for i in range(int(48000*sec)):
    v=int(8000*math.sin(2*math.pi*440*i/48000)); sys.stdout.buffer.write(struct.pack('<hh',v,v))
