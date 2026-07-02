#### Note extra

##### Pacchetti installati:
    • Audio toolbox: necessario per il comando “sdrtx” e per la gestione di segnali IQ 
    • Support package for analog devices: necessario al codice per vedere la Pluto e utilizzarla 
    • Signal Processing Toolbox: necessario per utilizzare comandi come “resample” e “hilbert”
    • Audio Toolbox: non necessario ma consigliato per gestire meglio file audio di diverso tipo; alternativa senza scaricarlo: utilizzare file wav.

##### Upsampling:

Matematicamente aumento la frequenza di campionamento a quella richiesta, passo per un filtro anti-aliasing e infine decremento la frequenza di campioonamento a quellla iniziale.
Passo da 44.1 k campioni a 1 milione di campioni al secondo.
È cio che si aspetta la Pluto, così non fosse si velocizzerebbe il segnale (nostro problema)

##### Normalizzazione segnale:

Normalizzo il segnale per 3 motivi:
    • Non sovramodulare: se la modulazione supera la portante alloa ottengo distorsiaone del segnale
    • Standardizzare segnali diversi: i diversi tipi di file audio hanno picchi diversi quindi facendo così standardizziamo ad un unico picco uguale per tutti
    • Evito divisione per zero: se il segnale fosse in alcuni punti silemzioso aggiungiamo eps che evita un crash del codice
    
Matematicamente divido il mio audio samplizzato per il modulo del suo picco più un errore positivo. Il picco diventa quindi un capione pari a 1