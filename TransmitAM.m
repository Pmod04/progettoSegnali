clc; clear;

fc = 915e6;         %frequenza di campionamento
sample_rate = 1e6;  % sample rate requested by ADALM-Pluto
ampiezza_portante = 0.5;
gain_tx = -15;
fc_am = 100e3;

%% LOADING THE AUDIO FILE
% In this block we load the audio which we will then transmit. 
% We upload the file and narrow the streaming to a single channel.
% Then we indicate a time segment we want to broadcast and convert it into samples.

% Below I will mark the first case with a 1 and the second with a 2. 
% The thing in common is the duration of the frame, but the thing that differentiates 
% the two cases is the starting point of the song.

% In the first case the song starts right away so we put the "start_sec" to 0 (case 1)
% Unpinn the comments with "case 1" and pinn the "case 2" commands for the first case
% (1) [audio, fs_audio] = audioread('Monsters Inc theme (full).wav'); 

%IN the second case the song starts 37 seconds after the start of the file because of a inital speech (case 2)
% (2) [audio, fs_audio] = audioread('Smash Mouth - All Star (Official Music Video).mp3');
[audio, fs_audio] = audioread('Smash-Mouth-All-Star-_Official-Music-Video_.wav'); % (2)
audio_mono = mean(audio,2);  % (case 1 and 2)
start_sec = 37; % I indicate in this variable the starting point from which to transmit (2)
% (1) start_sec = 0 

% from this point is ok for each of the cases
dur_sec   = 10;  % this variable stores the stream duration 
start_sample = round(start_sec * fs_audio);
end_sample   = round((start_sec + dur_sec) * fs_audio);
audio_segment = audio_mono(start_sample:end_sample); 

% so in the last three lines we sampled the values to create a segment of the file

%% UPSAMPLING (VERY IMPORTANT !!!)
% We increased the sampling frequency of the audio signal to that required by the Pluto (1 Mhz)

audio_resampled = resample(audio_segment, sample_rate, fs_audio);
% it helped us because if you don't put this command (also in rx) the sound will result accelerated

%% NORMALIZING THE AUDIO SIGNAL 
% Now we normalize the signal for three reasons:
- to avoid overmodulation
- to standardize different signals
- to avoid division by zero

audio_resampled = audio_resampled / (max(abs(audio_resampled))+eps);

%% BASEBAND AM MODULATION
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

