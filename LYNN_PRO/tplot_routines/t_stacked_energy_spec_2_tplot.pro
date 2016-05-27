;*****************************************************************************************
;
;  FUNCTION :   calc_particle_ener_spectra.pro
;  PURPOSE  :   This routine calculates the omni-directional energy spectra from an
;                 input array of 3D particle velocity distributions.  The results are
;                 very similar to those returned by get_spec.pro.
;
;  CALLED BY:   
;               t_stacked_energy_spec_2_tplot.pro
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               wind_3dp_units.pro
;               is_a_number.pro
;               get_valid_trange.pro
;               format_esa_bins_keyword.pro
;               str_element.pro
;               is_a_3_vector.pro
;               transform_vframe_3d_array.pro
;               conv_units.pro
;               calc_log_scale_yrange.pro
;               extract_tags.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT         :  [N]-Element [structure] array of THEMIS ESA or Wind/3DP
;                                IDL data structures containing the 3D velocity
;                                distribution functions to use to create the stacked
;                                energy spectra plots
;
;  EXAMPLES:    
;               [calling sequence]
;               test = calc_particle_ener_spectra(dat [,UNITS=units] [,BINS=bins]   $
;                                                 [,TRANGE=trange] [,ERANGE=erange] $
;                                                 [,LIMITS=limits] [,/NO_TRANS])
;
;  KEYWORDS:    
;               UNITS       :  Scalar [string] defining the units to use for the
;                                vertical axis of the plot and the outputs YDAT and DYDAT
;                                [Default = 'flux' or number flux]
;               BINS        :  [N]-Element [byte] array defining which solid angle bins
;                                should be plotted [i.e., BINS[good] = 1b] and which
;                                bins should not be plotted [i.e., BINS[bad] = 0b].
;                                One can also define bins as an array of indices that
;                                define which solid angle bins to plot.  If this is the
;                                case, then on output, BINS will be redefined to an
;                                array of byte values specifying which bins are TRUE or
;                                FALSE.
;                                [Default:  BINS[*] = 1b]
;               TRANGE      :  [2]-Element [double] array of Unix times specifying the
;                                time range over which to calculate spectra
;                                [Default : [MIN(DAT.TIME),MAX(DAT.END_TIME)] ]
;               ERANGE      :  [2]-Element [double] array defining the energy [eV] range
;                                over which to calculate spectra
;                                [Default : [MIN(DAT.ENERGY),MAX(DAT.ENERGY)] ]
;               LIMITS      :  Scalar [structure] that may contain any combination of the
;                                following structure tags or keywords accepted by
;                                PLOT.PRO:
;                                  XLOG,   YLOG,   ZLOG,
;                                  XRANGE, YRANGE, ZRANGE,
;                                  XTITLE, YTITLE,
;                                  TITLE, POSITION, REGION, etc.
;                                  (see IDL documentation for a description)
;               NO_TRANS    :  If set, routine will not transform data into bulk flow
;                                rest frame defined by the structure tag VSW in each
;                                DAT structure (VELOCITY tag in THEMIS ESA structures
;                                will work as well so long as the THETA/PHI angles are
;                                in the same coordinate basis as VELOCITY and MAGF)
;                                [Default = FALSE]
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [02/01/2015   v1.0.0]
;             2)  Continued to write routine
;                                                                   [02/01/2015   v1.0.0]
;             3)  Continued to write routine
;                                                                   [02/06/2015   v1.0.0]
;             4)  Continued to write routine
;                                                                   [02/06/2015   v1.0.0]
;             5)  Continued to write routine
;                                                                   [02/11/2015   v1.0.0]
;             6)  Fixed an issue to avoid conflicting data structures
;                                                                   [11/16/2015   v1.0.1]
;             7)  Fixed an issue to avoid conflicting data structures
;                                                                   [11/24/2015   v1.0.2]
;             8)  Something was wrong with OMNI spectra calculation for SST inputs
;                                                                   [11/25/2015   v1.0.3]
;             9)  Now removes repeated energy bin values (i.e., SST does this) and
;                   cleaned up a bit and now calls test_plot_axis_range.pro
;                                                                   [11/25/2015   v1.0.4]
;            10)  Changed how Avg. energy is defined
;                                                                   [12/01/2015   v1.0.5]
;            11)  Changed how Avg. energy is defined and cleaned up a little
;                                                                   [12/02/2015   v1.0.6]
;            12)  Cleaned up and renamed from
;                   temp_calc_ener_spect.pro to calc_particle_ener_spectra.pro and
;                   now calls is_a_number.pro, get_valid_trange.pro,
;                   is_a_3_vector.pro
;                                                                   [01/15/2016   v1.1.0]
;            13)  Fixed a bug where badvdf_msg and notthm_msg variables were not defined
;                                                                   [02/02/2016   v1.1.1]
;
;   NOTES:      
;               0)  ***  User should not call this routine directly  ***
;               1)  See also:  get_spec.pro, get_padspecs.pro
;               2)  The following structure tags must be defined in DAT
;                     VSW or VELOCITY, and {usual 3DP and ESA tags}
;
;  REFERENCES:  
;               1)  Carlson et al., (1983), "An instrument for rapidly measuring
;                      plasma distribution functions with high resolution,"
;                      Adv. Space Res. Vol. 2, pp. 67-70.
;               2)  Curtis et al., (1989), "On-board data analysis techniques for
;                      space plasma particle instruments," Rev. Sci. Inst. Vol. 60,
;                      pp. 372.
;               3)  Lin et al., (1995), "A Three-Dimensional Plasma and Energetic
;                      particle investigation for the Wind spacecraft," Space Sci. Rev.
;                      Vol. 71, pp. 125.
;               4)  Paschmann, G. and P.W. Daly (1998), "Analysis Methods for Multi-
;                      Spacecraft Data," ISSI Scientific Report, Noordwijk, 
;                      The Netherlands., Int. Space Sci. Inst.
;               5)  McFadden, J.P., C.W. Carlson, D. Larson, M. Ludlam, R. Abiad,
;                      B. Elliot, P. Turin, M. Marckwordt, and V. Angelopoulos
;                      "The THEMIS ESA Plasma Instrument and In-flight Calibration,"
;                      Space Sci. Rev. 141, pp. 277-302, (2008).
;               6)  McFadden, J.P., C.W. Carlson, D. Larson, J.W. Bonnell,
;                      F.S. Mozer, V. Angelopoulos, K.-H. Glassmeier, U. Auster
;                      "THEMIS ESA First Science Results and Performance Issues,"
;                      Space Sci. Rev. 141, pp. 477-508, (2008).
;               7)  Auster, H.U., K.-H. Glassmeier, W. Magnes, O. Aydogar, W. Baumjohann,
;                      D. Constantinescu, D. Fischer, K.H. Fornacon, E. Georgescu,
;                      P. Harvey, O. Hillenmaier, R. Kroth, M. Ludlam, Y. Narita,
;                      R. Nakamura, K. Okrafka, F. Plaschke, I. Richter, H. Schwarzl,
;                      B. Stoll, A. Valavanoglou, and M. Wiedemann "The THEMIS Fluxgate
;                      Magnetometer," Space Sci. Rev. 141, pp. 235-264, (2008).
;               8)  Angelopoulos, V. "The THEMIS Mission," Space Sci. Rev. 141,
;                      pp. 5-34, (2008).
;               9)  Ni, B., Y. Shprits, M. Hartinger, V. Angelopoulos, X. Gu, and
;                      D. Larson "Analysis of radiation belt energetic electron phase
;                      space density using THEMIS SST measurements: Cross‐satellite
;                      calibration and a case study," J. Geophys. Res. 116, A03208,
;                      doi:10.1029/2010JA016104, 2011.
;              10)  Turner, D.L., V. Angelopoulos, Y. Shprits, A. Kellerman, P. Cruce,
;                      and D. Larson "Radial distributions of equatorial phase space
;                      density for outer radiation belt electrons," Geophys. Res. Lett.
;                      39, L09101, doi:10.1029/2012GL051722, 2012.
;
;   CREATED:  02/01/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  02/02/2016   v1.1.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION calc_particle_ener_spectra,dat,UNITS=units,BINS=bins,TRANGE=trange,ERANGE=erange,$
                                  LIMITS=limits,NO_TRANS=no_trans

;;  Define compiler options
COMPILE_OPT IDL2
;;  Let IDL know that the following are functions
FORWARD_FUNCTION test_wind_vs_themis_esa_struct, wind_3dp_units,         $
                 format_esa_bins_keyword, conv_units, is_a_number,       $
                 calc_log_scale_yrange, get_valid_trange, is_a_3_vector, $
                 transform_vframe_3d_array
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
mission_logic  = [0b,0b]                ;;  Logic variable used for determining which mission is associated with DAT
;;  Dummy error messages
noinpt_msg     = 'User must supply an array of velocity distribution functions as IDL structures...'
notstr_msg     = 'DAT must be an array of IDL structures...'
notvdf_msg     = 'Input must be a velocity distribution function as an IDL structure...'
badtra_msg     = 'TRANGE must be a 2-element array of Unix times and DAT must have a range of times as well...'
badera_msg     = 'ERANGE must be a 2-element array of energies [eV] and DAT.ENERGY must have a range of energies as well...'
badvsw_msg     = 'DAT structure must have VSW (or VELOCITY) tag defined as a 3 element vector of cartesian magnetic field components'
badvdf_msg     = 'Input must be an IDL structure with similar format to Wind/3DP or THEMIS/ESA...'
not3dp_msg     = 'Input must be a velocity distribution IDL structure from Wind/3DP...'
notthm_msg     = 'Input must be a velocity distribution IDL structure from THEMIS/ESA...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 1) THEN BEGIN
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
IF (SIZE(dat,/TYPE) NE 8L OR N_ELEMENTS(dat) LT 2) THEN BEGIN
  MESSAGE,notstr_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Check to make sure distribution has the correct format
test0          = test_wind_vs_themis_esa_struct(dat[0],/NOM)
test           = (test0.(0) + test0.(1)) NE 1
IF (test[0]) THEN BEGIN
  MESSAGE,notvdf_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check UNITS
test           = (N_ELEMENTS(units) EQ 0) OR (SIZE(units,/TYPE) NE 7)
IF (test[0]) THEN units = 'flux'
;;  Format to allowable units
temp           = wind_3dp_units(units)
gunits         = temp.G_UNIT_NAME      ;;  e.g. 'flux'
units          = gunits[0]             ;;  redefine UNITS incase it changed
;;  Check ERANGE
test           = (N_ELEMENTS(erange) LT 2) OR (is_a_number(erange,/NOMSSG) EQ 0)
ener0          = dat.ENERGY
def_eran       = [MIN(ener0,/NAN),MAX(ener0,/NAN)]      ;;  Default energy range [eV]
IF (test[0]) THEN eran = def_eran ELSE eran = [MIN(erange),MAX(erange)]
test           = (eran[0] EQ eran[1]) AND (def_eran[0] EQ def_eran[1])
IF (test[0]) THEN BEGIN
  MESSAGE,badera_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF ELSE BEGIN
  IF (eran[0] EQ eran[1]) THEN eran = def_eran
ENDELSE
;;  Clean up
ener0          = 0
;;  Check TRANGE
test           = (N_ELEMENTS(trange) LT 2) OR (is_a_number(trange,/NOMSSG) EQ 0)
IF (test[0]) THEN trange = [MIN(dat.TIME),MAX(dat.END_TIME)]
tra_struc      = get_valid_trange(TRANGE=trange,PRECISION=prec)
tra_unix       = tra_struc.UNIX_TRANGE
test           = (TOTAL(FINITE(tra_unix)) LT 2)
IF (test[0]) THEN tra = [MIN(dat.TIME),MAX(dat.END_TIME)] ELSE tra = [MIN(tra_unix),MAX(tra_unix)]
test           = (N_ELEMENTS(tra) NE 2) OR (tra[0] EQ tra[1])
IF (test[0]) THEN BEGIN
  MESSAGE,badtra_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Check BINS
n_b            = dat[0].NBINS[0]        ;;  # of solid angle bins per structure
bstr           = format_esa_bins_keyword(dat,BINS=bins)
test           = (SIZE(bstr,/TYPE) NE 8)
IF (test[0]) THEN STOP     ;;  Debug --> something is wrong
;;  Check NO_TRANS
test           = ~KEYWORD_SET(no_trans)
IF (test[0]) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  User wants to transform into bulk flow rest frame
  ;;    --> Need the VSW (or VELOCITY) structure tag
  ;;--------------------------------------------------------------------------------------
  str_element,dat[0],'VSW',vsw
  test           = (is_a_3_vector(vsw,/NOMSSG) EQ 0)
  IF (test[0]) THEN str_element,dat[0],'VELOCITY',vsw
  test           = (is_a_3_vector(vsw,/NOMSSG) EQ 0)
  IF (test[0]) THEN BEGIN
    MESSAGE,'TAG:  '+badvsw_msg,/INFORMATIONAL,/CONTINUE
    RETURN,0b
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  At least one of them is set  -->  Determine which one
  ;;--------------------------------------------------------------------------------------
  alltags        = STRLOWCASE(TAG_NAMES(dat[0]))
  good0          = WHERE(alltags EQ 'vsw',gd0)
  good1          = WHERE(alltags EQ 'velocity',gd1)
  test           = (gd0 GT 0)
  IF (test[0]) THEN BEGIN
    vsw           = dat.(good0[0])
    IF (gd1 GT 0) THEN add_vel_logic = 0b ELSE add_vel_logic = 1b
    add_vsw_logic = 0b
  ENDIF ELSE BEGIN
    vsw           = dat.(good1[0])
    add_vel_logic = 0b
    add_vsw_logic = 1b
  ENDELSE
  test           = (TOTAL(FINITE(vsw)) EQ 0) OR (TOTAL(ABS(vsw)) EQ 0)
  IF (test[0]) THEN BEGIN
    MESSAGE,'FINITE:  '+badvsw_msg,/INFORMATIONAL,/CONTINUE
    RETURN,0b
  ENDIF
  ;;  Set transformation logic
  yes_trans = 1
ENDIF ELSE yes_trans = 0
IF (yes_trans[0]) THEN f_suffx = 'swf' ELSE f_suffx = 'scf'
;;----------------------------------------------------------------------------------------
;;  Define parameters relevant to structure format
;;----------------------------------------------------------------------------------------
n_e            = dat[0].NENERGY[0]      ;;  E = # of energy bins per structure
n_b            = dat[0].NBINS[0]        ;;  A = # of solid angle bins per structure
n_dat          = N_ELEMENTS(dat)        ;;  D = # of data structures
;;----------------------------------------------------------------------------------------
;;  Define data parameters
;;----------------------------------------------------------------------------------------
;;  Keep DAT within TRANGE
test           = (dat.TIME GE tra[0]) AND (dat.END_TIME LE tra[1])
good           = WHERE(test,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
IF (gd[0] GT 0 AND gd[0] LT n_dat[0]) THEN BEGIN
  ;;  Remove data out of time range
  dat20  = dat[good]
ENDIF ELSE BEGIN
  dat20  = dat ;;  Else --> use all
ENDELSE
IF (yes_trans[0]) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Define transformation velocities
  ;;--------------------------------------------------------------------------------------
  test           = (gd0 GT 0)
  IF (test[0]) THEN vsw = TRANSPOSE(dat20.(good0[0])) ELSE vsw = TRANSPOSE(dat20.(good1[0]))
  dat21 = transform_vframe_3d_array(dat20,vsw)
ENDIF ELSE dat21 = dat20
;;  Clean up
dumb           = TEMPORARY(dat20)
;;  Redefine # of structures and data
;;    E = # of energy bins per structure
;;    A = # solid angle bins per energy per structure
;;    D = # of structures
n_dat          = N_ELEMENTS(dat21)      ;;  D = # of data structures
n_e            = dat21[0].NENERGY[0]    ;;  E = # of energy bins per structure
n_b            = dat21[0].NBINS[0]      ;;  A = # of solid angle bins per structure
;;----------------------------------------------------------------------------------------
;;  Check if user wants to transform into bulk flow frame
;;----------------------------------------------------------------------------------------
;;  Make sure units are converted properly
dat2           = conv_units(dat21,gunits[0])
;;  Clean up
dumb           = TEMPORARY(dat21)
;;  Redefine # of structures and data
;;    E = # of energy bins per structure
;;    A = # solid angle bins per energy per structure
;;    D = # of structures
energy         = dat2.ENERGY            ;;  [E,A,D]-Element array of energy bin midpoint values [eV]
data0          = dat2.DATA              ;;  [E,A,D]-Element array of data values [UNITS]
denergy        = dat2.DENERGY           ;;  [E,A,D]-Element array of energy bin ranges [eV]
;;----------------------------------------------------------------------------------------
;;  Check for repeated energy bin values
;;----------------------------------------------------------------------------------------
nall           = N_ELEMENTS(denergy)
test           = (ABS(denergy) GT 0) AND FINITE(denergy)
good           = WHERE(test,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
test           = (bd[0] GT 0) AND (gd[0] GT 4*n_dat[0])
IF (test[0]) THEN BEGIN
  ;;  Use only the unique energy bins
  energy[bad] = f
  data0[bad]  = f
  ;;  Change ERANGE (if necessary)
  mnmx        = [MIN(ABS(energy),/NAN),MAX(ABS(energy),/NAN)]
  eran0       = eran      ;;  Original input
  eran[0]     = (eran[0] > mnmx[0]) > 1e0          ;;  keep above 1 eV for lower bound
  eran[1]     = (eran[1] < mnmx[1])
  test        = (test_plot_axis_range(eran,/NOMSSG) EQ 0)
  IF (test[0]) THEN BEGIN
    ;;  Bad --> expand about finite range
    eran1       = mnmx + [-1,1]*1.05*MEAN(mnmx,/NAN)
    eran1[0]    = eran1[0] > 1e0
    eran1[1]    = eran1[1] < 1e10
  ENDIF ELSE eran1 = eran
  ;;  Redefine
  eran        = eran1
ENDIF ELSE BEGIN
  ;;  Either it's totally fine or we need to quit!
  test           = (gd[0] LE 4*n_dat[0])
  IF (test[0]) THEN BEGIN
    ;;  Not enough points --> Stop
    MESSAGE,'Not enough finite and/or unique energy bin values...',/INFORMATIONAL,/CONTINUE
    STOP
  ENDIF ;;  Else --> use all
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Keep only data within TRANGE and ERANGE and with BINS = 1
;;----------------------------------------------------------------------------------------
energy1d       = REPLICATE(0e0,n_e[0])
FOR j=0L, n_e[0] - 1L DO BEGIN
  ener0   = REFORM(dat2.ENERGY[j,*])        ;;  [A,N]-Element array
  good_e0 = WHERE(FINITE(ener0) AND ener0 GT 0,gd_e0)
  IF (gd_e0 GT 0) THEN BEGIN
    mede0    = MEDIAN(ener0[good_e0])
    energy1d[j] = mede0[0]
  ENDIF
ENDFOR
;;--------------------------------------
;;  Keep DAT.ENERGY within ERANGE
;;--------------------------------------
test           = (energy1d GE eran[0]) AND (energy1d LE eran[1])
good           = WHERE(test,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
test           = (gd[0] GT 0) AND (bd[0] LT (n_e[0] - 1L))
IF (test[0]) THEN BEGIN
  ;;  Use only the good (average) energy bins
  good_eind        = good
ENDIF ELSE BEGIN
  ;;  Else --> use all
  good_eind        = LINDGEN(n_e[0])
ENDELSE
;;  Redefine # of structures and data
;;    E = # of energy bins per structure
;;    A = # solid angle bins per energy per structure
;;    D = # of structures
n_e_out        = N_ELEMENTS(good_eind)                     ;;  E = # of energy bins to use on output
avg_ener_out   = energy1d[good_eind]
;;--------------------------------------
;;  Keep only DAT.DATA satisfying BINS
;;--------------------------------------
good           = WHERE(bins,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
test           = (gd[0] GT 5) AND (bd[0] LT n_b[0] - 5L)
IF (test) THEN BEGIN
  ;;  Use only good bins
  bins           = bins
ENDIF ELSE bins = REPLICATE(1b,data[0].NBINS) ;;  Else --> use all
;;  Define normalization factor
good_bins      = WHERE(bins,count,COMPLEMENT=bad,NCOMPLEMENT=bd)
IF (gunits[0] EQ 'counts') THEN fnorm = 1 ELSE fnorm = count
;;----------------------------------------------------------------------------------------
;;  Calculate omni-directional spectra
;;----------------------------------------------------------------------------------------
spec_data      = REPLICATE(f,n_dat[0],n_e_out[0])     ;;  Omin-directional UNITS spectra
spec_ener      = REPLICATE(f,n_dat[0],n_e_out[0])     ;;  Avg. energy bin values for each structure
spec_midt      = REPLICATE(d,n_dat[0])                ;;  Unix times at center of range for each structure
;;  Calculate results
spec_midt      = (dat2.TIME + dat2.END_TIME)/2d0
spec_data      = TRANSPOSE(TOTAL(data0[good_eind,good_bins,*],2L,/NAN)/fnorm[0])
spec_ener      = TRANSPOSE(TOTAL(energy[good_eind,good_bins,*],2L,/NAN)/count[0])
;;----------------------------------------------------------------------------------------
;;  Make sure no points are outside of ERANGE
;;----------------------------------------------------------------------------------------
test           = (spec_ener GE eran[0]) AND (spec_ener LE eran[1])
good           = WHERE(test,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
test           = (bd[0] GT 0); AND (bd[0] LT (n_e_out[0]*n_dat[0] - 1L))
IF (test[0]) THEN BEGIN
  spec_data[bad] = f
  spec_ener[bad] = f
ENDIF
;;  Redefine Avg. output energy
avg_ener_out   = TOTAL(spec_ener,1,/NAN)/TOTAL(FINITE(spec_ener),1)
;;  Change 0s --> NaNs
test           = (spec_data GT 0) AND FINITE(spec_ener)
good           = WHERE(test,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
IF (bd[0] GT 0) THEN spec_data[bad] = f
;;----------------------------------------------------------------------------------------
;;  Define labels and colors for TPLOT
;;----------------------------------------------------------------------------------------
;;  Check if minimum energy > 1.5 keV
mn_avg_E       = MIN(avg_ener_out,/NAN)
test           = (mn_avg_E[0] GT 1.5e3)
IF (test[0]) THEN lab_suffx = ' keV' ELSE lab_suffx = ' eV'
IF (test[0]) THEN lab_fac   = 1d-3   ELSE lab_fac   = 1d0
avg_en_lab     = avg_ener_out*lab_fac[0]    ;;  [E]-Element array defining the energies [eV or keV] to use for labels
ener_cols      = LONARR(n_e_out[0])
ener_labs      = STRARR(n_e_out[0])
;;  Check if any entire energy bin is full of NaNs or 0's
test           = TOTAL(FINITE(spec_ener),1L,/NAN) EQ 0
bad            = WHERE(test,bd,COMPLEMENT=good,NCOMPLEMENT=gd)
test           = (gd[0] GT 0) AND (bd[0] GT 0L)
IF (test[0]) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Found bins with ALL NaNs --> Redefine outputs to exclude those bins
  ;;--------------------------------------------------------------------------------------
  n_e_out    = gd[0]
  spec_data  = TEMPORARY(spec_data[*,good])     ;;  New data array with ONLY the good bins
  spec_ener  = TEMPORARY(spec_ener[*,good])     ;;  New energy bin array with ONLY the good bins
  avg_en_lab = TEMPORARY(avg_en_lab[good])      ;;  New plot labels array with ONLY the good bins
  ener_labs  = STRTRIM(ROUND(avg_en_lab),2L)+lab_suffx[0]
  ener_cols  = LINDGEN(gd[0])*(250L - 30L)/(gd[0] - 1L) + 30L
  ;;  Want lowest(highest) energy = Red(Purple)
  ;;    --> Reverse order of colors if E[0] < E[1]
  diff              = MAX(avg_en_lab,lx,/NAN) - MIN(avg_en_lab,ln,/NAN)
  IF (lx[0] GT ln[0]) THEN ener_cols = REVERSE(ener_cols)
ENDIF ELSE BEGIN
  IF (gd[0] GT 0) THEN BEGIN
    ;;  All energy bins have finite values
    ener_labs         = STRTRIM(ROUND(avg_en_lab),2L)+lab_suffx[0]
    ener_cols         = LINDGEN(n_e_out[0])*(250L - 30L)/(n_e_out[0] - 1L) + 30L
    ;;  Want lowest(highest) energy = Red(Purple)
    ;;    --> Reverse order of colors if E[0] < E[1]
    diff              = MAX(avg_en_lab,lx,/NAN) - MIN(avg_en_lab,ln,/NAN)
    IF (lx[0] GT ln[0]) THEN ener_cols = REVERSE(ener_cols)
  ENDIF
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Estimate YRANGE for TPLOT
;;----------------------------------------------------------------------------------------
temp           = REFORM(spec_data,n_dat[0]*n_e_out[0])
yran0          = calc_log_scale_yrange(temp)
test           = (N_ELEMENTS(yran0) EQ 2)
IF (test) THEN IF (yran0[0] NE yran0[1]) THEN yran = yran0
;;----------------------------------------------------------------------------------------
;;  Define return structures
;;----------------------------------------------------------------------------------------
data_str       = {X:spec_midt,Y:spec_data,V:spec_ener}
opts_str       = {PANEL_SIZE:2.,YSTYLE:1,XMINOR:5,XTICKLEN:0.04,YTICKLEN:0.01}
IF (N_ELEMENTS(yran) EQ 2) THEN BEGIN
  dopts_str      = {YLOG:1,LABELS:ener_labs,COLORS:ener_cols,YRANGE:yran,SPEC:0,YMINOR:9L}
ENDIF ELSE BEGIN
  dopts_str      = {YLOG:1,LABELS:ener_labs,COLORS:ener_cols,SPEC:0,YMINOR:9L}
ENDELSE
;;  Add LABELS values to Default limits structure
str_element,dopts_str,'DATA_ATT.LAB_VALUES',avg_en_lab,/ADD_REPLACE
;;  Add LIMITS info if applicable
IF (SIZE(limits,/TYPE) EQ 8) THEN BEGIN
  extract_tags,dlim,dopts_str                      ;;  Get current default plot limits settings
  extract_tags,dlim,limits,/PLOT                   ;;  Get plot limits settings from LIMITS, if present
  dlim_tags = TAG_NAMES(dlim)
  extract_tags,lim,opts_str,EXCEPT_TAGS=dlim_tags  ;;  Try to avoid overlapping tags
ENDIF ELSE BEGIN
  dlim      = dopts_str
  lim       = opts_str
ENDELSE
struct         = {DATA:data_str,DLIMITS:dlim,LIMITS:lim,UNITS:gunits[0],BINS:bins,$
                  E_UNITS:lab_suffx[0],FRAME_SUFFX:f_suffx[0],AVG_ENERGY_LAB:avg_en_lab}
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,struct
END


;+
;*****************************************************************************************
;
;  PROCEDURE:   t_stacked_energy_spec_2_tplot.pro
;  PURPOSE  :   This routine calculates the omni-directional energy spectra from an
;                 input array of 3D particle velocity distributions and sends the
;                 results to TPLOT.  The results are very similar to those returned
;                 by get_spec.pro.
;
;  CALLED BY:   
;               t_stacked_ener_pad_spec_2_tplot.pro
;
;  INCLUDES:
;               calc_particle_ener_spectra.pro
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               dat_themis_esa_str_names.pro
;               calc_particle_ener_spectra.pro
;               wind_3dp_units.pro
;               str_element.pro
;               store_data.pro
;
;  REQUIRES:    
;               1)  SPEDAS IDL libraries and UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT         :  [N]-Element [structure] array of THEMIS ESA or Wind/3DP
;                                IDL data structures containing the 3D velocity
;                                distribution functions to use to create the stacked
;                                energy spectra plots
;
;  EXAMPLES:    
;               [calling sequence]
;               t_stacked_energy_spec_2_tplot, dat [,LIMITS=limits] [,UNITS=units]     $
;                                                  [,BINS=bins] [,NAME=name]           $
;                                                  [,TRANGE=trange] [,ERANGE=erange]   $
;                                                  [,/NO_TRANS] [,TPN_STRUC=tpn_struc] $
;                                                  [,_EXTRA=_extra]
;
;               [Example Usage]
;               t_stacked_energy_spec_2_tplot,dat,LIMITS=limits,UNITS=units, $
;                                                       BINS=bins,NAME=name,           $
;                                                       TRANGE=trange,ERANGE=erange,   $
;                                                       _EXTRA=ex_str
;
;  KEYWORDS:    
;               **********************************
;               ***       DIRECT  INPUTS       ***
;               **********************************
;               LIMITS      :  Scalar [structure] that may contain any combination of the
;                                following structure tags or keywords accepted by
;                                PLOT.PRO:
;                                  XLOG,   YLOG,   ZLOG,
;                                  XRANGE, YRANGE, ZRANGE,
;                                  XTITLE, YTITLE,
;                                  TITLE, POSITION, REGION, etc.
;                                  (see IDL documentation for a description)
;               UNITS       :  Scalar [string] defining the units to use for the
;                                vertical axis of the plot and the outputs YDAT and DYDAT
;                                [Default = 'flux' or number flux]
;               BINS        :  [N]-Element [byte] array defining which solid angle bins
;                                should be plotted [i.e., BINS[good] = 1b] and which
;                                bins should not be plotted [i.e., BINS[bad] = 0b].
;                                One can also define bins as an array of indices that
;                                define which solid angle bins to plot.  If this is the
;                                case, then on output, BINS will be redefined to an
;                                array of byte values specifying which bins are TRUE or
;                                FALSE.
;                                [Default:  BINS[*] = 1b]
;               NAME        :  Scalar [string] defining the TPLOT handle for the energy
;                                omni-directional spectra
;                                [Default : '??_ener_spec', ?? = 'el','eh','elb',etc.]
;               TRANGE      :  [2]-Element [double] array of Unix times specifying the
;                                time range over which to calculate spectra
;                                [Default : [MIN(DAT.TIME),MAX(DAT.END_TIME)] ]
;               ERANGE      :  [2]-Element [double] array defining the energy [eV] range
;                                over which to calculate spectra
;                                [Default : [MIN(DAT.ENERGY),MAX(DAT.ENERGY)] ]
;               NO_TRANS    :  If set, routine will not transform data into bulk flow
;                                rest frame defined by the structure tag VSW in each
;                                DAT structure (VELOCITY tag in THEMIS ESA structures
;                                will work as well so long as the THETA/PHI angles are
;                                in the same coordinate basis as VELOCITY and MAGF)
;                                [Default = FALSE]
;               _EXTRA      :  ***  Currently not in use  ***
;               **********************************
;               ***       DIRECT OUTPUTS       ***
;               **********************************
;               TPN_STRUC   :  Set to a named variable to return an IDL structure
;                                containing information relevant to the newly created
;                                TPLOT handles
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [02/01/2015   v1.0.0]
;             2)  Continued to write routine
;                                                                   [02/01/2015   v1.0.0]
;             3)  Continued to write routine
;                                                                   [02/06/2015   v1.0.0]
;             4)  Continued to write routine
;                                                                   [02/06/2015   v1.0.0]
;             5)  Continued to write routine
;                                                                   [02/11/2015   v1.0.0]
;             6)  Fixed an issue to avoid conflicting data structures
;                                                                   [11/16/2015   v1.0.1]
;             7)  Fixed an issue to avoid conflicting data structures
;                                                                   [11/24/2015   v1.0.2]
;             8)  Something was wrong with OMNI spectra calculation for SST inputs
;                                                                   [11/25/2015   v1.0.3]
;             9)  Now removes repeated energy bin values (i.e., SST does this) and
;                   cleaned up a bit and now calls test_plot_axis_range.pro
;                                                                   [11/25/2015   v1.0.4]
;            10)  Changed how Avg. energy is defined
;                                                                   [12/01/2015   v1.0.5]
;            11)  Changed how Avg. energy is defined and cleaned up a little
;                                                                   [12/02/2015   v1.0.6]
;            12)  Cleaned up and renamed from
;                   temp_create_stacked_energy_spec_2_tplot.pro to
;                   t_stacked_energy_spec_2_tplot.pro
;                                                                   [01/15/2016   v1.1.0]
;            13)  Fixed a bug where badvdf_msg and notthm_msg variables were not defined
;                                                                   [02/02/2016   v1.1.1]
;
;   NOTES:      
;               1)  See also:  get_spec.pro, get_padspecs.pro
;               2)  Future Plans:
;                   A)  improve robustness and portability
;
;  REFERENCES:  
;               1)  Carlson et al., (1983), "An instrument for rapidly measuring
;                      plasma distribution functions with high resolution,"
;                      Adv. Space Res. Vol. 2, pp. 67-70.
;               2)  Curtis et al., (1989), "On-board data analysis techniques for
;                      space plasma particle instruments," Rev. Sci. Inst. Vol. 60,
;                      pp. 372.
;               3)  Lin et al., (1995), "A Three-Dimensional Plasma and Energetic
;                      particle investigation for the Wind spacecraft," Space Sci. Rev.
;                      Vol. 71, pp. 125.
;               4)  Paschmann, G. and P.W. Daly (1998), "Analysis Methods for Multi-
;                      Spacecraft Data," ISSI Scientific Report, Noordwijk, 
;                      The Netherlands., Int. Space Sci. Inst.
;               5)  McFadden, J.P., C.W. Carlson, D. Larson, M. Ludlam, R. Abiad,
;                      B. Elliot, P. Turin, M. Marckwordt, and V. Angelopoulos
;                      "The THEMIS ESA Plasma Instrument and In-flight Calibration,"
;                      Space Sci. Rev. 141, pp. 277-302, (2008).
;               6)  McFadden, J.P., C.W. Carlson, D. Larson, J.W. Bonnell,
;                      F.S. Mozer, V. Angelopoulos, K.-H. Glassmeier, U. Auster
;                      "THEMIS ESA First Science Results and Performance Issues,"
;                      Space Sci. Rev. 141, pp. 477-508, (2008).
;               7)  Auster, H.U., K.-H. Glassmeier, W. Magnes, O. Aydogar, W. Baumjohann,
;                      D. Constantinescu, D. Fischer, K.H. Fornacon, E. Georgescu,
;                      P. Harvey, O. Hillenmaier, R. Kroth, M. Ludlam, Y. Narita,
;                      R. Nakamura, K. Okrafka, F. Plaschke, I. Richter, H. Schwarzl,
;                      B. Stoll, A. Valavanoglou, and M. Wiedemann "The THEMIS Fluxgate
;                      Magnetometer," Space Sci. Rev. 141, pp. 235-264, (2008).
;               8)  Angelopoulos, V. "The THEMIS Mission," Space Sci. Rev. 141,
;                      pp. 5-34, (2008).
;               9)  Ni, B., Y. Shprits, M. Hartinger, V. Angelopoulos, X. Gu, and
;                      D. Larson "Analysis of radiation belt energetic electron phase
;                      space density using THEMIS SST measurements: Cross‐satellite
;                      calibration and a case study," J. Geophys. Res. 116, A03208,
;                      doi:10.1029/2010JA016104, 2011.
;              10)  Turner, D.L., V. Angelopoulos, Y. Shprits, A. Kellerman, P. Cruce,
;                      and D. Larson "Radial distributions of equatorial phase space
;                      density for outer radiation belt electrons," Geophys. Res. Lett.
;                      39, L09101, doi:10.1029/2012GL051722, 2012.
;
;   CREATED:  02/01/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  02/02/2016   v1.1.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO t_stacked_energy_spec_2_tplot,dat,LIMITS=limits,UNITS=units,BINS=bins,          $
                                      NAME=name,TRANGE=trange,ERANGE=erange,        $
                                      NO_TRANS=no_trans,TPN_STRUC=tpn_struc,        $
                                      _EXTRA=ex_str

;;  Define compiler options
COMPILE_OPT IDL2
;;  Let IDL know that the following are functions
FORWARD_FUNCTION test_wind_vs_themis_esa_struct, dat_3dp_str_names,                 $
                 dat_themis_esa_str_names, calc_particle_ener_spectra, wind_3dp_units
;;****************************************************************************************
ex_start = SYSTIME(1)
;;****************************************************************************************
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
mission_logic  = [0b,0b]                ;;  Logic variable used for determining which mission is associated with DAT
def_nm_suffx   = '_ener_spec'
;;  Dummy error messages
noinpt_msg     = 'User must supply an array of velocity distribution functions as IDL structures...'
notstr_msg     = 'DAT must be an array of IDL structures...'
notvdf_msg     = 'Input must be a velocity distribution function as an IDL structure...'
badtra_msg     = 'TRANGE must be a 2-element array of Unix times and DAT must have a range of times as well...'
badera_msg     = 'ERANGE must be a 2-element array of energies [eV] and DAT.ENERGY must have a range of energies as well...'
badvdf_msg     = 'Input must be an IDL structure with similar format to Wind/3DP or THEMIS/ESA...'
not3dp_msg     = 'Input must be a velocity distribution IDL structure from Wind/3DP...'
notthm_msg     = 'Input must be a velocity distribution IDL structure from THEMIS/ESA...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 1) THEN BEGIN
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
IF (SIZE(dat,/TYPE) NE 8L OR N_ELEMENTS(dat) LT 2) THEN BEGIN
  MESSAGE,notstr_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;  Check to make sure distribution has the correct format
test0          = test_wind_vs_themis_esa_struct(dat[0],/NOM)
test           = (test0.(0) + test0.(1)) NE 1
IF (test[0]) THEN BEGIN
  MESSAGE,notvdf_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Determine instrument (i.e., ESA or 3DP) and define electric charge
;;----------------------------------------------------------------------------------------
dat0           = dat[0]
IF (test0.(0)) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Wind
  ;;--------------------------------------------------------------------------------------
  mission      = 'Wind'
  strns        = dat_3dp_str_names(dat0[0])
  IF (SIZE(strns,/TYPE) NE 8) THEN BEGIN
    ;;  Neither Wind/3DP nor THEMIS/ESA VDF
    MESSAGE,not3dp_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN
  ENDIF
  inst_nm_mode = strns.LC[0]         ;;  e.g., 'Pesa Low Burst'
ENDIF ELSE BEGIN
  IF (test0.(1)) THEN BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  THEMIS
    ;;------------------------------------------------------------------------------------
    mission      = 'THEMIS'
    strns        = dat_themis_esa_str_names(dat0[0])
    IF (SIZE(strns,/TYPE) NE 8) THEN BEGIN
      ;;  Neither Wind/3DP nor THEMIS/ESA VDF
      MESSAGE,notthm_msg[0],/INFORMATIONAL,/CONTINUE
      RETURN
    ENDIF
    temp         = strns.LC[0]                  ;;  e.g., 'IESA 3D Reduced Distribution'
    tposi        = STRPOS(temp[0],'Distribution') - 1L
    inst_nm_mode = STRMID(temp[0],0L,tposi[0])  ;;  e.g., 'IESA 3D Reduced'
  ENDIF ELSE BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Other mission?
    ;;------------------------------------------------------------------------------------
    ;;  Not handling any other missions yet
    MESSAGE,badvdf_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN
  ENDELSE
ENDELSE
mission_logic  = [(test0.(0))[0],(test0.(1))[0]]
data_str       = strns.SN[0]     ;;  e.g., 'el' for Wind EESA Low or 'peeb' for THEMIS EESA
;;----------------------------------------------------------------------------------------
;;  Define parameters relevant to structure format
;;----------------------------------------------------------------------------------------
n_dat          = N_ELEMENTS(dat)        ;;  # of data structures
n_b            = dat[0].NBINS[0]        ;;  # of solid angle bins per structure
n_e            = dat[0].NENERGY[0]      ;;  # of energy bins per structure
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check NAME
test           = (N_ELEMENTS(name) EQ 0) OR (SIZE(name,/TYPE) NE 7)
IF (test[0]) THEN name = data_str[0]+def_nm_suffx[0]
;;----------------------------------------------------------------------------------------
;;  Calculate energy spectra
;;----------------------------------------------------------------------------------------
spec_struc     = calc_particle_ener_spectra(dat,UNITS=units,BINS=bins,TRANGE=trange,$
                                            NO_TRANS=no_trans,ERANGE=erange,    $
                                            LIMITS=limits)
IF (SIZE(spec_struc,/TYPE) NE 8) THEN STOP     ;;  Debug
;;  Define variables for output
data0          = spec_struc.DATA
dlim           = spec_struc.DLIMITS
lim            = spec_struc.LIMITS
;;  Define frame of reference suffix [SWF = Bulk Flow Frame, SCF = Spacecraft Frame]
f_suffx        = spec_struc.FRAME_SUFFX                ;;  e.g., 'swf' or 'scf'
;;  Define units and values used for TPLOT labels
units_tpl      = STRTRIM(spec_struc.E_UNITS[0],2L)     ;;  units associated with AVG_ENERGY_LAB
avg_en_lab     = spec_struc.AVG_ENERGY_LAB             ;;  values used for energy labels [units defined by E_UNITS]
;;  Define YTITLE and YSUBTITLE
gunits         = spec_struc.UNITS
temp           = wind_3dp_units(gunits)
gunits         = temp.G_UNIT_NAME                      ;;  e.g. 'flux'
punits         = temp.G_UNIT_P_NAME                    ;;  e.g. ' (# cm!U-2!Ns!U-1!Nsr!U-1!NeV!U-1!N)'
ytitle         = data_str[0]+' '+gunits[0]
ysubtl         = STRMID(punits[0],1L)                  ;;  e.g. '(# cm!U-2!Ns!U-1!Nsr!U-1!NeV!U-1!N)'
str_element,dlim,   'YTITLE',ytitle[0],/ADD_REPLACE
str_element,dlim,'YSUBTITLE',ysubtl[0],/ADD_REPLACE
;;  Define TPLOT handle  [e.g., 'elspec_raw_swf_omni_flux']
tpn_mid        = f_suffx[0]+'_omni'
out_name       = name[0]+'_'+tpn_mid[0]+'_'+gunits[0]  ;;  e.g., 'el_ener_spec_swf_omni_flux'
;;----------------------------------------------------------------------------------------
;;  Send results to TPLOT
;;----------------------------------------------------------------------------------------
store_data,out_name[0],DATA=data0,DLIM=dlim,LIM=lim
;;  Add to TPN_STRUC
str_element,tpn_struc,  'OMNI.SPEC_FRAME_OF_REF',  f_suffx[0],/ADD_REPLACE
str_element,tpn_struc,    'OMNI.SPEC_TPLOT_NAME', out_name[0],/ADD_REPLACE
str_element,tpn_struc,  'OMNI.SPEC_ENERGY_UNITS',units_tpl[0],/ADD_REPLACE
str_element,tpn_struc,'OMNI.SPEC_ENERGY_LABVALS',  avg_en_lab,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------
;;****************************************************************************************
ex_time = SYSTIME(1) - ex_start
MESSAGE,STRING(ex_time)+' seconds execution time.',/cont,/info
;;****************************************************************************************

RETURN
END

