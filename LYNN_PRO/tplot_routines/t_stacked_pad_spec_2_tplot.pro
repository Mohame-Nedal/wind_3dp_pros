;*****************************************************************************************
;
;  FUNCTION :   calc_particle__pad_spectra.pro
;  PURPOSE  :   This routine calculates the pitch-angle distributions (PADs) from an
;                 input array of 3D particle velocity distributions.  The results are
;                 very similar to those returned by get_padspecs.pro.
;
;  CALLED BY:   
;               t_stacked_pad_spec_2_tplot.pro
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               dat_themis_esa_str_names.pro
;               str_element.pro
;               is_a_3_vector.pro
;               wind_3dp_units.pro
;               is_a_number.pro
;               get_valid_trange.pro
;               format_esa_bins_keyword.pro
;               transform_vframe_3d_array.pro
;               test_plot_axis_range.pro
;               conv_units.pro     **  Only UMN/3DP version can handle arrays ** [SPEDAS version should now too]
;               pad.pro
;               themis_esa_pad.pro
;               themis_sst_pad.pro
;               calc_log_scale_yrange.pro
;               extract_tags.pro
;
;  REQUIRES:    
;               1)  SPEDAS IDL libraries and UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT         :  [N]-Element [structure] array of THEMIS ESA or Wind/3DP
;                                IDL data structures containing the 3D velocity
;                                distribution functions to use to create the stacked
;                                energy spectra as pitch-angle distributions
;
;  EXAMPLES:    
;               [calling sequence]
;               test = calc_particle__pad_spectra(dat [,UNITS=units] [,BINS=bins]   $
;                                                 [,TRANGE=trange] [,ERANGE=erange] $
;                                                 [,NUM_PA=num_pa] [,LIMITS=limits] $
;                                                 [,/NO_TRANS])
;
;               [Example Usage]
;               test = calc_particle__pad_spectra(dat,UNITS='eflux',BINS=bins,NUM_PA=9L)
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
;               NUM_PA      :  Scalar [integer] that defines the number of pitch-angle
;                                bins to calculate for the resulting distribution
;                                [Default = 8]
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
;                                                                   [02/10/2015   v1.0.0]
;             2)  Continued to write routine
;                                                                   [02/11/2015   v1.0.0]
;             3)  Fixed an issue with missing tags in data structures expected by
;                   themis_esa_pad.pro
;                                                                   [11/24/2015   v1.0.1]
;             4)  Now removes repeated energy bin values (i.e., SST does this) and
;                   cleaned up a bit and now calls test_plot_axis_range.pro
;                                                                   [11/25/2015   v1.0.2]
;             5)  Fixed an issue that only seemed to affect IESA structures causing all
;                   resulting PADs to be zeros or NaNs
;                                                                   [11/30/2015   v1.0.3]
;             6)  Changed how Avg. energy is defined
;                                                                   [12/01/2015   v1.0.4]
;             7)  Changed how Avg. energy is defined and cleaned up a little
;                                                                   [12/02/2015   v1.0.5]
;             8)  Fixed an issue with implementation of ERANGE keyword
;                                                                   [01/07/2016   v1.0.6]
;             9)  Cleaned up and renamed from
;                   temp_calc_pad_spect.pro to calc_particle__pad_spectra.pro and
;                   now calls is_a_number.pro, get_valid_trange.pro,
;                   is_a_3_vector.pro
;                                                                   [01/15/2016   v1.1.0]
;            10)  Fixed a bug where badvdf_msg and notthm_msg variables were not defined
;                                                                   [02/02/2016   v1.1.1]
;            11)  Fixed an issue that occurs if no data are found preventing a dummy
;                   array from being filled in the event of no finite pitch-angles
;                                                                   [05/26/2016   v1.1.2]
;
;   NOTES:      
;               0)  ***  User should not call this routine directly  ***
;               1)  See also:  get_spec.pro, get_padspecs.pro, calc_padspecs.pro
;               2)  The following structure tags must be defined in DAT
;                     MAGF, (VSW or VELOCITY), and {usual 3DP and ESA tags}
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
;   CREATED:  02/06/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  05/26/2016   v1.1.2
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION calc_particle__pad_spectra,dat,UNITS=units,BINS=bins,TRANGE=trange,ERANGE=erange,$
                                 NUM_PA=num_pa,LIMITS=limits,NO_TRANS=no_trans

;;  Define compiler options
COMPILE_OPT IDL2
;;  Let IDL know that the following are functions
FORWARD_FUNCTION test_wind_vs_themis_esa_struct, dat_3dp_str_names,                   $
                 dat_themis_esa_str_names, wind_3dp_units, format_esa_bins_keyword,   $
                 conv_units, pad, themis_esa_pad, calc_log_scale_yrange,              $
                 is_a_number, get_valid_trange, is_a_3_vector, transform_vframe_3d_array
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
mission_logic  = [0b,0b]                ;;  Logic variable used for determining which mission is associated with DAT
thm_sst_on     = 0b
dt_arr_on      = 0b
dead_on        = 0b
;;  Dummy error messages
noinpt_msg     = 'User must supply an array of velocity distribution functions as IDL structures...'
notstr_msg     = 'DAT must be an array of IDL structures...'
notvdf_msg     = 'Input must be a velocity distribution function as an IDL structure...'
badtra_msg     = 'TRANGE must be a 2-element array of Unix times and DAT must have a range of times as well...'
badera_msg     = 'ERANGE must be a 2-element array of energies [eV] and DAT.ENERGY must have a range of energies as well...'
badmag_msg     = 'DAT structure must have MAGF tag defined as a 3 element vector of cartesian magnetic field components'
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
;;  Determine instrument (i.e., ESA or 3DP) and define electric charge
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
    RETURN,0b
  ENDIF
  inst_nm_mode = strns.LC[0]         ;;  e.g., 'Pesa Low Burst'
  pad_func     = 'pad'               ;;  pad.pro routine to be called for Wind/3DP distributions
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
      RETURN,0b
    ENDIF
    temp         = strns.LC[0]                  ;;  e.g., 'IESA 3D Reduced Distribution'
    tposi        = STRPOS(temp[0],'Distribution') - 1L
    inst_nm_mode = STRMID(temp[0],0L,tposi[0])  ;;  e.g., 'IESA 3D Reduced'
    pad_func     = 'themis_esa_pad'             ;;  themis_esa_pad.pro routine to be called for THEMIS/ESA distributions
    shnme        = STRLOWCASE(STRMID(strns.SN[0],0L,2L))
    CASE shnme[0] OF
      'ps'  :  BEGIN
        pad_func       = 'themis_sst_pad'             ;;  themis_sst_pad.pro routine to be called for THEMIS/SST distributions
        thm_sst_on     = 1b
        dt_arr_on      = (N_ELEMENTS(dt_arr) EQ N_ELEMENTS(dat0[0].DATA))
        dead_on        = (N_ELEMENTS(deadt)  EQ N_ELEMENTS(dat0[0].DATA))
      END
      ELSE  :  ;;  Do nothing
    ENDCASE
  ENDIF ELSE BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Other mission?
    ;;------------------------------------------------------------------------------------
    ;;  Not handling any other missions yet
    MESSAGE,badvdf_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN,0b
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
;;  Check for MAGF and make sure it has valid values
str_element,dat0,'MAGF',magf
test           = (is_a_3_vector(magf,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  MESSAGE,'TAG:  '+badmag_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
magf           = dat.MAGF
test           = (TOTAL(FINITE(magf)) EQ 0) OR (TOTAL(ABS(magf)) EQ 0)
IF (test[0]) THEN BEGIN
  MESSAGE,'FINITE:  '+badmag_msg,/INFORMATIONAL,/CONTINUE
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
;;  Default energy range [eV]
;;    --> Need the extra ±1% to prevent averaging from removing energy bins if user
;;        in case user did not set ERANGE
def_eran       = [MIN(ener0,/NAN),MAX(ener0,/NAN)]*[0.99,1.01]
IF (test[0]) THEN eran = def_eran ELSE eran = [MIN(erange),MAX(erange)]
test           = (eran[0] EQ eran[1]) AND (def_eran[0] EQ def_eran[1])
IF (test[0]) THEN BEGIN
  ;;  No valid energies available
  MESSAGE,badera_msg[0],/INFORMATIONAL,/CONTINUE
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
  ;;  No valid data available
  MESSAGE,badtra_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Check BINS
bstr           = format_esa_bins_keyword(dat,BINS=bins)
test           = (SIZE(bstr,/TYPE) NE 8)
IF (test[0]) THEN STOP     ;;  Debug --> something is wrong
;;  Check NUM_PA
test           = (N_ELEMENTS(num_pa) EQ 0) OR (is_a_number(num_pa,/NOMSSG) EQ 0)
IF (test[0]) THEN n_pa = 8L ELSE n_pa = num_pa[0]
;;  Check NO_TRANS
test           = ~KEYWORD_SET(no_trans)
IF (test[0]) THEN BEGIN
  ;;  User wants to transform into bulk flow rest frame
  ;;    --> Need the VSW (or VELOCITY) structure tag
  str_element,dat0,'VSW',vsw
  test           = is_a_3_vector(vsw,/NOMSSG)
  IF (test[0] EQ 0) THEN str_element,dat0,'VELOCITY',vsw
  test           = is_a_3_vector(vsw,/NOMSSG)
  IF (test[0] EQ 0) THEN BEGIN
    MESSAGE,'TAG:  '+badvsw_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN,0b
  ENDIF
  ;;  At least one of them is set  -->  Determine which one
  alltags        = STRLOWCASE(TAG_NAMES(dat[0]))
  good0          = WHERE(alltags EQ 'vsw',gd0)
  good1          = WHERE(alltags EQ 'velocity',gd1)
  test           = (gd0 GT 0)
  IF (test[0]) THEN vsw = dat.(good0[0]) ELSE vsw = dat.(good1[0])
  test           = (TOTAL(FINITE(vsw)) EQ 0) OR (TOTAL(ABS(vsw)) EQ 0)
  IF (test[0]) THEN BEGIN
    MESSAGE,'FINITE:  '+badvsw_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN,0b
  ENDIF
  ;;  Set transformation logic
  yes_trans = 1
ENDIF ELSE yes_trans = 0
IF (yes_trans[0]) THEN f_suffx = 'swf' ELSE f_suffx = 'scf'
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
  ;;  Define transformation velocities
  test           = (gd0 GT 0)
  IF (test[0]) THEN vsw = TRANSPOSE(dat20.(good0[0])) ELSE vsw = TRANSPOSE(dat20.(good1[0]))
  dat2 = transform_vframe_3d_array(dat20,vsw)
ENDIF ELSE dat2 = dat20
;;  Clean up
dat20          = 0
;;----------------------------------------------------------------------------------------
;;  Check for repeated energy bin values
;;----------------------------------------------------------------------------------------
;;  Redefine # of structures and data
;;    E = # of energy bins per structure
;;    A = # solid angle bins per energy per structure
;;    D = # of structures
energy         = dat2.ENERGY            ;;  [E,A,D]-Element array of energy bin midpoint values [eV]
data0          = dat2.DATA              ;;  [E,A,D]-Element array of data values [UNITS]
denergy        = dat2.DENERGY           ;;  [E,A,D]-Element array of energy bin ranges [eV]
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
;;  Keep DAT.ENERGY within ERANGE
;;----------------------------------------------------------------------------------------
ener1          = REPLICATE(0e0,n_e[0])
FOR j=0L, n_e[0] - 1L DO BEGIN
  ener0   = REFORM(dat2.ENERGY[j,*])        ;;  [A,N]-Element array
  good_e0 = WHERE(FINITE(ener0) AND ener0 GT 0,gd_e0)
  IF (gd_e0 GT 0) THEN BEGIN
    mede0    = MEDIAN(ener0[good_e0])
    ener1[j] = mede0[0]
  ENDIF
ENDFOR
test           = (ener1 GE eran[0]) AND (ener1 LE eran[1])
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
n_dat          = N_ELEMENTS(dat2)                          ;;  # of data structures
n_e_out        = N_ELEMENTS(good_eind)                     ;;  # of energy bins to use on output
pad_time       = REPLICATE(d,n_dat[0])                     ;;  Unix times associated with each PAD
pad_data       = REPLICATE(f,n_dat[0],n_e_out[0],n_pa[0])  ;;  PAD data array [UNITS]
pad_ener       = REPLICATE(f,n_dat[0],n_e_out[0])          ;;  PAD energy bin array [eV]
pad_pang       = REPLICATE(f,n_dat[0],n_pa[0])             ;;  PAD pitch-angle bin array [degrees]
dumb           = REPLICATE(f,n_e_out[0],n_pa[0])           ;;  Dummy array to sue in event of "bad" data
;;  Test pitch-angle range
pa_range       = REPLICATE(f,n_dat[0],2L)
;;----------------------------------------------------------------------------------------
;;  Calculate pitch-angle distributions (PADs)
;;----------------------------------------------------------------------------------------
FOR i=0L, n_dat[0] - 1L DO BEGIN
  tdat          = dat2[i]
  ;;--------------------------------------------------------------------------------------
  ;;  Convert to user defined units
  ;;--------------------------------------------------------------------------------------
  tdat          = conv_units(tdat[0],gunits[0])
  ;;--------------------------------------------------------------------------------------
  ;;  Calculate PAD
  ;;--------------------------------------------------------------------------------------
  ;;  ** think about SPIKES keyword for EESA High if bad bins don't work **
  pad0          = CALL_FUNCTION(pad_func[0],tdat,NUM_PA=n_pa[0],BINS=bins)
  test          = (SIZE(pad0,/TYPE) NE 8)
  IF (test[0]) THEN CONTINUE       ;;  Non-structure format return --> skip this index
  test          = (pad0[0].VALID EQ 1)
;  IF (test[0]) THEN temp_dat      = REFORM(pad0[0].DATA) ;;  [E,A]-Element array
  IF (test[0]) THEN temp_dat = REFORM(pad0[0].DATA) ELSE temp_dat = dumb
  ;;  Test pitch-angle range
  paran0        = [MIN(pad0[0].ANGLES,/NAN),MAX(pad0[0].ANGLES,/NAN)]
  testa         = [(paran0[0] GT 0) AND FINITE(paran0[0]),(paran0[1] GT 0) AND FINITE(paran0[1])]
  FOR k=0L, 1L DO IF (testa[k]) THEN pa_range[i,k] = paran0[k]
  ;;--------------------------------------------------------------------------------------
  ;;  Average energies over PAs and PAs over energies
  ;;--------------------------------------------------------------------------------------
  ;;  pad0.ANGLES = [E,A]-Element array
  count_pa      = TOTAL(FINITE(pad0[0].ANGLES[good_eind,*]),2,/NAN)   ;;  [E]-Element array = # of finite PAs
  count_en      = TOTAL(FINITE(pad0[0].ENERGY[good_eind,*]),1,/NAN)   ;;  [A]-Element array = # of finite energies
  temp__en      = TOTAL(pad0[0].ENERGY[good_eind,*],2,/NAN)/count_pa  ;;  sum energy bins over PAs  = [E]-Element array = Avg. Energy bin values [eV]
  temp__pa      = TOTAL(pad0[0].ANGLES[good_eind,*],1,/NAN)/count_en  ;;  sum PA bins over energies = [A]-Element array = Avg. PA bin values [deg]
  ;;--------------------------------------------------------------------------------------
  ;;  Define PAD params
  ;;--------------------------------------------------------------------------------------
  pad_time[i]     = (tdat[0].TIME + tdat[0].END_TIME)/2d0
  pad_ener[i,*]   = temp__en
  pad_pang[i,*]   = temp__pa
  pad_data[i,*,*] = temp_dat[good_eind,*]
  ;;  --> Next iteration
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Make sure no points are outside of ERANGE
;;----------------------------------------------------------------------------------------
pad3den        = REPLICATE(f,n_dat[0],n_e_out[0],n_pa[0])
FOR pp=0L, n_pa[0] - 1L DO pad3den[*,*,pp] = pad_ener
test           = (pad3den GE eran[0]) AND (pad3den LE eran[1])
good_en        = WHERE(test,gd_en,COMPLEMENT=bad_en,NCOMPLEMENT=bd_en)
test           = (bd_en[0] GT 0)
IF (test[0]) THEN BEGIN
  pad_data[bad_en]  = f
ENDIF
test           = (pad_ener GE eran[0]) AND (pad_ener LE eran[1])
good_en        = WHERE(test,gd_en,COMPLEMENT=bad_en,NCOMPLEMENT=bd_en)
test           = (bd_en[0] GT 0)
IF (test[0]) THEN pad_ener[bad_en] = f
;;----------------------------------------------------------------------------------------
;;  Remove NaNs in PAs if possible
;;----------------------------------------------------------------------------------------
test           = (pad_pang LE 0) OR (pad_pang GT 180) OR (FINITE(pad_pang) EQ 0)
bad_pa         = WHERE(test,bd_pa,COMPLEMENT=good_pa,NCOMPLEMENT=gd_pa)
IF (bd_pa GT 0) THEN BEGIN
  ;;  Try using the average PAs from all structures to fill bad PA bins
  count_pa      = TOTAL(FINITE(pad_pang),1,/NAN)  ;;  # of finite PAs
  temp__pa      = TOTAL(pad_pang,1,/NAN)/count_pa
  bind          = ARRAY_INDICES(pad_pang,bad_pa)
  new_angs      = REPLICATE(1e0,n_dat[0]) # temp__pa
  ;;  Redefine "bad" PAs to averages
  pad_pang[bind[0,*],bind[1,*]] = new_angs[bind[0,*],bind[1,*]]
ENDIF
;;  Redefine Avg. output energy
avg_ener_out   = TOTAL(pad_ener,1,/NAN)/TOTAL(FINITE(pad_ener),1)
;;----------------------------------------------------------------------------------------
;;  Define labels and colors for TPLOT
;;----------------------------------------------------------------------------------------
;;  Check if minimum energy > 1.5 keV
mn_avg_E       = MIN(avg_ener_out,/NAN)
test           = (mn_avg_E[0] GT 1.5e3)
IF (test[0]) THEN lab_suffx = ' keV' ELSE lab_suffx = ' eV'
IF (test[0]) THEN lab_fac   = 1d-3   ELSE lab_fac   = 1d0
avg_en_lab     = avg_ener_out*lab_fac[0]
ener_cols      = LONARR(n_e_out[0])
ener_labs      = STRARR(n_e_out[0])
;;  Check if any entire energy bin is full of NaNs or 0's
tenperc        = 1e-1*n_dat[0]*n_pa[0]                          ;;  10% of all times
test0          = (TOTAL(FINITE(pad_ener),1L,/NAN) EQ 0)
test1          = (TOTAL(TOTAL(FINITE(pad_data),3L,/NAN),1L,/NAN) LE tenperc[0])
test           = test0 OR test1
bad            = WHERE(test,bd,COMPLEMENT=good,NCOMPLEMENT=gd)
test           = (gd[0] GT 0) AND (bd[0] GT 0L)
IF (test[0]) THEN BEGIN
  ;;  Redefine values
  n_e_out    = gd[0]
  pad_data   = TEMPORARY(pad_data[*,good,*])
  pad_ener   = TEMPORARY(pad_ener[*,good])
  pad_pang   = TEMPORARY(pad_pang)
  avg_en_lab = TEMPORARY(avg_en_lab[good])
  ;;  Want lowest(highest) energy = Red(Purple)
  ;;    --> Reverse order of colors if E[0] < E[1]
  ener_labs = STRTRIM(ROUND(avg_en_lab),2L)+lab_suffx[0]
  ener_cols = LINDGEN(gd[0])*(250L - 30L)/(gd[0] - 1L) + 30L
  diff      = MAX(avg_en_lab,lx,/NAN) - MIN(avg_en_lab,ln,/NAN)
  IF (lx[0] GT ln[0]) THEN ener_cols = REVERSE(ener_cols)
ENDIF ELSE BEGIN
  IF (gd[0] GT 0) THEN BEGIN
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
temp0          = REFORM(pad_data[*,[0L,(n_e_out[0] - 1L)],*])
temp           = REFORM(temp0,N_ELEMENTS(temp0))
yran0          = calc_log_scale_yrange(temp)
test           = (N_ELEMENTS(yran0) EQ 2)
IF (test[0]) THEN IF (yran0[0] NE yran0[1]) THEN yran = yran0
;;----------------------------------------------------------------------------------------
;;  Define return structures
;;----------------------------------------------------------------------------------------
data_str       = {X:pad_time,Y:pad_data,V1:pad_ener,V2:pad_pang}
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
;  PROCEDURE:   t_stacked_pad_spec_2_tplot.pro
;  PURPOSE  :   This routine calculates a pitch-angle distribution (PAD) energy spectra
;                 from an input array of 3D particle velocity distributions and sends
;                 the results to TPLOT.  The results are very similar to those returned
;                 by get_padspecs.pro.
;
;  CALLED BY:   
;               t_stacked_ener_pad_spec_2_tplot.pro
;
;  INCLUDES:
;               calc_particle__pad_spectra.pro
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               dat_themis_esa_str_names.pro
;               calc_particle__pad_spectra.pro
;               wind_3dp_units.pro
;               str_element.pro
;               store_data.pro
;               reduce_pads.pro
;               tnames.pro
;               options.pro
;               get_data.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT         :  [N]-Element [structure] array of THEMIS ESA or Wind/3DP
;                                IDL data structures containing the 3D velocity
;                                distribution functions to use to create the stacked
;                                PAD energy spectra plots
;
;  EXAMPLES:    
;               [calling sequence]
;               t_stacked_pad_spec_2_tplot,dat [,LIMITS=limits] [,UNITS=units]     $
;                                              [,BINS=bins] [,NAME=name]           $
;                                              [,TRANGE=trange] [,ERANGE=erange]   $
;                                              [,NUM_PA=num_pa] [,/NO_TRANS]       $
;                                              [,TPN_STRUC=tpn_struc]
;
;               [Example Usage]
;               t_stacked_pad_spec_2_tplot,dat,LIMITS=limits,UNITS=units,        $
;                                              BINS=bins,NAME=name,TRANGE=trange,$
;                                              ERANGE=erange,NUM_PA=num_pa,      $
;                                              NO_TRANS=no_trans
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
;               NUM_PA      :  Scalar [integer] that defines the number of pitch-angle
;                                bins to calculate for the resulting distribution
;                                [Default = 8]
;               NO_TRANS    :  If set, routine will not transform data into bulk flow
;                                rest frame defined by the structure tag VSW in each
;                                DAT structure (VELOCITY tag in THEMIS ESA structures
;                                will work as well so long as the THETA/PHI angles are
;                                in the same coordinate basis as VELOCITY and MAGF)
;                                [Default = FALSE]
;               **********************************
;               ***       DIRECT OUTPUTS       ***
;               **********************************
;               TPN_STRUC   :  Set to a named variable to return an IDL structure
;                                containing information relevant to the newly created
;                                TPLOT handles
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [02/10/2015   v1.0.0]
;             2)  Continued to write routine
;                                                                   [02/11/2015   v1.0.0]
;             3)  Fixed an issue with missing tags in data structures expected by
;                   themis_esa_pad.pro
;                                                                   [11/24/2015   v1.0.1]
;             4)  Now removes repeated energy bin values (i.e., SST does this) and
;                   cleaned up a bit and now calls test_plot_axis_range.pro
;                                                                   [11/25/2015   v1.0.2]
;             5)  Fixed an issue that only seemed to affect IESA structures causing all
;                   resulting PADs to be zeros or NaNs
;                                                                   [11/30/2015   v1.0.3]
;             6)  Changed how Avg. energy is defined
;                                                                   [12/01/2015   v1.0.4]
;             7)  Changed how Avg. energy is defined and cleaned up a little
;                                                                   [12/02/2015   v1.0.5]
;             8)  Fixed an issue with implementation of ERANGE keyword
;                                                                   [01/07/2016   v1.0.6]
;             9)  Cleaned up and renamed from
;                   temp_create_stacked_pad_spec_2_tplot.pro to
;                   t_stacked_pad_spec_2_tplot.pro
;                                                                   [01/15/2016   v1.1.0]
;            10)  Fixed a bug where badvdf_msg and notthm_msg variables were not defined
;                                                                   [02/02/2016   v1.1.1]
;            11)  Fixed an issue that occurs if no data are found preventing a dummy
;                   array from being filled in the event of no finite pitch-angles
;                                                                   [05/26/2016   v1.1.2]
;
;   NOTES:      
;               1)  See also:  get_spec.pro, get_padspecs.pro, and calc_padspecs.pro
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
;   CREATED:  02/06/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  05/26/2016   v1.1.2
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO t_stacked_pad_spec_2_tplot,dat,LIMITS=limits,UNITS=units,BINS=bins,    $
                                   NAME=name,TRANGE=trange,ERANGE=erange,  $
                                   NUM_PA=num_pa,NO_TRANS=no_trans,        $
                                   TPN_STRUC=tpn_struc

;;  Define compiler options
COMPILE_OPT IDL2
;;  Let IDL know that the following are functions
FORWARD_FUNCTION test_wind_vs_themis_esa_struct, dat_3dp_str_names,                 $
                 dat_themis_esa_str_names, calc_particle__pad_spectra, wind_3dp_units
;;****************************************************************************************
ex_start       = SYSTIME(1)
;;****************************************************************************************
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
mission_logic  = [0b,0b]                ;;  Logic variable used for determining which mission is associated with DAT
def_nm_suffx   = '_pad_spec'
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
;;  Determine instrument (i.e., ESA or 3DP) and define electric charge
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
;;  Calculate pitch-angle distributin (PAD) spectra
;;----------------------------------------------------------------------------------------
spec_struc     = calc_particle__pad_spectra(dat,UNITS=units,BINS=bins,TRANGE=trange,  $
                                            ERANGE=erange,NUM_PA=num_pa,              $
                                            NO_TRANS=no_trans,LIMITS=limits)
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
;;  Define units for TPLOT handle and YSUBTITLE
gunits         = spec_struc.UNITS
temp           = wind_3dp_units(gunits)
gunits         = temp.G_UNIT_NAME                      ;;  e.g. 'flux'
punits         = temp.G_UNIT_P_NAME                    ;;  e.g. ' (# cm!U-2!Ns!U-1!Nsr!U-1!NeV!U-1!N)'
;;  Define YTITLE and YSUBTITLE
ytitle         = data_str[0]+' '+gunits[0]
ysubtl         = STRMID(punits[0],1L)                  ;;  e.g. '(# cm!U-2!Ns!U-1!Nsr!U-1!NeV!U-1!N)'
str_element,dlim,   'YTITLE',ytitle[0],/ADD_REPLACE
str_element,dlim,'YSUBTITLE',ysubtl[0],/ADD_REPLACE
str_element,dlim,'LABFLAG',1,/ADD_REPLACE
;;  Define TPLOT handle  [e.g., 'elspec_raw_swf_flux']
out_name       = name[0]+'_'+f_suffx[0]+'_'+gunits[0]  ;;  e.g., 'el_pad_spec_swf_flux'
;;----------------------------------------------------------------------------------------
;;  Send results to TPLOT
;;----------------------------------------------------------------------------------------
store_data,out_name[0],DATA=data0,DLIM=dlim,LIM=lim
;;  Add to TPN_STRUC
str_element,tpn_struc,  'PAD.SPEC_FRAME_OF_REF',  f_suffx[0],/ADD_REPLACE
str_element,tpn_struc,    'PAD.SPEC_TPLOT_NAME', out_name[0],/ADD_REPLACE
str_element,tpn_struc,  'PAD.SPEC_ENERGY_UNITS',units_tpl[0],/ADD_REPLACE
str_element,tpn_struc,'PAD.SPEC_ENERGY_LABVALS',  avg_en_lab,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Separate PADs and send results to TPLOT
;;----------------------------------------------------------------------------------------
n_pa           = N_ELEMENTS(data0.V2[0,*])    ;;  # of PAs
;;  Determine the energy units
;;    0 =  eV  [Default]
;;    1 = keV
;;    2 = MeV
test           = (STRLOWCASE(units_tpl[0]) EQ ['','k','m']+'ev')
e_units        = ((WHERE(test))[0] > 0) < 2
newna          = out_name[0]
ang            = FLTARR(2,n_pa[0] - 1L)
FOR i=0L, n_pa[0] - 2L DO BEGIN
  j        = i[0] + 1L
  pang     = FLTARR(2)
  reduce_pads,newna[0],2L,i[0],j[0],ANGLES=pang,/NAN
  ang[*,i] = (pang > 0e0) < 180e0
ENDFOR
;;  Add to TPN_STRUC
str_element,tpn_struc,         'PAD.PAD_ANGLES',         ang,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Fix TPLOT options
;;----------------------------------------------------------------------------------------
;;  Fix colors and energy bin labels
new_tpn        = tnames(newna[0]+'-2-*')
options,new_tpn,COLORS=dlim.COLORS,LABELS=dlim.LABELS,/DEF
options,new_tpn,'COLORS'
options,new_tpn,'LABELS'
;;  Fix YRANGE, YMINOR, and YSTYLE
str_element,dlim,   'YRANGE',yran00
options,new_tpn,'YRANGE'
options,new_tpn,'YMINOR'
options,new_tpn,'YSTYLE'
test           = (N_ELEMENTS(yran00) EQ 2)
IF (test[0]) THEN yran11 = yran00 ELSE yran11 = [0,0]
test           = (yran11[0] NE yran11[1])
IF (test[0]) THEN options,new_tpn,'YRANGE',yran11,/DEF
options,new_tpn,YMINOR=9L,/YSTYLE,/DEF
;;  Fix YTITLEs
FOR i=0L, N_ELEMENTS(new_tpn) - 1L DO BEGIN
  get_data,new_tpn[i],DATA=temp00,DLIM=dlim00,LIM=lim00
  pang     = STRTRIM(STRING(REFORM(ang[*,i]),FORMAT='(I)'),2L)
  yttl00   = pang[0]+'-'+pang[1]
  new_yttl = ytitle[0]+' ['+yttl00[0]+']'
  str_element,dlim00,   'YTITLE',new_yttl[0],/ADD_REPLACE
  str_element,dlim00,'YSUBTITLE',  ysubtl[0],/ADD_REPLACE
  ;;  Send back to TPLOT
  store_data,new_tpn[i],DATA=temp00,DLIM=dlim00,LIM=lim00
ENDFOR
;;  Add to TPN_STRUC
str_element,tpn_struc,    'PAD.PAD_TPLOT_NAMES',     new_tpn,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------
;;****************************************************************************************
ex_time        = SYSTIME(1) - ex_start[0]
MESSAGE,STRING(ex_time[0])+' seconds execution time.',/INFORMATIONAL,/CONTINUE
;;****************************************************************************************

RETURN
END

