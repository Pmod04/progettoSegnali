import numpy as np
import adi
import sounddevice as sd
from scipy.io.wavfile import write
from rich.progress import Progress, BarColumn, TextColumn, TimeRemainingColumn
from scipy.signal import resample_poly, firwin, lfilter
import math

# Paramtetri
duration = 10          # secondi da acquisire
audio_fs = 48000       # frequenza di uscita audio
fs_sdr = 1e6          # frequenza di campionamento SDR
Rs = 1e5              # Rate di simbolo
sps = int(fs_sdr / Rs)   
rolloff = 0.35
Nbits = 8
audio_fs = 32000

# Set parametri SDR
sdr = adi.Pluto("ip:192.168.3.1")
sdr.rx_lo = int(915e6)
sdr.sample_rate = int(1e6)
sdr.rx_rf_bandwidth = int(1e6)
sdr.rx_buffer_size = 8192
sdr.gain_control_mode_chan0 = "manual"
sdr.rx_hardwaregain_chan0 = 50


# Print debug
fs_sdr = int(sdr.sample_rate)
print("Sample rate reale Pluto:", fs_sdr)
print("Buffer RX:", sdr.rx_buffer_size)

# Acquisizione

samples = []
n_buffers = math.ceil(duration * fs_sdr / sdr.rx_buffer_size)

print(f"\nAcquisizione prevista: {n_buffers} buffer")
print("Durata teorica:", duration, "s\n")

with Progress(
    TextColumn("[progress.description]{task.description}"),
    BarColumn(bar_width=70, complete_style="green"),
    TimeRemainingColumn(compact=True)
) as progress:

    task = progress.add_task("[green]Ricezione in corso...", total=n_buffers)

    for _ in range(n_buffers):
        rx = sdr.rx()
        samples.append(rx)
        progress.update(task, advance=1)

samples = np.concatenate(samples)


print("\nCampioni acquisiti:", len(samples))
dur_reale = len(samples) / fs_sdr
print("Durata effettiva acquisita:", round(dur_reale, 3), "s")

# Envelope detection
am_demod = np.abs(samples)
am_demod -= np.mean(am_demod)

# Matched RRC filter

span = 6
num_taps = span * sps + 1
rrc = firwin(num_taps, 1/sps, window=('kaiser', 8))

rx_filt = np.convolve(samples, rrc, mode='same')

#Decisore Qpsk

offset = np.argmax(np.abs(rx_filt[:sps]))
symbols = rx_filt[offset::sps]
bits = []

for s in symbols:
    bits.append(1 if np.real(s) > 0 else 0)
    bits.append(1 if np.imag(s) > 0 else 0)

bits = np.array(bits)

#PCM 8bit

bits = bits[:len(bits) - len(bits) % Nbits]
pcm = np.packbits(bits.reshape(-1, Nbits), axis=1)
pcm = pcm.flatten().astype(np.uint8)


#Decode audio

audio = pcm.astype(np.float32)
audio = audio / (2**(Nbits-1) - 1) - 1

audio = audio / (np.max(np.abs(audio)) + 1e-9)


if(input("Salvare il file audio? (y/n): ") .lower() == 'y'):

    filename = input("Inserire il nome del file: ")
    write(filename, audio_fs, (audio * 32767).astype(np.int16))
    print("File finale salvato:", filename)


if(input("Riprodurre l'audio? (y/n): ") .lower() == 'y'):

    print("Riproduzione...")
    sd.play(audio, audio_fs)
    sd.wait()
