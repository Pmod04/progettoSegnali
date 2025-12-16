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
lp_cutoff = 6000       # banda audio AM (Hz)
lp_order = 1000       # ordine filtro FIR

# Set parametri SDR
sdr = adi.Pluto("ip:192.168.3.1")
sdr.rx_lo = int(915e6)
sdr.sample_rate = int(1e6)
sdr.rx_rf_bandwidth = int(1e6)
sdr.rx_buffer_size = 8192
sdr.gain_control_mode_chan0 = "manual"
sdr.rx_hardwaregain_chan0 = 50.0

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

# Filtro passa basso

print("Filtro passa-basso cutoff:", lp_cutoff, "Hz")

nyq = fs_sdr / 2
lp_norm = lp_cutoff / nyq
fir = firwin(lp_order, lp_norm)

am_filtered = lfilter(fir, 1.0, am_demod)

# Resampling

dur_before = len(am_filtered) / fs_sdr
print("Durata pre-resample:", round(dur_before, 4), "s")

g = math.gcd(audio_fs, fs_sdr)
up = audio_fs // g
down = fs_sdr // g

audio = resample_poly(am_filtered, up, down)

dur_after = len(audio) / audio_fs

print("Durata post-resample:", round(dur_after, 4), "s")

# Normalizzazione
audio = audio / (np.max(np.abs(audio)) + 1e-9)


if(input("Salvare il file audio? (y/n): ") .lower() == 'y'):

    filename = input("Inserire il nome del file: ")
    write(filename, audio_fs, (audio * 32767).astype(np.int16))
    print("File finale salvato:", filename)


if(input("Riprodurre l'audio? (y/n): ") .lower() == 'y'):

    print("Riproduzione...")
    sd.play(audio, audio_fs)
    sd.wait()
