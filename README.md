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
