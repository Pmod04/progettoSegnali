import numpy as np
import adi
import sounddevice as sd
from scipy.io.wavfile import write
from rich.progress import Progress, BarColumn, TextColumn, TimeRemainingColumn
import time

# Parametri
fs_sdr = 1e6          # Sample rate SDR (Hz)
fc = 915e6            # Frequenza centrale (Hz)
duration = 10         # secondi di acquisizione
audio_fs = 48000      # frequenza di campionamento audio finale (Hz)

#Config pluto
sdr = adi.Pluto('ip:192.168.3.1')
sdr.rx_lo = int(fc)
sdr.sample_rate = int(fs_sdr)
sdr.rx_rf_bandwidth = int(fs_sdr)
sdr.gain_control_mode_chan0 = 'manual'
sdr.rx_hardwaregain_chan0 = 50.0
sdr.rx_buffer_size = 8192

print("Acquisizione in corso...")
samples = np.array([], dtype=np.complex64)
n_buffers = int(duration * fs_sdr / sdr.rx_buffer_size)

#Progress bar
#Acquisizione
with Progress(
    TextColumn("[progress.description]{task.description}"),
    BarColumn(bar_width=70, complete_style="green", finished_style="blue"),
    TimeRemainingColumn(compact=True)
) as progress:
    task = progress.add_task("[green]Ricezione in corso...", total=n_buffers)
    
    for _ in range(n_buffers):
        rx = sdr.rx()
        samples = np.concatenate((samples, rx))
        progress.update(task, advance=1)

print(f"Acquisiti {len(samples)} campioni")

# ===== DEMODULAZIONE AM =====
am_demod = np.abs(samples)
am_demod = am_demod - np.mean(am_demod)   # rimuove DC

# Riduci campionamento per ottenere audio (~48 kHz)
decimation = int(fs_sdr / audio_fs)
audio = am_demod[::decimation]

# Normalizza
audio = audio / np.max(np.abs(audio))

# Salva su file
write("ricezione_audio.wav", int(audio_fs), (audio * 32767).astype(np.int16))
print("Salvato come ricezione_audio.wav")

# Riproduzione
# print("Riproduzione audio...")
# sd.play(audio, samplerate=audio_fs)
# sd.wait()
# print("Fine riproduzione")
