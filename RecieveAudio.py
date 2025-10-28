import adi
import numpy as np
import sounddevice as sd

# =======================
# Configura PlutoSDR
# =======================
sdr_ip = "ip:192.168.3.1"
fs_sdr = 1e6       # sample rate della trasmissione
fc = 915e6         # frequenza centrale della trasmissione
num_samps = 8192   # buffer SDR

sdr = adi.Pluto(sdr_ip)
sdr.sample_rate = int(fs_sdr)
sdr.rx_lo = int(fc)
sdr.rx_buffer_size = num_samps
sdr.rx_rf_bandwidth = int(fs_sdr)
sdr.gain_control_mode_chan0 = 'manual'
sdr.rx_hardwaregain_chan0 = 40

# Decimazione per audio udibile (~48 kHz)
audio_fs = 48000
decimation_factor = int(fs_sdr / audio_fs)
output_fs = int(fs_sdr / decimation_factor)

print("Inizio ricezione AM... Ctrl+C per fermare")

try:
    while True:
        # Ricevi campioni complessi
        samples = sdr.rx()[:num_samps].flatten()
        
        # Demodulazione AM: magnitude
        audio = np.abs(samples)
        audio -= np.mean(audio)  # rimuove DC
        audio /= np.max(np.abs(audio))  # normalizza
        
        # Decimazione per sample rate udibile
        audio_out = audio[::decimation_factor]
        
        # Riproduci
        sd.play(audio_out, samplerate=output_fs, blocking=False)
        sd.wait()

except KeyboardInterrupt:
    print("Ricezione terminata.")
