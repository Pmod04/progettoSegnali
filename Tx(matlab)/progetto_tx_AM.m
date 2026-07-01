clc; clear;

%% ---------------- DEFINIZIONE PARAMETRI -------------------------------------------------------------------

fc = 915e6;         %frequenza della Portante
sample_rate = 1e6;  %frequenza di campionamento
ampiezza_portante = 0.5; %ampiezza di base della portante da modulare
gain_tx = -15;      %max potenza di gain a 0

%% ---------------- CARICAMENTO FILE AUDIO ED ESTRAZIONE  -------------------------------------------------------------------

%[audio, fs_audio] = audioread('Smash Mouth - All Star (Official Music Video).mp3');
%[audio, fs_audio] = audioread('Monsters Inc theme (full).wav');
[audio, fs_audio] = audioread('Smash-Mouth-All-Star-_Official-Music-Video_.wav');

audio_mono = mean(audio,2);  % operazione di conversione ad un canale mono richiesta dall'AM standard
start_sec = 37; 
dur_sec   = 10;

%Trasformo gli indici da tempo (secondi) a sample 
start_sample = round(start_sec * fs_audio); 
end_sample   = round((start_sec + dur_sec) * fs_audio);

% Estrazione
audio_segment = audio_mono(start_sample:end_sample); 

% Upsampling per matchare la frequenza della pluto
audio_resampled = resample(audio_segment, sample_rate, fs_audio);

% Normalizzo
audio_resampled = audio_resampled / (max(abs(audio_resampled))+eps);

%% ---------------- MODULAZIONE AM BANDA BASE --------------------------------------------------------------------
% Utilizziamo la modulazione AM classica (compresa fra [-1,1] grazie a normalizzazione precedente)
txSignal = ampiezza_portante * (1 + audio_resampled); 

txNorm   = 0.7 * (txSignal / max(abs(txSignal)));  % normalizzazione di sicurezza per evitare distorsioni hardware (clipping)
txNorm   = complex(txNorm, zeros(size(txNorm)));   % Forziamo il segnale ad essere comlesso, quindi compatibile ai requisiti della Pluto


%% ---------------- CONFIGURAZIONE HARDWARE -----------------------------------------------------------------------

tx = sdrtx('Pluto');
tx.BasebandSampleRate = sample_rate;
tx.CenterFrequency = fc;
tx.Gain = gain_tx;
tx.ShowAdvancedProperties = true;


%% ---------------- TRASMISSIONE SEGNALE AUDIO -----------------------------------------------------------------------
% trasmettiamo in loop di 10 sec

transmitRepeat(tx, txNorm); 

% I seguenti valori sono serviti per verificare la correttezza del codice a livello di durata del segmento audio prima e dopo il ricampionamento.
% Verifica corretta se i due valori a display risultano uguali a 10 secondi.

disp(length(audio_segment)/fs_audio);
disp(length(audio_resampled)/sample_rate);
