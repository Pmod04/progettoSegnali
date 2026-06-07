<div align="center">
    <h1>Trasmission of an Audio File via Pluto SDR</h1>
</div>

> [!caution]
> ⚠ If you are using windows you must install this [driver](https://github.com/analogdevicesinc/plutosdr-m2k-drivers-win/releases/download/v0.7/PlutoSDR-M2k-USB-Drivers.exe) to be able to communicate with the pluto

> [!note]
> This project uses 192.168.3.1 in the python scripts as the pluto IP address (default pluto address is 192.168.2.1)

---

## Libraries setup
#### Transmit (Matlab) :

> [!warning]
> Be sure to have installed :
> - Communication Toolbox: required for "sdrtx" command and IQ signal handling
> - Support package for analog devices: required to see and use the Pluto
> - Signal Processing Toolbox: required for "resample" and "hilbert" commands
> - Audio Toolbox: NOT necessary but recommended for better management and reading of different audio file formats

#### Recieve (Python) :

>[!note]
> It is recommended to use a python virtual enviroment to run this project, to do so and install all the libraries simply run the commands below one by one

```bash
python3 -m venv venv
```
```bash
source venv/bin/activate
```
```bash
pip install -r requirements.txt
```

---

### Non-encoded AM 

#### Matlab (Tx)

1. ...


#### Python (Rx)

1. Signal acquisition
2. Envelope detection
3. Low-pass filter (nyquist)
4. Resampling
5. Normalization

### Encoded FM

#### Matlab (Tx)

1. ...


#### Python (Rx)

1. Signal acquisition
2. Normalize respect to deviation
3. Low-pass filter
4. Resampling
5. Normalization
6. Decode
7. Final

