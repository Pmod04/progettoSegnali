<div align="center">
    <h1>PROVA FINALE SISTEMI DI COMUNICAZIONE</h1>
</div>

L’obiettivo del nostro progetto è la costruzione di un sistema di comunicazione per trasmettere e ricevere un segnale audio utilizzando o no la codifica. 
Abbiamo di conseguenza diviso il progetto in due codici: un primo codice (sia tx che rx) dove utilizziamo una modulazione AM in banda base senza l’utilizzo di una codifica e un secondo codice (sia tx che rx) dove utilizziamo una modulazione FM con una codifica μ-Law.

#### Formato audio e specifiche dei test

Per il primo tipo di codice abbiamo scelto un file audio preso sia in formato *.mp3* che in *.wav* che riproduce la canzone di apertura del film “Shrek”
Abbiamo scelto di trasmettere solo 10 secondi della canzone per far vedere la possibilità di trasmettere singoli frame di un file audio, oltre che per limitazioni hardware della PlutoSDR (overflow). Infine la scelta dei due formati differenti è stata fatta per controllare che il codice funzionasse per diversi tipi di formato audio. 
Nel secondo codice, per semplificare, abbiamo scelto di caricare un solo file .wav.

I test applicati per il controllo del funzionamento del codice hanno previsto una trasmissione tra le due radio in visibilità, con ostacolo piccolo (un panino), con ostacolo acustico (voce delle persone) e infine con un ostacolo di grandi dimensioni e spessore (le mura tra due aule). 

#### Trasmissione AM 

##### TX matlab

La fase iniziale del codice prevede l’implementazione delle variabili globali che governano il sistema di trasmissione (che devono essere uguali sia in trasmissione che in ricezione) :

```matlab  
fc = 915e6;              %frequenza della Portante scelta da banda pubblica ISM
sample_rate = 1e6;       %frequenza di campionamento della Pluto
ampiezza_portante = 0.5; %ampiezza di base della portante da modulare
gain_tx = -15;           %max potenza di gain a 0
```

Successivamente il segnale sorgente viene estratto da un file audio digitale e convertito in un formato idoneo alla trasmissione SDR attraverso i seguenti passi:

1. **Conversione mono**: il segnale originale ha un formato stereo a due canali, ma per la modulazione AM ne serve solo uno quindi lo converto facendo la media dei due canali;
2. **Finestratura temporale**: estraggo un segmento di 10 secondi a partire dal secondo 37, convertendo i tempi in indici di campionamento assoluti tramite la frequenza di campionamento nativa del file (fs_audio);
3. **Ricampionamento (Upsampling)**: poiché la frequenza di campionamento dell'audio differisce da quella richiesta dall'hardware della Pluto, viene utilizzata la funzione resample per portare il segnale alla frequenza target di 1 MHz;
4. **Normalizzazione**: il segnale viene diviso per il suo valore massimo assoluto (sommato a una costante infinitesima eps per evitare divisioni per zero), garantendo che l’ampiezza del segnale audio rimanga sempre entro limiti precisi e prevedibili, nello specifico tra -1 e 1 e per evitare clipping (tagli di picchi di ampiezza troppo alti che l’hardware non può sopportare)

La modulazione avviene in forma numerica secondo l'equazione classica dell'AM Full Carrier: *txSignal = Ac \* [1 + audio_resampled]*, dove Ac è un parametro definito in partenza e *“audio_resampled”* è il segnale audio normalizzato; oltre a ciò, viene applicato un’ulteriore normalizzazione di sicurezza (con attenuazione 0.7) per prevenire fenomeni di clipping hardware.
L'SDR ADALM-Pluto richiede in ingresso un segnale in quadratura (I/Q), quindi il vettore reale viene convertito in un segnale complesso a parte immaginaria nulla tramite la funzione “complex”.
Detto ciò il penultimo passaggio è quello di configurare l’hardware Pluto tramite la funzione “sdrtx” e infine trasmettere il segnale attraverso la funzione “transmitRepeat(tx, txNorm)”, che carica il buffer del segnale nella memoria della scheda e lo ritrasmette in loop.

##### Rx python

Per interagire con la pluto su python ci appoggiamo alla libreria adi, poi anche qua impostiamo i parametri della pluto 

```python
duration = 10          # secondi da acquisire
audio_fs = 48000       # frequenza di uscita audio
lp_cutoff = 6000       # banda audio AM (Hz)
lp_order = 1000       # ordine filtro FIR

# Set parametri SDR
sdr = adi.Pluto("ip:192.168.3.1")   #indirizzo della pluto
sdr.rx_lo = int(915e6)              #freq. portante
sdr.sample_rate = int(1e6)          #sample
sdr.rx_rf_bandwidth = int(1e6)
sdr.rx_buffer_size = 8192
sdr.gain_control_mode_chan0 = "manual"
sdr.rx_hardwaregain_chan0 = 50.0
```
Succesivamente i campioni vengono acquisiti con un semlice ciclo for e messi all'interno di un array
Poi inizia il processo di demodulazione, per prima cosa usiamo un rivelatore di inviluppo 

```python
# Envelope detection
am_demod = np.abs(samples)      #prendiamo il valore assoluto 
am_demod -= np.mean(am_demod)   #sottraiamo la media
```

Successivamente applichiamo un filtro passa-basso per tagliare il rumore ad altra frequenza

```python
nyq = fs_sdr / 2                               #calcolo nyq = sample rate / 2 
lp_norm = lp_cutoff / nyq                      #calcolo lafreq. normalizzata fra 0 e nyq (per le librerie)
fir = firwin(lp_order, lp_norm)                #creo i coeff. del filtro

am_filtered = lfilter(fir, 1.0, am_demod)      #convoluzione fra audio e filtro
```

Poi essendo che la pluto lavora a una frequenza di campionamento molto più alta del pc devo fare un resampling per poter ascoltare l'audio

```python
dur_before = len(am_filtered) / fs_sdr          #calcoliamo la durata pre-resample

g = math.gcd(audio_fs, fs_sdr)                  #troviamo l'mcd fra le due frequenze così da poter fare upsampling e dopo downsampling
up = audio_fs // g
down = fs_sdr // g

audio = resample_poly(am_filtered, up, down)    #la funzione resample_poly si occupa di tutto
dur_after = len(audio) / audio_fs               #calcoliamo la durata post-resample
```

Ora normalizziamo l'audio per avere volume uniforme ed evitare clippin ed infine offriamo la possibilità di salvarlo e/o riprodurlo immediatamente

##### Test e problemi riscontrati nella prima parte

Nei test del primo codice abbiamo riscontrato due problemi in particolare: 

- rumore di sottofondo che prevaleva sulla canzone 
- avelocità di riproduzione audio aumentava con la riproduzione. 
  
Per risolvere il primo problema abbiano cambiato la frequenza portante, inizialmente usavamo 2.4GHz ma c'era molta interferenza e optando per i 915 MHz il problema si è risolto

Per il secondo problema nella parte di ricezione abbiamo dovuto implementare un resampling dato che la frequenza alla quale lavora la pluto è troppo alta per la scheda audio del pc

---

#### Trasmissione codificata FM

##### Tx matlab

La fase iniziale del codice prevede l’implementazione delle variabili globali che governano il sistema di trasmissione (che devono essere uguali in ricezione); tra queste abbiamo la frequenza dell’onda portante scelta all’interno della banda pubblica ISM, la frequenza di campionamento della radio SDR, il guadagno del trasmettitore per evitare saturazioni dello stadio RF, la deviazione di frequenza massima (parametro fondamentale per determinare la banda occupata dal segnale FM tramite la regola di Carson: B = 2 * [fm_dev + fm]) e il fattore μ di compressione dell’omonima codifica.

La parte successiva di caricamento dell’audio differisce poco dal codice di trasmissione senza codifica, sono state infatti introdotti solo metodi di controllo per il corretto funzionamento del codice: per esempio un if che converte in mono il canale solo se è in primis doppio o il limite di durata del frame per non sprecare memoria hardware della PlutoSDR.

Prima di modulare il segnale sulla portante, il segnale subisce una compressione logaritmica *(codifica μ-Law)*, implementata tramite la formula: $$F(x) = \operatorname{sgn}(x) \frac{\ln(1 + \mu |x|)}{\ln(1 + \mu)}$$

In questa configurazione, il segnale mantiene la sua natura continua senza subire una quantizzazione numerica a bit discreti e inoltre comprime la gamma dinamica dell'audio, enfatizzando i campioni a basso volume e attenuando i picchi, migliorando così il rapporto segnale-rumore complessivo sul canale radio.
Procedo ulteriormente prima della modulazione nel portare il segnale compresso alla frequenza operativa della pluto tramite un upsampling non intero e utilizzando un’operazione di zero padding , il vettore viene allungato con degli zeri fino a diventare un multiplo esatto della dimensione fissa del buffer (buf_size), ottimizzando il lavoro dei processori della PlutoSDR.

La modulazione FM viene eseguita integrando numericamente nel tempo il segnale in banda base per mappare l'informazione sulla fase istantanea della portante complessa: $$\vartheta(t) = \frac{2 \cdot \pi \cdot \Delta f}{fs} \cdot \Sigma  \operatorname{m}(t)$$

Il segnale viene quindi convertito nella sua rappresentazione equivalente in banda base (IQ) tramite l'esponenziale complesso:
$$\text{fm}_{\text{signal}} = e ^ {j \cdot \operatorname{\vartheta} (t)}$$

Infine, l'inviluppo del segnale IQ viene normalizzato a 1 per rispettare i limiti di input del convertitore digitale-analogico (DAC) della Pluto.
Detto ciò il penultimo passaggio è quello di configurare l’hardware Pluto tramite la funzione “sdrtx” e infine Il segnale FM viene forzato come vettore colonna di numeri complessi a doppia precisione (double). La trasmissione avviene in modalità continua mediante “transmitRepeat”. Lo script calcola analiticamente la durata esatta del file e impiega la funzione pause per mantenere attivo il processo MATLAB per il tempo necessario alla riproduzione, rilasciando infine la risorsa hardware con il comando release(tx).

##### Rx python

Come prima occorre impostare tutti i parametri per la ricezione :

```python
duration    = 10           # secondi da acquisire
audio_fs    = 48000        # sample rate audio di uscita
fm_dev      = 50000        # deviazione FM in Hz
lp_cutoff   = 6000         # taglio filtro passa-basso audio (Hz)
lp_order    = 1000         # ordine filtro FIR
mu          = 255          # parametro µ-Law

#Configurazione SDR
sdr = adi.Pluto("ip:192.168.3.1")
sdr.rx_lo                   = int(915e6) #portante
sdr.sample_rate             = int(1e6)
sdr.rx_rf_bandwidth         = int(1e6)
sdr.rx_buffer_size          = 8192
sdr.gain_control_mode_chan0 = "manual"
sdr.rx_hardwaregain_chan0   = 50.0
```

Poi acquisiamo i campioni con lo stesso metodo dell'AM e iniziamo la demodulazione :

1. il vettore "samples" è un vettore di numeri complessi, a noi serve la variazione di freq. istantanea campione per campione e la estraiamo facendo la derivata "analitica" fra il campione attualee quello successivo

```python
phase        = np.angle(samples)                                #trovo lafase del numero complesso
phase_unwrap = np.unwrap(phase)                                 #svincolo la fase dall'intervallo [-π,π]
freq_inst    = np.diff(phase_unwrap) / (2 * np.pi) * fs_sdr     #calcolo la freq. istantanea
```
2. successivamente normalizziamo rispetto alla deviazione di frequenza e riportiamo l'array alla dimensione originale aggiungendo un campione (duplicato dell'ultimo)

3. come nel caso AM applichiamo un filtro passa bassoper eliminare rumore ad alta frequenza

4. viene normalizzato tutto fra [-1, 1]

Ora decodifichiamo applicando semplicemente la funzione inversa $$y = \operatorname{sign}(x) \cdot (1 / \mu) \cdot (1+\mu) ^ {|x| - 1}$$

Infine normalizziamo rispetto al picco come prima e poi possiamo salvare e/o riprodurre immediatamente l'audio

##### Test e problemi riscontrati nella prima parte

Nei test del secondo codice non abbiamo riscontrato problemi
