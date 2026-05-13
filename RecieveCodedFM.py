import numpy as np
import adi
import sounddevice as sd
from scipy.io.wavfile import write
from scipy.signal import resample_poly, firwin, lfilter
from rich.progress import Progress, BarColumn, TextColumn, TimeRemainingColumn
import math

# =========================================================
#  RX - Ricezione FM con decodifica µ-Law
#  PlutoSDR - Python
#  Deve corrispondere ai parametri del TX MATLAB
# =========================================================

# ── Parametri (devono coincidere con TX MATLAB) ──────────
duration    = 10           # secondi da acquisire
audio_fs    = 48000        # sample rate audio di uscita
fm_dev      = 50000        # deviazione FM in Hz (stesso del TX!)
lp_cutoff   = 6000         # taglio filtro passa-basso audio (Hz)
lp_order    = 1000         # ordine filtro FIR
mu          = 255          # parametro µ-Law (stesso del TX!)

# ── Configurazione PlutoSDR ───────────────────────────────
sdr = adi.Pluto("ip:192.168.3.1")
sdr.rx_lo                   = int(915e6)
sdr.sample_rate             = int(1e6)
sdr.rx_rf_bandwidth         = int(1e6)
sdr.rx_buffer_size          = 8192
sdr.gain_control_mode_chan0 = "manual"
sdr.rx_hardwaregain_chan0   = 50.0

fs_sdr = int(sdr.sample_rate)
print("Sample rate PlutoSDR:", fs_sdr, "Hz")
print("Buffer RX:", sdr.rx_buffer_size)
print("Deviazione FM:", fm_dev, "Hz")
print("Parametro µ-Law:", mu)

# ── Acquisizione campioni IQ ──────────────────────────────
n_buffers = math.ceil(duration * fs_sdr / sdr.rx_buffer_size)
print(f"\nAcquisizione: {n_buffers} buffer — durata teorica: {duration} s\n")

samples = []

with Progress(
    TextColumn("[progress.description]{task.description}"),
    BarColumn(bar_width=70, complete_style="cyan"),
    TimeRemainingColumn(compact=True)
) as progress:
    task = progress.add_task("[cyan]Ricezione FM in corso...", total=n_buffers)
    for _ in range(n_buffers):
        rx = sdr.rx()
        samples.append(rx)
        progress.update(task, advance=1)

samples = np.concatenate(samples)
print(f"\nCampioni acquisiti: {len(samples)}")
print(f"Durata effettiva: {round(len(samples)/fs_sdr, 3)} s")

# ── Demodulazione FM ─────────────────────────────────────
# La frequenza istantanea è la derivata della fase
# f_inst = diff(unwrap(angle(s))) / (2*pi) * fs
# Poi si normalizza dividendo per la deviazione fm_dev

print("\nDemodulazione FM...")

phase       = np.angle(samples)
phase_unwrap = np.unwrap(phase)
freq_inst   = np.diff(phase_unwrap) / (2 * np.pi) * fs_sdr

# Normalizza rispetto alla deviazione
fm_demod = freq_inst / fm_dev

# Aggiusta lunghezza (diff riduce di 1 campione)
fm_demod = np.append(fm_demod, fm_demod[-1])

# ── Filtro passa-basso ────────────────────────────────────
print(f"Filtro passa-basso: {lp_cutoff} Hz, ordine {lp_order}")

nyq     = fs_sdr / 2
lp_norm = lp_cutoff / nyq
fir     = firwin(lp_order, lp_norm)
audio_filtered = lfilter(fir, 1.0, fm_demod)

# ── Resampling SDR -> audio ───────────────────────────────
print(f"Resampling: {fs_sdr} Hz -> {audio_fs} Hz")

g    = math.gcd(audio_fs, fs_sdr)
up   = audio_fs // g
down = fs_sdr // g
audio = resample_poly(audio_filtered, up, down)

print(f"Durata post-resample: {round(len(audio)/audio_fs, 3)} s")

# ── Normalizzazione ───────────────────────────────────────
audio = audio / (np.max(np.abs(audio)) + 1e-9)
audio = np.clip(audio, -1.0, 1.0)

# ── Decodifica µ-Law ─────────────────────────────────────
def decode_ulaw(signal, mu=255):
    """
    Inversa della codifica µ-Law:
        y = sign(x) * (1/mu) * ((1+mu)^|x| - 1)
    Il segnale in ingresso deve essere in [-1, 1].
    """
    signal = np.clip(signal, -1.0, 1.0)
    return np.sign(signal) * (1.0 / mu) * ((1 + mu) ** np.abs(signal) - 1)

print(f"Decodifica µ-Law (mu={mu})...")
audio = decode_ulaw(audio, mu=mu)

# Normalizzazione finale dopo la decodifica
audio = audio / (np.max(np.abs(audio)) + 1e-9)

# ── Salvataggio ───────────────────────────────────────────
if input("\nSalvare il file audio? (y/n): ").lower() == 'y':
    filename = input("Nome del file (senza estensione): ").strip()
    filename += ".wav"
    write(filename, audio_fs, (audio * 32767).astype(np.int16))
    print(f"File salvato: {filename}")

# ── Riproduzione ──────────────────────────────────────────
if input("Riprodurre l'audio? (y/n): ").lower() == 'y':
    print("Riproduzione...")
    sd.play(audio, audio_fs)
    sd.wait()

print("\nFine.")