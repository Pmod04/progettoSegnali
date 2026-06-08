<div align="center">
    <h1>Trasmission of an Audio File via Pluto SDR</h1>
</div>

## Non-encoded AM

### Tx(matlab)

1. Song loading + resampling
2. Normalization
3. AM modulation
4. Transmission

### Rx(python)

1. Signal acquisition
2. Envelope detection
3. Low-pass filter (nyquist)
4. Resampling
5. Normalization

### Encoded FM

### Tx(matlab)

1. Song loading + resampling
2. Normalization
3. Enconde
4. Upsample
5. FM Modulation
6. Normalize
7. Transmit

### Rx(python)

1. Signal acquisition
2. Normalize respect to deviation
3. Low-pass filter
4. Resampling
5. Normalization
6. Decode
7. Final