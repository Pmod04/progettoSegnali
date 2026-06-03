clc; clear;

%% DEFINIZIONE PARAMETRI

fc = 915e6;         %frequenza della Portante della PLuto --> frequenza radio centrale a cui trasmetterà l'antenna 
sample_rate = 1e6;  %frequenza di campionamento della Banda Base = è la velocità alla quale la PLuto leggerà i dati digitali per convertirli in analogico
ampiezza_portante = 0.5; %ampiezza di base della portante da modulare
gain_tx = -15;      % indica il guadagno dell'amplificatoe di trasmissione, max potenza di gain a 0
fc_am = 100e3;      %sub portante che serve successivamente 

%% CARICAMENTO FILE AUDIO DA TRASMETTERE
% In questa sezione ci limitiamo a caricare il file audio ed estrarre la porzione di canzone desiderata da trasmettere 

%[audio, fs_audio] = audioread('Smash Mouth - All Star (Official Music Video).mp3');
%[audio, fs_audio] = audioread('Monsters Inc theme (full).wav');

[audio, fs_audio] = audioread('Smash-Mouth-All-Star-_Official-Music-Video_.wav');
audio_mono = mean(audio,2);  % operazione di conversione ad un canale mono richiesta dall'AM standard
start_sec = 37; % definisce punto di partenza della riproduzione audio
dur_sec   = 10;  % durata totale del frame audio da riprodurre

%Ora moltiplico i valori appena descritti (in secondi) per la frequenza di campionamento del file trovando gli indici di campionamento del file 
start_sample = round(start_sec * fs_audio); 
end_sample   = round((start_sec + dur_sec) * fs_audio);

% ora seleziono usando gli indici di campionamento la porzione del mio array desiderata, nonchè i soli 10 seconi del mio audio desiderati
audio_segment = audio_mono(start_sample:end_sample); 

%se invece non pongo limiti di durata alla canzone uso questo
%audio_segment = audio_mono(start_sample:end); 

%% ADATTAMENTO DEL SEGNALE ALLA PLUTO SDR
% Prima faccio il procedimento di upsampling, ovvero porto la frequenza di campionamento del file audio a quella richiesta dalla Pluto, che non funzionerebbe altrimenti
audio_resampled = resample(audio_segment, sample_rate, fs_audio); % interpola il segnale

% Ora normalizzo il segnale per garantire la corretta modulazione e nessuna socramodulazione

audio_resampled = audio_resampled / (max(abs(audio_resampled))+eps);

%% MODULAZIONE AM BANDA BASE
%
txSignal = ampiezza_portante * (1 + audio_resampled); 
txNorm   = 0.7 * (txSignal / max(abs(txSignal)));  % normalizzazione per sicurezza
txNorm   = complex(txNorm, zeros(size(txNorm)));   % assicuriamo complesso

%%

%t = (0:length(audio_resampled)-1).' / sample_rate;
%am_modulated = ampiezza_portante * (1 + audio_resampled) .* cos(2*pi*fc_am*t);

%txNorm = complex(am_modulated, zeros(size(am_modulated)));
%txNorm = 0.7 * (txNorm / max(abs(txNorm)));


% Segnale complesso IQ puro (parte Q = 0); senza AM banda base

%txSignal = hilbert(audio_resampled); 
%txNorm = 0.7 * (txSignal / max(abs(txSignal)));

%CONNETTO PLUTO
tx = sdrtx('Pluto');
tx.BasebandSampleRate = sample_rate;
tx.CenterFrequency = fc;
tx.Gain = gain_tx;
tx.ShowAdvancedProperties = true;


%TRASMETTO SEGNALE AUDIO
transmitRepeat(tx, txNorm);

%block_size = 2048;
%num_blocks = ceil(length(txNorm)/block_size);

%for k = 1:num_blocks
    %idx = (k-1)*block_size + 1 : min(k*block_size, length(txNorm));
    %transmit(tx, txNorm(idx));
%end


disp(length(audio_segment)/fs_audio);
disp(length(audio_resampled)/sample_rate);

