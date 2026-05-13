import numpy as np
import adi
import sounddevice as sd
from scipy.io.wavfile import write
from rich.progress import Progress, BarColumn, TextColumn, TimeRemainingColumn
from scipy.signal import resample_poly, butter, lfilter
import matplotlib.pyplot as plt
import math

# --- Parametri ---
duration = 5          # Ridotto a 5s per test rapido
audio_fs = 32000      
fs_sdr = 1000000      
fc = int(434e6)

# --- SDR Setup ---
try:
    sdr = adi.Pluto("ip:192.168.3.1")
    sdr.rx_lo = fc
    sdr.sample_rate = int(fs_sdr)
    sdr.rx_rf_bandwidth = int(250e3) 
    sdr.rx_buffer_size = 1024 * 16
    sdr.gain_control_mode_chan0 = "manual"
    sdr.rx_hardwaregain_chan0 = 40 
except Exception as e:
    print(f"Errore SDR: {e}")
    exit()

# --- Acquisizione ---
n_buffers = math.ceil(duration * fs_sdr / sdr.rx_buffer_size)
samples_list = []
print(f"Ricezione {duration}s su {fc/1e6} MHz...")

with Progress(TextColumn("[progress.description]{task.description}"), BarColumn(), TimeRemainingColumn()) as progress:
    task = progress.add_task("[green]Acquisizione...", total=n_buffers)
    for _ in range(n_buffers):
        samples_list.append(sdr.rx())
        progress.update(task, advance=1)

iq_samples = np.concatenate(samples_list)

# --- Visualizzazione Spettro ---
print("Generazione grafici...")
plt.figure(figsize=(12, 6))

# Subplot 1: Spettro di frequenza del segnale ricevuto
plt.subplot(2, 1, 1)
plt.psd(iq_samples, NFFT=1024, Fs=fs_sdr/1e6, Fc=fc/1e6, color='blue')
plt.title("Spettro del Segnale Ricevuto (IQ)")
plt.xlabel("Frequenza [MHz]")
plt.ylabel("Potenza [dB/Hz]")

# --- Demodulazione FM ---
# Calcolo frequenza istantanea
diff_phase = np.angle(iq_samples[1:] * np.conj(iq_samples[:-1]))

# Filtro Passa-Basso (15 kHz)
nyq = 0.5 * fs_sdr
b, a = butter(5, 15000 / nyq, btype='low')
audio_filtered = lfilter(b, a, diff_phase)

# Resampling a 32kHz
audio_resampled = resample_poly(audio_filtered, audio_fs, fs_sdr)
audio_resampled /= (np.max(np.abs(audio_resampled)) + 1e-6) # Normalizzazione

# Subplot 2: Segnale Audio nel tempo
plt.subplot(2, 1, 2)
time_axis = np.linspace(0, len(audio_resampled)/audio_fs, len(audio_resampled))
plt.plot(time_axis, audio_resampled, color='green')
plt.title("Segnale Audio Demodulato")
plt.xlabel("Tempo [s]")
plt.ylabel("Ampiezza")
plt.tight_layout()
plt.show()

# --- Salvataggio/Play ---
if input("\nSalvare il file .wav? (y/n): ").lower() == 'y':
    write(input("Nome file: ") + ".wav", audio_fs, (audio_resampled * 32767).astype(np.int16))

if input("Riprodurre l'audio? (y/n): ").lower() == 'y':
    sd.play(audio_resampled, audio_fs)
    sd.wait()