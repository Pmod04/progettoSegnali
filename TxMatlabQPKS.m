clc; clear;

%% PARAMETRI
fc = 915e6;                 % frequenza ISM
sample_rate = 1e6;          % Sample rate Pluto
gain_tx = -15;              % Gain tx

Rs = 100e3;                 % symbol rate
sps = sample_rate / Rs;     % Samples per symbol
rolloff = 0.35;
Nbits = 8;                  % PCM a 8 bit 

audio_fs_target = 32000;    % audio più leggero
buffer_audio_sec = 0.05;    % 50 ms per blocco

%% CARICAMENTO AUDIO 
[audio, fs_audio] = audioread('Monsters Inc theme (full).wav');
audio = mean(audio,2);      % mono

audio = resample(audio, audio_fs_target, fs_audio);
audio = audio / (max(abs(audio)) + eps);

%% FILTRO RRC
rrc = rcosdesign(rolloff, 6, sps);

%% PLUTO
tx = sdrtx('Pluto');
tx.BasebandSampleRate = sample_rate;
tx.CenterFrequency = fc;
tx.Gain = gain_tx;

%% STREAMING
samples_per_block = round(audio_fs_target * buffer_audio_sec);  %converto tempo in campioni audio
num_blocks = ceil(length(audio)/samples_per_block); %calcolo il numero di blocchi che servono per coprire tutta la canzone

disp('Trasmissione in streaming...');

for k = 1:num_blocks
    idx = (k-1)*samples_per_block + 1 : ...         %indici del blocco
          min(k*samples_per_block, length(audio));
    audio_blk = audio(idx);                         %estraggo blocco

    % PCM
    pcm = round( (audio_blk + 1) * (2^(Nbits-1)-1) );
    pcm = max(min(pcm, 2^Nbits-1), 0);

    % Bitstream
    bits = de2bi(pcm, Nbits, 'left-msb');
    bits = bits.';
    bits = bits(:);
    bits = bits(1:2*floor(length(bits)/2));

    % QPSK
    sym = reshape(bits, 2, []).';
    qpsk = (2*sym(:,1)-1) + 1j*(2*sym(:,2)-1);
    qpsk = qpsk / sqrt(2);

    % Pulse shaping
    txSig = upfirdn(qpsk, rrc, sps);
    txSig = 0.7 * txSig / max(abs(txSig));

    % TX
    transmit(tx, txSig);
end

disp('Fine trasmissione');