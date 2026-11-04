# Adaptive Noise Cancellation Using LMS and NLMS

Implementation and analysis of **Least Mean Squares (LMS)** and **Normalized Least Mean Squares (NLMS)** adaptive filters in MATLAB for noise cancellation.

The goal of this project was to explore how adaptive FIR filters can identify and suppress correlated noise when the characteristics of the noise are not known beforehand.

---

## Project Objective

Traditional FIR filters use fixed coefficients selected ahead of time.

For this project, I wanted to investigate a different problem:

> **Can a filter continuously adjust its own coefficients based on measured error and learn how to remove an unwanted signal?**

I implemented and compared two adaptive-filtering algorithms:

- **LMS - Least Mean Squares**
- **NLMS - Normalized Least Mean Squares**

The algorithms were evaluated by comparing:

- Time-domain output
- Mean Squared Error (MSE) convergence
- Signal-to-Noise Ratio (SNR)
- Frequency-domain behavior using spectrograms

---

## System Architecture

The adaptive noise-cancellation system uses two inputs:

1. A **primary input** containing the desired signal plus noise
2. A **reference input** correlated with the unwanted noise

```text
Desired Signal
      |
      +----------------+
                       |
                       v
                  +---------+
Noise ----------> | Primary |
                  |  Input  |
                  +---------+
                       |
                       +------------------+
                                          |
Reference Noise                            v
      |                           +----------------+
      +-------------------------->| Adaptive FIR   |
                                  | LMS / NLMS     |
                                  +----------------+
                                          |
                                     Noise Estimate
                                          |
                                          v
Primary Signal ----------------------->  (-)
                                          |
                                          v
                                     Error Signal
                                          |
                                          v
                                  Recovered Signal
```

The adaptive filter attempts to model the noise contained in the primary signal.

The estimated noise is then subtracted from the primary input, producing an error signal that ideally approaches the original desired signal.

---

## Desired Signal

The original experiment uses a controlled synthetic signal containing three sinusoidal components:

- **300 Hz**
- **600 Hz**
- **900 Hz**

```matlab
f1 = 300;
f2 = 600;
f3 = 900;

d = sin(2*pi*f1*t) ...
  + 0.5*sin(2*pi*f2*t) ...
  + 0.3*sin(2*pi*f3*t);
```

A controlled signal made it possible to directly compare the adaptive-filter outputs against a known reference.

The signal was sampled at:

```text
Fs = 8000 Hz
```

for a duration of:

```text
T = 5 seconds
```

---

## Noise Model

The experiment uses a filtered random-noise source to approximate broadband environmental noise.

```matlab
noise = filter([1 -0.5 0.25], 1, 0.4*randn(size(t)));
```

The noisy primary input is then formed as:

```matlab
x_primary = d + noise;
```

A correlated reference-noise signal is separately generated for the adaptive filter:

```matlab
noise_ref = filter([1 0.5], 1, noise);
```

This represents the basic adaptive-noise-cancellation problem: the system has access to the corrupted signal and to a separate measurement correlated with the unwanted noise.

---

## Adaptive FIR Filter

Both algorithms use a **32-tap adaptive FIR filter**.

```matlab
M = 32;
```

For each new sample, a vector containing the most recent reference-noise samples is constructed:

```matlab
x_vec = noise_ref(n:-1:n-M+1)';
```

The adaptive filter then produces an estimate of the noise:

```text
Reference Noise
      |
      v
x[n], x[n-1], ... x[n-31]
      |
      v
Adaptive FIR Coefficients
      |
      v
Estimated Noise
```

The coefficients are continuously updated based on the error between the primary signal and the filter output.

---

# LMS Algorithm

For LMS, the filter output is calculated using:

```matlab
y_LMS(n) = w_LMS' * x_vec;
```

The error signal is:

```matlab
e_LMS(n) = x_primary(n) - y_LMS(n);
```

The filter coefficients are then updated using:

```matlab
w_LMS = w_LMS + mu_LMS * x_vec * e_LMS(n);
```

where the LMS step size was:

```matlab
mu_LMS = 0.01;
```

The step size determines how aggressively the adaptive filter changes its coefficients.

A larger value can increase convergence speed but may also increase instability or steady-state error.

---

# NLMS Algorithm

NLMS extends LMS by normalizing the coefficient update according to the energy of the input vector.

The input normalization term is calculated as:

```matlab
norm_factor = x_vec' * x_vec + eps_val;
```

and the coefficients are updated using:

```matlab
w_NLMS = w_NLMS ...
       + (mu_NLMS / norm_factor) * x_vec * e_NLMS(n);
```

with:

```matlab
mu_NLMS = 0.5;
```

Normalization reduces the sensitivity of the adaptation rate to changes in reference-signal magnitude.

---

## Performance Metrics

I evaluated the two algorithms using several different metrics rather than relying on visual inspection alone.

### Mean Squared Error

The instantaneous squared error is tracked using:

```matlab
mse_LMS(n)  = e_LMS(n)^2;
mse_NLMS(n) = e_NLMS(n)^2;
```

The resulting MSE is smoothed and plotted in decibels to evaluate convergence behavior.

This helps visualize both:

- How quickly the adaptive filter learns
- How much residual error remains after convergence

---

## Signal-to-Noise Ratio

SNR was calculated before and after adaptive filtering.

```matlab
snr_before = 10*log10(var(d) ...
           / (var(x_primary-d) + eps_val));

snr_LMS = 10*log10(var(d) ...
        / (var(e_LMS-d) + eps_val));

snr_NLMS = 10*log10(var(d) ...
         / (var(e_NLMS-d) + eps_val));
```

This gives a quantitative comparison between:

```text
Original Noisy Signal
        vs.
LMS Filter Output
        vs.
NLMS Filter Output
```

---

## Spectral Analysis

In addition to time-domain analysis, I generated spectrograms of:

- Noisy input
- LMS output
- NLMS output

The spectrogram calculation uses:

```text
Segment Length = 128 samples
Overlap        = 96 samples
FFT Size       = 512
```

The spectra are converted to logarithmic power:

```matlab
S1dB = 10*log10(abs(S1).^2 + eps);
```

Using identical color limits across the three spectrograms makes the frequency-domain effects of the adaptive filters easier to compare directly.

---

## Results

The experiment showed that both LMS and NLMS were capable of adapting to the correlated reference-noise signal and improving the recovered output.

One of the more interesting results was that **LMS produced better performance than NLMS under the selected experimental parameters**.

This was useful because it demonstrated that a theoretically more sophisticated algorithm does not automatically produce a better result.

Performance depends on factors such as:

- Step-size selection
- Filter length
- Input-signal statistics
- Reference-noise correlation
- Convergence requirements
- Steady-state error

Rather than assuming NLMS should always outperform LMS, the experiment reinforced the importance of evaluating algorithms using measured results.

---

## Debugging and Analysis

A major part of this project was learning how to evaluate signal-processing algorithms beyond simply determining whether the MATLAB code executed successfully.

The analysis required asking:

```text
Did the algorithm converge?

How quickly did it converge?

How much residual noise remains?

Did SNR actually improve?

What happened to the desired frequency components?

How sensitive is performance to the learning rate?
```

Using multiple views of the same system helped answer those questions:

```text
Time Domain
     +
MSE Convergence
     +
SNR
     +
Spectrogram
     =
More Complete Performance Evaluation
```

This reinforced an engineering principle that I have also applied to hardware development:

> **A system should be validated with measurements that directly test the behavior it was designed to achieve.**

---

## Source Code

The MATLAB implementation can be found in:

```text
src/adaptive_noise_cancellation.m
```

The code contains:

- Controlled signal generation
- Correlated noise generation
- 32-tap adaptive FIR filtering
- LMS implementation
- NLMS implementation
- Coefficient adaptation
- MSE tracking
- SNR calculation
- Time-domain visualization
- Spectrogram analysis
- Convergence analysis

---

## What I Learned

This project provided practical experience with:

- **Digital Signal Processing**
- **MATLAB**
- **Adaptive filtering**
- **FIR filters**
- **LMS**
- **NLMS**
- **Coefficient adaptation**
- **Sampling**
- **Time-domain analysis**
- **Frequency-domain analysis**
- **FFT-based spectral analysis**
- **Spectrograms**
- **SNR**
- **Mean Squared Error**
- **Algorithm comparison**
- **Quantitative engineering validation**

Most importantly, the project strengthened my understanding that implementing an algorithm is only part of the engineering problem.

The other part is developing experiments and measurements that demonstrate **how well the implementation actually performs**.

---

# Future Work

The original project intentionally uses a controlled synthetic signal so that filter performance can be compared against a known desired signal.

A future revision would extend the project toward more realistic signals and deeper algorithm characterization.

## Real Audio

Replace the synthetic signal with:

- Recorded speech
- WAV files
- Recorded environmental noise

This would provide a more realistic adaptive-noise-cancellation problem.

## Parameter Sweeps

Automatically test multiple LMS and NLMS learning rates and compare:

- Convergence speed
- Steady-state MSE
- SNR improvement
- Stability

## Filter-Length Analysis

Compare:

```text
16 taps
32 taps
64 taps
128 taps
```

to analyze the tradeoff between computational complexity and filtering performance.

## Automated Metrics

Add automatic calculation of:

- Convergence time
- Residual noise power
- Average steady-state MSE
- SNR improvement
- Algorithm computational cost

## FPGA Implementation

A long-term extension would be to move portions of the adaptive-filter architecture from MATLAB into an FPGA implementation.

```text
Sample Stream
     |
     v
Adaptive FIR Filter
     |
     v
Error Calculation
     |
     v
Coefficient Update
     |
     v
Filtered Output
```

This would connect the DSP concepts explored in this project with my previous **VHDL and FPGA development experience**.

## RF / SDR Extension

Another future direction is to apply similar signal-processing techniques to sampled RF data from a software-defined radio.

```text
Antenna
   |
   v
SDR
   |
   v
Sampled Signal
   |
   v
DSP / Filtering
   |
   v
Spectrum / Detection / Demodulation
```

This would extend the concepts explored here into practical **RF signal processing and embedded DSP**.

---

## Repository Structure

```text
Adaptive-Noise-Cancellation-DSP/
|
├── README.md
|
├── src/
│   └── adaptive_noise_cancellation.m
|
├── results/
│   ├── time_domain.png
│   ├── spectrograms.png
│   ├── mse_convergence.png
│   └── snr_comparison.png
|
└── docs/
    └── ECEN_463_Final_Project.pdf
```

---

## Tools

- **MATLAB**
- Signal Processing Toolbox
- Adaptive FIR Filtering
- Spectrogram / FFT Analysis

---

## Background

This project was originally developed for **ECEN 463: Digital Signal Processing** at the University of Nebraska-Lincoln.

The original coursework established the LMS/NLMS implementation and experimental framework. Future revisions will extend the project toward real-world audio, automated parameter characterization, FPGA acceleration, and RF/SDR signal processing.
