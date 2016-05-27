;*****************************************************************************************
;
;  FUNCTION :   evdf_fits_init_limits_str.pro
;  PURPOSE  :   This routine initializes the LIMITS structure and formats the data to
;                 be fitted in the wrapping routines.
;
;  CALLED BY:   
;               wrapper_evdf_fits_para_perp_anti.pro
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               dat_themis_esa_str_names.pro
;               str_element.pro
;               routine_version.pro
;               time_string.pro
;               time_range_define.pro
;               wind_3dp_units.pro
;               trange_str.pro
;               conv_units.pro
;               moments_3d_new.pro
;               transform_vframe_3d.pro
;               lbw_spec3d.pro
;               log10_tickmarks.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DATA       :  Scalar [structure] associated with a known THEMIS ESA
;                               data structure [see get_th?_peib.pro, ? = a-f]
;                               or a Wind/3DP data structure
;                               [see get_?.pro, ? = el, elb, pl, ph, eh, etc.]
;
;  EXAMPLES:    
;               temp = evdf_fits_init_limits_str(data,_EXTRA=ex_str)
;
;  KEYWORDS:    
;               **********************************
;               ***       DIRECT  INPUTS       ***
;               **********************************
;               LIMITS     :  Scalar [structure] that may contain any combination of the
;                               following structure tags or keywords accepted by
;                               PLOT.PRO:
;                                 XLOG,   YLOG,   ZLOG,
;                                 XRANGE, YRANGE, ZRANGE,
;                                 XTITLE, YTITLE,
;                                 TITLE, POSITION, REGION, etc.
;                                 (see IDL documentation for a description)
;               PARAM      :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see FIT_FUNC below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = D
;               FIT_FUNC   :  Scalar [integer] specifying the type of function to use
;                               [Default  :  1]
;                               1  :  Y = A X^(B) + C
;                               2  :  Y = A e^(B X) + C
;                               3  :  Y = A + B Log_{e} |X^C|
;                               4  :  Y = A X^(B) e^(C X) + D
;                               5  :  Y = A B^(X) + C
;                               6  :  Y = A B^(C X) + D
;                               7  :  Y = ( A + B X )^(-1)
;                               8  :  Y = ( A B^(X) + C )^(-1)
;                               9  :  Y = A X^(B) ( e^(C X) + D )^(-1)
;                              10  :  Y = A + B Log_{10} |X| + C (Log_{10} |X|)^2
;                              11  :  Y = A X^(B) e^(C X) e^(D X)
;               FIXED_P    :  [4]-Element array containing zeros for each element of
;                               PARAM the user does NOT wish to vary (i.e., if FIXED_P[0]
;                               is = 0, then PARAM[0] will not change when calling
;                               MPFITFUN.PRO).
;                               [Default  :  FIXED_P[*] = 1]
;               A_RANGE    :  [4]-Element [float/double] array defining the range of
;                               allowed values to use for A or PARAM[0].  Note, if this
;                               keyword is set, it is equivalent to telling the routine
;                               that A should be limited by these bounds.  Setting this
;                               keyword will define:
;                                 PARINFO[0].LIMITED[*] = BYTE(A_RANGE[0:1])
;                                 PARINFO[0].LIMITS[*]  = A_RANGE[2:3]
;                               [Default  :  [not set] ]
;               B_RANGE    :  Same as A_RANGE but for B or PARAM[1], PARINFO[1].
;               C_RANGE    :  Same as A_RANGE but for C or PARAM[2], PARINFO[2].
;               D_RANGE    :  Same as A_RANGE but for D or PARAM[3], PARINFO[3].
;               E_RANGE    :  [2]-Element [float/double] array defining the range of
;                               energies [eV] over which data will be allowed in fit
;                               [Default  :  [30,15000] ]
;               EO_RA      :  [2]-Element [float/double] array defining the range of
;                               e-folding energies [eV] relevant to model fit functions
;                               2, 4, and 9
;                               [Default  :  [10,1000] ]
;               ERA_1C_SC  :  If set, routine defines the range of viable energies to
;                               allow in fitting by cutting off the lower bound at the
;                               spacecraft potential and the upper bound at the point
;                               where the data falls within a factor of 2 of the
;                               one-count level
;                               [Default  :  FALSE ]
;               PA_BIN_WD  :  Scalar [float/double] defining the angular width [degrees]
;                               over which to average for each fit direction
;                               [Default  :  20 ]
;               SC_FRAME   :  If set, routine will fit the data in the spacecraft frame
;                               of reference rather than the eVDF's bulk flow frame
;                               [Default  :  FALSE ]
;               FILE_DIR   :  Scalar [string] defining the directory in which to place
;                               output fit plot results
;                               [Default  :  FILE_EXPAND_PATH('') ]
;               VERSION    :  Scalar [string or integer] defining whether [TRUE] or not
;                               [FALSE] to output the current routine version and date
;                               to be placed on outside of lower-right-hand corner.
;                               If a string is supplied, the string is output.  If TRUE
;                               is supplied, then routine_version.pro is called to get
;                               the current version and date/time for output.
;                               [Default  :  FALSE]
;               EL_RA      :  [2]-Element [float/double] array defining the range of
;                               (low end) e-folding energies [eV] relevant to model fit
;                               function 11
;                               [ Default  :  [1,100] ]
;               EH_RA      :  [2]-Element [float/double] array defining the range of
;                               (high end) e-folding energies [eV] relevant to model fit
;                               function 11
;                               [ Default  :  [10,1000] ]
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/15/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [09/16/2014   v1.0.0]
;             4)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             5)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             6)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             7)  Continued to write routine
;                                                                   [10/06/2014   v1.0.0]
;             8)  Continued to write routine
;                                                                   [10/06/2014   v1.0.0]
;             9)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;            10)  Continued to write routine
;                                                                   [10/08/2014   v1.0.0]
;            11)  Continued to write routine
;                                                                   [10/21/2014   v1.0.0]
;            12)  Continued to write routine
;                                                                   [10/22/2014   v1.0.0]
;            13)  Continued to write routine
;                                                                   [10/22/2014   v1.0.0]
;            14)  Continued to write routine
;                                                                   [11/28/2014   v1.0.0]
;            15)  Finished writing routine and renamed:
;             temp_fit_evdf_para_perp_anti.pro --> wrapper_evdf_fits_para_perp_anti.pro
;             temp_init_evdf_limits_str.pro    --> evdf_fits_init_limits_str.pro
;             temp_fit_evdf_cut_wrapper.pro    --> evdf_fits_fit_to_cut_wrapper.pro
;             temp_moments_evdf_str.pro        --> evdf_fits_moments_calc_str.pro
;                                                                   [01/27/2015   v1.0.0]
;            16)  Now calls lbw_spec3d.pro instead of spec3d.pro
;                                                                   [08/15/2015   v1.1.0]
;
;   NOTES:      
;               1)  User should not call this routine directly
;               2)  Use of the ERA_1C_SC keyword will override the E_RANGE keyword
;                     if set and will define the lower bound by the following:
;                       DATA.SC_POT > (3*Te)
;                     where Te = average electron temperature computed from DATA
;               3)  EL_RA and EH_RA keywords are only relevant if FIT_FUNC=11
;
;  REFERENCES:  
;               NA
;
;   CREATED:  09/13/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/15/2015   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION evdf_fits_init_limits_str,data,_EXTRA=ex_str

FORWARD_FUNCTION evdf_fits_moments_calc_str
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
slash          = get_os_slash()         ;;  '/' for Unix, '\' for Windows
def_eran       = [30e0,15e3]            ;;  Default allowed energy range [eV] over which to fit
def_pawd       = 20d0                   ;;  Default angular width [degree] over which to average for each fit
def_eoran      = [1d0,1d4]              ;;  Default range of e-folding energies [eV]
def_elran      = [1d0,1d2]              ;;  Default range of (low  end) e-folding energies [eV]
def_ehran      = [1d1,1d4]              ;;  Default range of (high end) e-folding energies [eV]
def_el_eh      = [30e0,1e5]             ;;  Default energies [eV] for E_LOW and E_HIGH
;;  Dummy error messages
noinpt_msg     = 'User must supply an a velocity distribution function as an IDL structure...'
nofind_msg     = 'No finite data for this VDF...'
notstr_msg     = 'Must be an IDL structure...'
notvdf_msg     = 'Input must be a velocity distribution function as an IDL structure...'
badvdf_msg     = 'Input must be an IDL structure with similar format to Wind/3DP or THEMIS/ESA...'
not3dp_msg     = 'Input must be a velocity distribution IDL structure from Wind/3DP...'
notthm_msg     = 'Input must be a velocity distribution IDL structure from THEMIS/ESA...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 1) THEN BEGIN
  MESSAGE,noinpt_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
IF (SIZE(data,/TYPE) NE 8L) THEN BEGIN
  MESSAGE,notstr_mssg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
dat            = data[0]
;;  Check to make sure distribution has the correct format
test0          = test_wind_vs_themis_esa_struct(dat[0],/NOM)
test           = (test0.(0) + test0.(1)) NE 1
IF (test[0]) THEN BEGIN
  MESSAGE,notvdf_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Define number of solid-angle and energy bins
dat0           = dat[0]
;nb             = dat0[0].NBINS
nnd            = dat0[0].NBINS[0]
nne            = dat0[0].NENERGY[0]
;;  Determine instrument (i.e., ESA or 3DP) and define electric charge
IF (test0.(0)) THEN BEGIN
  ;;  Wind
  mission = 'Wind'
  strns   = dat_3dp_str_names(dat0[0])
  IF (SIZE(strns,/TYPE) NE 8) THEN BEGIN
    ;;  Neither Wind/3DP nor THEMIS/ESA VDF
    MESSAGE,not3dp_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN,0b
  ENDIF ELSE inst_nm_mode = strns.LC[0]         ;;  e.g., 'Pesa Low Burst'
ENDIF ELSE BEGIN
  IF (test0.(1)) THEN BEGIN
    ;;  THEMIS
    str_element,dat0,'PROJECT_NAME',mission
    IF (N_ELEMENTS(mission) EQ 0) THEN mission = 'THEMIS'
    strns   = dat_themis_esa_str_names(dat0[0])
    IF (SIZE(strns,/TYPE) NE 8) THEN BEGIN
      ;;  Neither Wind/3DP nor THEMIS/ESA VDF
      MESSAGE,notthm_msg[0],/INFORMATIONAL,/CONTINUE
      RETURN,0b
    ENDIF ELSE BEGIN
      temp         = strns.LC[0]                  ;;  e.g., 'IESA 3D Reduced Distribution'
      tposi        = STRPOS(temp[0],'Distribution') - 1L
      inst_nm_mode = STRMID(temp[0],0L,tposi[0])  ;;  e.g., 'IESA 3D Reduced'
    ENDELSE
  ENDIF ELSE BEGIN
    ;;  Other mission?
    str_element,dat0,'DATA_NAME',inst_nm_mode
    str_element,dat0,'PROJECT_NAME',mission
    IF (N_ELEMENTS(inst_nm_mode) EQ 0) THEN BEGIN
      MESSAGE,badvdf_msg[0],/INFORMATIONAL,/CONTINUE
      RETURN,0b
    ENDIF
  ENDELSE
ENDELSE
;;  Define plot title prefix
test           = (N_ELEMENTS(mission) EQ 0)
IF (test[0]) THEN ttl_pref = inst_nm_mode[0] ELSE ttl_pref = mission[0]+' '+inst_nm_mode[0]
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
chsz           = 1.05
xmarg          = [10,10]
era1csc        = 0b             ;;  Logic testing whether to let SC Pot. and 1-count determine E_RANGE
scframe        = 0b             ;;  Logic testing whether to fit in SC-Frame [TRUE] or bulk flow frame [FALSE]
test_ex        = (SIZE(ex_str,/TYPE) NE 8)
IF (test_ex[0]) THEN BEGIN
  ;;  TRUE --> use default fit function and LIMITS
  fitf           = 1
  ;;  Nothing set, so set up default limits structure
  str_element,limits,'XSTYLE',1,/ADD_REPLACE
  str_element,limits,'YSTYLE',1,/ADD_REPLACE
  str_element,limits,'CHARSIZE',chsz[0],/ADD_REPLACE
  str_element,limits,'XMARGIN',xmarg,/ADD_REPLACE
  ;;  Define defaults for E_RANGE, EO_RA, ERA_1C_SC, and PA_BIN_WD
;  e_range        = [30e0,15e3]    ;;  Allowed energies [eV] over which to fit
;  pa_bin_wd      = 20d0           ;;  Angular width [degree] over which to average for each fit
  e_range        = def_eran       ;;  Allowed energies [eV] over which to fit
  pa_bin_wd      = def_pawd       ;;  Angular width [degree] over which to average for each fit
ENDIF ELSE BEGIN
  ;;  FALSE --> check for FIT_FUNC and LIMITS
  str_element,ex_str,   'LIMITS',limits
  str_element,ex_str, 'FIT_FUNC',fit_func
  ;;  Check for SC_FRAME
  str_element,ex_str, 'SC_FRAME',sc_frame
  ;;  Check for fitting routine specific tags
  str_element,ex_str,    'PARAM',param
  str_element,ex_str,  'FIXED_P',fixed_p
  str_element,ex_str,  'A_RANGE',a_range
  str_element,ex_str,  'B_RANGE',b_range
  str_element,ex_str,  'C_RANGE',c_range
  str_element,ex_str,  'D_RANGE',d_range
  ;;  Check for constraint specific tags
  str_element,ex_str,  'E_RANGE',e_range
  str_element,ex_str,    'EO_RA',Eo_ran
  str_element,ex_str,'ERA_1C_SC',era_1c_sc
  str_element,ex_str,'PA_BIN_WD',pa_bin_wd
  ;;  Check for constraint specific tags for FIT_FUNC = 11
  str_element,ex_str,    'EL_RA',El_ran
  str_element,ex_str,    'EH_RA',Eh_ran
  ;;  Check input structure for FILE_DIR and VERSION
  str_element,ex_str, 'FILE_DIR',file_dir
  str_element,ex_str,  'VERSION',version
  test           = (N_ELEMENTS(file_dir) NE 1) OR (SIZE(file_dir,/TYPE) NE 7)
  IF (test) THEN file_dir = FILE_EXPAND_PATH('')
  test           = (N_ELEMENTS(version) EQ 1)
  IF (test) THEN BEGIN
    ;;  VERSION is set
    test        = (SIZE(version[0],/TYPE) NE 7)
    IF (test) THEN BEGIN
      ;;  VERSION = TRUE or FALSE
      test        = version[0]
      IF (test) THEN BEGIN
        ;;  VERSION = TRUE
        scope_trace = SCOPE_TRACEBACK(/STRUCTURE,/SYSTEM)
        ;;  Define the calling routine
        calling_r   = STRLOWCASE(scope_trace[1].ROUTINE)+'.pro'
        full_frpath = scope_trace[1].FILENAME
        gposi       = STRPOS(full_frpath[0],calling_r[0])
        path2_cr    = STRMID(full_frpath[0],0,gposi[0])
        ;;  Get routine version info
        r_version   = routine_version(calling_r[0],path2_cr[0])+' UT'
      ENDIF ELSE BEGIN
        ;;  VERSION = FALSE --> Don't output anything
        r_version = ''
      ENDELSE
    ENDIF ELSE BEGIN
      ;;  VERSION = string?
      IF (SIZE(version[0],/TYPE) EQ 7) THEN r_version = version[0]
    ENDELSE
  ENDIF
  ;;  Check for trailing slash
  ll             = STRMID(file_dir, STRLEN(file_dir) - 1L,1L)
  IF (ll[0] NE slash[0]) THEN file_dir = file_dir[0]+slash[0]
  ;;--------------------------------------------------------------------------------------
  ;;  Check E_RANGE, ERA_1C_SC, and PA_BIN_WD
  ;;--------------------------------------------------------------------------------------
;  IF (N_ELEMENTS(e_range)   NE 2) THEN e_range   = [30e0,15e3]    ;;  Allowed energies [eV] over which to fit
;  IF (N_ELEMENTS(pa_bin_wd) LT 1) THEN pa_bin_wd = 20d0           ;;  Angular width [degree] over which to average for each fit
  IF (N_ELEMENTS(e_range)   NE 2) THEN e_range   = def_eran       ;;  Allowed energies [eV] over which to fit
  IF (N_ELEMENTS(pa_bin_wd) LT 1) THEN pa_bin_wd = def_pawd       ;;  Angular width [degree] over which to average for each fit
  IF KEYWORD_SET(era_1c_sc)       THEN era1csc   = 1b             ;;  Logic:  Use SC Pot. and 1-count determine E_RANGE
  IF KEYWORD_SET(sc_frame)        THEN scframe   = 1b
  ;;--------------------------------------------------------------------------------------
  ;;  Check FIT_FUNC
  ;;--------------------------------------------------------------------------------------
  IF (N_ELEMENTS(fit_func) EQ 0) THEN BEGIN
    ;;  TRUE --> use default fit function
    fitf = 1
  ENDIF ELSE BEGIN
    ;;  Check to make sure it has correct format
    IF ((SIZE(fit_func,/TYPE) LT 1) OR (SIZE(fit_func,/TYPE) GT 5)) THEN fitf = 1 ELSE fitf = fit_func[0]
  ENDELSE
  ;;--------------------------------------------------------------------------------------
  ;;  Check LIMITS
  ;;--------------------------------------------------------------------------------------
  IF (SIZE(limits,/TYPE) NE 8) THEN BEGIN
    ;;  Nothing set, so set up default limits structure
    str_element,limits,'XSTYLE',1,/ADD_REPLACE
    str_element,limits,'YSTYLE',1,/ADD_REPLACE
    str_element,limits,'CHARSIZE',chsz[0],/ADD_REPLACE
    str_element,limits,'XMARGIN',xmarg,/ADD_REPLACE
  ENDIF ELSE BEGIN
    ;;  Check for appropriate structure tags
    str_element,limits,  'XSTYLE',xstyle
    str_element,limits,  'YSTYLE',ystyle
    str_element,limits,'CHARSIZE',charsize
    str_element,limits, 'XMARGIN',xmargin
    test = (N_ELEMENTS(xstyle) EQ 0)
    IF (test[0]) THEN str_element,limits,  'XSTYLE',1,/ADD_REPLACE
    test = (N_ELEMENTS(ystyle) EQ 0)
    IF (test[0]) THEN str_element,limits,  'YSTYLE',1,/ADD_REPLACE
    test = (N_ELEMENTS(charsize) EQ 0)
    IF (test[0]) THEN str_element,limits,'CHARSIZE',chsz[0],/ADD_REPLACE
    test = (N_ELEMENTS(xmargin) EQ 0)
    IF (test[0]) THEN str_element,limits, 'XMARGIN',xmarg,/ADD_REPLACE
  ENDELSE
ENDELSE
;;  Check if routine version info was added
test           = (N_ELEMENTS(r_version) NE 1)
IF (test[0]) THEN r_version   = 'Today:  '+time_string(SYSTIME(1,/SECONDS),PREC=3)+' UT'
;;  Define parameters for pitch-angle (PA) bin [degrees] ranges
str_element,dat0,'DTHETA',dtheta
str_element,dat0,'DPHI',dphi
test           = (N_ELEMENTS(dtheta) EQ N_ELEMENTS(dphi)) AND (N_ELEMENTS(dtheta) NE 0)
IF (test[0]) THEN test    = (TOTAL(FINITE([dtheta,dphi])) GT 0)
IF (test[0]) THEN min_dpa = MIN([MEDIAN(dtheta),MEDIAN(dphi)],/NAN)/2e0 ELSE min_dpa = 11.25
test           = (FINITE(pa_bin_wd) EQ 0) OR (pa_bin_wd LT min_dpa[0])
IF (test[0]) THEN pa_bin_wd = 20d0
;;  Define pitch-angle (PA) bin [degrees] ranges for parallel, perpendicular, and anti-parallel
para_ra        = ([-1d0,1d0]*pa_bin_wd[0] + pa_bin_wd[0])/2d0
perp_ra        = 9d1 + [-1d0,1d0]*pa_bin_wd[0]/2d0
anti_ra        = (18d1 - pa_bin_wd[0]/2d0) + [-1d0,1d0]*pa_bin_wd[0]/2d0
;;  Define reference frame and associated file name suffix
fsuffix        = '_SWFrame'
ttlesuffx      = '[SWF]'
IF (scframe[0]) THEN BEGIN
  fsuffix   = '_SCFrame'
  ttlesuffx = '[SCF]'
ENDIF
;;----------------------------------------------------------------------------------------
;;  Set up plot specific parameters
;;----------------------------------------------------------------------------------------
;;  Define time range and date of eVDF
tr_vdf         = [dat0[0].TIME,dat0[0].END_TIME]
time_ra        = time_range_define(TRANGE=tr_vdf)
tra            = time_ra.TR_UNIX
tdate          = time_ra.TDATE_SE  ;  e.g. '2009-07-13'
;;  Define desired strings for file names
fnm            = file_name_times(tra,PREC=3)
ftimes         = fnm.F_TIME          ; e.g. 1998-08-09_0801x09.494
fn_tsuffx      = ftimes[0]+'-'+STRMID(ftimes[1],11L)
fn_inst_name   = string_replace_char(inst_nm_mode[0],' ','_')
fn_prefx       = file_dir[0]+mission[0]+'_'+fn_inst_name[0]+'_'
;;  Define desired units strings for plot titles
units          = 'flux'                     ;;  i.e., # cm^(-2) s^(-1) sr^(-1) eV^(-1)
new_units      = wind_3dp_units(units[0])
gunits         = new_units.G_UNIT_NAME      ;;  e.g., 'flux'
punits         = new_units.G_UNIT_P_NAME    ;;  e.g., ' (# cm!U-2!Ns!U-1!Nsr!U-1!NeV!U-1!N)'
ytitle         = gunits[0]+punits[0]
title          = '('+ttl_pref[0]+')'+' '+trange_str(tra[0],tra[1])+' '+ttlesuffx[0]
xtitle         = 'Energy [eV]'
;;  Check current device settings
IF (STRLOWCASE(!D.NAME) EQ 'ps') THEN SET_PLOT,'X'
;;  Open windows
wxpos          = 0L
wypos          = 50L
win_lims       = {RETAIN:2,XSIZE:800,YSIZE:800,TITLE:ttl_pref[0]+' Plots ['+tdate[0]+']'}
;;  Only call if windows not already open
DEVICE,WINDOW_STATE=wins_open
IF (wins_open[1] EQ 0) THEN WINDOW,1,_EXTRA=win_lims,XPOS=wxpos[0]+000L,YPOS=wypos[0]+000L
IF (wins_open[2] EQ 0) THEN WINDOW,2,_EXTRA=win_lims,XPOS=wxpos[0]+300L,YPOS=wypos[0]+050L
IF (wins_open[3] EQ 0) THEN WINDOW,3,_EXTRA=win_lims,XPOS=wxpos[0]+600L,YPOS=wypos[0]+100L
;;----------------------------------------------------------------------------------------
;;  Compute moments of VDF
;;----------------------------------------------------------------------------------------
units          = 'flux'
dat2f          = conv_units(dat0[0],units[0],/FRACTIONAL_COUNTS)
;;  Calculate the one-count levels for error estimates
dat1c          = dat0[0]
dat1c[0].DATA  = 1e0    ;;  Set all values = 1 count in units of 'Counts'
dat1c          = conv_units(dat1c[0],units[0],/FRACTIONAL_COUNTS)
;;  Estimate bulk flow velocity from DF
sform          = moments_3d_new()
del            = dat0[0]
limits         = evdf_fits_moments_calc_str(del,LIMITS=limits,VDF_MOMS=vdf_moms)
test           = (SIZE(vdf_moms,/TYPE) NE 8L)
IF (test[0]) THEN BEGIN
  vbulk  = dat0[0].VSW
  avg_Te = 0.
  scpot  = dat0[0].SC_POT
ENDIF ELSE BEGIN
  str_element,vdf_moms,'VELOCITY',vbulk
  str_element,vdf_moms,'AVGTEMP',avg_Te
  str_element,vdf_moms,'SC_POT',scpot
;  vbulk = vdf_moms[0].VELOCITY
  test   = (TOTAL(FINITE(vbulk)) NE 3) OR (FINITE(avg_Te) EQ 0)
  IF (test[0]) THEN BEGIN
    vbulk  = dat0[0].VSW
    avg_Te = 0.
    scpot  = 0.
  ENDIF
ENDELSE
;;  Transform into bulk flow frame [IF ~SC_FRAME]
dat_sw         = conv_units(dat0[0],'df',/FRACTIONAL_COUNTS)
dat1c_sw       = conv_units(dat1c[0],'df',/FRACTIONAL_COUNTS)
dat_sw.VSW     = vbulk
dat1c_sw.VSW   = vbulk
IF (scframe[0] EQ 0) THEN BEGIN
  transform_vframe_3d,dat_sw,/EASY_TRAN
  transform_vframe_3d,dat1c_sw,/EASY_TRAN
ENDIF
;;  Convert units back to UNITS
dat_sw         = conv_units(dat_sw[0],units[0],/FRACTIONAL_COUNTS)
dat1c_sw       = conv_units(dat1c_sw[0],units[0],/FRACTIONAL_COUNTS)
onec0          = dat1c_sw[0].DATA
;;----------------------------------------------------------------------------------------
;;  Plot initial distribution spectra with colors indicating pitch-angles
;;----------------------------------------------------------------------------------------
pang           = 1
WSET,1
WSHOW,1
IF (scframe[0]) THEN BEGIN
  lbw_spec3d,dat0[0],UNITS=units,XDAT=energy0,YDAT=data0,LIMITS=limits,/RM_PHOTO_E,$
                     PITCHANGLE=pang,/LABEL,COLOR=pa_cols
ENDIF ELSE BEGIN
  lbw_spec3d,dat_sw[0],UNITS=units,XDAT=energy0,YDAT=data0,LIMITS=limits,$
                       PITCHANGLE=pang,/LABEL,COLOR=pa_cols
ENDELSE
;;----------------------------------------------------------------------------------------
;;  First make sure results are consistent
;;----------------------------------------------------------------------------------------
sze0           = SIZE(energy0,/DIMENSIONS)
szd0           = SIZE(data0,/DIMENSIONS)
szp0           = SIZE(pang,/DIMENSIONS)
test           = (sze0[0] NE nne[0]) OR (sze0[1] NE nnd[0]) OR $
                 (szd0[0] NE nne[0]) OR (szd0[1] NE nnd[0]) OR $
                 (szp0[0] NE nnd[0])
IF (test[0]) THEN BEGIN
  MESSAGE,nofind_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;----------------------------------------------------------------------------------------
;;  Redefine E_RANGE if ERA_1C_SC = TRUE
;;----------------------------------------------------------------------------------------
IF (era1csc[0]) THEN BEGIN
  ;;  Define (dJ/dE)/([dJ/dE]_{1-count})
  ratio = (data0/onec0) GT 2d0
  test  = ratio AND (energy0 GT scpot[0])
  good  = WHERE(test,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
  IF (gd[0] GT 0) THEN BEGIN
    min_ge     = MIN(ABS(energy0[good]),/NAN)
    max_ge     = MAX(ABS(energy0[good]),/NAN)
    test       = (SIZE(vdf_moms,/TYPE) EQ 8L) AND (N_ELEMENTS(avg_Te) EQ 1)
    IF (test) THEN BEGIN
      test       = FINITE(avg_Te[0])
;      IF (test) THEN min_ge = (min_ge[0] > (3.*avg_Te[0])) < 1e2  ;;  keep lower bound at 100 eV maximum
      IF (test) THEN min_ge = (min_ge[0] > (2.*avg_Te[0])) < 75e0  ;;  keep lower bound at 75 eV maximum
      ;;  change for FIT_FUNC = 11 to allow lower energies to contribute
      test       = (fitf[0] EQ 11)
      IF (test) THEN min_ge = MIN(ABS(energy0[good]),/NAN)
    ENDIF
    ;;  Redefine E_RANGE
    e_range[0] = e_range[0] > min_ge[0]
    e_range[1] = e_range[1] < max_ge[0]
  ENDIF
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define FIT_FUNC dependent parameters
;;----------------------------------------------------------------------------------------
;;  Define default values
fitf_ysubttl   = 'Y = A X!UB!N + C'
fitf_print     = 'Y = A X^(B) + C'
fitf_fnmid     = 'Power-Law_0_'
fitf_number    = fitf[0]
;;  Initialize variables used by fitting routines
;;  Define default energy range to consider
test           = (data0/onec0 GT 2d0) AND FINITE(data0/onec0) AND FINITE(data0) AND $
                 (energy0 LT e_range[1]) AND (energy0 GT e_range[0])
good           = WHERE(test,gd)
IF (gd GT 0) THEN BEGIN
  mndata         = MIN(ABS(data0[good]),/NAN,lnd)   ;;  = F_min
  mxdata         = MAX(ABS(data0[good]),/NAN,lxd)   ;;  = F_max
  e_mndat        = energy0[good[lxd[0]]]            ;;  E [eV] at MAX(dJ/dE) = E_min [E @ F_max]
  e_mxdat        = energy0[good[lnd[0]]]            ;;  E [eV] at MIN(dJ/dE) = E_max [E @ F_min]
ENDIF ELSE BEGIN
  mndata         = MIN(ABS(data0),/NAN,lnd)         ;;  = F_min
  mxdata         = MAX(ABS(data0),/NAN,lxd)         ;;  = F_max
  e_mndat        = energy0[lxd[0]]                  ;;  E [eV] at MAX(dJ/dE) = E_min [E @ F_max]
  e_mxdat        = energy0[lnd[0]]                  ;;  E [eV] at MIN(dJ/dE) = E_max [E @ F_min]
ENDELSE

CASE fitf[0] OF
  1    : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Y = A X^(B) + C
    ;;------------------------------------------------------------------------------------
    fitf_ysubttl   = 'Y = A X!UB!N + C'
    fitf_print     = 'Y = A X^(B) + C'
    fitf_fnmid     = 'Power-Law_0_'
    IF (N_ELEMENTS(param) NE 4) THEN BEGIN
      param          = DBLARR(4)
      ;;  Define default PARAM guesses
      param[0]       = MAX(ABS(data0),/NAN)     ;;  A = Lim_{E --> Infinity} (dJ/dE) ~ 10^(6)
      param[1]       = -2d0                     ;;  B = ¥ ~ 2
      param[2]       = 0d0                      ;;  C = Lim_{E --> Infinity} (dJ/dE) ~ 0
      param[3]       = 0d0                      ;;  D = N/A
    ENDIF
    ;;  Define default constraints
    IF (N_ELEMENTS(fixed_p) NE 4) THEN BEGIN
      fixed_p        = REPLICATE(1b,4)
      fixed_p[2:3]   = 0b                       ;;  Do NOT allow C or D to vary
    ENDIF
    ;;  Determine effective range for A
    test           = (data0/onec0 GT 2d0) AND FINITE(data0/onec0) AND FINITE(data0) AND $
                     (energy0 LT e_range[1]) AND (energy0 GT e_range[0])
    good           = WHERE(test,gd)
    IF (gd GT 0) THEN BEGIN
      ;;  Solve:  F_min = A (E_max)^B  &&  F_max = A (E_min)^B
      ;;          -->  B = (Log_{e}|F_min/F_max|)/(Log_{e}|E_max/E_min|) < 0
      bo_ra          = [-9d0,-5d-2]
      b0             = ALOG(mndata[0]/mxdata[0])/ALOG(e_mxdat[0]/e_mndat[0])
      a01            = [mndata[0]/(e_mxdat[0]^(b0[0])),mxdata[0]/(e_mndat[0]^(b0[0]))]
      a0             = mndata[0]/(e_mxdat[0]^(bo_ra))
      a1             = mxdata[0]/(e_mndat[0]^(bo_ra))
      ao_ra          = REPLICATE(0d0,2)
      b0_ra          = REPLICATE(0d0,2)
      ao_ra[0]       = (MIN([a0,a1],/NAN)) > mxdata[0]
      ao_ra[1]       = (MIN([MAX(a0,/NAN),MAX(a1,/NAN)],/NAN) < 1d3*a01[0]) > 1d2*mxdata[0]
      b0_ra[0]       = -1d0*(ABS(b0[0]) > 20d0)
      b0_ra[1]       = -1d0*(ABS(b0[0]) < MIN(ABS(bo_ra)))
      IF (N_ELEMENTS(a_range) NE 4) THEN a_range = [1,1,ao_ra[SORT(ao_ra)]]         ;;  Constrain A
      IF (N_ELEMENTS(b_range) NE 4) THEN b_range = [1,1,b0_ra[SORT(b0_ra)]]         ;;  Constrain spectral index
    ENDIF ELSE BEGIN
      IF (N_ELEMENTS(a_range) NE 4) THEN a_range = [1,1,[1d-1,1d3]*MAX(ABS(data0),/NAN)]
      IF (N_ELEMENTS(b_range) NE 4) THEN b_range = [1,1,-20d0,-5d-2]         ;;  Constrain spectral index
    ENDELSE
    ;;  Make sure lower bound on A_RANGE isn't too low
    a_range[2] = a_range[2] > (1d-1*MAX(ABS(data0),/NAN))
    ;;  Make sure upper bound isn't below lower bound now
    test       = (a_range[2] GT a_range[3])
    IF (test) THEN a_range[3] = a_range[2]*1d3
  END
  2    : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Y = A e^(B X) + C
    ;;------------------------------------------------------------------------------------
    fitf_ysubttl   = 'Y = A e!UB X!N + C'
    fitf_print     = 'Y = A e^(B X) + C'
    fitf_fnmid     = 'Exponential_0_'
    IF (N_ELEMENTS(param) NE 4) THEN BEGIN
      param          = DBLARR(4)
      ;;  Define default PARAM guesses
      param[0]       = MAX(ABS(data0),/NAN)     ;;  A = Lim_{E --> Infinity} (dJ/dE) ~ 10^(6)
      param[1]       = -1d0/1d2                 ;;  B = E_o ~ 100 eV
      param[2]       = 0d0                      ;;  C = Lim_{E --> Infinity} (dJ/dE) ~ 0
      param[3]       = 0d0                      ;;  D = N/A
    ENDIF
    ;;  Define default constraints
    IF (N_ELEMENTS(fixed_p) NE 4) THEN BEGIN
      fixed_p        = REPLICATE(1b,4)
      fixed_p[2:3]   = 0b                       ;;  Do NOT allow C or D to vary
    ENDIF
    ;;  Allowed e-folding energies [eV]
;    IF (N_ELEMENTS(Eo_ran) NE 2) THEN IF (scframe[0]) THEN Eo_ran = [1d0,1d3] ELSE Eo_ran = [1d1,1d3]
    IF (N_ELEMENTS(Eo_ran) NE 2) THEN IF (scframe[0]) THEN Eo_ran = def_eoran ELSE Eo_ran = def_eoran*[1d1,1d0]
    ;;  Slightly modify Eo[0]
    IF (scframe[0] EQ 0) THEN Eo_ran[0]      = Eo_ran[0] > (2.*e_range[0])
    IF (gd GT 0 AND scframe[0] EQ 0) THEN BEGIN
      ;;  Solve:  F_min = A e^(B E_max)  &&  F_max = A e^(B E_min)
      ;;          -->  B = (Log_{e}|F_min/F_max|)/(E_max - E_min) < 0
      bo_ra          = -1d0/Eo_ran
      b0             = ALOG(mndata[0]/mxdata[0])/(e_mxdat[0] - e_mndat[0])
      a01            = [mxdata[0]*EXP(b0[0]*e_mndat[0]),mndata[0]*EXP(b0[0]*e_mxdat[0])]
      a0             = mndata[0]*EXP(bo_ra*e_mxdat[0])
      a1             = mxdata[0]*EXP(bo_ra*e_mndat[0])
      ao_ra          = REPLICATE(0d0,2)
      b0_ra          = REPLICATE(0d0,2)
      ao_ra[0]       = (MIN([a0,a1],/NAN)) > mxdata[0]
      ao_ra[1]       = (MIN([MAX(a0,/NAN),MAX(a1,/NAN)],/NAN) < 1d3*MAX(a01)) > 1d2*mxdata[0]
      b0_ra[0]       = -1d0*(ABS(b0[0]) > MAX(ABS(bo_ra)))
      b0_ra[1]       = -1d0*(ABS(b0[0]) < MIN(ABS(bo_ra)))
      IF (N_ELEMENTS(a_range) NE 4) THEN a_range = [1,1,ao_ra[SORT(ao_ra)]]         ;;  Constrain A
      IF (N_ELEMENTS(b_range) NE 4) THEN b_range = [1,1,b0_ra[SORT(b0_ra)]]         ;;  Constrain exponent
    ENDIF ELSE BEGIN
      IF (N_ELEMENTS(a_range) NE 4 AND scframe[0] EQ 0) THEN a_range = [1,1,[75d-2,1.25]*MAX(ABS(data0),/NAN)]
      IF (N_ELEMENTS(b_range) NE 4) THEN b_range = [1,1,-1d0/Eo_ran]        ;;  Constrain e-folding energy
    ENDELSE
  END
  3    : BEGIN
    ;;  Y = A + B Log_{e} |X^C|
    fitf_ysubttl   = 'Y = A + B log!De!N'+'|'+'X!UC!N'+'|'
    fitf_print     = 'Y = A + B Log_{e} |X^C|'
    fitf_fnmid     = 'Log-Linear-Power-Law_'
  END
  4    : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Y = A X^(B) e^(C X) + D
    ;;------------------------------------------------------------------------------------
    fitf_ysubttl   = 'Y = A X!UB!N e!UC X!N + D'
    fitf_print     = 'Y = A X^(B) e^(C X) + D'
    fitf_fnmid     = 'Power-Law-Exponential_'
    IF (N_ELEMENTS(param) NE 4) THEN BEGIN
      param          = DBLARR(4)
      ;;  Define default PARAM guesses
      param[0]       = MAX(ABS(data0),/NAN)     ;;  A = Lim_{E --> Infinity} (dJ/dE) ~ 10^(6)
      param[1]       = -2d0                     ;;  B = ¥ ~ 2
      param[2]       = -1d0/1d2                 ;;  C = E_o ~ 100 eV
      param[3]       = 0d0                      ;;  D = Lim_{E --> Infinity} (dJ/dE) ~ 0
    ENDIF
    ;;  Define default constraints
    IF (N_ELEMENTS(fixed_p) NE 4) THEN BEGIN
      fixed_p        = REPLICATE(1b,4)
      fixed_p[3]     = 0b                       ;;  Do NOT allow D to vary
    ENDIF
;    IF (N_ELEMENTS(Eo_ran) NE 2)  THEN Eo_ran  = [1d1,1d3]      ;;  Allowed e-folding energies [eV]
    IF (N_ELEMENTS(Eo_ran) NE 2)  THEN Eo_ran  = def_eoran      ;;  Allowed e-folding energies [eV]
    ;;  Slightly modify Eo[0]
    Eo_ran[0]      = Eo_ran[0] > (2.*e_range[0])
    ;;  Slightly modify PARAM if necessary
    test_en        = (Eo_ran[0] GE (-1d0/param[2]))
    IF (test_en) THEN param[2] = -1d0/MEAN(Eo_ran,/NAN)
    IF (N_ELEMENTS(a_range) NE 4) THEN a_range = [1,1,[75d-2,1.25]*MAX(ABS(data0),/NAN)]
    IF (N_ELEMENTS(b_range) NE 4) THEN b_range = [1,1,-7d0,-5d-2]         ;;  Constrain spectral index
    IF (N_ELEMENTS(c_range) NE 4) THEN c_range = [1,1,-1d0/Eo_ran]        ;;  Constrain e-folding energy
  END
  5    : BEGIN
    ;;  Y = A B^(X) + C
    fitf_ysubttl   = 'Y = A B!UX!N + C'
    fitf_print     = 'Y = A B^(X) + C'
    fitf_fnmid     = 'Exponential_1_'
  END
  6    : BEGIN
    ;;  Y = A B^(C X) + D
    fitf_ysubttl   = 'Y = A B!UC X!N + D'
    fitf_print     = 'Y = A B^(C X) + D'
    fitf_fnmid     = 'Exponential_2_'
  END
  7    : BEGIN
    ;;  Y = ( A + B X )^(-1)
    fitf_ysubttl   = 'Y = [A + B X]!U-1!N'
    fitf_print     = 'Y = [ A + B X ]^(-1)'
    fitf_fnmid     = 'Hyperbolic_'
  END
  8    : BEGIN
    ;;  Y = ( A B^(X) + C )^(-1)
    fitf_ysubttl   = 'Y = [A B!UX!N + C ]!U-1!N'
    fitf_print     = 'Y = [A B^(X) + C ]^(-1)'
    fitf_fnmid     = 'Logistic_'
  END
  9    : BEGIN
    ;;  Y = A X^(B) ( e^(C X) + D )^(-1)
    fitf_ysubttl   = 'Y = A X!UB!N [ e!UC X!N + D ]!U-1!N'
    fitf_print     = 'Y = A X^(B) [ e^(C X) + D ]^(-1)'
    fitf_fnmid     = 'Blackbody_'
;    IF (N_ELEMENTS(Eo_ran) NE 2)  THEN Eo_ran  = [1d1,1d3]      ;;  Allowed e-folding energies [eV]
    IF (N_ELEMENTS(Eo_ran) NE 2)  THEN Eo_ran  = def_eoran      ;;  Allowed e-folding energies [eV]
    ;;  Slightly modify Eo[0]
    Eo_ran[0]      = Eo_ran[0] > (2.*e_range[0])
  END
  10   : BEGIN
    ;;  Y = A + B Log_{10} |X| + C (Log_{10} |X|)^2
    fitf_ysubttl   = 'Y = A + B log!D10!N'+'|X| + C [ log!D10!N'+'|X| ]!U2!N'
    fitf_print     = 'Y = A + B Log_{10} |X| + C [ Log_{10} |X| ]^(2)'
    fitf_fnmid     = 'Log-Square_'
  END
  11   : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Y = A X^(B) e^(C X) e^(D X)
    ;;------------------------------------------------------------------------------------
    fitf_ysubttl   = 'Y = A X!UB!N e!UC X!N e!U'+'D X'+'!N'
    fitf_print     = 'Y = A X^(B) e^(C X) e^(D X)'
    fitf_fnmid     = 'Power-Law-Double-Exponential_'
    IF (N_ELEMENTS(param) NE 4) THEN BEGIN
      param          = DBLARR(4)
      ;;  Define default PARAM guesses
      param[0]       = MAX(ABS(data0),/NAN)     ;;  A = Lim_{E --> Infinity} (dJ/dE) ~ 10^(6)
      param[1]       = -2d0                     ;;  B = ¥ ~ 2
      param[2]       = -1d0/1d1                 ;;  C = E_L ~ 10 eV
      param[3]       = -1d0/1d2                 ;;  C = E_H ~ 100 eV
    ENDIF
    ;;  Define default constraints --> Allow all parameters to vary
    IF (N_ELEMENTS(fixed_p) NE 4) THEN fixed_p = REPLICATE(1b,4)
    ;;  Check EL_RA and EH_RA
;    IF (N_ELEMENTS(El_ran) NE 2)  THEN El_ran  = [1d0,1d2]      ;;  Allowed (low end) e-folding energies [eV]
;    IF (N_ELEMENTS(Eh_ran) NE 2)  THEN Eh_ran  = [1d1,1d3]      ;;  Allowed (high end) e-folding energies [eV]
    IF (N_ELEMENTS(El_ran) NE 2)  THEN def_elran  = [1d0,1d2]      ;;  Allowed (low end) e-folding energies [eV]
    IF (N_ELEMENTS(Eh_ran) NE 2)  THEN def_ehran  = [1d1,1d3]      ;;  Allowed (high end) e-folding energies [eV]
    ;;  Slightly modify E_L[0] if below minimum resolved energy
    El_ran[0]      = El_ran[0] > (e_range[0])
    ;;  Slightly modify E_H[0]
    Eh_ran[0]      = Eh_ran[0] > (2.*e_range[0])
    ;;  Slightly modify PARAM if necessary
    test_en        = (El_ran[0] GE (-1d0/param[2]))
    IF (test_en) THEN param[2] = -1d0/MEAN(El_ran,/NAN)
    test_en        = (Eh_ran[0] GE (-1d0/param[3]))
    IF (test_en) THEN param[3] = -1d0/MEAN(Eh_ran,/NAN)
    ;;  Define PARAM ranges if necessary
    IF (N_ELEMENTS(a_range) NE 4) THEN a_range = [1,1,[75d-2,1.25]*MAX(ABS(data0),/NAN)]
    IF (N_ELEMENTS(b_range) NE 4) THEN b_range = [1,1,-9d0,-1d-2]         ;;  Constrain spectral index
    IF (N_ELEMENTS(c_range) NE 4) THEN c_range = [1,1,-1d0/El_ran]        ;;  Constrain (low end) e-folding energy
    IF (N_ELEMENTS(d_range) NE 4) THEN d_range = [1,1,-1d0/Eh_ran]        ;;  Constrain (high end) e-folding energy
  END
  ELSE :   ;;  Use default:  Y = A X^(B) + C
ENDCASE
;;----------------------------------------------------------------------------------------
;;  First, add fit-related parameters to LIMITS
;;----------------------------------------------------------------------------------------
;;  Define output file name for PS plot
fit_file_name  = fn_prefx[0]+'Fit_Results_Func_'+fitf_fnmid[0]+fn_tsuffx[0]+fsuffix[0]
;;  Define fit label-parameter structure
str_element,fit_struct, 'FIT_FUNC_YSUBT', fitf_ysubttl,/ADD_REPLACE
str_element,fit_struct,'FIT_FUNC_STRING',   fitf_print,/ADD_REPLACE
str_element,fit_struct,   'FIT_FUNC_NUM',      fitf[0],/ADD_REPLACE
str_element,fit_struct, 'FIT_FUNC_FNMID',   fitf_fnmid,/ADD_REPLACE
str_element,fit_struct,          'PARAM',        param,/ADD_REPLACE
str_element,fit_struct,        'FIXED_P',      fixed_p,/ADD_REPLACE
str_element,fit_struct,        'A_RANGE',      a_range,/ADD_REPLACE
str_element,fit_struct,        'B_RANGE',      b_range,/ADD_REPLACE
str_element,fit_struct,        'C_RANGE',      c_range,/ADD_REPLACE
str_element,fit_struct,        'D_RANGE',      d_range,/ADD_REPLACE
str_element,fit_struct,     'ENER_RANGE',      e_range,/ADD_REPLACE
str_element,fit_struct,      'E_O_RANGE',       Eo_ran,/ADD_REPLACE
str_element,fit_struct,      'E_L_RANGE',       El_ran,/ADD_REPLACE
str_element,fit_struct,      'E_H_RANGE',       Eh_ran,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Second, add titles and log-scale settings to LIMITS
;;----------------------------------------------------------------------------------------
ysubttl        = 'Fit Function: '+fitf_ysubttl[0]
str_element,limits,   'XTITLE', xtitle[0],/ADD_REPLACE
str_element,limits,   'YTITLE', ytitle[0],/ADD_REPLACE
str_element,limits,'YSUBTITLE',ysubttl[0],/ADD_REPLACE
str_element,limits,    'TITLE',  title[0],/ADD_REPLACE
str_element,limits,     'XLOG',         1,/ADD_REPLACE
str_element,limits,     'YLOG',         1,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Third, define plot ranges (if not already done in LIMITS structure)
;;----------------------------------------------------------------------------------------
test           = (data0 GT 0) AND FINITE(data0)
good           = WHERE(test,gd)
IF (gd[0] EQ 0) THEN BEGIN
  MESSAGE,nofind_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
e_mnmx         = [MIN(energy0[good],/NAN),MAX(energy0[good],/NAN)]*[9d-1,11d-1]
d_mnmx         = [MIN(data0[good],/NAN),MAX(data0[good],/NAN)]*[9d-1,11d-1]
str_element,limits,'XRANGE',xran
str_element,limits,'YRANGE',yran
IF (N_ELEMENTS(xran) EQ 0) THEN BEGIN
  xran = e_mnmx
  str_element,limits,'XRANGE',xran,/ADD_REPLACE
ENDIF
IF (N_ELEMENTS(yran) EQ 0) THEN BEGIN
  yran = d_mnmx
  str_element,limits,'YRANGE',yran,/ADD_REPLACE
ENDIF
;;----------------------------------------------------------------------------------------
;;  Fourth, define plot tick marks (if not already done in LIMITS structure)
;;----------------------------------------------------------------------------------------
tagns          = STRLOWCASE(TAG_NAMES(limits))
pref_tag       = STRMID(tagns,0L,5L)
check_suffx    = ['tickv','tickname','ticks','range']
check_xtags    = 'x'+check_suffx
check_ytags    = 'y'+check_suffx
test_xyran     = [WHERE(tagns EQ check_xtags[3]),WHERE(tagns EQ check_ytags[3])]
test_xytic     = [WHERE(pref_tag EQ 'xtick'),WHERE(pref_tag EQ 'ytick')]
def_minmax     = [1d-30,1d30]
IF (test_xytic[0] LT 0) THEN BEGIN
  ;;  Define new tick marks for X-Axis
  IF (test_xyran[0] GE 0) THEN BEGIN
    xran  = limits.XRANGE
    rmnmx = xran
    force = 1
  ENDIF ELSE BEGIN
    rmnmx = def_minmax
    force = 0
  ENDELSE
  xtick_str = log10_tickmarks(energy0,RANGE=xran,MIN_VAL=rmnmx[0],MAX_VAL=rmnmx[1],FORCE_RA=force)
  IF (SIZE(xtick_str,/TYPE) EQ 8) THEN BEGIN
    str_element,limits,   'XTICKV',   xtick_str.TICKV,/ADD_REPLACE
    str_element,limits,'XTICKNAME',xtick_str.TICKNAME,/ADD_REPLACE
    str_element,limits,   'XTICKS',   xtick_str.TICKS,/ADD_REPLACE
    str_element,limits,   'XMINOR',                 9,/ADD_REPLACE
  ENDIF
ENDIF
IF (test_xytic[1] LT 0) THEN BEGIN
  ;;  Define new tick marks for Y-Axis
  IF (test_xyran[1] GE 0) THEN  BEGIN
    yran  = limits.YRANGE
    rmnmx = yran
    force = 1
  ENDIF ELSE BEGIN
    rmnmx = def_minmax
    force = 0
  ENDELSE
  ytick_str = log10_tickmarks(data0,RANGE=yran,MIN_VAL=rmnmx[0],MAX_VAL=rmnmx[1],FORCE_RA=force)
  IF (SIZE(ytick_str,/TYPE) EQ 8) THEN BEGIN
    str_element,limits,   'YTICKV',   ytick_str.TICKV,/ADD_REPLACE
    str_element,limits,'YTICKNAME',ytick_str.TICKNAME,/ADD_REPLACE
    str_element,limits,   'YTICKS',   ytick_str.TICKS,/ADD_REPLACE
    str_element,limits,   'YMINOR',                 9,/ADD_REPLACE
  ENDIF
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define output structure
;;----------------------------------------------------------------------------------------
;;  Define original eVDF data structure in units of counts [SC-Frame]
str_element,struc,     'DATA',         dat0,/ADD_REPLACE
;;  Define one-count copy eVDF data structure [SC-Frame]
str_element,struc,   'DAT_1C',        dat1c,/ADD_REPLACE
;;  Define original eVDF data structure in units of flux [SC-Frame]
str_element,struc,   'DAT__F',        dat2f,/ADD_REPLACE
;;  Define original eVDF data structure in units of flux [SW-Frame]
str_element,struc,   'DAT_SW',       dat_sw,/ADD_REPLACE
;;  Define one-count copy eVDF data structure [SW-Frame]
str_element,struc,'DAT_1C_SW',     dat1c_sw,/ADD_REPLACE
;;  Define other relevant parameters
str_element,struc,   'LIMITS',       limits,/ADD_REPLACE
str_element,struc,   'P_ANGS',         pang,/ADD_REPLACE
str_element,struc,  'PA_COLS',      pa_cols,/ADD_REPLACE
str_element,struc,   'DATA_0',        data0,/ADD_REPLACE
str_element,struc, 'ENERGY_0',      energy0,/ADD_REPLACE
str_element,struc,   'ONE_C0',        onec0,/ADD_REPLACE
str_element,struc,  'PARA_RA',      para_ra,/ADD_REPLACE
str_element,struc,  'PERP_RA',      perp_ra,/ADD_REPLACE
str_element,struc,  'ANTI_RA',      anti_ra,/ADD_REPLACE
;;  Define fit structure
str_element,struc,'FIT_STRUC',   fit_struct,/ADD_REPLACE
;;  Define extra outputs
str_element,struc,  'MISSION',      mission,/ADD_REPLACE
str_element,struc,'INST_MODE', inst_nm_mode,/ADD_REPLACE
str_element,struc,    'TDATE',     tdate[0],/ADD_REPLACE
str_element,struc,   'TRANGE',          tra,/ADD_REPLACE
str_element,struc,'FILE_NAME',fit_file_name,/ADD_REPLACE
str_element,struc,  'VERSION',    r_version,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,struc
END


;*****************************************************************************************
;
;  FUNCTION :   evdf_fits_fit_to_cut_wrapper.pro
;  PURPOSE  :   This is a wrapping routine for the actual fit function calling sequence.
;                 The model function is a power-law, exponential, or combination of the
;                 two functions with one of the forms:
;
;                 *******************
;                   Y = A X^(B) + C
;                 *******************
;                 where the physical interpretation of the parameters are:
;                   Y  :  dJ/dE  = differential intensity
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;                   X  :   E     = particle kinetic energy
;                                  [eV]
;                   A  :   K     = Lim_{E --> 0} (dJ/dE)
;                                  [~10^(6) for electrons]
;                   B  :  -¥     = power-law slope or spectral index
;                                  [unitless]
;                   C  :  dJdE_o = Lim_{E --> Infinity} (dJ/dE) ~ 0
;                                  { expect:  ~ 0 for reasonable particles }
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;
;                 *********************
;                   Y = A e^(B X) + C
;                 *********************
;                 where the physical interpretation of the parameters are:
;                   Y  :  dJ/dE  = differential intensity
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;                   X  :   E     = particle kinetic energy
;                                  [eV]
;                   A  :   K     = Lim_{E --> 0} (dJ/dE)
;                                  [~10^(6) for electrons]
;                   B  :  -1/E_o = inverse of e-folding energy
;                                  { where:  E_o ~ 100's of eV for electrons }
;                                  [eV^(-1)]
;                   C  :  dJdE_o = Lim_{E --> Infinity} (dJ/dE) ~ 0
;                                  { expect:  ~ 0 for reasonable particles }
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;
;                 ***************************
;                   Y = A X^(B) e^(C X) + D
;                 ***************************
;                 where the physical interpretation of the parameters are:
;                   Y  :  dJ/dE  = differential intensity
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;                   X  :   E     = particle kinetic energy
;                                  [eV]
;                   A  :   K     = Lim_{E --> 0} (dJ/dE)
;                                  [~10^(6) for electrons]
;                   B  :  -¥     = power-law slope or spectral index
;                                  [unitless]
;                   C  :  -1/E_o = inverse of e-folding energy
;                                  { where:  E_o ~ 100's of eV for electrons }
;                                  [eV^(-1)]
;                   D  :  dJdE_o = Lim_{E --> Infinity} (dJ/dE) ~ 0
;                                  { expect:  ~ 0 for reasonable particles }
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;
;                 *******************************
;                   Y = A X^(B) e^(C X) e^(D X)
;                 *******************************
;                 where the physical interpretation of the parameters are:
;                   Y  :  dJ/dE  = differential intensity
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;                   X  :   E     = particle kinetic energy
;                                  [eV]
;                   A  :   K     = Lim_{E --> 0} (dJ/dE)
;                                  [~10^(5) - 10^(7) for electrons]
;                   B  :  -¥     = power-law slope or spectral index
;                                  [unitless]
;                   C  :  -1/E_L = inverse of e-folding energy of low energy electrons
;                                  { where:  E_L ~ 10's of eV for electrons }
;                                  [eV^(-1)]
;                   D  :  -1/E_H = inverse of e-folding energy of low energy electrons
;                                  { where:  E_H ~ 100's of eV for electrons }
;                                  [eV^(-1)]
;
;  CALLED BY:   
;               wrapper_evdf_fits_para_perp_anti.pro
;
;  CALLS:
;               wrapper_multi_func_fit.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               ;;..................................................
;               ;;  Below, the following definitions apply:
;               ;;    T  =  # of solid angle bins in eVDF
;               ;;    S  =  # of energy bins in eVDF
;               ;;..................................................
;               DATA       :  [T,S]-Element array [float] containing the data [flux] to
;                               which the the model function should be fit
;               ENERGY     :  [T,S]-Element array [float] containing the energies [eV]
;                               associated with each element in DATA
;               PANG       :  [T]-Element array [float] defining the average pitch-angle
;                               of each solid angle bin in DATA
;               CUT_RAN    :  [2]-Element array [float] defining the range of angles
;                               between which to average the data and use to fit
;               PARAM      :  [4]-Element [float] array containing the following
;                               initialization quantities for the model function
;                               (see above):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = D
;
;  EXAMPLES:    
;               test = evdf_fits_fit_to_cut_wrapper(data,energy,pang,cut_ran,param,_EXTRA=ex_str)
;
;  KEYWORDS:    
;               CUT_DIR    :  Scalar [float] defining the angle along which
;                               the fit is being performed
;                                            {  MIN(CUT_RAN)  for Parallel cut
;                                 Default  = { MEAN(CUT_RAN)  for Perpendicular cut
;                                            {  MAX(CUT_RAN)  for Anti-parallel cut
;               E_LOW      :  Scalar [float] defining the lowest energy [eV] to consider
;                               for the data to send to the fit routines
;                               [Default = 30e0]
;               E_HIGH     :  Scalar [float] defining the highest energy [eV] to consider
;                               for the data to send to the fit routines
;                               [Default = 1e5]
;               ONE_C      :  [T,S]-Element array [float] containing the one-count level
;                               for the eVDF from which DATA was derived [flux]
;               FIT_FUNC   :  Scalar [integer] specifying the type of function to use
;                               [Default  :  1]
;                               1  :  Y = A X^(B) + C
;                               2  :  Y = A e^(B X) + C
;                               3  :  Y = A + B Log_{e} |X^C|
;                               4  :  Y = A X^(B) e^(C X) + D
;                               5  :  Y = A B^(X) + C
;                               6  :  Y = A B^(C X) + D
;                               7  :  Y = ( A + B X )^(-1)
;                               8  :  Y = ( A B^(X) + C )^(-1)
;                               9  :  Y = A X^(B) ( e^(C X) + D )^(-1)
;                              10  :  Y = A + B Log_{10} |X| + C (Log_{10} |X|)^2
;                              11  :  Y = A X^(B) e^(C X) e^(D X)
;               FIXED_P    :  [4]-Element array containing zeros for each element of
;                               PARAM the user does NOT wish to vary (i.e., if FIXED_P[0]
;                               is = 0, then PARAM[0] will not change when calling
;                               MPFITFUN.PRO).
;                               [Default  :  All elements = 1]
;               A_RANGE    :  [4]-Element [float/double] array defining the range of
;                               allowed values to use for A or PARAM[0].  Note, if this
;                               keyword is set, it is equivalent to telling the routine
;                               that A should be limited by these bounds.  Setting this
;                               keyword will define:
;                                 PARINFO[0].LIMITED[*] = BYTE(A_RANGE[0:1])
;                                 PARINFO[0].LIMITS[*]  = A_RANGE[2:3]
;                               [Default  :  [not set] ]
;               B_RANGE    :  Same as A_RANGE but for B or PARAM[1], PARINFO[1].
;               C_RANGE    :  Same as A_RANGE but for C or PARAM[2], PARINFO[2].
;               D_RANGE    :  Same as A_RANGE but for D or PARAM[3], PARINFO[3].
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/15/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [09/16/2014   v1.0.0]
;             4)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             5)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             6)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             7)  Continued to write routine
;                                                                   [10/06/2014   v1.0.0]
;             8)  Continued to write routine
;                                                                   [10/06/2014   v1.0.0]
;             9)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;            10)  Continued to write routine
;                                                                   [10/08/2014   v1.0.0]
;            11)  Continued to write routine
;                                                                   [10/21/2014   v1.0.0]
;            12)  Continued to write routine
;                                                                   [10/22/2014   v1.0.0]
;            13)  Continued to write routine
;                                                                   [10/22/2014   v1.0.0]
;            14)  Continued to write routine
;                                                                   [11/28/2014   v1.0.0]
;            15)  Finished writing routine and renamed:
;             temp_fit_evdf_para_perp_anti.pro --> wrapper_evdf_fits_para_perp_anti.pro
;             temp_init_evdf_limits_str.pro    --> evdf_fits_init_limits_str.pro
;             temp_fit_evdf_cut_wrapper.pro    --> evdf_fits_fit_to_cut_wrapper.pro
;             temp_moments_evdf_str.pro        --> evdf_fits_moments_calc_str.pro
;                                                                   [01/27/2015   v1.0.0]
;            16)  Now calls lbw_spec3d.pro instead of spec3d.pro
;                                                                   [08/15/2015   v1.1.0]
;
;   NOTES:      
;               1)  Currently using a Poisson weighting defined by WEIGHTS = 1/|Y|
;               2)  Fit Status Interpretations
;                     > 0 = success
;                     -18 = a fatal execution error has occurred.  More information may
;                           be available in the ERRMSG string.
;                     -16 = a parameter or function value has become infinite or an
;                           undefined number.  This is usually a consequence of numerical
;                           overflow in the user's model function, which must be avoided.
;                     -15 to -1 = 
;                           these are error codes that either MYFUNCT or ITERPROC may
;                           return to terminate the fitting process (see description of
;                           MPFIT_ERROR common below).  If either MYFUNCT or ITERPROC
;                           set ERROR_CODE to a negative number, then that number is
;                           returned in STATUS.  Values from -15 to -1 are reserved for
;                           the user functions and will not clash with MPFIT.
;                     0 = improper input parameters.
;                     1 = both actual and predicted relative reductions in the sum of
;                           squares are at most FTOL.
;                     2 = relative error between two consecutive iterates is at most XTOL
;                     3 = conditions for STATUS = 1 and STATUS = 2 both hold.
;                     4 = the cosine of the angle between fvec and any column of the
;                           jacobian is at most GTOL in absolute value.
;                     5 = the maximum number of iterations has been reached
;                           (may indicate failure to converge)
;                     6 = FTOL is too small. no further reduction in the sum of squares
;                           is possible.
;                     7 = XTOL is too small. no further improvement in the approximate
;                           solution x is possible.
;                     8 = GTOL is too small. fvec is orthogonal to the columns of the
;                           jacobian to machine precision.
;               3)  MPFIT routines can be found at:
;                     http://cow.physics.wisc.edu/~craigm/idl/idl.html
;               4)  Definition of WEIGHTS keyword input for MPFIT routines
;                     Array of weights to be used in calculating the chi-squared
;                     value.  If WEIGHTS is specified then the ERR parameter is
;                     ignored.  The chi-squared value is computed as follows:
;
;                         CHISQ = TOTAL( ( Y - MYFUNCT(X,P) )^2 * ABS(WEIGHTS) )
;
;                     where ERR = the measurement error (yerr variable herein).
;
;                     Here are common values of WEIGHTS for standard weightings:
;                       1D/ERR^2 - Normal or Gaussian weighting
;                       1D/Y     - Poisson weighting (counting statistics)
;                       1D       - Unweighted
;
;                     NOTE: the following special cases apply:
;                       -- if WEIGHTS is zero, then the corresponding data point
;                            is ignored
;                       -- if WEIGHTS is NaN or Infinite, and the NAN keyword is set,
;                            then the corresponding data point is ignored
;                       -- if WEIGHTS is negative, then the absolute value of WEIGHTS
;                            is used
;
;  REFERENCES:  
;               1) Markwardt, C. B. "Non-Linear Least Squares Fitting in IDL with
;                    MPFIT," in proc. Astronomical Data Analysis Software and Systems
;                    XVIII, Quebec, Canada, ASP Conference Series, Vol. 411,
;                    Editors: D. Bohlender, P. Dowler & D. Durand, (Astronomical
;                    Society of the Pacific: San Francisco), pp. 251-254,
;                    ISBN:978-1-58381-702-5, 2009.
;               2) Moré, J. 1978, "The Levenberg-Marquardt Algorithm: Implementation and
;                    Theory," in Numerical Analysis, Vol. 630, ed. G. A. Watson
;                    (Springer-Verlag: Berlin), pp. 105, doi:10.1007/BFb0067690, 1978.
;               3) Moré, J. and S. Wright "Optimization Software Guide," SIAM,
;                    Frontiers in Applied Mathematics, Number 14,
;                    ISBN:978-0-898713-22-0, 1993.
;
;   CREATED:  09/13/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/15/2015   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION evdf_fits_fit_to_cut_wrapper,data0,energy0,pang0,cut_ran,param,_EXTRA=ex_str

FORWARD_FUNCTION wrapper_multi_func_fit
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
dumb0          = d
dumb2          = REPLICATE(d,2)
dumb4          = REPLICATE(d,4)
dumb10         = REPLICATE(d,10)
tags           = ['VALUE','FIXED','LIMITED','LIMITS','TIED','MPSIDE']
tags           = [tags,'MPDERIV_DEBUG','MPDERIV_RELTOL','MPDERIV_ABSTOL']
pinfo_1        = CREATE_STRUCT(tags,d,0b,[0b,0b],[0d0,0d0],'',3,0,1d-3,1d-7)
tags00         = ['YFIT','FIT_PARAMS',  'SIG_PARAM','CHISQ','DOF','N_ITER','STATUS',$
                  'YERROR','FUNC','PARINFO','PFREE_INDEX','NPEGGED']
d_fit_struc    = CREATE_STRUCT(tags00,dumb10,dumb4,dumb4,dumb0,dumb0,-1,-1,dumb10,'',pinfo_1,-1,-1)
;;  Defaults
def_eran       = [30e0,15e3]            ;;  Default allowed energy range [eV] over which to fit
def_pawd       = 20d0                   ;;  Default angular width [degree] over which to average for each fit
def_eoran      = [1d0,1d4]              ;;  Default range of e-folding energies [eV]
def_elran      = [1d0,1d2]              ;;  Default range of (low  end) e-folding energies [eV]
def_ehran      = [1d1,1d4]              ;;  Default range of (high end) e-folding energies [eV]
def_e_min      = [1e0,1e1]              ;;  Default range of (high end) e-folding energies [eV]
;;  Dummy error messages
noinpt_msg     = 'User must supply DATA, ENERGY, PANG, CUT_RAN, and PARAM...'
nofind_msg     = 'Incorrect input format...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 5) THEN BEGIN
  MESSAGE,noinpt_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Check formats
sze0           = SIZE(energy0,/DIMENSIONS)
szd0           = SIZE(data0,/DIMENSIONS)
szp0           = SIZE(pang0,/DIMENSIONS)
szc0           = SIZE(cut_ran,/DIMENSIONS)
szm0           = SIZE(param,/DIMENSIONS)
test           = (sze0[0] NE szd0[0]) OR (sze0[1] NE szd0[1]) OR $
                 (sze0[1] NE szp0[0]) OR (szd0[1] NE szp0[0]) OR $
                 (szc0[0] NE      2L) OR (szm0[0] NE      4L)
IF (test[0]) THEN BEGIN
  MESSAGE,nofind_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define parameters
;;----------------------------------------------------------------------------------------
nne            = sze0[0]
nnd            = sze0[1]
pang1          = pang0
data1          = data0
energy1        = energy0
;;  Sort by pitch-angle
sp             = SORT(pang1)
pang           = pang1[sp]
data_pa        = data1[*,sp]
ener_pa        = energy1[*,sp]
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check ONE_C
str_element,ex_str,'ONE_C',one_c
test           = (TOTAL(SIZE(one_c,/DIMENSIONS) EQ szd0) EQ 2)
IF (test[0])   THEN g_onec = 1 ELSE g_onec = 0
IF (g_onec[0]) THEN onec_pa = one_c[*,sp] ELSE onec_pa = REPLICATE(f,szd0[0],szd0[1])
;;  Check E_LOW
str_element,ex_str,'E_LOW',e_low
test           = (N_ELEMENTS(e_low) EQ 1)
IF (test[0]) THEN BEGIN
;  IF (e_low[0] GE 0 AND FINITE(e_low[0])) THEN e_low = e_low[0] ELSE e_low = 30e0
  IF (e_low[0] GE 0 AND FINITE(e_low[0])) THEN e_low = e_low[0] ELSE e_low = def_el_eh[0]
ENDIF ELSE BEGIN
;  e_low = 30e0
  e_low = def_el_eh[0]
ENDELSE
;;  Check E_HIGH
str_element,ex_str,'E_HIGH',e_high
test           = (N_ELEMENTS(e_high) EQ 1)
IF (test[0]) THEN BEGIN
;  IF (e_high[0] GE 0 AND FINITE(e_high[0])) THEN e_high = e_high[0] ELSE e_high = 1e5
  IF (e_high[0] GE 0 AND FINITE(e_high[0])) THEN e_high = e_high[0] ELSE e_high = def_el_eh[1]
ENDIF ELSE BEGIN
;  e_high = 1e5
  e_high = def_el_eh[1]
ENDELSE
;;  Check CUT_DIR
avg_cran       = MEAN(cut_ran,/NAN)
tests          = [(avg_cran[0] LT 45e0),                          $
                  (avg_cran[0] LT 135e0 AND avg_cran[0] GE 45e0), $
                  (avg_cran[0] GE 135e0)]
good           = WHERE(tests,gd)
CASE good[0] OF
  0 : def_cdir = MIN(cut_ran,/NAN)   ;;  Parallel fit
  1 : def_cdir = avg_cran[0]         ;;  Perpendicular fit
  2 : def_cdir = MAX(cut_ran,/NAN)   ;;  Anti-parallel fit
ENDCASE
IF (good[0] EQ 1) THEN perpfit = 1 ELSE perpfit = 0
str_element,ex_str,'CUT_DIR',cut_dir
test           = (N_ELEMENTS(cut_dir) EQ 1)
IF (test[0]) THEN BEGIN
  test = (cut_dir[0] LT cut_ran[0]) OR (cut_dir[0] GT cut_ran[1])
  IF (test[0]) THEN cut_dir = def_cdir[0]
ENDIF ELSE BEGIN
  ;;  CUT_DIR not supplied by user
  cut_dir = def_cdir[0]
ENDELSE
;;  Check [A,B,C,D]_RANGE
str_element,ex_str,'A_RANGE',a_range
str_element,ex_str,'B_RANGE',b_range
str_element,ex_str,'C_RANGE',c_range
str_element,ex_str,'D_RANGE',d_range
;;  Check TIED_P and FIXED_P
str_element,ex_str,'TIED_P',tied_p
str_element,ex_str,'FIXED_P',fixed_p
;;  Check FIT_FUNC
str_element,ex_str,'FIT_FUNC',func
;IF (N_ELEMENTS(cut_dir) EQ 0) THEN func = 1
IF (N_ELEMENTS(func) EQ 0) THEN func = 1
;;  Check ITMAX and CTOL
str_element,ex_str,'ITMAX',itmax
str_element,ex_str,'CTOL',ctol
;;----------------------------------------------------------------------------------------
;;  Determine the elements that fall withing desired pitch-angle ranges
;;----------------------------------------------------------------------------------------
test_pang      = (pang GE cut_ran[0]) AND (pang LE cut_ran[1])
good_pang      = WHERE(test_pang,gd_pang,COMPLEMENT=bad_pang,NCOMPLEMENT=bd_pang)
;;----------------------------------------------------------------------------------------
;;  Fit to model function if data within constraints
;;----------------------------------------------------------------------------------------
IF (gd_pang GT 0) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Good values found --> try to fit
  ;;--------------------------------------------------------------------------------------
  ;;  Define the good data, energy, and pitch-angles
  data_pang      = data_pa[*,good_pang]
  ener_pang      = ener_pa[*,good_pang]
  pang_pang      = pang[good_pang]
  ;;  Average data over each direction
  IF (gd_pang GT 1) THEN BEGIN
    Avgf_pang      = TOTAL(data_pang,2L,/NAN)/TOTAL(FINITE(data_pang),2L,/NAN)
    AvgE_pang      = TOTAL(ener_pang,2L,/NAN)/TOTAL(FINITE(ener_pang),2L,/NAN)
  ENDIF ELSE BEGIN
    ;;  Only one pitch-angle bin in this range
    Avgf_pang      = data_pang
    AvgE_pang      = ener_pang
  ENDELSE
  IF (g_onec[0]) THEN BEGIN
    ;;  Find PA bin closest to CUT_DIR
    diff_pang      = MIN(ABS(cut_dir[0] - pang_pang),gind_pang,/NAN)
    onec_pang      = SQRT(onec_pa[*,good_pang[gind_pang[0]]])
    Avg1_pang      = onec_pang
  ENDIF ELSE BEGIN
    diff_pang      = MIN(ABS(pang_pang),gind_pang,/NAN)
    onec_pang      = REPLICATE(f,nne[0])
    Avg1_pang      = 1e-2*Avgf_pang
  ENDELSE
  ;;  Look for positive slopes > 3 keV --> Bad
  slope          = DERIV(AvgE_pang,Avgf_pang)
  test_slope     = (slope LT 0) AND (AvgE_pang LT 3e3)
  ;;  Unless user is fitting to a double exponential and and power-law
  ;;    --> then ignore positive slope and let that be fit by 2nd exponential
  ;;  LBW III  08/15/2015   v1.1.0
  IF (func[0] EQ 11) THEN test_slope = REPLICATE(1b,N_ELEMENTS(slope))
  ;;--------------------------------------------------------------------------------------
  ;;  Example:
  ;;======================================================================================
  ;;  Try fitting to Y = A X^(B) e^(C X) + D
  ;;
  ;;    Y  =  dJ/dE [flux units]
  ;;    X  =  E  [eV]
  ;;    A  =  K  [some constant] = Lim_{E --> Infinity} (dJ/dE) ~ 10^(6) - 10^(9)
  ;;    B  =  -¥ = power-law slope = spectral index
  ;;    C  =  -1/E_o, E_o = e-folding energy [eV]
  ;;    D  =  Lim_{E --> Infinity} (dJ/dE) ~ 0
  ;;--------------------------------------------------------------------------------------
  ;;  Use only those elements which satisfy the following two constraints:
  ;;    1)  E > E_min           [user defined]
  ;;    2)  f > (f_1c)^(1/2)    [f_1c = one-count level]
  ;;--------------------------------------------------------------------------------------
  test_pang_fit  =  (AvgE_pang GE e_low[0]) AND (AvgE_pang LE e_high[0]) AND $
                   ((Avgf_pang GE Avg1_pang) AND (Avgf_pang GT 0) AND FINITE(Avgf_pang))
  good_pang_fit  = WHERE(test_pang_fit AND test_slope,gd_pang_fit,COMPLEMENT=bad_pang_fit,NCOMPLEMENT=bd_pang_fit)
  IF (gd_pang_fit GT 0) THEN BEGIN
    x              = AvgE_pang[good_pang_fit]
    y              = Avgf_pang[good_pang_fit]
    yerr           = ABS(y - Avg1_pang[good_pang_fit])
;    wghts          = 1d0/(ABS(yerr)^2)        ;;  Gaussian weighting
    wghts          = 1d0/ABS(y)               ;;  Poisson weighting
    fit_str_pang   = wrapper_multi_func_fit(x,y,param,FIT_FUNC=func[0],ERROR=yerr,        $
                                            WEIGHTS=wghts,A_RANGE=a_range,B_RANGE=b_range,$
                                            C_RANGE=c_range,D_RANGE=d_range,TIED_P=tied_p,$
                                            FIXED_P=fixed_p,ITMAX=itmax,CTOL=ctol,/P_QUIET)
    IF (SIZE(fit_str_pang,/TYPE) NE 8L) THEN BEGIN
      ;;  Fit failed or bad input
      ;;    --> Return dummy (formatted) results
      x            = dumb10
      y            = dumb10
      yerr         = dumb10
      fit_str_pang = d_fit_struc
    ENDIF
  ENDIF ELSE BEGIN
    ;;  No finite data within constraints --> use dummy values
    x            = dumb10
    y            = dumb10
    yerr         = dumb10
    fit_str_pang = d_fit_struc
  ENDELSE
ENDIF ELSE BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Nothing within 20 degrees of 0 was found --> No parallel fit
  ;;--------------------------------------------------------------------------------------
  pang_pang      = dumb10
  diff_pang      = dumb10
  data_pang      = dumb10
  ener_pang      = dumb10
  onec_pang      = dumb10
  Avgf_pang      = dumb10
  AvgE_pang      = dumb10
  Avg1_pang      = dumb10
  x              = dumb10
  y              = dumb10
  yerr           = dumb10
  fit_str_pang   = d_fit_struc
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Define output structure
;;----------------------------------------------------------------------------------------
data_str       = {DATA_SORT:data_pa,DATA_PANG:data_pang,AVG_DATA:Avgf_pang,FIT_DATA:y}
ener_str       = {ENER_SORT:ener_pa,ENER_PANG:ener_pang,AVG_ENER:AvgE_pang,FIT_ENER:x}
onec_str       = {ONEC_SORT:onec_pa,ONEC_PANG:onec_pang,AVG_ONEC:Avg1_pang,FIT_ONEC:yerr}
struc          = {DATA:data_str,ENERGY:ener_str,ONE_C:onec_str,FIT:fit_str_pang,CONSTRAINTS:ex_str}
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,struc
END


;*****************************************************************************************
;
;  FUNCTION :   evdf_fits_moments_calc_str.pro
;  PURPOSE  :   This routine calculates the moments of the input velocity distribution
;                 function then defines strings for the density, Avg. temperature, both
;                 parallel and perpendicular temperatures, and temperature anisotropy.
;                 These strings are then appended to the X-Axis Title for output.
;
;  CALLED BY:   
;               wrapper_evdf_fits_para_perp_anti.pro
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               str_element.pro
;               moments_3d_new.pro
;               get_font_symbol.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DATA       :  Scalar [structure] associated with a known THEMIS ESA
;                               data structure [see get_th?_peib.pro, ? = a-f]
;                               or a Wind/3DP data structure
;                               [see get_?.pro, ? = el, elb, pl, ph, eh, etc.]
;
;  EXAMPLES:    
;               limits = evdf_fits_moments_calc_str(data,LIMITS=limits)
;
;  KEYWORDS:    
;               LIMITS     :  Scalar [structure] that may contain any combination of the
;                               following structure tags or keywords accepted by
;                               PLOT.PRO:
;                                 XLOG,   YLOG,   ZLOG,
;                                 XRANGE, YRANGE, ZRANGE,
;                                 XTITLE, YTITLE,
;                                 TITLE, POSITION, REGION, etc.
;                                 (see IDL documentation for a description)
;               VDF_MOMS   :  Set to a named variable to return the velocity moment
;                               results returned by moments_3d_new.pro
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/16/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             4)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             5)  Continued to write routine
;                                                                   [10/06/2014   v1.0.0]
;             6)  Continued to write routine
;                                                                   [10/06/2014   v1.0.0]
;             7)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             8)  Continued to write routine
;                                                                   [10/08/2014   v1.0.0]
;             9)  Continued to write routine
;                                                                   [10/21/2014   v1.0.0]
;            10)  Continued to write routine
;                                                                   [10/21/2014   v1.0.0]
;            11)  Continued to write routine
;                                                                   [10/21/2014   v1.0.0]
;            12)  Continued to write routine
;                                                                   [10/22/2014   v1.0.0]
;            13)  Continued to write routine
;                                                                   [10/22/2014   v1.0.0]
;            14)  Continued to write routine
;                                                                   [11/28/2014   v1.0.0]
;            15)  Finished writing routine and renamed:
;             temp_fit_evdf_para_perp_anti.pro --> wrapper_evdf_fits_para_perp_anti.pro
;             temp_init_evdf_limits_str.pro    --> evdf_fits_init_limits_str.pro
;             temp_fit_evdf_cut_wrapper.pro    --> evdf_fits_fit_to_cut_wrapper.pro
;             temp_moments_evdf_str.pro        --> evdf_fits_moments_calc_str.pro
;                                                                   [01/27/2015   v1.0.0]
;            16)  Now calls lbw_spec3d.pro instead of spec3d.pro
;                                                                   [08/15/2015   v1.1.0]
;
;   NOTES:      
;               1)  If this routine is called when SET_PLOT,'X' is the current
;                     graphics device, then the font symbols may not be the same
;                     in the 'PS' graphics device if the font settings changed.
;                     Thus, the routine may need to be called for both X-Win plots
;                     and for output to PS files.
;
;  REFERENCES:  
;               NA
;
;   CREATED:  09/15/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/15/2015   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION evdf_fits_moments_calc_str,data,LIMITS=limit0,VDF_MOMS=vdf_moms

FORWARD_FUNCTION test_wind_vs_themis_esa_struct,moments_3d_new,get_font_symbol
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Dummy error messages
noinpt_msg     = 'User must supply an a velocity distribution function as an IDL structure...'
nofind_msg     = 'No finite data for this VDF...'
notstr_msg     = 'Must be an IDL structure...'
notvdf_msg     = 'Input must be a velocity distribution function as an IDL structure...'
badvdf_msg     = 'Input must be an IDL structure with similar format to Wind/3DP or THEMIS/ESA...'
not3dp_msg     = 'Input must be a velocity distribution IDL structure from Wind/3DP...'
notthm_msg     = 'Input must be a velocity distribution IDL structure from THEMIS/ESA...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 1) THEN BEGIN
  MESSAGE,noinpt_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
IF (SIZE(data,/TYPE) NE 8L) THEN BEGIN
  MESSAGE,notstr_mssg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
dat            = data[0]
;;  Check to make sure distribution has the correct format
test0          = test_wind_vs_themis_esa_struct(dat[0],/NOM)
test           = (test0.(0) + test0.(1)) NE 1
IF (test[0]) THEN BEGIN
  MESSAGE,notvdf_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Re-define data structure
dat0           = dat[0]
;;----------------------------------------------------------------------------------------
;;  Check LIMITS
;;----------------------------------------------------------------------------------------
IF (!D.NAME EQ 'X') THEN ymargin = [10,4] ELSE ymargin = [6,2]
spacing        = 1.2
;;  Get current character size
chsz_old       = !P.CHARSIZE
;;  Set LIMITS.YMARGIN
IF (SIZE(limit0,/TYPE) NE 8) THEN BEGIN
  str_element,limits,'YMARGIN',ymargin,/ADD_REPLACE
ENDIF ELSE BEGIN
  limits = limit0
  str_element,limits,'YMARGIN',ymargin,/ADD_REPLACE
ENDELSE
;;  Check for LIMITS.CHARSIZE
;;    --> Use to define line spacing
str_element,limits,'CHARSIZE',chsz
test           = (N_ELEMENTS(chsz) EQ 0) AND (chsz_old[0] EQ 0)
ratio          = FLOAT(!D.Y_CH_SIZE)/FLOAT(!D.Y_SIZE)
IF (test[0]) THEN BEGIN
  line_space = ratio[0]*spacing[0]
ENDIF ELSE BEGIN
  IF (chsz_old[0] EQ 0) THEN charsize = chsz[0] ELSE charsize = chsz_old[0]
  line_space = ratio[0]*(spacing[0] > charsize[0])
ENDELSE
;;  Check for LIMITS.XTITLE
str_element,limits,'XTITLE',xttle
IF (N_ELEMENTS(xttle) EQ 0) THEN BEGIN
  xttle = 'Energy [eV]'
ENDIF ELSE BEGIN
  xlen   = STRLEN(xttle) GT 15
  IF (xlen[0]) THEN BEGIN
    gposi = STRPOS(xttle[0],'!C')
    ;;  routine was already called
    ;;    --> remove appended strings in case DEVICE settings have changed
    ;;      --> redefine within current DEVICE
    IF (gposi[0] GT 0) THEN xttle = STRMID(xttle[0],0L,gposi[0])
  ENDIF
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Compute moments of VDF
;;----------------------------------------------------------------------------------------
sform          = moments_3d_new()
str_element,dat0,'SC_POT',scpot
IF (N_ELEMENTS(scpot) EQ 0) THEN scpot = 0.
IF (FINITE(scpot) EQ 0) THEN scpot = 0.
str_element,dat0,'MAGF',magf
IF (N_ELEMENTS(magf) NE 3) THEN magf = [-1e0,1e0,0e0]/SQRT(2e0)
extra          = {FORMAT:sform,DOMEGA_WEIGHTS:1,SC_POT:scpot[0],MAGDIR:magf}
del            = dat0[0]
vdf_moms       = moments_3d_new(del,_EXTRA=extra)
;;  Define N, T, Tpara, Tperp, Tanis
vdf__dens      = vdf_moms[0].DENSITY                ;;  Particle density [# cm^(-3)]
vdf__avgT      = vdf_moms[0].AVGTEMP                ;;  Avg. temperature [eV]
vdf__T3_B      = vdf_moms[0].MAGT3                  ;;  Temperature tensor components {perp1,perp2,para} [eV]
vdf_Tpara      = vdf__T3_B[2]                       ;;  Tpara [eV]
vdf_Tperp      = (vdf__T3_B[0] + vdf__T3_B[1])/2e0  ;;  Tperp [eV]
vdf_Tanis      = vdf_Tperp[0]/vdf_Tpara[0]          ;;  Tperp/Tpara
;;----------------------------------------------------------------------------------------
;;  Convert results to strings
;;----------------------------------------------------------------------------------------
mform          = '(e15.3)'
vdf_N_T_string = STRTRIM(STRING([vdf__dens[0],vdf__avgT[0]],FORMAT=mform),2L)
vdf_T12_string = STRTRIM(STRING([vdf_Tperp[0],vdf_Tpara[0]],FORMAT=mform),2L)
vdf_Tan_string = STRTRIM(STRING(vdf_Tanis[0],FORMAT=mform),2L)

perp_string    = get_font_symbol('perpendicular')
para_string    = get_font_symbol('parallel')
IF (para_string[0] EQ '') THEN para_string = '||'
subs           = '!D'+[perp_string[0],para_string[0]]+'!N'
tanis_string   = '(T'+subs[0]+'/T'+subs[1]+')!De!N'
units_suffx    = ['cm!U-3!N','eV']
label_prefx    = [['N','T']+'!De!N','T'+subs+'!De!N',tanis_string[0]]+' = '
Ne_Te_string   = label_prefx[0]+vdf_N_T_string[0]+' '+units_suffx[0]+'; '
Ne_Te_string   = Ne_Te_string[0]+label_prefx[1]+vdf_N_T_string[1]+' '+units_suffx[1]
T12___string   = label_prefx[2]+vdf_T12_string[0]+' '+units_suffx[1]+'; '
T12___string   = T12___string[0]+label_prefx[3]+vdf_T12_string[1]+' '+units_suffx[1]
Tanis_string   = label_prefx[4]+vdf_Tan_string[0]
moms__string   = [Ne_Te_string[0],T12___string[0],Tanis_string[0]]
;;----------------------------------------------------------------------------------------
;;  Append moment results to LIMITS.XTITLE using the SUBTITLE option
;;----------------------------------------------------------------------------------------
subttl         = moms__string
str_element,limits,'XSUBTITLE',subttl,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,limits
END

;+
;*****************************************************************************************
;
;  FUNCTION :   wrapper_evdf_fits_para_perp_anti.pro
;  PURPOSE  :   This is a wrapping routine that takes an input velocity distribution
;                 function, in the form of an IDL structure, and then fits cuts of the
;                 data along the parallel, perpendicular, and anti-parallel directions
;                 to a power-law, exponential, power-law+exponential, or a
;                 power-law+double-exponential with one of the forms:
;
;                 *******************
;                   Y = A X^(B) + C
;                 *******************
;                 where the physical interpretation of the parameters are:
;                   Y  :  dJ/dE  = differential intensity
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;                   X  :   E     = particle kinetic energy
;                                  [eV]
;                   A  :   K     = Lim_{E --> 0} (dJ/dE)
;                                  [~10^(6) for electrons]
;                   B  :  -¥     = power-law slope or spectral index
;                                  [unitless]
;                   C  :  dJdE_o = Lim_{E --> Infinity} (dJ/dE) ~ 0
;                                  { expect:  ~ 0 for reasonable particles }
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;
;                 *********************
;                   Y = A e^(B X) + C
;                 *********************
;                 where the physical interpretation of the parameters are:
;                   Y  :  dJ/dE  = differential intensity
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;                   X  :   E     = particle kinetic energy
;                                  [eV]
;                   A  :   K     = Lim_{E --> 0} (dJ/dE)
;                                  [~10^(6) for electrons]
;                   B  :  -1/E_o = inverse of e-folding energy
;                                  { where:  E_o ~ 100's of eV for electrons }
;                                  [eV^(-1)]
;                   C  :  dJdE_o = Lim_{E --> Infinity} (dJ/dE) ~ 0
;                                  { expect:  ~ 0 for reasonable particles }
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;
;                 ***************************
;                   Y = A X^(B) e^(C X) + D
;                 ***************************
;                 where the physical interpretation of the parameters are:
;                   Y  :  dJ/dE  = differential intensity
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;                   X  :   E     = particle kinetic energy
;                                  [eV]
;                   A  :   K     = Lim_{E --> 0} (dJ/dE)
;                                  [~10^(6) for electrons]
;                   B  :  -¥     = power-law slope or spectral index
;                                  [unitless]
;                   C  :  -1/E_o = inverse of e-folding energy
;                                  { where:  E_o ~ 100's of eV for electrons }
;                                  [eV^(-1)]
;                   D  :  dJdE_o = Lim_{E --> Infinity} (dJ/dE) ~ 0
;                                  { expect:  ~ 0 for reasonable particles }
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;
;                 *******************************
;                   Y = A X^(B) e^(C X) e^(D X)
;                 *******************************
;                 where the physical interpretation of the parameters are:
;                   Y  :  dJ/dE  = differential intensity
;                                  [# cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;                   X  :   E     = particle kinetic energy
;                                  [eV]
;                   A  :   K     = Lim_{E --> 0} (dJ/dE)
;                                  [~10^(5) - 10^(7) for electrons]
;                   B  :  -¥     = power-law slope or spectral index
;                                  [unitless]
;                   C  :  -1/E_L = inverse of e-folding energy of low energy electrons
;                                  { where:  E_L ~ 10's of eV for electrons }
;                                  [eV^(-1)]
;                   D  :  -1/E_H = inverse of e-folding energy of low energy electrons
;                                  { where:  E_H ~ 100's of eV for electrons }
;                                  [eV^(-1)]
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               evdf_fits_init_limits_str.pro
;               evdf_fits_fit_to_cut_wrapper.pro
;               evdf_fits_moments_calc_str.pro
;
;  CALLS:
;               evdf_fits_init_limits_str.pro
;               str_element.pro
;               extract_tags.pro
;               evdf_fits_fit_to_cut_wrapper.pro
;               get_greek_letter.pro
;               popen.pro
;               evdf_fits_moments_calc_str.pro
;               pclose.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DATA       :  Scalar [structure] associated with a known THEMIS ESA
;                               data structure [see get_th?_peib.pro, ? = a-f]
;                               or a Wind/3DP data structure
;                               [see get_?.pro, ? = el, elb, pl, ph, eh, etc.]
;
;  EXAMPLES:    
;               ;;------------------------------------------------------------------------
;               ;;  To fit in spacecraft frame (SCF)
;               ;;------------------------------------------------------------------------
;               func   = 1     ;;  Fit to:  Y = A X^(B) + C
;               pa_wd  = 25d0  ;;  Use 25 degree pitch-angle bin width
;               ;;------------------------------------------------------------------------
;               ;;  Define LIMITS structure
;               ;;------------------------------------------------------------------------
;               xran   = [1d0,30d3]
;               yran   = [1d-1,2d7]
;               l10yr  = ALOG10(yran*[1d1,5d-1])
;               temp   = DINDGEN(nnd[0])*(l10yr[1] - l10yr[0])/(nnd[0] - 1L) + l10yr[0]
;               yposi  = 1d1^(temp)
;               limits = {XRANGE:xran,XSTYLE:1,YRANGE:yran,YSTYLE:1,LABPOS:yposi}
;               ;;------------------------------------------------------------------------
;               ;;  Call routine in one of two ways:
;               ;;    1)  Use explicit keyword settings
;               ;;------------------------------------------------------------------------
;               temp = wrapper_evdf_fits_para_perp_anti(data,LIMITS=limits,FIT_FUNC=func,$
;                                                   /ERA_1C_SC,PA_BIN_WD=pa_wd,/SC_FRAME)
;               ;;------------------------------------------------------------------------
;               ;;    2)  Use passive transfer keyword settings
;               ;;------------------------------------------------------------------------
;               extra  = {LIMITS:limits,FIT_FUNC:func,ERA_1C_SC:1,PA_BIN_WD:pa_wd,$
;                         SC_FRAME:1}
;               temp = wrapper_evdf_fits_para_perp_anti(data,_EXTRA=extra)
;
;  KEYWORDS:    
;               **********************************
;               ***       DIRECT  INPUTS       ***
;               **********************************
;               LIMITS     :  Scalar [structure] that may contain any combination of the
;                               following structure tags or keywords accepted by
;                               PLOT.PRO:
;                                 XLOG,   YLOG,   ZLOG,
;                                 XRANGE, YRANGE, ZRANGE,
;                                 XTITLE, YTITLE,
;                                 TITLE, POSITION, REGION, etc.
;                                 (see IDL documentation for a description)
;               PARAM      :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see FIT_FUNC below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = D
;               FIT_FUNC   :  Scalar [integer] specifying the type of function to use
;                               [Default  :  1]
;                               1  :  Y = A X^(B) + C
;                               2  :  Y = A e^(B X) + C
;                               3  :  Y = A + B Log_{e} |X^C|
;                               4  :  Y = A X^(B) e^(C X) + D
;                               5  :  Y = A B^(X) + C
;                               6  :  Y = A B^(C X) + D
;                               7  :  Y = ( A + B X )^(-1)
;                               8  :  Y = ( A B^(X) + C )^(-1)
;                               9  :  Y = A X^(B) ( e^(C X) + D )^(-1)
;                              10  :  Y = A + B Log_{10} |X| + C (Log_{10} |X|)^2
;                              11  :  Y = A X^(B) e^(C X) e^(D X)
;               FIXED_P    :  [4]-Element array containing zeros for each element of
;                               PARAM the user does NOT wish to vary (i.e., if FIXED_P[0]
;                               is = 0, then PARAM[0] will not change when calling
;                               MPFITFUN.PRO).
;                               [Default  :  FIXED_P[*] = 1]
;               A_RANGE    :  [4]-Element [float/double] array defining the range of
;                               allowed values to use for A or PARAM[0].  Note, if this
;                               keyword is set, it is equivalent to telling the routine
;                               that A should be limited by these bounds.  Setting this
;                               keyword will define:
;                                 PARINFO[0].LIMITED[*] = BYTE(A_RANGE[0:1])
;                                 PARINFO[0].LIMITS[*]  = A_RANGE[2:3]
;                               [Default  :  [not set] ]
;               B_RANGE    :  Same as A_RANGE but for B or PARAM[1], PARINFO[1].
;               C_RANGE    :  Same as A_RANGE but for C or PARAM[2], PARINFO[2].
;               D_RANGE    :  Same as A_RANGE but for D or PARAM[3], PARINFO[3].
;               E_RANGE    :  [2]-Element [float/double] array defining the range of
;                               energies [eV] over which data will be allowed in fit
;                               [ Default  :  [30,15000] ]
;               EO_RA      :  [2]-Element [float/double] array defining the range of
;                               e-folding energies [eV] relevant to model fit functions
;                               2, 4, and 9
;                               [ Default  :  [10,1000] ]
;               ERA_1C_SC  :  If set, routine defines the range of viable energies to
;                               allow in fitting by cutting off the lower bound at the
;                               spacecraft potential and the upper bound at the point
;                               where the data falls within a factor of 2 of the
;                               one-count level
;                               [Default  :  FALSE ]
;               PA_BIN_WD  :  Scalar [float/double] defining the angular width [degrees]
;                               over which to average for each fit direction
;                               [Default  :  20 ]
;               SC_FRAME   :  If set, routine will fit the data in the spacecraft frame
;                               of reference rather than the eVDF's bulk flow frame
;                               [Default  :  FALSE ]
;               FILE_DIR   :  Scalar [string] defining the directory in which to place
;                               output fit plot results
;                               [Default  :  FILE_EXPAND_PATH('') ]
;               VERSION    :  Scalar [string or integer] defining whether [TRUE] or not
;                               [FALSE] to output the current routine version and date
;                               to be placed on outside of lower-right-hand corner.
;                               If a string is supplied, the string is output.  If TRUE
;                               is supplied, then routine_version.pro is called to get
;                               the current version and date/time for output.
;                               [Default  :  FALSE]
;               EL_RA      :  [2]-Element [float/double] array defining the range of
;                               (low end) e-folding energies [eV] relevant to model fit
;                               function 11
;                               [ Default  :  [1,100] ]
;               EH_RA      :  [2]-Element [float/double] array defining the range of
;                               (high end) e-folding energies [eV] relevant to model fit
;                               function 11
;                               [ Default  :  [10,1000] ]
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/15/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [09/16/2014   v1.0.0]
;             4)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             5)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             6)  Continued to write routine
;                                                                   [09/30/2014   v1.0.0]
;             7)  Continued to write routine
;                                                                   [10/06/2014   v1.0.0]
;             8)  Continued to write routine
;                                                                   [10/06/2014   v1.0.0]
;             9)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;            10)  Continued to write routine
;                                                                   [10/08/2014   v1.0.0]
;            11)  Continued to write routine
;                                                                   [10/21/2014   v1.0.0]
;            12)  Continued to write routine
;                                                                   [10/22/2014   v1.0.0]
;            13)  Continued to write routine
;                                                                   [10/22/2014   v1.0.0]
;            14)  Continued to write routine
;                                                                   [11/28/2014   v1.0.0]
;            15)  Finished writing routine and renamed:
;             temp_fit_evdf_para_perp_anti.pro --> wrapper_evdf_fits_para_perp_anti.pro
;             temp_init_evdf_limits_str.pro    --> evdf_fits_init_limits_str.pro
;             temp_fit_evdf_cut_wrapper.pro    --> evdf_fits_fit_to_cut_wrapper.pro
;             temp_moments_evdf_str.pro        --> evdf_fits_moments_calc_str.pro
;                                                                   [01/27/2015   v1.0.0]
;            16)  Now calls lbw_spec3d.pro instead of spec3d.pro
;                                                                   [08/15/2015   v1.1.0]
;
;   NOTES:      
;               1)  Use of the ERA_1C_SC keyword will override the E_RANGE keyword
;                     if set and will define the lower bound by the following:
;                       DATA.SC_POT > (3*Te)
;                     where Te = average electron temperature computed from DATA
;               2)  Fit Status Interpretations
;                     > 0 = success
;                     -18 = a fatal execution error has occurred.  More information may
;                           be available in the ERRMSG string.
;                     -16 = a parameter or function value has become infinite or an
;                           undefined number.  This is usually a consequence of numerical
;                           overflow in the user's model function, which must be avoided.
;                     -15 to -1 = 
;                           these are error codes that either MYFUNCT or ITERPROC may
;                           return to terminate the fitting process (see description of
;                           MPFIT_ERROR common below).  If either MYFUNCT or ITERPROC
;                           set ERROR_CODE to a negative number, then that number is
;                           returned in STATUS.  Values from -15 to -1 are reserved for
;                           the user functions and will not clash with MPFIT.
;                     0 = improper input parameters.
;                     1 = both actual and predicted relative reductions in the sum of
;                           squares are at most FTOL.
;                     2 = relative error between two consecutive iterates is at most XTOL
;                     3 = conditions for STATUS = 1 and STATUS = 2 both hold.
;                     4 = the cosine of the angle between fvec and any column of the
;                           jacobian is at most GTOL in absolute value.
;                     5 = the maximum number of iterations has been reached
;                           (may indicate failure to converge)
;                     6 = FTOL is too small. no further reduction in the sum of squares
;                           is possible.
;                     7 = XTOL is too small. no further improvement in the approximate
;                           solution x is possible.
;                     8 = GTOL is too small. fvec is orthogonal to the columns of the
;                           jacobian to machine precision.
;               3)  MPFIT routines can be found at:
;                     http://cow.physics.wisc.edu/~craigm/idl/idl.html
;               4)  Definition of WEIGHTS keyword input for MPFIT routines
;                     Array of weights to be used in calculating the chi-squared
;                     value.  If WEIGHTS is specified then the ERR parameter is
;                     ignored.  The chi-squared value is computed as follows:
;
;                         CHISQ = TOTAL( ( Y - MYFUNCT(X,P) )^2 * ABS(WEIGHTS) )
;
;                     where ERR = the measurement error (yerr variable herein).
;
;                     Here are common values of WEIGHTS for standard weightings:
;                       1D/ERR^2 - Normal or Gaussian weighting
;                       1D/Y     - Poisson weighting (counting statistics)
;                       1D       - Unweighted
;
;                     NOTE: the following special cases apply:
;                       -- if WEIGHTS is zero, then the corresponding data point
;                            is ignored
;                       -- if WEIGHTS is NaN or Infinite, and the NAN keyword is set,
;                            then the corresponding data point is ignored
;                       -- if WEIGHTS is negative, then the absolute value of WEIGHTS
;                            is used
;          ***  5)  Need to remove the (+ slope) = "bad" criteria in fit wrapping
;                     routine when FIT_FUNC = 11
;
;  REFERENCES:  
;               1) Markwardt, C. B. "Non-Linear Least Squares Fitting in IDL with
;                    MPFIT," in proc. Astronomical Data Analysis Software and Systems
;                    XVIII, Quebec, Canada, ASP Conference Series, Vol. 411,
;                    Editors: D. Bohlender, P. Dowler & D. Durand, (Astronomical
;                    Society of the Pacific: San Francisco), pp. 251-254,
;                    ISBN:978-1-58381-702-5, 2009.
;               2) Moré, J. 1978, "The Levenberg-Marquardt Algorithm: Implementation and
;                    Theory," in Numerical Analysis, Vol. 630, ed. G. A. Watson
;                    (Springer-Verlag: Berlin), pp. 105, doi:10.1007/BFb0067690, 1978.
;               3) Moré, J. and S. Wright "Optimization Software Guide," SIAM,
;                    Frontiers in Applied Mathematics, Number 14,
;                    ISBN:978-0-898713-22-0, 1993.
;               4)  The IDL MINPACK routines can be found on Craig B. Markwardt's site at:
;                     http://cow.physics.wisc.edu/~craigm/idl/fitting.html
;               5)  McFadden, J.P., C.W. Carlson, D. Larson, M. Ludlam, R. Abiad,
;                      B. Elliot, P. Turin, M. Marckwordt, and V. Angelopoulos
;                      "The THEMIS ESA Plasma Instrument and In-flight Calibration,"
;                      Space Sci. Rev. 141, pp. 277-302, (2008).
;               6)  McFadden, J.P., C.W. Carlson, D. Larson, J.W. Bonnell,
;                      F.S. Mozer, V. Angelopoulos, K.-H. Glassmeier, U. Auster
;                      "THEMIS ESA First Science Results and Performance Issues,"
;                      Space Sci. Rev. 141, pp. 477-508, (2008).
;               7)  Carlson et al., (1983), "An instrument for rapidly measuring
;                      plasma distribution functions with high resolution,"
;                      Adv. Space Res. Vol. 2, pp. 67-70.
;               8)  Curtis et al., (1989), "On-board data analysis techniques for
;                      space plasma particle instruments," Rev. Sci. Inst. Vol. 60,
;                      pp. 372.
;               9)  Lin et al., (1995), "A Three-Dimensional Plasma and Energetic
;                      particle investigation for the Wind spacecraft," Space Sci. Rev.
;                      Vol. 71, pp. 125.
;              10)  Paschmann, G. and P.W. Daly (1998), "Analysis Methods for Multi-
;                      Spacecraft Data," ISSI Scientific Report, Noordwijk, 
;                      The Netherlands., Int. Space Sci. Inst.
;
;   CREATED:  09/13/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/15/2015   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION wrapper_evdf_fits_para_perp_anti,data,_EXTRA=ex_str

;*****************************************************************************************
ex_start = SYSTIME(1)
;*****************************************************************************************
FORWARD_FUNCTION evdf_fits_init_limits_str,evdf_fits_fit_to_cut_wrapper,$
                 evdf_fits_moments_calc_str,get_greek_letter
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
struc          = 0
dumb0          = d
dumb2          = REPLICATE(d,2)
dumb4          = REPLICATE(d,4)
dumb10         = REPLICATE(d,10)
tags           = ['VALUE','FIXED','LIMITED','LIMITS','TIED','MPSIDE']
tags           = [tags,'MPDERIV_DEBUG','MPDERIV_RELTOL','MPDERIV_ABSTOL']
pinfo_1        = CREATE_STRUCT(tags,d,0b,[0b,0b],[0d0,0d0],'',3,0,1d-3,1d-7)
tags00         = ['YFIT','FIT_PARAMS',  'SIG_PARAM','CHISQ','DOF','N_ITER','STATUS',$
                  'YERROR','FUNC','PARINFO','PFREE_INDEX','NPEGGED']
d_fit_struc    = CREATE_STRUCT(tags00,dumb10,dumb4,dumb4,dumb0,dumb0,-1,-1,dumb10,'',pinfo_1,-1,-1)
;;  Defaults
def_eran       = [30e0,15e3]            ;;  Default allowed energy range [eV] over which to fit
def_pawd       = 20d0                   ;;  Default angular width [degree] over which to average for each fit
def_eoran      = [1d0,1d4]              ;;  Default range of e-folding energies [eV]
def_elran      = [1d0,1d2]              ;;  Default range of (low  end) e-folding energies [eV]
def_ehran      = [1d1,1d4]              ;;  Default range of (high end) e-folding energies [eV]
def_e_min      = [1e0,1e1]              ;;  Default range of (high end) e-folding energies [eV]
;;  Dummy logic variables
parallel_fit   = 1
perpendi_fit   = 1
antipara_fit   = 1
;;  Dummy error messages
noinpt_msg     = 'User must supply an a velocity distribution function as an IDL structure...'
nofind_msg     = 'No finite data for this VDF...'
notstr_msg     = 'Must be an IDL structure...'
notvdf_msg     = 'Input must be a velocity distribution function as an IDL structure...'
badvdf_msg     = 'Input must be an IDL structure with similar format to Wind/3DP or THEMIS/ESA...'
not3dp_msg     = 'Input must be a velocity distribution IDL structure from Wind/3DP...'
notthm_msg     = 'Input must be a velocity distribution IDL structure from THEMIS/ESA...'
;;----------------------------------------------------------------------------------------
;;  Initialize data structure and LIMITS structure
;;----------------------------------------------------------------------------------------
init_struc     = evdf_fits_init_limits_str(data,_EXTRA=ex_str)
IF (SIZE(init_struc,/TYPE) NE 8L) THEN BEGIN
  RETURN,0b
ENDIF
;;  Define eVDF data structures
str_element,init_struc,           'DATA',         dat0  ;;  Input eVDF data structure [counts, SC-Frame]
str_element,init_struc,         'DAT_1C',        dat1c  ;;  One-count copy of eVDF [counts, SC-Frame]
str_element,init_struc,         'DAT__F',        dat2f  ;;  Input eVDF data structure [flux, SC-Frame]
str_element,init_struc,         'ONE_C0',        onec0  ;;  One-count levels [flux, SW-Frame]
;;  Define LIMITS structure
str_element,init_struc,         'LIMITS',       limits
;;  Define outputs from lbw_spec3d.pro
str_element,init_struc,         'P_ANGS',        pang0  ;;  Pitch-angle bins [degrees]
str_element,init_struc,        'PA_COLS',      pa_cols
str_element,init_struc,         'DATA_0',        data0  ;;  Data sorted by pitch-angle bins [flux units]
str_element,init_struc,       'ENERGY_0',      energy0  ;;  Energies [eV] sorted by pitch-angle bins
;;  Define fit structure and check tags
str_element,init_struc,      'FIT_STRUC',   fit_struct  ;;  Structure containing relevant inputs for fit functions
str_element,fit_struct,'FIT_FUNC_STRING', fit_f_string  ;;  e.g., 'Y = A X^(B) + C'
str_element,fit_struct,   'FIT_FUNC_NUM',         func  ;;  e.g., 1 <--> 'Y = A X^(B) + C' model function
str_element,fit_struct, 'FIT_FUNC_FNMID',   fitf_fnmid  ;;  e.g., 'Power-Law_0_'
str_element,fit_struct,          'PARAM',        param  ;;  [4]-Element array defining parameters A-D in model functions
str_element,fit_struct,        'FIXED_P',      fixed_p  ;;  [4]-Element array specifying which parameters A-D can be varied during fit
str_element,fit_struct,        'A_RANGE',         aran  ;;  [4]-Element array (see Man. page for more)
str_element,fit_struct,        'B_RANGE',         bran  ;;  " "
str_element,fit_struct,        'C_RANGE',         cran  ;;  " "
str_element,fit_struct,        'D_RANGE',      d_range  ;;  " "
str_element,fit_struct,     'ENER_RANGE',      e_range  ;;  [2]-Element array defining the allowed energies [eV] to use in fit
str_element,fit_struct,      'E_O_RANGE',       Eo_ran  ;;  [2]-Element array defining the range of e-folding energies [eV] to allow in fit
str_element,fit_struct,      'E_L_RANGE',       El_ran  ;;  [2]-Element array defining the range of e-folding energies [eV] to allow in fit
str_element,fit_struct,      'E_H_RANGE',       Eh_ran  ;;  [2]-Element array defining the range of e-folding energies [eV] to allow in fit
;;  Define extra outputs
str_element,init_struc,      'FILE_NAME',fit_file_name  ;;  String defining the name of the output PS showing the fit results
str_element,init_struc,        'PARA_RA',      para_ra  ;;  [2]-Element array defining the range [degrees] of pitch-angles (PA) to average over for parallel fit
str_element,init_struc,        'PERP_RA',      perp_ra  ;;  " " for perpendicular fit
str_element,init_struc,        'ANTI_RA',      anti_ra  ;;  " " for anti-parallel fit
str_element,init_struc,        'VERSION',    r_version  ;;  String defining the current routine version and date
;;  Define _EXTRA structure for evdf_fits_fit_to_cut_wrapper.pro
str_element,extra_00, 'CUT_DIR',       0e0,/ADD_REPLACE
str_element,extra_00,   'E_LOW',e_range[0],/ADD_REPLACE
str_element,extra_00,  'E_HIGH',e_range[1],/ADD_REPLACE
str_element,extra_00,   'ONE_C',     onec0,/ADD_REPLACE
str_element,extra_00,'FIT_FUNC',      func,/ADD_REPLACE
IF (N_ELEMENTS(aran)    EQ 4) THEN str_element,extra_00,'A_RANGE',   aran,/ADD_REPLACE
IF (N_ELEMENTS(bran)    EQ 4) THEN str_element,extra_00,'B_RANGE',   bran,/ADD_REPLACE
IF (N_ELEMENTS(cran)    EQ 4) THEN str_element,extra_00,'C_RANGE',   cran,/ADD_REPLACE
IF (N_ELEMENTS(d_range) EQ 4) THEN str_element,extra_00,'D_RANGE',d_range,/ADD_REPLACE
IF (N_ELEMENTS(fixed_p) EQ 4) THEN str_element,extra_00,'FIXED_P',fixed_p,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Compute Fits
;;----------------------------------------------------------------------------------------
;;  Check for SC_FRAME
str_element,    ex_str,       'SC_FRAME',     sc_frame
;;  Check for SC_POT
str_element,      dat0,         'SC_POT',        scpot
;;  Check for ENERGY
str_element,      dat0,         'ENERGY',      allener
;;  Check if either were set
IF KEYWORD_SET(sc_frame)      THEN scframe =  1b ELSE scframe =  0b
;IF (scframe[0])               THEN e_min   = 1e1 ELSE e_min   = 1e0
e_min   = def_e_min[scframe[0]]       ;;  TRUE --> 10 eV, FALSE --> 1 eV
IF (N_ELEMENTS(scpot) NE 1)   THEN scpot   = e_min[0]
good_e         = WHERE(FINITE(allener) AND allener GT 0,gd_e)
IF (gd_e GT 0)                THEN e_max   = 2.1*MAX(allener[good_e],/NAN) ELSE e_max   = 1e6
;;  Get constraint tag values and define new structure
const_tags     = ['a','b','c','d']+'_range'
dumb4          = REPLICATE(0d0,4L)
con_struct     = CREATE_STRUCT(const_tags,dumb4,dumb4,dumb4,dumb4)
extract_tags,con_struct,extra_00,TAGS=const_tags
;;  Define structures for fits
cut_dir_str    = {T0:0e0,T1:90e0,T2:180e0}
pa_rang_str    = {T0:para_ra,T1:perp_ra,T2:anti_ra}
;;  Define output prefixes
out_pre_pre    = ['Parallel','Perpendicular','Anti-parallel']
out_pre        = out_pre_pre+' Fit to Model Function:  '
cmax           = 5L
temp           = 0
FOR m=0L, 2L DO BEGIN
  PRINT,''
  PRINT,out_pre[m]+fit_f_string[0]
  PRINT,''
  str_element,extra_00,'CUT_DIR',cut_dir_str.(m),/ADD_REPLACE
  ;;--------------------------------------------------------------------------------------
  ;;  Define parameters
  ;;--------------------------------------------------------------------------------------
  pa_ra          = pa_rang_str.(m)
  expanded       = REPLICATE(0b,4L)
  cc             = 0L
  status         = 0
  removed        = 1
  del_parm       = 0
  ;;  Define copy of _EXTRA structure
  extra_11       = extra_00
  WHILE (status NE 1) DO BEGIN
    fit_str        = evdf_fits_fit_to_cut_wrapper(data0,energy0,pang0,pa_ra,param,_EXTRA=extra_11)
    IF (SIZE(fit_str,/TYPE) NE 8) THEN STOP     ;;  Something is wrong
    fit_structure  = fit_str.FIT
    status         = fit_structure.STATUS
    IF (cc GT 0) THEN del_parm = TOTAL(ABS(fit_structure.FIT_PARAMS - fit_parm)) EQ 0
    fit_parm       = fit_structure.FIT_PARAMS
    fit_sigp       = fit_structure.SIG_PARAM
    ;;  Check difference between data and fit line in case of "parallel" fail
    temp_ff        = fit_structure.YFIT
    temp_yy        = fit_str.DATA.FIT_DATA
    diff_fy        = ABS(temp_yy - temp_ff)
    test_diff      = (MEAN(diff_fy,/NAN) GE 1d1)
;    IF (test_diff) THEN IF (status EQ 1) THEN status = 2    ;;  Make sure routine tries to adjust
    test_sig       = TOTAL((fit_sigp EQ 0) AND (param NE 0) AND (fit_parm NE 0)) NE 0
    IF (status NE 1 OR test_sig) THEN BEGIN
      ;;----------------------------------------------------------------------------------
      ;;  See if removing constraints will improve fit results
      ;;    --> Only remove constraints that bounded results => ones where sigma = 0
      ;;----------------------------------------------------------------------------------
      test_parm = (fit_sigp EQ 0) AND (param NE 0) AND (fit_parm NE 0)
      bad_parm  = WHERE(test_parm,bdparm,COMPLEMENT=good_parm,NCOMPLEMENT=gdparm)
      IF (bdparm GT 0) THEN BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  At least one parameter was over constrained --> Expand or remove?
        ;;--------------------------------------------------------------------------------
        FOR j=0L, bdparm - 1L DO BEGIN
          k       = bad_parm[j]
          con_str = con_struct.(k)
          con_tag = const_tags[k]
          IF (expanded[k] GT 3) THEN BEGIN
            ;;  constraint was already expanded --> Try removing
            str_element,extra_11,con_tag[0],/DELETE
          ENDIF ELSE BEGIN
            ;;  constraint has not been expanded
            expanded[k] += 1b  ;;  keep track of which variables were expanded
            xo           = con_str[2L:3L]
            inv          = REPLICATE(-1,2L)
            yo           = REPLICATE(0e0,2L)
            wo           = xo
            wfac         = [1e-1,1e1]
            test         = (ABS(xo) LE 1.)
            inv          = ([-1,1])[test]
            wfac         = wfac^(([1,-1])[test])
            yo           = xo^(-inv)
            wfac         = wfac^(-inv)
            wo           = (yo*wfac)^(-inv)
            ;;  Redefine constraint
            str_element,extra_11,con_tag[0],[con_str[0L:1L],wo],/ADD_REPLACE
          ENDELSE
        ENDFOR
        IF (status EQ 1) THEN status = 0    ;;  Make sure routine tries to fit again
      ENDIF ELSE BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  All parameters were either over constrained or fit completely failed
        ;;--------------------------------------------------------------------------------
        IF (status LT 0) THEN BEGIN
          ;;  Fatal Error --> Fit Failed!
          failed_msg = 'Fatal Error --> Fit Failed!'
          MESSAGE,failed_msg,/INFORMATIONAL,/CONTINUE
          status     = 1
        ENDIF
        IF (status GT 4) THEN BEGIN
          failed_msg = 'Fit failed for tolerance reasons... Move on!'
          MESSAGE,failed_msg,/INFORMATIONAL,/CONTINUE
          status     = 1
        ENDIF
      ENDELSE
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;;  Increment check index to prevent infinite loop
    ;;------------------------------------------------------------------------------------
    cc  += 1L
    test = ((((cc GT 1L) AND (status NE 1)) OR del_parm) AND (SIZE(temp,/TYPE) NE 8)) OR $
           ((cc GT cmax[0] - 1L) AND (status NE 1))
    IF (test AND removed) THEN BEGIN
      IF (cc LE cmax[0] - 1L) THEN cc = cmax[0]
      PRINT,''
      MESSAGE,'Remove all constraints for:  '+out_pre_pre[m],/INFORMATIONAL,/CONTINUE
      PRINT,''
      extract_tags,temp,extra_11,TAGS=const_tags
      test_tags = TAG_NAMES(temp)
      FOR j=0L, N_TAGS(temp) - 1L DO BEGIN
        str_element,extra_11,test_tags[j],/DELETE
      ENDFOR
      removed   = 0
      IF (status EQ 1) THEN status = 0    ;;  Make sure routine tries to fit again
      ;;----------------------------------------------------------------------------------
      ;;  Remove most constraints, but not all
      ;;----------------------------------------------------------------------------------
      CASE func[0] OF
        1L   :  BEGIN
          ;;------------------------------------------------------------------------------
          ;;  Y = A X^(B) + C
          ;;------------------------------------------------------------------------------
          test_ta   = [FINITE(MEDIAN(fit_str.DATA.FIT_DATA)),FINITE(MEDIAN(dat2f.DATA))]
          IF (test_ta[0] OR test_ta[1]) THEN BEGIN
            ;;  Make sure there is a reasonable lower bound since these fits
            ;;    seem to want to jump to unreasonably low values
            IF (test_ta[0] AND ~test_ta[1]) THEN BEGIN
              ;;  There are finite values for fit data
              famin = MAX(fit_str.DATA.FIT_DATA,/NAN)*1d1
            ENDIF ELSE BEGIN
              ;;  There are finite values for data
              test  = MAX(dat2f.DATA,/NAN) LT 1e15   ;;  Assume data is good if this holds
              IF (test[0]) THEN famin = MAX(dat2f.DATA,/NAN) ELSE famin = 1d1*MEDIAN(dat2f.DATA)
            ENDELSE
            t_a_range = [1,0,famin[0],1e30]
            ;;  Check PARAM[0] to make sure it is within parameter ranges
            test      = (param[0] LE t_a_range[2])
            IF (test[0]) THEN param[0] = 2d0*t_a_range[2]
          ENDIF ELSE BEGIN
            ;;  No finite data --> ignore
            t_a_range = 0.
          ENDELSE
          t_b_range = 0.
        END
        2L   :  BEGIN
          ;;------------------------------------------------------------------------------
          ;;  Y = A e^(B X) + C
          ;;------------------------------------------------------------------------------
          test_ta   = [FINITE(MEDIAN(fit_str.DATA.FIT_DATA)),FINITE(MEDIAN(dat2f.DATA))]
          ;;  If exponential involved, make sure lower bound for Eo is at minimum ø_sc
          IF (test_ta[0] OR test_ta[1]) THEN BEGIN
            ;;  Make sure there is a reasonable lower bound since these fits
            ;;    seem to want to jump to unreasonably low values
            IF (test_ta[0] AND ~test_ta[1]) THEN BEGIN
              ;;  There are finite values for fit data
              famin = MAX(fit_str.DATA.FIT_DATA,/NAN);*1d1
            ENDIF ELSE BEGIN
              ;;  There are finite values for data
              test1 = (dat2f[0].DATA LT 1e15)   ;;  Assume data is good if this holds
;              IF (test_ta[0]) THEN test_emin = MIN(fit_str.ENERGY.FIT_ENER) ELSE test_emin = 3d1
              IF (test_ta[0]) THEN test_emin = MIN(fit_str.ENERGY.FIT_ENER) ELSE test_emin = def_eran[0]
              test2 = (dat2f[0].ENERGY GE test_emin[0])
              test  = WHERE(test1 AND test2)
              IF (test[0] GE 0) THEN famin = MAX(dat2f[0].DATA[test],/NAN)/2d0 ELSE famin = 1d0*MEAN(dat2f.DATA)
            ENDELSE
            t_a_range = [1,0,famin[0],1e30]
            ;;  Check PARAM[0] to make sure it is within parameter ranges
            test      = (param[0] LE t_a_range[2])
            IF (test[0]) THEN param[0] = 1.1d0*t_a_range[2]
          ENDIF ELSE BEGIN
            ;;  No finite data --> ignore
            t_a_range = 0.
          ENDELSE
          t_b_range = [1,1,-1e0/[scpot[0],e_max[0]]]
          t_c_range = 0.
;          IF (test_diff) THEN BEGIN
;            t_b_range = [1,1,-1e0/[(scpot[0] > (e_range[0] > def_eran[0])),e_max[0]]]
;            IF (N_ELEMENTS(t_a_range) EQ 4) THEN BEGIN
;              test1        = (dat2f[0].DATA LT 1e15)   ;;  Assume data is good if this holds
;              test2        = (dat2f[0].ENERGY GE def_eran[0])
;              temp_famax   = MAX(dat2f[0].DATA[WHERE(test1 AND test2)],/NAN)
;              t_a_range[1] = 1
;              t_a_range[3] = 2.*temp_famax[0]
;            ENDIF
;          ENDIF
        END
        4L   :  BEGIN
          ;;------------------------------------------------------------------------------
          ;;  Y = A X^(B) e^(C X) + D
          ;;------------------------------------------------------------------------------
          test_ta   = [FINITE(MEDIAN(fit_str.DATA.FIT_DATA)),FINITE(MEDIAN(dat2f.DATA))]
          IF (test_ta[0] OR test_ta[1]) THEN BEGIN
            ;;  Make sure there is a reasonable lower bound since these fits
            ;;    seem to want to jump to unreasonably low values
            IF (test_ta[0] AND ~test_ta[1]) THEN BEGIN
              ;;  There are finite values for fit data
              famin = MAX(fit_str.DATA.FIT_DATA,/NAN)*1d1
            ENDIF ELSE BEGIN
              ;;  There are finite values for data
              test1 = (dat2f[0].DATA LT 1e15)   ;;  Assume data is good if this holds
;              IF (test_ta[0]) THEN test_emin = MIN(fit_str.ENERGY.FIT_ENER) ELSE test_emin = 3d1
              IF (test_ta[0]) THEN test_emin = MIN(fit_str.ENERGY.FIT_ENER) ELSE test_emin = def_eran[0]
              test2 = (dat2f[0].ENERGY GE test_emin[0])
              test  = WHERE(test1 AND test2)
              IF (test[0] GE 0) THEN famin = MAX(dat2f[0].DATA[test],/NAN)/2d0 ELSE famin = 1d0*MEAN(dat2f.DATA)
            ENDELSE
            t_a_range = [1,0,famin[0],1e30]
            ;;  Check PARAM[0] to make sure it is within parameter ranges
            test      = (param[0] LE t_a_range[2])
            IF (test[0]) THEN param[0] = 1.1d0*t_a_range[2]
          ENDIF ELSE BEGIN
            ;;  No finite data --> ignore
            t_a_range = 0.
          ENDELSE
;          t_b_range = 0.
          t_b_range = [1,1,-1e4,0e0]
          t_c_range = [1,1,-1e0/[scpot[0],e_max[0]]]
          IF (test_diff) THEN t_c_range = [1,1,-1e0/[scpot[0],((e_max[0] < e_range[1]) > 1e3)]]
        END
        11L  :  BEGIN
          ;;------------------------------------------------------------------------------
          ;;  Y = A X^(B) e^(C X) e^(D X)
          ;;------------------------------------------------------------------------------
          test_ta   = [FINITE(MEDIAN(fit_str.DATA.FIT_DATA)),FINITE(MEDIAN(dat2f.DATA))]
          IF (test_ta[0] OR test_ta[1]) THEN BEGIN
            ;;  Make sure there is a reasonable lower bound since these fits
            ;;    seem to want to jump to unreasonably low values
            IF (test_ta[0] AND ~test_ta[1]) THEN BEGIN
              ;;  There are finite values for fit data
              famin = MAX(fit_str.DATA.FIT_DATA,/NAN)*1d1
            ENDIF ELSE BEGIN
              ;;  There are finite values for data
              test1 = (dat2f[0].DATA LT 1e15)   ;;  Assume data is good if this holds
;              IF (test_ta[0]) THEN test_emin = MIN(fit_str.ENERGY.FIT_ENER) ELSE test_emin = 3d1
              IF (test_ta[0]) THEN test_emin = MIN(fit_str.ENERGY.FIT_ENER) ELSE test_emin = def_eran[0]
              test2 = (dat2f[0].ENERGY GE test_emin[0])
              test  = WHERE(test1 AND test2)
              IF (test[0] GE 0) THEN famin = MAX(dat2f[0].DATA[test],/NAN)/2d0 ELSE famin = 1d0*MEAN(dat2f.DATA)
            ENDELSE
            t_a_range = [1,0,famin[0],1e30]
            ;;  Check PARAM[0] to make sure it is within parameter ranges
            test      = (param[0] LE t_a_range[2])
            IF (test[0]) THEN param[0] = 1.1d0*t_a_range[2]
          ENDIF ELSE BEGIN
            ;;  No finite data --> ignore
            t_a_range = 0.
          ENDELSE
          t_b_range = 0.
          t_c_range = [1,1,-1e0/[scpot[0],e_max[0]/2]]
          t_d_range = [1,1,-1e0/[scpot[0]*2,e_max[0]]]
        END
        ELSE :  BEGIN  ;;  Do nothing otherwise
          t_a_range = 0.
          t_b_range = 0.
          t_c_range = 0.
        END
      ENDCASE
      ;;----------------------------------------------------------------------------------
      ;;  Add new constraints, if defined, to _EXTRA fit structure
      ;;----------------------------------------------------------------------------------
      IF (N_ELEMENTS(t_a_range) EQ 4) THEN str_element,extra_11,'A_RANGE',t_a_range,/ADD_REPLACE
      IF (N_ELEMENTS(t_b_range) EQ 4) THEN str_element,extra_11,'B_RANGE',t_b_range,/ADD_REPLACE
      IF (N_ELEMENTS(t_c_range) EQ 4) THEN str_element,extra_11,'C_RANGE',t_c_range,/ADD_REPLACE
      IF (N_ELEMENTS(t_d_range) EQ 4) THEN str_element,extra_11,'D_RANGE',t_d_range,/ADD_REPLACE
    ENDIF
    IF (cc GT cmax[0] AND status NE 1) THEN MESSAGE,'Forced Exit:  '+out_pre_pre[m],/INFORMATIONAL,/CONTINUE
    IF (cc GT cmax[0] AND status NE 1) THEN status = 1    ;; force leave
  ENDWHILE
  CASE m[0] OF
    0L   :  fit_str_para = fit_str
    1L   :  fit_str_perp = fit_str
    2L   :  fit_str_anti = fit_str
  ENDCASE
  ;;  Reset values
  fit_str        = 0
  temp           = 0
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Define fit parameter results
;;----------------------------------------------------------------------------------------
;;-------------------------------------------
;;  Parallel Fit
;;-------------------------------------------
;;  Define parameters
data_para_str  = fit_str_para.DATA
ener_para_str  = fit_str_para.ENERGY
onec_para_str  = fit_str_para.ONE_C
fit__para_str  = fit_str_para.FIT
Avgf_para      = data_para_str.AVG_DATA
AvgE_para      = ener_para_str.AVG_ENER
Avg1_para      = onec_para_str.AVG_ONEC
;;  Define fit results
xx_fit_para    = ener_para_str.FIT_ENER
yy_fit_para    = data_para_str.FIT_DATA
yerr___para    = onec_para_str.FIT_ONEC
ff_fit_para    = fit__para_str.YFIT
fit_parm_para  = fit__para_str.FIT_PARAMS
fit_sigp_para  = fit__para_str.SIG_PARAM
;;  Define fit status results
fit_stat__para = fit__para_str.STATUS[0]
fit_chisq_para = fit__para_str.CHISQ[0]
fit_rchsq_para = fit_chisq_para/(1d0*fit__para_str.DOF[0])
;;-------------------------------------------
;;  Perpendicular Fit
;;-------------------------------------------
;;  Define parameters
data_perp_str  = fit_str_perp.DATA
ener_perp_str  = fit_str_perp.ENERGY
onec_perp_str  = fit_str_perp.ONE_C
fit__perp_str  = fit_str_perp.FIT
Avgf_perp      = data_perp_str.AVG_DATA
AvgE_perp      = ener_perp_str.AVG_ENER
Avg1_perp      = onec_perp_str.AVG_ONEC
;;  Define fit results
xx_fit_perp    = ener_perp_str.FIT_ENER
yy_fit_perp    = data_perp_str.FIT_DATA
yerr___perp    = onec_perp_str.FIT_ONEC
ff_fit_perp    = fit__perp_str.YFIT
fit_parm_perp  = fit__perp_str.FIT_PARAMS
fit_sigp_perp  = fit__perp_str.SIG_PARAM
;;  Define fit status results
fit_stat__perp = fit__perp_str.STATUS[0]
fit_chisq_perp = fit__perp_str.CHISQ[0]
fit_rchsq_perp = fit_chisq_perp/(1d0*fit__perp_str.DOF[0])
;;-------------------------------------------
;;  Anti-parallel Fit
;;-------------------------------------------
;;  Define parameters
data_anti_str  = fit_str_anti.DATA
ener_anti_str  = fit_str_anti.ENERGY
onec_anti_str  = fit_str_anti.ONE_C
fit__anti_str  = fit_str_anti.FIT
Avgf_anti      = data_anti_str.AVG_DATA
AvgE_anti      = ener_anti_str.AVG_ENER
Avg1_anti      = onec_anti_str.AVG_ONEC
;;  Define fit results
xx_fit_anti    = ener_anti_str.FIT_ENER
yy_fit_anti    = data_anti_str.FIT_DATA
yerr___anti    = onec_anti_str.FIT_ONEC
ff_fit_anti    = fit__anti_str.YFIT
fit_parm_anti  = fit__anti_str.FIT_PARAMS
fit_sigp_anti  = fit__anti_str.SIG_PARAM
;;  Define fit status results
fit_stat__anti = fit__anti_str.STATUS[0]
fit_chisq_anti = fit__anti_str.CHISQ[0]
fit_rchsq_anti = fit_chisq_anti/(1d0*fit__anti_str.DOF[0])
;;  Check on parameter A for power-law fits
param_a_all    = [fit_parm_para[0],fit_parm_perp[0],fit_parm_anti[0]]
max_ff_all     = [MAX(yy_fit_para,/NAN),MAX(yy_fit_perp,/NAN),MAX(yy_fit_anti,/NAN)]
test_all       = (param_a_all LE max_ff_all) AND FINITE(max_ff_all)
;;----------------------------------------------------------------------------------------
;;  Define parameter arrays for XYOUTS.PRO
;;----------------------------------------------------------------------------------------
;;  Define e-folding energy [eV] values = -1/C
CASE func[0] OF
  2    : ef_ind = 1L
  4    : ef_ind = 2L
  9    : ef_ind = 2L
  11   : ef_ind = [2L,3L]
  ELSE : ef_ind = 3L
ENDCASE
fit_stat_all   = [fit_stat__para[0],fit_stat__perp[0],fit_stat__anti[0]]
fit_rchs_all   = [fit_rchsq_para[0],fit_rchsq_perp[0],fit_rchsq_anti[0]]
;;----------------------------------------------------------------------------------------
;;  Define strings for XYOUTS.PRO
;;----------------------------------------------------------------------------------------
letter_prefx   = ['A','B','C','D']+' = '
dletter_prefx  = '+/- d'+letter_prefx
mform          = '(e15.3)'
fparm_para_str = STRTRIM(STRING(fit_parm_para,FORMAT=mform),2L)
fsigp_para_str = STRTRIM(STRING(fit_sigp_para,FORMAT=mform),2L)
fparm_perp_str = STRTRIM(STRING(fit_parm_perp,FORMAT=mform),2L)
fsigp_perp_str = STRTRIM(STRING(fit_sigp_perp,FORMAT=mform),2L)
fparm_anti_str = STRTRIM(STRING(fit_parm_anti,FORMAT=mform),2L)
fsigp_anti_str = STRTRIM(STRING(fit_sigp_anti,FORMAT=mform),2L)
;;  Define e-folding energy [eV] strings
efold_ener_str = STRARR(3L,2L)
;efold_eners    = -1d0/[fit_parm_para[ef_ind],fit_parm_perp[ef_ind],fit_parm_anti[ef_ind]]
;efold_ener_str = STRTRIM(STRING(efold_eners,FORMAT=mform),2L)
CASE func[0] OF
  11   : BEGIN
    t_efold_low         = -1d0/[fit_parm_para[ef_ind[0]],fit_parm_perp[ef_ind[0]],fit_parm_anti[ef_ind[0]]]
    t_efold_hig         = -1d0/[fit_parm_para[ef_ind[1]],fit_parm_perp[ef_ind[1]],fit_parm_anti[ef_ind[1]]]
    efold_ener_str      = STRARR(3L,2L)
    efold_ener_str[*,0] = STRTRIM(STRING(t_efold_low,FORMAT=mform),2L)
    efold_ener_str[*,1] = STRTRIM(STRING(t_efold_hig,FORMAT=mform),2L)
  END
  ELSE : BEGIN
    efold_eners         = -1d0/[fit_parm_para[ef_ind],fit_parm_perp[ef_ind],fit_parm_anti[ef_ind]]
    efold_ener_str[*,0] = STRTRIM(STRING(efold_eners,FORMAT=mform),2L)
  END
ENDCASE
;;  Defined parameters for XYOUTS [Legend]
redchsq__x_str = 'Red. '+get_greek_letter('chi')+'!U2!N = '
fit_status_str = STRTRIM(STRING(fit_stat_all,FORMAT='(I1.1)'),2L)
fit_rchsqs_str = STRTRIM(STRING(fit_rchs_all,FORMAT=mform),2L)
;fit_status_str = STRTRIM(STRING([fit_stat__para[0],fit_stat__perp[0],fit_stat__anti[0]],FORMAT='(I1.1)'),2L)
;fit_rchsqs_str = STRTRIM(STRING([fit_rchsq_para[0],fit_rchsq_perp[0],fit_rchsq_anti[0]],FORMAT=mform),2L)
legend_out     = ['Parallel','Perpendicular','Anti-parallel']+' Avg.'
legend_out     = legend_out+', Status = '+fit_status_str+', '
legend_out_ps  = legend_out
legend_out     = legend_out+redchsq__x_str[0]+fit_rchsqs_str
lo_xposi       = 0.15
lo_yposi       = 0.25
;;  Defined parameters for XYOUTS
;;    --> X-Windows project differently than PS files
xposi          = 0.60
chsz           = 1.00
lthck          = 2.00
symsz          = 1.50
dypos          = 0.02
nparm          = N_ELEMENTS(fparm_para_str)
xylims         = {ALIGNMENT:0.,CHARSIZE:chsz[0],NORMAL:1}
cols           = [250,125,45]
;;  Defined user symbol for outputing all data points
nxxo           = 25
xxro           = 0.35
xxo            = FINDGEN(nxxo[0])*(!PI*2.)/(nxxo[0] - 1L)
USERSYM,xxro[0]*COS(xxo),xxro[0]*SIN(xxo),/FILL
;;----------------------------------------------------------------------------------------
;;  Determine character sizes relative to 'X' and 'PS'
;;----------------------------------------------------------------------------------------
str_element,   limits, 'CHARSIZE',xy_chsz
str_element,   limits,'XTICKNAME',x_tickn
str_element,   limits,'YTICKNAME',y_tickn
;;  Define structure for XYOUTS to use for axis titles
xy_ttlim       = {ALIGNMENT:0.5,CHARSIZE:xy_chsz[0],NORMAL:1}
xy_ttlimn      = {ALIGNMENT:0.5,CHARSIZE:-xy_chsz[0],NORMAL:1}
WSET,3
xyw_size       = [!D.X_SIZE,!D.Y_SIZE]
WINDOW,/FREE,/PIXMAP,XSIZE=xyw_size[0],YSIZE=xyw_size[1]
;;  Define current size of text [normalized units]
XYOUTS,0.5,0.5,y_tickn[0],_EXTRA=xy_ttlimn,WIDTH=ytn_wdx
;;  Delete dummy window
WDELETE

;;  Do the same for the 'PS' device
limits_ps      = limits
popen,fit_file_name[0],/LAND
  xyw_size       = [!D.X_SIZE,!D.Y_SIZE]
  XYOUTS,0.5,0.5,y_tickn[0],_EXTRA=xy_ttlimn,WIDTH=ytn_wdps
  ;;  Redefine LIMITS from within PS DEVICE
  limits_ps      = evdf_fits_moments_calc_str(dat0,LIMITS=limits_ps)
  redchsq_ps_str = 'Red. '+get_greek_letter('chi')+'!U2!N = '
pclose
legend_out_ps  = legend_out_ps+redchsq_ps_str[0]+fit_rchsqs_str
;;----------------------------------------------------------------------------------------
;;  Define new LIMITS structure
;;----------------------------------------------------------------------------------------
except_tags    = ['XTITLE','YTITLE','SUBTITLE','XSUBTITLE','YSUBTITLE']
extract_tags,new_limits__x,limits,EXCEPT_TAGS=except_tags
extract_tags,new_limits_ps,limits_ps,EXCEPT_TAGS=except_tags
;;  Define parameters for axes titles
str_element,   limits, 'CHARSIZE',xy_chsz__x
str_element,   limits,   'XTITLE',x_title__x
str_element,   limits,   'YTITLE',y_title__x
str_element,   limits,'XSUBTITLE',x_subtl__x
str_element,   limits,'YSUBTITLE',y_subtl__x
str_element,limits_ps, 'CHARSIZE',xy_chsz_ps
str_element,limits_ps,   'XTITLE',x_title_ps
str_element,limits_ps,   'YTITLE',y_title_ps
str_element,limits_ps,'XSUBTITLE',x_subtl_ps
str_element,limits_ps,'YSUBTITLE',y_subtl_ps

xy_ttlim__x    = {ALIGNMENT:0.5,CHARSIZE:xy_chsz__x[0],NORMAL:1}
xy_ttlim_ps    = {ALIGNMENT:0.5,CHARSIZE:xy_chsz_ps[0],NORMAL:1}
;;----------------------------------------------------------------------------------------
;;  Plot results
;;----------------------------------------------------------------------------------------
xdat0          = AvgE_para
xdat1          = AvgE_perp
xdat2          = AvgE_anti
ydat0          = Avgf_para
ydat1          = Avgf_perp
ydat2          = Avgf_anti
;;  Define one-count levels for comparison
yone0          = Avg1_para
yone1          = Avg1_perp
yone2          = Avg1_anti
;;  Define fit results
xfit0          = xx_fit_para
xfit1          = xx_fit_perp
xfit2          = xx_fit_anti
yfit0          = ff_fit_para
yfit1          = ff_fit_perp
yfit2          = ff_fit_anti

;;  Plot all data
WSET,2
WSHOW,2
PLOT,xdat0,ydat0,_EXTRA=limits,/NODATA
  OPLOT,xdat0,ydat0,COLOR=cols[0],PSYM=2
  OPLOT,xdat1,ydat1,COLOR=cols[1],PSYM=2
  OPLOT,xdat2,ydat2,COLOR=cols[2],PSYM=2
  ;;  Plot one-count levels
  OPLOT,xdat0,yone0,COLOR=cols[0],LINESTYLE=2
  OPLOT,xdat1,yone1,COLOR=cols[1],LINESTYLE=2
  OPLOT,xdat2,yone2,COLOR=cols[2],LINESTYLE=2
;;----------------------------------------------------------------------------------------
;;  Plot only data used in fit
;;----------------------------------------------------------------------------------------
ydat0          = yy_fit_para
ydat1          = yy_fit_perp
ydat2          = yy_fit_anti

WSET,3
WSHOW,3
  PLOT,AvgE_para,Avgf_para,_EXTRA=new_limits__x,/NODATA
    ;;------------------------------------------------------------------------------------
    ;;  Output specialized Axes Titles
    ;;------------------------------------------------------------------------------------
    ;;  Get current position of plot axes
    x_loc          = !X.WINDOW       ;;  {X0,X1} = {start,end} of X-Axis [normalized units]
    y_loc          = !Y.WINDOW       ;;  {X0,X1} = {start,end} of X-Axis [normalized units]
    yposi          = y_loc[1] - dypos[0]
    IF (!D.NAME EQ 'X') THEN yscl_wd  = 1.0         ELSE yscl_wd  = 1.05
    IF (!D.NAME EQ 'X') THEN xy_chsz  = xy_chsz__x  ELSE xy_chsz  = xy_chsz_ps
    IF (!D.NAME EQ 'X') THEN x_title  = x_title__x  ELSE x_title  = x_title_ps
    IF (!D.NAME EQ 'X') THEN y_title  = y_title__x  ELSE y_title  = y_title_ps
    IF (!D.NAME EQ 'X') THEN x_subtl  = x_subtl__x  ELSE x_subtl  = x_subtl_ps
    IF (!D.NAME EQ 'X') THEN y_subtl  = y_subtl__x  ELSE y_subtl  = y_subtl_ps
    IF (!D.NAME EQ 'X') THEN xy_ttlim = xy_ttlim__x ELSE xy_ttlim = xy_ttlim_ps
    IF (!D.NAME EQ 'X') THEN yo_wd    = ytn_wdx[0]  ELSE yo_wd    = ytn_wdps[0]
    x_ch           = (1e0*!D.X_CH_SIZE)/(1e0*!D.X_VSIZE)*xy_chsz[0]
    y_ch           = (1e0*!D.Y_CH_SIZE)/(1e0*!D.Y_VSIZE)*xy_chsz[0]
    xy_xtloc       = [MEAN(x_loc),y_loc[0] - (y_ch[0]/0.62 + y_ch[0])]
    xy_ytloc       = [x_loc[0] - (2*x_ch[0] + 2*yo_wd[0]),MEAN(y_loc)]
    ;;  Output base X-Title and Y-Title
    XYOUTS,xy_xtloc[0],xy_xtloc[1],x_title[0],_EXTRA=xy_ttlim
    XYOUTS,xy_ytloc[0],xy_ytloc[1],y_title[0],_EXTRA=xy_ttlim,ORIENTATION=9e1
    ;;  Output X-Subtitles
    FOR j=0L, N_ELEMENTS(x_subtl) - 1L DO BEGIN
      jy = j[0] + 1L
      XYOUTS,xy_xtloc[0],xy_xtloc[1] - yo_wd[0]*yscl_wd[0]*jy[0],x_subtl[j],_EXTRA=xy_ttlim
    ENDFOR
    ;;  Output Y-Subtitles
    FOR j=0L, N_ELEMENTS(y_subtl) - 1L DO BEGIN
      jy = j[0] + 1L
      XYOUTS,xy_ytloc[0] + yo_wd[0]*jy[0],xy_ytloc[1],y_subtl[j],_EXTRA=xy_ttlim,ORIENTATION=9e1
    ENDFOR
    ;;------------------------------------------------------------------------------------
    ;;  Plot fit lines
    ;;------------------------------------------------------------------------------------
    OPLOT,    xfit0,    yfit0,COLOR=cols[0],LINESTYLE=2,THICK=lthck[0]
    OPLOT,    xfit1,    yfit1,COLOR=cols[1],LINESTYLE=2,THICK=lthck[0]
    OPLOT,    xfit2,    yfit2,COLOR=cols[2],LINESTYLE=2,THICK=lthck[0]
    ;;  Plot one-count levels
    OPLOT,xdat0,yone0,COLOR=cols[0],LINESTYLE=1
    OPLOT,xdat1,yone1,COLOR=cols[1],LINESTYLE=1
    OPLOT,xdat2,yone2,COLOR=cols[2],LINESTYLE=1
    ;;  Plot all data points
    OPLOT,AvgE_para,Avgf_para,COLOR=cols[0],PSYM=8
    OPLOT,AvgE_perp,Avgf_perp,COLOR=cols[1],PSYM=8
    OPLOT,AvgE_anti,Avgf_anti,COLOR=cols[2],PSYM=8
    ;;  Plot only the data points used for fits
    OPLOT,xfit0,ydat0,COLOR=cols[0],PSYM=6,SYMSIZE=symsz[0]
    OPLOT,xfit1,ydat1,COLOR=cols[1],PSYM=6,SYMSIZE=symsz[0]
    OPLOT,xfit2,ydat2,COLOR=cols[2],PSYM=6,SYMSIZE=symsz[0]
    ;;------------------------------------------------------------------------------------
    ;;  Output plot labels/legend
    ;;------------------------------------------------------------------------------------
    loy0 = lo_yposi[0] + dypos[0]
    FOR j=0L, 2L DO BEGIN
      loy0 -= dypos[0]
      XYOUTS,lo_xposi[0],loy0[0],legend_out[j],_EXTRA=xylims,COLOR=cols[j]
    ENDFOR
    ;;------------------------------------------------------------------------------------
    ;;  Output fit parameters
    ;;------------------------------------------------------------------------------------
    str_out_para   = fparm_para_str
    str_out_perp   = fparm_perp_str
    str_out_anti   = fparm_anti_str
    FOR j=0L, nparm[0] - 1L DO BEGIN
      yposi -= dypos[0]
      ;;  Output letter prefix
      sout   = letter_prefx[j]
      XYOUTS,xposi[0],yposi[0],sout[0],_EXTRA=xylims,WIDTH=wda
      ;;  Parallel Fit Params
      sout   = str_out_para[j]+', '
      XYOUTS,xposi[0]+wda[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[0],WIDTH=wdb
      ;;  Perpendicular Fit Params
      sout   = str_out_perp[j]+', '
      XYOUTS,xposi[0]+wda[0]+wdb[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[1],WIDTH=wdc
      ;;  Anti-parallel Fit Params
      sout   = str_out_anti[j]
      XYOUTS,xposi[0]+wda[0]+wdb[0]+wdc[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[2],WIDTH=wdd
    ENDFOR
    ;;------------------------------------------------------------------------------------
    ;;  Output fit parameter uncertainties
    ;;------------------------------------------------------------------------------------
    str_out_para   = fsigp_para_str
    str_out_perp   = fsigp_perp_str
    str_out_anti   = fsigp_anti_str
    FOR j=0L, nparm[0] - 1L DO BEGIN
      yposi -= dypos[0]
      ;;  Output letter prefix
      sout   = dletter_prefx[j]
      XYOUTS,xposi[0],yposi[0],sout[0],_EXTRA=xylims,WIDTH=wda
      ;;  Parallel Fit Params
      sout   = str_out_para[j]+', '
      XYOUTS,xposi[0]+wda[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[0],WIDTH=wdb
      ;;  Perpendicular Fit Params
      sout   = str_out_perp[j]+', '
      XYOUTS,xposi[0]+wda[0]+wdb[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[1],WIDTH=wdc
      ;;  Anti-parallel Fit Params
      sout   = str_out_anti[j]
      XYOUTS,xposi[0]+wda[0]+wdb[0]+wdc[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[2],WIDTH=wdd
    ENDFOR
    ;;------------------------------------------------------------------------------------
    ;;  Output e-folding energy [eV] values
    ;;------------------------------------------------------------------------------------
    test   = (func EQ 2) OR (func EQ 4) OR (func EQ 9)
    IF (test) THEN BEGIN
      yposi -= dypos[0]
      sout   = 'Eo = '
      XYOUTS,xposi[0],yposi[0],sout[0],_EXTRA=xylims,WIDTH=wda
      cc     = 0
      FOR j=0L, 2L DO BEGIN
        cc    += wda[0]
        sout   = efold_ener_str[j,0]
;        sout   = efold_ener_str[j]
        IF (j EQ 2) THEN sout = sout[0]+' eV' ELSE sout = sout[0]+', '
        XYOUTS,xposi[0]+cc[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[j],WIDTH=wda
      ENDFOR
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;;  Output (low and high end) e-folding energy [eV] values
    ;;    -->  Only for FIT_FUNC = 11 or Y = A X^(B) e^(C X) e^(D X)
    ;;------------------------------------------------------------------------------------
    test   = (func EQ 11)
    IF (test) THEN BEGIN
      FOR eee=0L, 1L DO BEGIN
        yposi -= dypos[0]
        IF (eee[0] EQ 0) THEN sout = 'E_L = ' ELSE sout = 'E_H = ' 
        XYOUTS,xposi[0],yposi[0],sout[0],_EXTRA=xylims,WIDTH=wda
        cc     = 0
        FOR j=0L, 2L DO BEGIN
          cc    += wda[0]
          sout   = efold_ener_str[j,eee[0]]
          IF (j EQ 2) THEN sout = sout[0]+' eV' ELSE sout = sout[0]+', '
          XYOUTS,xposi[0]+cc[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[j],WIDTH=wda
        ENDFOR
      ENDFOR
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;;  Output routine version # and date produced
    ;;------------------------------------------------------------------------------------
    IF (SIZE(r_version,/TYPE) EQ 7) THEN BEGIN
      xwin0 = !X.WINDOW + 0.025
      ywin0 = !Y.WINDOW + 0.010
      XYOUTS,xwin0[1],ywin0[0],r_version[0],CHARSIZE=.65,/NORMAL,ORIENTATION=90.
    ENDIF
;;----------------------------------------------------------------------------------------
;;  Save plots
;;----------------------------------------------------------------------------------------
;;  Reset initial XYOUTS positions
xposi          = 0.57
lthck          = 2.50
chsz           = 0.90
dypos          = 0.02
xylims         = {ALIGNMENT:0.,CHARSIZE:chsz[0],NORMAL:1}

popen,fit_file_name[0],/LAND
;;  Redefine LIMITS from within PS DEVICE
  PLOT,AvgE_para,Avgf_para,_EXTRA=new_limits_ps,/NODATA
    ;;------------------------------------------------------------------------------------
    ;;  Output specialized Axes Titles
    ;;------------------------------------------------------------------------------------
    ;;  Get current position of plot axes
    x_loc          = !X.WINDOW       ;;  {X0,X1} = {start,end} of X-Axis [normalized units]
    y_loc          = !Y.WINDOW       ;;  {X0,X1} = {start,end} of X-Axis [normalized units]
    yposi          = y_loc[1] - dypos[0]
    IF (!D.NAME EQ 'X') THEN yscl_wd  = 1.0         ELSE yscl_wd  = 1.05
    IF (!D.NAME EQ 'X') THEN xy_chsz  = xy_chsz__x  ELSE xy_chsz  = xy_chsz_ps
    IF (!D.NAME EQ 'X') THEN x_title  = x_title__x  ELSE x_title  = x_title_ps
    IF (!D.NAME EQ 'X') THEN y_title  = y_title__x  ELSE y_title  = y_title_ps
    IF (!D.NAME EQ 'X') THEN x_subtl  = x_subtl__x  ELSE x_subtl  = x_subtl_ps
    IF (!D.NAME EQ 'X') THEN y_subtl  = y_subtl__x  ELSE y_subtl  = y_subtl_ps
    IF (!D.NAME EQ 'X') THEN xy_ttlim = xy_ttlim__x ELSE xy_ttlim = xy_ttlim_ps
    IF (!D.NAME EQ 'X') THEN yo_wd    = ytn_wdx[0]  ELSE yo_wd    = ytn_wdps[0]
    x_ch           = (1e0*!D.X_CH_SIZE)/(1e0*!D.X_VSIZE)*xy_chsz[0]
    y_ch           = (1e0*!D.Y_CH_SIZE)/(1e0*!D.Y_VSIZE)*xy_chsz[0]
    xy_xtloc       = [MEAN(x_loc),y_loc[0] - (y_ch[0]/0.62 + y_ch[0])]
    xy_ytloc       = [x_loc[0] - (2*x_ch[0] + 2*yo_wd[0]),MEAN(y_loc)]
    ;;  Output base X-Title and Y-Title
    XYOUTS,xy_xtloc[0],xy_xtloc[1],x_title[0],_EXTRA=xy_ttlim
    XYOUTS,xy_ytloc[0],xy_ytloc[1],y_title[0],_EXTRA=xy_ttlim,ORIENTATION=9e1
    ;;  Output X-Subtitles
    FOR j=0L, N_ELEMENTS(x_subtl) - 1L DO BEGIN
      jy = j[0] + 1L
      XYOUTS,xy_xtloc[0],xy_xtloc[1] - yo_wd[0]*yscl_wd[0]*jy[0],x_subtl[j],_EXTRA=xy_ttlim
    ENDFOR
    ;;  Output Y-Subtitles
    FOR j=0L, N_ELEMENTS(y_subtl) - 1L DO BEGIN
      jy = j[0] + 1L
      XYOUTS,xy_ytloc[0] + yo_wd[0]*jy[0],xy_ytloc[1],y_subtl[j],_EXTRA=xy_ttlim,ORIENTATION=9e1
    ENDFOR
    ;;------------------------------------------------------------------------------------
    ;;  Plot fit lines
    ;;------------------------------------------------------------------------------------
    OPLOT,    xfit0,    yfit0,COLOR=cols[0],LINESTYLE=2,THICK=lthck[0]
    OPLOT,    xfit1,    yfit1,COLOR=cols[1],LINESTYLE=2,THICK=lthck[0]
    OPLOT,    xfit2,    yfit2,COLOR=cols[2],LINESTYLE=2,THICK=lthck[0]
    ;;  Plot one-count levels
    OPLOT,xdat0,yone0,COLOR=cols[0],LINESTYLE=1
    OPLOT,xdat1,yone1,COLOR=cols[1],LINESTYLE=1
    OPLOT,xdat2,yone2,COLOR=cols[2],LINESTYLE=1
    ;;  Plot all data points
    OPLOT,AvgE_para,Avgf_para,COLOR=cols[0],PSYM=8
    OPLOT,AvgE_perp,Avgf_perp,COLOR=cols[1],PSYM=8
    OPLOT,AvgE_anti,Avgf_anti,COLOR=cols[2],PSYM=8
    ;;  Plot only the data points used for fits
    OPLOT,xfit0,ydat0,COLOR=cols[0],PSYM=6,SYMSIZE=symsz[0]
    OPLOT,xfit1,ydat1,COLOR=cols[1],PSYM=6,SYMSIZE=symsz[0]
    OPLOT,xfit2,ydat2,COLOR=cols[2],PSYM=6,SYMSIZE=symsz[0]
    ;;------------------------------------------------------------------------------------
    ;;  Output plot labels/legend
    ;;------------------------------------------------------------------------------------
    loy0 = lo_yposi[0] + dypos[0]
    FOR j=0L, 2L DO BEGIN
      loy0 -= (dypos[0] + 0.01)
      XYOUTS,lo_xposi[0],loy0[0],legend_out_ps[j],_EXTRA=xylims,COLOR=cols[j]
    ENDFOR
    ;;------------------------------------------------------------------------------------
    ;;  Output fit parameters
    ;;------------------------------------------------------------------------------------
    str_out_para   = fparm_para_str
    str_out_perp   = fparm_perp_str
    str_out_anti   = fparm_anti_str
    FOR j=0L, nparm[0] - 1L DO BEGIN
      yposi -= dypos[0]
      ;;  Output letter prefix
      sout   = letter_prefx[j]
      XYOUTS,xposi[0],yposi[0],sout[0],_EXTRA=xylims,WIDTH=wda
      ;;  Parallel Fit Params
      sout   = str_out_para[j]+', '
      XYOUTS,xposi[0]+wda[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[0],WIDTH=wdb
      ;;  Perpendicular Fit Params
      sout   = str_out_perp[j]+', '
      XYOUTS,xposi[0]+wda[0]+wdb[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[1],WIDTH=wdc
      ;;  Anti-parallel Fit Params
      sout   = str_out_anti[j]
      XYOUTS,xposi[0]+wda[0]+wdb[0]+wdc[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[2],WIDTH=wdd
    ENDFOR
    ;;------------------------------------------------------------------------------------
    ;;  Output fit parameter uncertainties
    ;;------------------------------------------------------------------------------------
    str_out_para   = fsigp_para_str
    str_out_perp   = fsigp_perp_str
    str_out_anti   = fsigp_anti_str
    FOR j=0L, nparm[0] - 1L DO BEGIN
      yposi -= dypos[0]
      ;;  Output letter prefix
      sout   = dletter_prefx[j]
      XYOUTS,xposi[0],yposi[0],sout[0],_EXTRA=xylims,WIDTH=wda
      ;;  Parallel Fit Params
      sout   = str_out_para[j]+', '
      XYOUTS,xposi[0]+wda[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[0],WIDTH=wdb
      ;;  Perpendicular Fit Params
      sout   = str_out_perp[j]+', '
      XYOUTS,xposi[0]+wda[0]+wdb[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[1],WIDTH=wdc
      ;;  Anti-parallel Fit Params
      sout   = str_out_anti[j]
      XYOUTS,xposi[0]+wda[0]+wdb[0]+wdc[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[2],WIDTH=wdd
    ENDFOR
    ;;------------------------------------------------------------------------------------
    ;;  Output e-folding energy [eV] values
    ;;------------------------------------------------------------------------------------
    test   = (func EQ 2) OR (func EQ 4) OR (func EQ 9)
    IF (test) THEN BEGIN
      yposi -= dypos[0]
      sout   = 'Eo = '
      XYOUTS,xposi[0],yposi[0],sout[0],_EXTRA=xylims,WIDTH=wda
      cc     = 0
      FOR j=0L, 2L DO BEGIN
        cc    += wda[0]
        sout   = efold_ener_str[j,0]
;        sout   = efold_ener_str[j]
        IF (j EQ 2) THEN sout = sout[0]+' eV' ELSE sout = sout[0]+', '
        XYOUTS,xposi[0]+cc[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[j],WIDTH=wda
      ENDFOR
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;;  Output (low and high end) e-folding energy [eV] values
    ;;    -->  Only for FIT_FUNC = 11 or Y = A X^(B) e^(C X) e^(D X)
    ;;------------------------------------------------------------------------------------
    test   = (func EQ 11)
    IF (test) THEN BEGIN
      FOR eee=0L, 1L DO BEGIN
        yposi -= dypos[0]
        IF (eee[0] EQ 0) THEN sout = 'E_L = ' ELSE sout = 'E_H = ' 
        XYOUTS,xposi[0],yposi[0],sout[0],_EXTRA=xylims,WIDTH=wda
        cc     = 0
        FOR j=0L, 2L DO BEGIN
          cc    += wda[0]
          sout   = efold_ener_str[j,eee[0]]
          IF (j EQ 2) THEN sout = sout[0]+' eV' ELSE sout = sout[0]+', '
          XYOUTS,xposi[0]+cc[0],yposi[0],sout[0],_EXTRA=xylims,COLOR=cols[j],WIDTH=wda
        ENDFOR
      ENDFOR
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;;  Output routine version # and date produced
    ;;------------------------------------------------------------------------------------
    IF (SIZE(r_version,/TYPE) EQ 7) THEN BEGIN
      xwin0 = !X.WINDOW + 0.025
      ywin0 = !Y.WINDOW + 0.010
      XYOUTS,xwin0[1],ywin0[0],r_version[0],CHARSIZE=.65,/NORMAL,ORIENTATION=90.
    ENDIF
pclose
;;----------------------------------------------------------------------------------------
;;  Define return structure
;;----------------------------------------------------------------------------------------
;;  Change init_struc.LIMITS to account for changes added in wrapping routins
str_element,init_struc,'LIMITS',limits,/ADD_REPLACE
;;  Define fit constraints structure
fit_cons       = fit_struct
;;  Define extras structure
str_element,     added,       'VDF_MOMS',        vdf_moms,/ADD_REPLACE
str_element,     added,        'PARA_RA',         para_ra,/ADD_REPLACE
str_element,     added,        'PERP_RA',         perp_ra,/ADD_REPLACE
str_element,     added,        'ANTI_RA',         anti_ra,/ADD_REPLACE
str_element,     added,      'FILE_NAME',fit_file_name[0],/ADD_REPLACE
str_element,     added,'FIT_CONSTRAINTS',        fit_cons,/ADD_REPLACE
;;  Add to initialization structure
str_element,init_struc,        'EXTRAS',        added,/ADD_REPLACE
;;  Define tags for return structure
str_element,     struc,    'INIT_STRUC',   init_struc,/ADD_REPLACE
str_element,     struc,'FIT_PARA_STRUC', fit_str_para,/ADD_REPLACE
str_element,     struc,'FIT_PERP_STRUC', fit_str_perp,/ADD_REPLACE
str_element,     struc,'FIT_ANTI_STRUC', fit_str_anti,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------
;*****************************************************************************************
ex_time = SYSTIME(1) - ex_start
PRINT,''
MESSAGE,STRING(ex_time)+' seconds execution time.',/CONTINUE,/INFORMATIONAL
PRINT,''
;*****************************************************************************************

RETURN,struc
END


