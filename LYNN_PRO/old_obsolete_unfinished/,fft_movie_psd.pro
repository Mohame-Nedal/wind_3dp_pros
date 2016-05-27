;+
;*****************************************************************************************
;
;  FUNCTION :   fft_movie_psd.pro
;  PURPOSE  :   Calculates the power spectral density (PSD) for fft_movie.pro.
;
;  CALLED BY:   
;               fft_movie.pro
;
;  CALLS:
;               power_of_2.pro
;               my_windowf.pro
;               vector_bandpass.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               TIME        :  N-Element array of times [seconds]
;               DATA        :  N-Element array of data [units]
;               WLEN        :  Scalar defining the # of elements to use in each
;                                snapshot/(time window) of the shifting FFT
;               WSHIFT      :  Scalar defining the # points to shift the 
;                                snapshot/(time window) after each FFT is calculated
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               READ_WIN    :   If set, program uses windowing for FFT calculation
;               FORCE_N     :  Set to a scalar (best if power of 2) to force the program
;                                my_power_of_2.pro return an array with this desired
;                                number of elements [e.g.  FORCE_N = 2L^12]
;               FRANGE      :  2-Element float array defining the freq. range
;                                to use when plotting the power spec (Hz)
;                                [min, max]
;               PRANGE      :  2-Element float array defining the power spectrum
;                                Y-Axis range to use [min, max]
;
;   CHANGED:  1)  NA [MM/DD/YYYY   v1.0.0]
;
;   NOTES:      
;               1)  This routine should not be called by user.
;
;  REFERENCES:  
;               1)  Paschmann, G. and P.W. Daly (1998), "Analysis Methods for Multi-
;                      Spacecraft Data," ISSI Scientific Report, Noordwijk, 
;                      The Netherlands., Int. Space Sci. Inst.
;
;   CREATED:  06/15/2011
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  06/15/2011   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION fft_movie_psd,time,data,wlen,wshift,READ_WIN=read_win,FORCE_N=force_n,$
                       FRANGE=frange,PRANGE=prange

;-----------------------------------------------------------------------------------------
; => Define dummy variables
;-----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
np             = N_ELEMENTS(time)
tags           = ['START_END_0','FREQS','POWER_SPEC','FRANGE','PRANGE']
;-----------------------------------------------------------------------------------------
; => Define # of FFTs to perform
;-----------------------------------------------------------------------------------------
nsteps         = (np[0] - wlen[0])/wshift[0]
; => timestep is the average delay time between data points
x              = LINDGEN(np - 1L)
y              = x + 1L
del_t          = time[y] - time[x]
timestep       = MEAN(del_t,/NAN)
;-----------------------------------------------------------------------------------------
; => initialize the sub series variables
;-----------------------------------------------------------------------------------------
subseries     = FLTARR(wlen[0])                                ; => Sub-array of data points
subtimes      = FLTARR(wlen[0])                                ; => Sub-array of times
IF KEYWORD_SET(force_n) THEN BEGIN
  focn = force_n[0]  ; => # of elements after zero padding
ENDIF ELSE BEGIN
  focn = 2*wlen[0]
ENDELSE
freq_bins     = DINDGEN(wlen[0]/2)/(timestep[0]*wlen[0])            ; => Freq. bin values [Hz]
; => set up the start and end points for the sub timeseries
startpoint    = 0L                                                  ; => Start Element
endpoint      = LONG(startpoint[0] + wlen[0] - 1L)                  ; => End   Element
nsub          = (endpoint[0] - startpoint[0]) + 1L                  ; => # of elements in subarray
gels          = LINDGEN(nsub) + startpoint[0]
subseries     = data[gels]
subtimes      = time[gels]
; => evlength is the FFT window length [seconds]
evlength      = MAX(subtimes,/NAN) - MIN(subtimes,/NAN)
;-----------------------------------------------------------------------------------------
; => Calculate initial FFT window function
;-----------------------------------------------------------------------------------------
; => Zero Pad timeseries and calculate new corresponding frequency bin values
signal        = power_of_2(subseries,FORCE_N=focn)
nfbins2       = N_ELEMENTS(signal)
; => LBW III  [06/15/2011]
;      the zero-padding should actually be done before the window is applied [see ref.]
fft_win       = FLTARR(nfbins2)       ; => var. used for FFT windowing routine
my_windowf,nfbins2 - 1L,2,fft_win     ; => Uses a Hanning Window first
wsign         = signal*fft_win
;-----------------------------------------------------------------------------------------
; => Calculate new corresponding frequency bin values
;-----------------------------------------------------------------------------------------
nsps          = 1d0/timestep[0]
nfreqbins     = DINDGEN(nfbins2[0]/2L)*(nsps[0]/(nfbins2[0] - 1L))
fmin_index    = MIN(WHERE(nfreqbins GT 0.))
fmin          = nfreqbins[fmin_index]                               ; => Min. FFT frequency [Hz]
fbin          = nfreqbins[2L] - nfreqbins[1L]                       ; => Width of freq. bin [Hz]
npowers       = nfbins2[0]/2L - 1L
; => First Power Spectrum Calculation
temp          = (2d0*nfbins2^2)/(nsub*nsps[0])*ABS(FFT(signal))^2
temp          = temp[0:npowers]
; => Define Dummy Power Spectrum Array
subpower      = DBLARR(nsteps,npowers+1L)
subpower[0,*] = temp
; => Shift start/end elements
startpoint   += wshift[0]
endpoint     += wshift[0]
;-----------------------------------------------------------------------------------------
; => Calculate power spectrum for the rest of the intervals
;-----------------------------------------------------------------------------------------
FOR j=1L, nsteps - 1L DO BEGIN
  gels          = LINDGEN(nsub) + startpoint[0]
  ; => Check elements of gels to make sure we do not go beyond time series
  IF (MAX(gels,/NAN) GE np) THEN BEGIN
    bad = WHERE(gels GE np,bd,COMPLEMENT=good,NCOMPLEMENT=gd)
    IF (gd GT 0) THEN gels  = gels[good] ELSE gels  = -1
    IF (gd GT 0) THEN wsign = data[gels] ELSE wsign = REPLICATE(0d0,nsub)
  ENDIF ELSE BEGIN
    wsign = data[gels]
  ENDELSE
  ;-----------------------------------------------------------------------------------------
  ; => Zero Pad timeseries
  ;-----------------------------------------------------------------------------------------
  evlength      = MAX(time[gels],/NAN) - MIN(time[gels],/NAN)
  nfbins        = N_ELEMENTS(gels)
  signal        = power_of_2(wsign,FORCE_N=focn)
  nfbins2       = N_ELEMENTS(signal)
  fels          = LINDGEN(nfbins2)
  ; => Check elements of fels to make sure we do not go beyond time series
  IF (MAX(fels,/NAN) GE np) THEN BEGIN
    bad = WHERE(fels GE np,bd,COMPLEMENT=good,NCOMPLEMENT=gd)
    IF (gd GT 0) THEN fels  = fels[good] ELSE fels  = -1
    IF (gd NE nfbins2) THEN fftw2 = fft_win[fels] ELSE fftw2 = fft_win
  ENDIF ELSE fftw2 = fft_win
  ; => Add window
  signal       *= fftw2
  npowers       = nfbins2/2L - 1L
  ; => Calculate power spectrum [units^2/Hz]
  temp          = (2d0*nfbins2^2)/(nsub*nsps[0])*ABS(FFT(signal))^2
  temp          = temp[0:npowers]
  subpower[j,*] = temp
  ;-----------------------------------------------------------------------------------------
  ; => now move to the next interval
  ;-----------------------------------------------------------------------------------------
  startpoint   += wshift[0]
  endpoint     += wshift[0]
  ;-----------------------------------------------------------------------------------------
  ; => spit out a little status update so we know how fast we're moving through the ffts/
  ;-----------------------------------------------------------------------------------------
  IF (j MOD 100 EQ 0) THEN PRINT,'stepcount:',j
ENDFOR
;-----------------------------------------------------------------------------------------
; => Smooth out spikes to get a better estimate of plot ranges by making up a sample rate
;      and performing a bandpass filter to remove high frequencies...
;-----------------------------------------------------------------------------------------
IF KEYWORD_SET(frange) THEN BEGIN
  fra_0 = REFORM(frange)
ENDIF ELSE BEGIN
  fra_0 = [fmin,MAX(nfreqbins,/NAN)]
ENDELSE
p1    = subpower
sepx  = [[p1],[p1],[p1]]
gfreq = WHERE(nfreqbins GE fra_0[0] AND nfreqbins LE fra_0[1],gfr)
;-----------------------------------------------------------------------------------------
; => negative low freq inclues zero freq. [Fake frequencies and sample rates]
;-----------------------------------------------------------------------------------------
smpx  = vector_bandpass(sepx,1d3,-1d-9,49d1,/MIDF)  
smp1  = REFORM(smpx[*,0])
bad   = WHERE(smp1 LE 0.,bd)
IF (bd GT 0) THEN smp1[bad] = f
IF (gfr GT 0L) THEN BEGIN
  powermin = MIN(smp1[gfreq],/NAN) - 3.5d-1*ABS(MIN(subpower[*,gfreq],/NAN))
  powermax = MAX(subpower[gfreq],/NAN) + 3.5d-1*ABS(MAX(subpower[*,gfreq],/NAN))
ENDIF ELSE BEGIN
  powermin = MIN(smp1,/NAN) - 3.5d-1*ABS(MIN(subpower,/NAN))
  powermax = MAX(subpower,/NAN) + 3.5d-1*ABS(MAX(subpower,/NAN))
ENDELSE
IF (powermin LE 0.) THEN powermin = ABS(MIN(smp1,/NAN))
IF KEYWORD_SET(prange) THEN BEGIN
  powermin = (REFORM(prange))[0]
  powermax = (REFORM(prange))[1]
ENDIF
pra_0 = [powermin,powermax]
;-----------------------------------------------------------------------------------------
; => return structure to user
;-----------------------------------------------------------------------------------------
s0     = 0L                                          ; => Initial Start Element
e0     = LONG(s0[0] + wlen[0] - 1L)                  ; => Initial End   Element
tags   = ['START_END_0','FREQS','POWER_SPEC','FRANGE','PRANGE']
struct = CREATE_STRUCT(tags,[s0,e0],nfreqbins,subpower,fra_0,pra_0)

RETURN,struct
END
