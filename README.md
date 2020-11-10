# Independent Low-Rank Matrix Analysis (ILRMA)

## About
MATLAB script for Generalized Gaussian  Distribution (GGD) independent low-rank matrix analysis (ILRMA) and its application to blind audio source separation.
These scripts are minor changes from D.kitamura's implementation of ILRMA (https://github.com/d-kitamura/ILRMA).
!!Caution!! now debagging

## Contents
- input [dir]:		        includes test audio signals (reverberation time is around 300 ms)
- reference [dir]:	        includes reference documents for ILRMA
- bss_GGDILRMA.m:		        apply pre- and post-processing for blind source separation (STFT, whitening, ILRMA, back projection, and ISTFT)
- GGDILRMA_readable.m:	        function of GGD-ILRMA (slow but somewhat readable implementation)
- ISTFT.m:			        inverse short-time Fourier transform
- main.m:			        main script with parameter settings
- STFT.m:			        short-time Fourier transform


## Copyright Note
Copyright 2018 Daichi Kitamura.  
These programs are distributed only for academic research at universities and research institutions.  
* S. Mogami,  N. Takamune, D. Kitamura, H. Saruwatari, Y. Takahashi, et al. , "Independent Low-Rank Matrix Analysis Based on Time-Variant Sub-Gaussian Source Model for Determined Blind Source Separation"  IEEE/ACM Transactions on Audio, Speech, and Language Processing ( Volume: 28) pp 503-518
