clear; clc;

%% Parametri (devono coincidere con il RX Python)
fs_sdr      = 1e6;          % Sample rate PlutoSDR (Hz)
fc          = 915e6;        % Frequenza portante (Hz)
audio_fs    = 48000;        % Sample rate audio sorgente (Hz)
fm_dev      = 50000;        % Deviazione FM (Hz) — deve coincidere col RX
tx_gain     = -10;          % Guadagno TX in dBm (regola se il segnale è troppo forte/debole)
mu          = 255;          % Parametro µ-Law

%% Caricamento audio
[audio_raw, fs_file] = audioread('Monsters Inc theme (full).wav');

% Mono
if size(audio_raw, 2) > 1
    audio_raw = mean(audio_raw, 2);
end

% Resample al sample rate audio di riferimento (48 kHz)
if fs_file ~= audio_fs
    audio_raw = resample(audio_raw, audio_fs, fs_file);
    fprintf('Resample: %d Hz -> %d Hz\n', fs_file, audio_fs);
end

% Normalizzazione in [-1, 1]
audio_raw = audio_raw / (max(abs(audio_raw)) + 1e-9);
max_seconds = 15;
if length(audio_raw) > max_seconds * audio_fs
    audio_raw = audio_raw(1 : max_seconds * audio_fs);
    fprintf('Audio tagliato a %d secondi per limiti hardware.\n', max_seconds);
end

fprintf('Audio caricato: %.2f secondi\n', length(audio_raw)/audio_fs);


%% Codifica µ-Law
fprintf('Codifica µ-Law (mu=%d)...\n', mu);
audio_ulaw = sign(audio_raw) .* log1p(mu * abs(audio_raw)) / log1p(mu);

% Il segnale rimane in [-1, 1] ma con compressione logaritmica
% Nessuna quantizzazione — rimane analogico

%% Upsample audio -> sample rate SDR
% Fattore di upsample: fs_sdr / audio_fs = 1e6 / 48000 ≈ 20.83
% Usiamo resample per avere esattamente fs_sdr campioni al secondo
fprintf('Upsample audio a %d Hz...\n', fs_sdr);
audio_up = resample(audio_ulaw, fs_sdr, audio_fs);

% Tronca o padda per avere una lunghezza multipla del buffer
buf_size = 8192;
n_samples = length(audio_up);
n_buf = ceil(n_samples / buf_size);
audio_up(end+1 : n_buf * buf_size) = 0;   % zero-padding

fprintf('Campioni totali da trasmettere: %d (%d buffer)\n', length(audio_up), n_buf);

%% Modulazione FM
% Integrale della fase = integrale della frequenza istantanea normalizzata
fprintf('Modulazione FM (deviazione=%d Hz)...\n', fm_dev);

phase = cumsum(audio_up) * (2 * pi * fm_dev / fs_sdr);
fm_signal = exp(1j * phase);

% Normalizzazione ampiezza IQ in [-1, 1] (richiesto da PlutoSDR)
fm_signal = fm_signal / max(abs(fm_signal));

%% Configurazione PlutoSDR TX

tx = sdrtx('Pluto', ...
    'RadioID',          'usb:0', ...
    'CenterFrequency',  fc, ...
    'BasebandSampleRate', fs_sdr, ...
    'Gain',             tx_gain);

%% Trasmissione

% Assicuriamoci che sia un vettore colonna complesso double
tx_data = complex(double(fm_signal(:))); 

fprintf('Trasmissione in corso su f = %.2f MHz...\n', fc/1e6);

transmitRepeat(tx, tx_data); 

% Keepalive
disp('La radio sta trasmettendo. Premi CTRL+C per fermare.');
pause(length(audio_up)/fs_sdr); % Resta in trasmissione per la durata del brano

release(tx);