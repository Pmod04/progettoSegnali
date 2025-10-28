#%%
import matplotlib.pyplot as plt
import numpy as np
import adi
from IPython.display import display, clear_output
import time

# Configura PlutoSDR
fs = 10e6
f0 = 2.1e9
N = 2**14
num_samps = 10000

sdr = adi.Pluto("ip:192.168.3.1")
sdr.gain_control_mode_chan0 = 'manual'
sdr.rx_hardwaregain_chan0 = 40.0
sdr.rx_lo = int(f0)
sdr.sample_rate = int(fs)
sdr.rx_rf_bandwidth = int(fs)
sdr.rx_buffer_size = num_samps

try:
    while True:
        samples = sdr.rx().flatten()[:N]
        X = np.fft.fftshift(np.fft.fft(samples))
        freqs_hz = f0 + np.fft.fftshift(np.fft.fftfreq(len(samples), d=1/fs))
        power = 20*np.log10(np.abs(X))

        # Traccia inline
        plt.figure(figsize=(8,6))
        plt.plot(freqs_hz/1e6, power)
        plt.xlabel("Frequenza (MHz)")
        plt.ylabel("Potenza (dB)")
        plt.title(f"Spettro centrato su {f0/1e9:.3f} GHz")
        plt.grid(True)
        plt.xlim((f0 - 5e6)/1e6, (f0 + 5e6)/1e6)
        plt.ylim(30,130)

        display(plt.gcf())
        clear_output(wait=True)
        plt.close()

        time.sleep(0.5)  # aggiorna ogni 0.5 secondi

except KeyboardInterrupt:
    print("Loop interrotto manualmente.")


#%%