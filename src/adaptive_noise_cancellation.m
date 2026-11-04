%% ================= ECEN 463 DSP Final Project =================
% Adaptive Noise Cancellation using LMS and NLMS
% Elijah Larson
% ===============================================================

clc; clear; close all;

%% ---------------------- Parameters ----------------------
Fs = 8000;                 
T  = 5;
t  = 0:1/Fs:T-1/Fs;

mu_LMS  = 0.01;
mu_NLMS = 0.5;
M = 32;
eps_val = 1e-8;

%% ---------------------- Desired Signal ------------------------
f1 = 300; f2 = 600; f3 = 900;
d = sin(2*pi*f1*t) ...
  + 0.5*sin(2*pi*f2*t) ...
  + 0.3*sin(2*pi*f3*t);

%% ---------------------- Cafe-like Noise -----------------------
noise = filter([1 -0.5 0.25],1,0.4*randn(size(t)));

x_primary = d + noise;
noise_ref = filter([1 0.5],1,noise);

N = length(x_primary);

%% ---------------------- Initialization ------------------------
w_LMS = zeros(M,1); w_NLMS = zeros(M,1);
y_LMS = zeros(1,N); y_NLMS = zeros(1,N);
e_LMS = zeros(1,N); e_NLMS = zeros(1,N);
mse_LMS = zeros(1,N); mse_NLMS = zeros(1,N);

%% ================= LMS / NLMS Filtering =======================
for n = M:N
    x_vec = noise_ref(n:-1:n-M+1)';

    % ----- LMS -----
    y_LMS(n) = w_LMS' * x_vec;
    e_LMS(n) = x_primary(n) - y_LMS(n);
    w_LMS = w_LMS + mu_LMS * x_vec * e_LMS(n);
    mse_LMS(n) = e_LMS(n)^2;

    % ----- NLMS -----
    y_NLMS(n) = w_NLMS' * x_vec;
    e_NLMS(n) = x_primary(n) - y_NLMS(n);
    norm_factor = x_vec'*x_vec + eps_val;
    w_NLMS = w_NLMS + (mu_NLMS / norm_factor) * x_vec * e_NLMS(n);
    mse_NLMS(n) = e_NLMS(n)^2;
end

%% ---------------------- SNR Metrics ---------------------------
snr_before = 10*log10(var(d)/(var(x_primary-d)+eps_val));
snr_LMS = 10*log10(var(d)/(var(e_LMS-d)+eps_val));
snr_NLMS = 10*log10(var(d)/(var(e_NLMS-d)+eps_val));

%% ======================= FIGURES ==============================

%% -------- Figure 1: Zoomed Time-Domain (50 ms) --------
zoom_len = round(0.05*Fs);
figure;
plot(t(1:zoom_len),x_primary(1:zoom_len),'r','DisplayName','Noisy Input'); hold on;
plot(t(1:zoom_len),e_LMS(1:zoom_len),'b','DisplayName','LMS Output');
plot(t(1:zoom_len),e_NLMS(1:zoom_len),'g','DisplayName','NLMS Output');
plot(t(1:zoom_len),d(1:zoom_len),'k--','DisplayName','Desired Signal');
xlabel('Time (s)'); ylabel('Amplitude');
title('Zoomed Time-Domain Comparison (Cafe Noise)');
legend; grid on;

%% -------- Figure 2: Focused Spectrograms (Auto-Scaled) --------
seg_len = 128;
overlap = 96;
nfft = 512;

% Same 50 ms window
sig_noisy = x_primary(1:zoom_len);
sig_LMS   = e_LMS(1:zoom_len);
sig_NLMS  = e_NLMS(1:zoom_len);

% Compute spectrograms
[S1,F,T1] = spectrogram(sig_noisy,seg_len,overlap,nfft,Fs);
[S2,~,T2] = spectrogram(sig_LMS,seg_len,overlap,nfft,Fs);
[S3,~,T3] = spectrogram(sig_NLMS,seg_len,overlap,nfft,Fs);

% Convert to power dB
S1dB = 10*log10(abs(S1).^2 + eps);
S2dB = 10*log10(abs(S2).^2 + eps);
S3dB = 10*log10(abs(S3).^2 + eps);

% Automatic color limits
max_val = max([S1dB(:); S2dB(:); S3dB(:)]);
clim = [max_val-60 max_val];

figure;
subplot(3,1,1);
imagesc(T1,F/1000,S1dB); axis xy;
ylim([0 1.5]); caxis(clim);
title('Noisy Input'); ylabel('Frequency (kHz)');

subplot(3,1,2);
imagesc(T2,F/1000,S2dB); axis xy;
ylim([0 1.5]); caxis(clim);
title('LMS Output'); ylabel('Frequency (kHz)');

subplot(3,1,3);
imagesc(T3,F/1000,S3dB); axis xy;
ylim([0 1.5]); caxis(clim);
title('NLMS Output'); ylabel('Frequency (kHz)');
xlabel('Time (s)');

colormap jet;
colorbar;



%% -------- Figure 3: Smoothed MSE (dB) --------
figure;
plot(10*log10(movmean(mse_LMS,500)),'b','DisplayName','LMS'); hold on;
plot(10*log10(movmean(mse_NLMS,500)),'g','DisplayName','NLMS');
xlabel('Sample Index'); ylabel('MSE (dB)');
title('Smoothed MSE Convergence');
legend; grid on;

%% -------- Figure 4: SNR Before vs After --------
figure;
snr_vals = [snr_before snr_LMS snr_NLMS];
bar(snr_vals);
set(gca,'XTickLabel',{'Noisy','LMS','NLMS'});
ylabel('SNR (dB)');
title('SNR Comparison (Cafe Noise)');
grid on;
