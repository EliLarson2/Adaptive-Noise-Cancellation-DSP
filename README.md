# Adaptive Noise Cancellation Using LMS and NLMS

A MATLAB implementation and comparison of **Least Mean Squares (LMS)** and **Normalized Least Mean Squares (NLMS)** adaptive filters for noise cancellation.

I built this project to explore a problem that fixed-coefficient filters do not directly address: removing noise when its characteristics are not completely known ahead of time.

The system uses a second measurement correlated with the unwanted noise. A 32-tap adaptive FIR filter continuously adjusts its coefficients to estimate that noise, subtract it from the corrupted signal, and recover the desired signal. I implemented both LMS and NLMS, then compared their behavior using time-domain output, mean squared error, signal-to-noise ratio, and spectrograms.

The complete MATLAB implementation is available in [`src/adaptive_noise_cancellation.m`](src/adaptive_noise_cancellation.m).

---

## Adaptive Noise-Cancellation Architecture

The experiment uses two inputs:

- A **primary input** containing the desired signal plus noise
- A **reference input** correlated with the unwanted noise

The adaptive filter processes the reference signal and produces an estimate of the noise in the primary input. Subtracting that estimate produces the error signal, which serves as both the recovered output and the feedback used to update the filter coefficients.

```text
        Desired Signal
              |
              v
          +-------+
Noise -->|   +   |-----> Primary Input ------------------+
          +-------+                                       |
                                                          v
Reference Noise ---> Adaptive FIR Filter ---> Noise Estimate
                          LMS / NLMS                       |
                               ^                          (-)
                               |                           |
                               +------ Error Signal <------+
                                          |
                                          v
                                   Recovered Signal
```

The system works when the reference measurement is correlated with the unwanted noise but not with the desired signal. As the filter adapts, its output approaches an estimate of the noise rather than the desired waveform.

---

## Controlled Experiment

I used a known synthetic signal so the filtered outputs could be compared directly against the desired result. The signal contains three sinusoidal components at **300 Hz, 600 Hz, and 900 Hz**, sampled at **8 kHz** for **5 seconds**.

```matlab
f1 = 300;
f2 = 600;
f3 = 900;

d = sin(2*pi*f1*t) ...
  + 0.5*sin(2*pi*f2*t) ...
  + 0.3*sin(2*pi*f3*t);
```

Filtered random noise is added to the desired signal to form the primary input. A separately filtered version of that noise provides the correlated reference measurement used by the adaptive filters.

```matlab
noise = filter([1 -0.5 0.25], 1, 0.4*randn(size(t)));

x_primary = d + noise;
noise_ref = filter([1 0.5], 1, noise);
```

Both algorithms use the same 32-tap FIR structure so the comparison focuses on the coefficient-update method.

| Parameter | Value |
| --- | ---: |
| Sample rate | 8 kHz |
| Signal duration | 5 seconds |
| Desired frequencies | 300, 600, and 900 Hz |
| Adaptive-filter length | 32 taps |
| LMS step size | 0.01 |
| NLMS step size | 0.5 |

---

## LMS and NLMS Implementation

For each sample, the filter forms a vector from the most recent reference-noise values and calculates a noise estimate:

```matlab
x_vec = noise_ref(n:-1:n-M+1)';

y(n) = w' * x_vec;
e(n) = x_primary(n) - y(n);
```

Here, `y(n)` is the estimated noise and `e(n)` is the recovered output.

### LMS

LMS updates the coefficient vector using the current input, error, and a fixed step size:

```matlab
w_LMS = w_LMS + mu_LMS * x_vec * e_LMS(n);
```

The step size controls how aggressively the filter adapts. A larger value can respond more quickly, but it can also increase coefficient variation or make the filter unstable.

### NLMS

NLMS uses the same basic approach but normalizes its update by the energy of the current input vector:

```matlab
norm_factor = x_vec' * x_vec + eps_val;

w_NLMS = w_NLMS ...
       + (mu_NLMS / norm_factor) * x_vec * e_NLMS(n);
```

This makes the effective adaptation rate less dependent on the magnitude of the reference signal. It does not, however, guarantee that NLMS will outperform LMS for every step size, filter length, or noise realization.

---

## Results

I evaluated the algorithms from several perspectives rather than relying on a single plot. The time-domain output shows waveform recovery, the MSE plot shows adaptation behavior, SNR provides a numerical comparison, and the spectrograms show what happened to the desired frequency components and surrounding noise energy.

### Time-Domain Recovery

![Time-domain comparison of the noisy input, desired signal, LMS output, and NLMS output](Results/time_domain.png)

*Time-domain comparison of the noisy input and the outputs recovered by LMS and NLMS.*

Both adaptive filters reduce the visible noise component and follow the structure of the desired signal more closely than the unfiltered input. Neither output perfectly reconstructs the original waveform, but the comparison shows that both algorithms are learning from the correlated reference signal rather than acting like fixed filters.

The time-domain plot is useful for checking waveform behavior, but it does not fully describe convergence or residual noise. That required looking at the other measurements.

### MSE Convergence

![Smoothed MSE convergence for LMS and NLMS](Results/mse_convergence.png)

*Smoothed squared-error behavior for the LMS and NLMS adaptive filters.*

Both algorithms remain adaptive throughout the experiment. Under the selected parameters, LMS settles to a lower error level, while NLMS shows larger steady-state fluctuations.

This does not mean LMS is universally better than NLMS. In this experiment, the LMS and NLMS step sizes were different, and the normalized update used by NLMS was more aggressive. The result demonstrates that algorithm selection cannot be separated from parameter selection.

### Signal-to-Noise Ratio

![SNR comparison before filtering and after LMS and NLMS processing](Results/snr_bar.png)

*Signal-to-noise ratio for the original noisy signal and the recovered LMS and NLMS outputs.*

The SNR comparison supports the same conclusion as the MSE plot. LMS produced the largest improvement for this test case, while NLMS provided a smaller improvement under the selected settings.

I intentionally treat this as an **experiment-specific result**, not a general ranking of the two algorithms. NLMS can be advantageous when input power varies because its update is normalized, but its performance still depends on the normalized step size, input statistics, filter length, and reference-noise correlation.

### Spectral Behavior

![Spectrogram comparison of the noisy input, LMS output, and NLMS output](Results/spectrograms.png)

*Spectrograms of the noisy input and the outputs produced by LMS and NLMS.*

The spectrograms show that both filters preserve the desired components near **300 Hz, 600 Hz, and 900 Hz** while reducing broadband background energy.

The spectral differences between LMS and NLMS are smaller than the differences shown by the MSE and SNR comparisons. NLMS produces a slightly lower noise floor in some regions, while LMS provides the stronger overall steady-state MSE and SNR result for the selected parameters.

That distinction was one reason it was useful to evaluate the algorithms with several metrics. A single time-domain trace or spectrogram would not have told the complete story.

---

## Engineering Takeaways

The most important lesson from this project was that successfully implementing an algorithm is not the same as proving that it works well.

The MATLAB code ran both adaptive filters, but evaluating them required asking more specific questions:

- Did the filters actually reduce the unwanted signal?
- Did they preserve the desired frequency components?
- How stable was the adaptation?
- How much residual error remained?
- Did the measured SNR improve?
- How sensitive were the results to the selected step sizes?

No single plot answered all of those questions. The time-domain view showed waveform recovery, MSE exposed steady-state behavior, SNR provided a direct performance comparison, and the spectrograms showed whether the desired spectral content survived the filtering process.

The comparison also reinforced that a more sophisticated algorithm does not automatically produce a better result. NLMS adds useful normalization, but its performance still depends on how the experiment is configured. For this run, the selected LMS parameters produced the better overall result.

If I expanded the comparison, I would make it more repeatable by controlling the random-noise realization and running automated step-size sweeps across multiple trials. That would separate the underlying algorithm behavior from the outcome of one noise realization and one selected parameter set.

---

## Future Work: RF and SDR Signal Processing

The direction I am most interested in pursuing next is applying the same adaptive-filtering and measurement techniques to sampled RF data from a software-defined radio.

```text
Antenna
   |
   v
Software-Defined Radio
   |
   v
Sampled I/Q Data
   |
   +----------------------+
   |                      |
   v                      v
Primary Channel     Reference Channel
   |                      |
   +----------+-----------+
              |
              v
      Adaptive Filtering
              |
              v
  Interference-Reduced Output
              |
              v
   Spectrum / Detection /
       Demodulation
```

A practical extension would replace the synthetic waveform with recorded complex I/Q samples and investigate whether an available reference channel could be used to estimate and suppress correlated interference.

That would introduce new questions that are not present in this controlled experiment: how to obtain a useful reference measurement, how signal bandwidth affects the required filter length, how the adaptation behaves with changing RF conditions, and whether the desired signal is distorted during cancellation.

The same validation approach would still apply. I would compare time-domain or I/Q behavior, convergence, output SNR, and spectral content rather than relying only on whether the algorithm produced an output.

If the processing eventually needed to operate continuously on a high-rate sample stream, an FPGA implementation could become a useful later step. My first priority, however, would be building and validating the RF/SDR signal-processing experiment before moving the adaptive FIR and coefficient-update path into hardware.

---

## Repository Structure

```text
.
├── README.md
├── src/
│   └── adaptive_noise_cancellation.m
└── Results/
    ├── time_domain.png
    ├── mse_convergence.png
    ├── snr_bar.png
    └── spectrograms.png
```

---

## Background

This project was originally developed for **ECEN 463: Digital Signal Processing** at the University of Nebraska–Lincoln.

It gave me practical experience implementing adaptive filters, but the more valuable part was learning how to design an experiment that measures whether a DSP algorithm actually achieves its intended result. That measurement-driven approach is what I want to continue applying to embedded DSP, FPGA, and RF systems.
