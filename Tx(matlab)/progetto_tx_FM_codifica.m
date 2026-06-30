clear; clc;

%% ---------------- DEFINIZIONE PARAMETRI -------------------------------------------------------------------
%Devono coincidere con i parametri definiti in ricezione su python

fs_sdr      = 1e6;          % Sample rate PlutoSDR (Hz)
fc          = 915e6;        % Frequenza portante (Hz)
audio_fs    = 48000;        % Sample rate audio sorgente (Hz)
fm_dev      = 50000;        % Deviazione FM (Hz) — deve coincidere col RX
tx_gain     = -10;          % Guadagno TX in dBm (regola se il segnale è troppo forte/debole)
mu          = 255;          % Parametro µ-Law

%% ---------------- CARICAMENTO AUDIO -------------------------------------------------------------------

[audio_raw, fs_file] = audioread('Monsters Inc theme (full).wav');

% operazione di conversione ad un canale mono
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
%% ---------------- CODIFCA µ-LAW -------------------------------------------------------------------
fprintf('Codifica µ-Law (mu=%d)...\n', mu);
audio_ulaw = sign(audio_raw) .* log1p(mu * abs(audio_raw)) / log1p(mu);

% Il segnale rimane in [-1, 1] ma con compressione logaritmica
% Nessuna quantizzazione — rimane analogico (versione semplificata per SDR)

%% ---------------- UPSAMPLE AUDIO -> SAMPLE RATE SDR -------------------------------------------------------------------
% Fattore di upsample: fs_sdr / audio_fs = 1e6 / 48000 ≈ 20.83
% Usiamo resample per avere esattamente fs_sdr campioni/s

fprintf('Upsample audio a %d Hz...\n', fs_sdr);
audio_up = resample(audio_ulaw, fs_sdr, audio_fs);

% Tronca o padda per avere una lunghezza multipla del buffer
buf_size = 8192;
n_samples = length(audio_up);
n_buf = ceil(n_samples / buf_size);
audio_up(end+1 : n_buf * buf_size) = 0;   % zero-padding

fprintf('Campioni totali da trasmettere: %d (%d buffer)\n', length(audio_up), n_buf);

%% ---------------- MODULAZIONE FM -------------------------------------------------------------------
% Integrale della fase = integrale della frequenza istantanea normalizzata
fprintf('Modulazione FM (deviazione=%d Hz)...\n', fm_dev);

phase = cumsum(audio_up) * (2 * pi * fm_dev / fs_sdr);
fm_signal = exp(1j * phase);

% Normalizzazione ampiezza IQ in [-1, 1] (richiesto da PlutoSDR)
fm_signal = fm_signal / max(abs(fm_signal));

%% ---------------- CONFIGURAZIONE PLUTOSDR TX -------------------------------------------------------------------
fprintf('Configurazione PlutoSDR...\n');

tx = sdrtx('Pluto', ...
    'RadioID',          'usb:0', ...
    'CenterFrequency',  fc, ...
    'BasebandSampleRate', fs_sdr, ...
    'Gain',             tx_gain);

%% ---------------- TRASMISSIONE -------------------------------------------------------------------

fprintf('\nPreparazione buffer complesso...\n');

%Assicuriamoci che sia un vettore colonna complesso double
tx_data = complex(double(fm_signal(:))); 

%Verifica dimensionale (Opzionale ma utile)
if isreal(tx_data)
    error('Il segnale è ancora reale! La Pluto richiede I/Q complessi.');
end

fprintf('Trasmissione in corso su f = %.2f MHz...\n', fc/1e6);

transmitRepeat(tx, tx_data); 

% Il programma deve rimanere "vivo" per trasmettere
disp('La radio sta trasmettendo. Premi CTRL+C per fermare.');
pause(length(audio_up)/fs_sdr); % Resta in trasmissione per la durata del brano

release(tx);
