## Trasmission of an Audio File via Pluto SDR

> <span style="color:red">⚠ If you are using windows you must install this [driver](https://github.com/analogdevicesinc/plutosdr-m2k-drivers-win/releases/download/v0.7/PlutoSDR-M2k-USB-Drivers.exe) to be able to communicate with the pluto </span>

### Non-encoded AM 
#### Transmit (Matlab) :
> Be sure to have installed :
> - communication toolbox
> - wireless test bench

#### Recieve (Python) :
> Be sure to have installed the required libraries and use python 3.10 if you can, ideally in a venv :
> - numpy
> - pyadi-iio
> - sounddevice
> - scipy
> - rich
>
> Alternatively you can install all of these libraries with this script [autoInstallLibraries.py](/autoInstallLibraries.py)
    
---

### Encoded QPKS
#### Transmit (Matlab) :

