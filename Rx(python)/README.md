<div align="center">
    <h1>Trasmission of an Audio File via Pluto SDR</h1>
</div>

---

> [!caution]
> If you are using windows you must install this [driver](https://github.com/analogdevicesinc/plutosdr-m2k-drivers-win/releases/download/v0.7/PlutoSDR-M2k-USB-Drivers.exe) **(direct download link)** to be able to communicate with the pluto
>
> On linux there should be no need to install anything other than the libraries in the "libraries_install_linux.sh"

> [!note]
> This project uses 192.168.3.1 in the python scripts as the pluto IP address (default pluto address is 192.168.2.1)

---

## Libraries setup

>[!note]
> It is recommended to use a python virtual enviroment to run this project, to do so and install all the libraries simply run the commands below one by one

```bash
python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt
```
