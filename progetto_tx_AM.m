clc; clear;

fc = 915e6;         %frequenza di campionamento
sample_rate = 1e6;  
ampiezza_portante = 0.5;
gain_tx = -15;%  (max potenza di gain a 0)
fc_am = 100e3;

%CARICAMENTO FILE AUDIO DA TRASMETTERE
%[audio, fs_audio] = audioread('Smash Mouth - All Star (Official Music Video).mp3');
%[audio, fs_audio] = audioread('Monsters Inc theme (full).wav');
[audio, fs_audio] = audioread('Smash-Mouth-All-Star-_Official-Music-Video_.wav');
audio_mono = mean(audio,2);  % Mono
start_sec = 37; % aggiungo 37 per far partire la canzone 37 secondi dopo
dur_sec   = 10;  % questo lo aggiungo per trasmettere solo 10 secondi di
                  % audio

start_sample = round(start_sec * fs_audio);
% ora faccio un end_sample dove dico alla trasmissione di finire a 47
% secondi (parto da 37, trasmetto 10 secondi). Infatti poi con
% audio_segment definisco il segmento di audio da trasmettere 

end_sample   = round((start_sec + dur_sec) * fs_audio);
audio_segment = audio_mono(start_sample:end_sample); 

%se invece non pongo limiti di durata alla canzone uso questo
%audio_segment = audio_mono(start_sample:end); 

% UPSAMPLING A 1 MHZ: PORTO LA FREQUENZA DI CAMPIONAMENTO DEL SEGNALE AUDIO
% A QUELLA RICHIESTA DALLA PLUTO

audio_resampled = resample(audio_segment, sample_rate, fs_audio);

%NORMALIZZO IL SEGNALE AUDIO

audio_resampled = audio_resampled / (max(abs(audio_resampled))+eps);

%%
% MOODULO CON MODULAZIONE AM BANDA BASE
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

