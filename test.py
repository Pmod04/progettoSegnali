import adi
import numpy as np


sdr = adi.Pluto('ip:192.168.3.1')
sdr.rx_lo = int(fc)
sdr.sample_rate = int(fs_sdr)
sdr.rx_rf_bandwidth = int(fs_sdr)
sdr.gain_control_mode_chan0 = 'manual'
sdr.rx_hardwaregain_chan0 = 50.0
sdr.rx_buffer_size = 8192


N = 8192
spectrum = np.fft.fftshift(np.fft.fft(samples[:N]))
freqs = np.fft.fftshift(np.fft.fftfreq(N, 1/fs_sdr))
peak = freqs[np.argmax(np.abs(spectrum))]
print("Peak offset (Hz):", peak)