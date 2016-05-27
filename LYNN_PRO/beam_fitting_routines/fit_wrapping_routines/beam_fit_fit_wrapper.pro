;+
;*****************************************************************************************
;
;  PROCEDURE:   beam_fit_fit_wrapper.pro
;  PURPOSE  :   The is a wrapping routine for the fitting algorithm and the prompting
;                 routine that allows the user to interactively improve the fit results.
;
;  CALLED BY:   
;               beam_fit_1df_plot_fit.pro
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               beam_fit___get_common.pro
;               conv_units.pro
;               transform_vframe_3d.pro
;               rotate_3dp_structure.pro
;               find_dist_func_cuts.pro
;               moments_3d_new.pro
;               str_element.pro
;               beam_fit___set_common.pro
;               bimaxwellian.pro
;               beam_fit_contour_plot.pro
;               beam_fit_gen_prompt.pro
;               beam_fit_fit_prompts.pro
;               delete_variable.pro
;               df_fit_beam_peak.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;               2)  LBW's Beam Fitting IDL Libraries
;
;  INPUT:
;               DAT        :  Scalar [structure] containing a particle velocity
;                               distribution function (DF) from either the Wind/3DP
;                               instrument [use get_??.pro, ?? = e.g. phb] or from
;                               the THEMIS ESA instruments.  Regardless, the structure
;                               must satisfy the criteria needed to produce a contour
;                               plot showing the phase (velocity) space density of the
;                               DF.  The structure must also have the following two tags
;                               with finite [3]-element vectors:  VSW and MAGF.
;
;  EXAMPLES:    
;               [calling sequence]
;               beam_fit_fit_wrapper,dat [,VCIRC=vcirc] [,EX_VECN=ex_vecn]              $
;                                        [,WINDN=windn] [,QUIET=quiet] [,BFRAME=bframe] $
;                                        [,DATA_OUT=data_out] [,READ_OUT=read_out]      $
;                                        [,PLOT_STR=plot_str] [,MODEL_OUT=model_out]
;
;  KEYWORDS:    
;               ***************
;               ***  INPUT  ***
;               ***************
;               VCIRC      :  Scalar(or array) [float/double] defining the value(s) to
;                               plot as a circle(s) of constant speed [km/s] on the
;                               contour plot [e.g. gyrospeed of specularly reflected ion]
;                               [Default = FALSE]
;               EX_VECN    :  [V]-Element structure array containing extra vectors the
;                               user wishes to project onto the contour, each with
;                               the following format:
;                                  VEC   :  [3]-Element vector in the same coordinate
;                                             system as the bulk flow velocity etc.
;                                             contour plot projection
;                                             [e.g. VEC[0] = along X-GSE]
;                                  NAME  :  Scalar [string] used as a name for VEC
;                                             output onto the contour plot
;                                             [Default = 'Vec_j', j = index of EX_VECS]
;               WINDN      :  Scalar [long] defining the index of the window to use when
;                               selecting the region of interest
;                               [Default = !D.WINDOW]
;               QUIET      :  If set, routine will not print out each set of parameter
;                               solutions for the model distribution functions
;                               [Note:  Not the keyword used by MPFIT2DFUN.PRO]
;               BFRAME     :  If set, routine will know the VSW tag in DAT is set to the
;                               beam bulk velocity => transforms into beam frame,
;                               otherwise the routine fits distributions in core frame
;               ****************
;               ***  OUTPUT  ***
;               ****************
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  [all the following changed on output]  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               DATA_OUT   :  Set to a named variable to return a structure containing
;                               the relevant information associated with the plots,
;                               plot analysis, and fit results
;               READ_OUT   :  Set to a named variable to return a string containing the
;                               last command line input.  This is used by the overhead
;                               routine to determine whether user left the program by
;                               quitting or if the program finished
;               PLOT_STR   :  Scalar [structure] that defines the scaling factors for the
;                               contour plot shown in window WINDN to be used by
;                               region_cursor_select.pro
;               MODEL_OUT  :  Set to a named variable to return the beam fitting results
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/03/2012   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/04/2012   v1.0.0]
;             3)  Continued to write routine
;                                                                   [09/04/2012   v1.0.0]
;             4)  Changed error estimates to the square root of the average of the
;                   beam data in counts [e.g. Poisson errors]
;                                                                   [09/05/2012   v1.0.0]
;             5)  Changed error estimates to the square root of the counts and filled
;                   empty bins with 1.0
;                                                                   [09/06/2012   v1.0.0]
;             6)  Continued to change routine
;                                                                   [09/07/2012   v1.0.0]
;             7)  Changed format of DATA_OUT structure
;                                                                   [09/08/2012   v1.0.0]
;             8)  Added keyword:  BFRAME
;                                                                   [09/11/2012   v1.1.0]
;             9)  Fixed an issue that occurred when fitting in the "core" frame of
;                   reference and now allows user to dynamically turn on and off the
;                   tying of the density to the thermal speeds
;                                                                   [09/17/2012   v1.2.0]
;            10)  Cleaned up and fixed some bugs
;                                                                   [09/21/2012   v1.3.0]
;            11)  Now uses the square root of the count rate (corrected for deadtime)
;                   for error estimates
;                                                                   [10/09/2012   v1.4.0]
;            12)  There was an issue in the unit conversion routines that did not allow
;                   for fractional counts.  This posed a problem when using the one-
;                   count level for error estimates.  The issue has been corrected by
;                   using the FRACTIONAL_COUNTS keyword in conv_units.pro
;                                                                   [09/19/2014   v1.5.0]
;            13)  Fixed a bug caught by S.E. Dorfman and updated Man. page
;                                                                   [12/04/2015   v1.6.0]
;
;   NOTES:      
;               1)  User should not call this routine
;               2)  The error factor does not [currently] have a physical explanation.
;                     I only know that it gives results which appear to match the
;                     observations to with the fewest parameter constraints.
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
;   CREATED:  09/01/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  12/04/2015   v1.6.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO beam_fit_fit_wrapper,dat,VCIRC=vcirc,EX_VECN=ex_vecn,WINDN=windn,QUIET=quiet,  $
                             DATA_OUT=data_out,READ_OUT=read_out,                  $
                             PLOT_STR=plot_str,MODEL_OUT=model_out,                $
                             BFRAME=bframe

;;  Let IDL know that the following are functions
FORWARD_FUNCTION beam_fit___get_common, conv_units, find_dist_func_cuts, $
                 moments_3d_new, bimaxwellian, beam_fit_gen_prompt, df_fit_beam_peak
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
n_tied         = 0                   ;;  missed defining this later (caught by SED)
;;  Define contour plotting routine
func_cont      = 'beam_fit_contour_plot'
tag_pref       = ['DF2D','VELX','VELY','TR','VX_GRID','VY_GRID','GOOD_IND']

dumb           = {VALUE:0d0,FIXED:0b,LIMITED:[0b,0b],LIMITS:[0d0,0d0],TIED:''}
;;----------------------------------------------------------------------------------------
;;  Get parameters (from common blocks)
;;----------------------------------------------------------------------------------------
vbmax          = beam_fit___get_common('vcmax',DEFINED=defined)
plane          = beam_fit___get_common('plane',DEFINED=defined)
perc_pk        = beam_fit___get_common('perc_pk',DEFINED=defined)
fill           = beam_fit___get_common('fill',DEFINED=defined)
angle          = beam_fit___get_common('angle',DEFINED=defined)
sm_cont        = beam_fit___get_common('sm_cont',DEFINED=defined)
nsmooth        = beam_fit___get_common('nsmooth',DEFINED=defined)
;;----------------------------------------------------------------------------------------
;;  Define parameters
;;----------------------------------------------------------------------------------------
perc_old       = perc_pk[0]
perc           = perc_pk[0]
miss           = fill[0]
;;  Define suffix for structure tags
tagsuf         = '_'+STRUPCASE(plane[0])
tags           = STRLOWCASE(tag_pref+tagsuf[0])
;;----------------------------------------------------------------------------------------
;;  Define dummy copy
;;----------------------------------------------------------------------------------------
dat_beam       = dat[0]
;;  Define copy of original input for error estimates
;;    [LBW III  09/06/2012   v1.0.0]
dat_orig       = data_out[0].DAT[0].IDL_DIST[0].ORIG[0]
;; Define masks used on core and beam to remove values from analysis
mask_core      = data_out[0].MASKS[0].CORE
mask_beam      = data_out[0].MASKS[0].BEAM
;; Fill empty bins with 1.0
dat_bkg        = dat_orig
data_or        = dat_bkg.DATA
zero           = WHERE(data_or LT 1. OR FINITE(data_or) EQ 0,ze,COMPLEMENT=good,NCOMPLEMENT=gd)
IF (ze GT 0) THEN BEGIN
  ;; Fill empty bins with 1.0
  data_or[zero]   = 1.0
ENDIF
dat_bkg.DATA   = data_or
;;  Convert to corrected count rate
dat_bkg        = conv_units(dat_bkg,'crate',/FRACTIONAL_COUNTS)
data_or        = dat_bkg.DATA
;;  Use Poisson error estimates
data_0         = SQRT(data_or)
;;  Apply core mask
data_0         = data_0 - data_0*mask_core
;;  Apply beam mask
data_0        *= mask_beam
;;  Redefine data
dat_bkg.DATA   = data_0
;;  Convert to back to counts
dat_bkg        = conv_units(dat_bkg,'counts',/FRACTIONAL_COUNTS)
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Fit to "beam" peak
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
dat_mom        = dat_beam[0]
pot            = dat_mom[0].SC_POT
tmagf          = REFORM(dat_mom[0].MAGF)
tvbulk         = REFORM(dat_mom[0].VSW)  ;; use this for rotation only
;;  Define "Error" Structure
dat_onec       = dat_bkg[0]
;;  Change VSW tag to "beam"("core") frame value
dat_onec.VSW   = tvbulk
;;----------------------------------------------------------------------------------------
;;  Transform into "beam"("core") frame
;;----------------------------------------------------------------------------------------
transform_vframe_3d,dat_mom,/EASY_TRAN
;;  one-count
transform_vframe_3d,dat_onec,/EASY_TRAN
;;----------------------------------------------------------------------------------------
;;  Rotate into FACs
;;----------------------------------------------------------------------------------------
rotate_3dp_structure,dat_mom,tmagf,tvbulk,VLIM=vlim
;;  one-count
rotate_3dp_structure,dat_onec,tmagf,tvbulk,VLIM=vlim
;;  Define rotation matrix
IF (plane[0] EQ 'xz') THEN rmat = dat_mom.ROT_MAT_Z ELSE rmat = dat_mom.ROT_MAT
IF (plane[0] EQ 'xz') THEN gels = [2L,0L]           ELSE gels = [0L,1L]

all_tags       = STRLOWCASE(TAG_NAMES(dat_mom))
FOR j=0L, N_ELEMENTS(tags) - 1L DO BEGIN
  good = WHERE(all_tags EQ tags[j],gd)
  IF (j EQ 0) THEN df2d    = dat_mom.(good[0])   ;;  define 2D data projection
  IF (j EQ 0) THEN df2d1c  = dat_onec.(good[0])  ;;  one-count 2D data projection
  IF (j EQ 4) THEN vx2d    = dat_mom.(good[0])   ;;  define gridded X-velocities
  IF (j EQ 5) THEN vy2d    = dat_mom.(good[0])   ;;  define gridded Y-velocities
ENDFOR
;;--------------------------------------------------------
;;  Replace zeros or negative values with NaNs
;;    [LBW III  09/05/2012   v1.0.0]
;;--------------------------------------------------------
bad            = WHERE(df2d LE 0. OR FINITE(df2d) EQ 0,bd,COMPLEMENT=good,NCOMPLEMENT=gd)
IF (bd GT 0) THEN df2d[bad] = f
test           = (df2d1c LE 0.) OR (FINITE(df2d1c) EQ 0)
bad            = WHERE(test,bd,COMPLEMENT=good,NCOMPLEMENT=gd)
IF (bd GT 0) THEN df2d1c[bad] = f
;;  Replace zeros or NaNs with 10% of data
test           = ((FINITE(df2d1c) EQ 0) AND FINITE(df2d)) EQ 0
bad            = WHERE(test,bd,COMPLEMENT=good,NCOMPLEMENT=gd)
IF (gd GT 0) THEN df2d1c[good] = ABS(df2d[good])/1e1
;;--------------------------------------------------------
;;  Smooth contour if desired
;;--------------------------------------------------------
df2ds          = SMOOTH(df2d,nsmooth[0],/EDGE_TRUNCATE,/NAN)
df2d1cs        = SMOOTH(df2d1c,nsmooth[0],/EDGE_TRUNCATE,/NAN)
;;--------------------------------------------------------
;;  Replace errors that are "too large" with 10% of data
;;--------------------------------------------------------
test           = (df2d1cs/df2ds GE 0.7)
bad            = WHERE(test,bd,COMPLEMENT=good,NCOMPLEMENT=gd)
IF (bd GT 0) THEN df2d1cs[bad] = ABS(df2ds[bad])/1e1

zmax           = MAX(df2ds,/NAN,zxind)                 ;; = A_b [peak beam amplitude]
zmax_str0      = STRCOMPRESS(STRING(zmax[0],FORMAT='(E15.2)'),/REMOVE_ALL)
zmax_str       = zmax_str0[0]+' [cm^(-3) km^(-3) s^(+3)]'

zind           = ARRAY_INDICES(df2ds,zxind)
;;--------------------------------------------------------
;;  Calculate Cuts
;;--------------------------------------------------------
vox_00         = vx2d[zind[0]]
voy_00         = vy2d[zind[1]]
dumb_cuts      = find_dist_func_cuts(df2ds,vx2d,vy2d,V_0X=vox_00[0],V_0Y=voy_00[0],ANGLE=angle)
zmax_cut       = MAX([dumb_cuts.DF_PARA,dumb_cuts.DF_PERP],/NAN)
zmax_cut_str   = STRCOMPRESS(STRING(zmax_cut[0],FORMAT='(E15.2)'),/REMOVE_ALL)
;;--------------------------------------------------------
;;  Perform moment analysis to get initial estimates
;;--------------------------------------------------------
sform          = moments_3d_new(/DOMEGA_WEIGHTS)
tmoms          = moments_3d_new(dat_mom,FORMAT=sform,SC_POT=pot[0],MAGDIR=tmagf,/DOMEGA_WEIGHTS)

mass           = tmoms.MASS      ;; particle mass [eV/c^2, with c in km/s]
n_b            = tmoms.DENSITY   ;; density of entire "halo" [# cm^(-3)]
t3mag          = tmoms.MAGT3     ;; "vector" temperature [eV, (perp1,perp2,para)]
t_b_perp       = (t3mag[0] + t3mag[1])/2d0
t_b_para       = REFORM(t3mag[2])
v_b_gse        = tmoms.VELOCITY              ;; bulk velocity [km/s]
vtb_par        = SQRT(2d0*t_b_para/mass[0])  ;; Para. thermal speed [km/s]
vtb_per        = SQRT(2d0*t_b_perp/mass[0])  ;; Perp. thermal speed [km/s]
;;  Rotate V_b into FACs
v_b_fac        = REFORM(rmat ## v_b_gse)
vob_par        = v_b_fac[gels[0]]
vob_per        = v_b_fac[gels[1]]
;;----------------------------------------------------------------------------------------
;;  Set up parameters
;;----------------------------------------------------------------------------------------
force_per      = 0                ;; logic [changing relative % of peak to use]
force_vo       = 0                ;; logic [changing drift speeds]
force_vta      = 0                ;; logic [changing para. thermal speed]
force_vtp      = 0                ;; logic [changing perp. thermal speed]
const          = REPLICATE(0b,6)  ;; logic for constraints in fitting routine
func           = 'bimaxwellian'   ;; routine used for model function to fit to
error          = ABS(df2d1cs)     ;; absolute errors = one-count level
;;-----------------------------------------------------------------------
;               PARAM  :  [6]-Element array containing:
;                           PARAM[0] = Number Density [cm^(-3)]
;                           PARAM[1] = Parallel Thermal Speed [km/s]
;                           PARAM[2] = Perpendicular Thermal Speed [km/s]
;                           PARAM[3] = Parallel Drift Speed [km/s]
;                           PARAM[4] = Perpendicular Drift Speed [km/s]
;                           PARAM[5] = *** Not Used Here ***
;;-----------------------------------------------------------------------
param          = [n_b[0],vtb_par[0],vtb_per[0],vob_par[0],vob_per[0],0d0]
;;----------------------------------------------------------------------------------------
;;  Add to output structure
;;----------------------------------------------------------------------------------------
str_element,data_out,'MOMENT_ANALYSIS.MOMENTS',tmoms[0],/ADD_REPLACE
str_element,data_out,'MOMENT_ANALYSIS.PARAMS',param,/ADD_REPLACE
IF KEYWORD_SET(bframe) THEN BEGIN
  ;; Fits performed in "beam" frame
  param          = [n_b[0],vtb_par[0],vtb_per[0],vob_par[0],vob_per[0],0d0]
  str_element,data_out,'DAT.IDL_DIST.BEAM.BEAM_FRAME',dat_mom,/ADD_REPLACE
  str_element,data_out,'VELOCITY.BEAM.BEAM_FRAME.V_0X',vob_par[0],/ADD_REPLACE
  str_element,data_out,'VELOCITY.BEAM.BEAM_FRAME.V_0Y',vob_per[0],/ADD_REPLACE
  vox_b          = param[3]
  voy_b          = param[4]
  ;;  Change center of "beam" peak offsets
  beam_fit___set_common,'v_bx',vox_b,STATUS=status
  beam_fit___set_common,'v_by',voy_b,STATUS=status
ENDIF ELSE BEGIN
  ;; Fits performed in "core" frame
  vox_b          = beam_fit___get_common('v_bx',DEFINED=defined)
  voy_b          = beam_fit___get_common('v_by',DEFINED=defined)
  ;; Force drift speeds to match user defined values
  param          = [n_b[0],vtb_par[0],vtb_per[0],vox_b[0],voy_b[0],0d0]
ENDELSE
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Plot Moment Analysis Results
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Construct bi-Maxwellian from fit results and plot
x              = vx2d
y              = vy2d
fv_bimax       = bimaxwellian(x,y,param)
;;  Calculate Cuts
fv_cuts        = find_dist_func_cuts(fv_bimax,x,y,V_0X=vox_b[0],V_0Y=voy_b[0],ANGLE=angle)
;;  Define plot params
windn          = 4
WSET,windn[0]
WSHOW,windn[0]
  beam_fit_contour_plot,dat_beam,VCIRC=vcirc,VB_REG=vb_reg,VC_XOFF=vox_b,                 $
                                VC_YOFF=voy_b,MODEL=fv_cuts,EX_VECN=ex_vecn,              $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
;;----------------------------------------------------------------------------------------
;; Try initializing PARINFO structure with minimal constraints
;;----------------------------------------------------------------------------------------
np             = N_ELEMENTS(param)
parinfo        = REPLICATE(dumb[0],np)
parinfo.VALUE  = param

read_out       = ''    ;; output value of decision
param_str      = STRCOMPRESS(STRING([param,ABS(param[2]/param[1])^2],FORMAT='(f25.4)'),/REMOVE_ALL)
;;--------------------------------------------------------------------------------------
;;  Print results
;;--------------------------------------------------------------------------------------
pro_out        = ['The initial Moment Analysis results are:','',          $
                  'Beam Density [cm^(-3)]              = '+param_str[0],  $
                  'Beam Para. Thermal Speed [km/s]     = '+param_str[1],  $
                  'Beam Perp. Thermal Speed [km/s]     = '+param_str[2],  $
                  'Beam Para. Drift Speed [km/s]       = '+param_str[3],  $
                  'Beam Perp. Drift Speed [km/s]       = '+param_str[4],  $
                  'Beam Temp. Anisotropy [Tperp/Tpara] = '+param_str[6],  $
                  '','Do the results shown in the plot look good or is',  $
                  'further analysis necessary?']
str_out        = "Do you wish to constrain/limit any of these parameters before fitting (y/n)?  "
WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
  read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
  IF (read_out EQ 'debug') THEN STOP
ENDWHILE
;;  Check if user wishes to quit
IF (read_out EQ 'q') THEN RETURN
;;--------------------------------------------------------------------------------------
;;  Change Parameters?
;;--------------------------------------------------------------------------------------
IF (read_out EQ 'y') THEN true = 1 ELSE true = 0
WHILE (true) DO BEGIN
  ;;------------------------------------------------------------------------------------
  ;;  Check if user wants to tie the density to A_b [ONLY use if no spurious peaks]
  ;;------------------------------------------------------------------------------------
  read_out       = ''
  pro_out        = ["*** ONLY say yes to the following if there are no spurious peaks ***",$
                    "","[Type 'q' to quit at any time]"]
  str_out        = "Do you wish to tie the density to the thermal speeds and peak (y/n)?  "
  WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
  ENDWHILE
  ;;  Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;  Check answer
  IF (read_out EQ 'y') THEN n_tied = 1 ELSE n_tied = 0
  IF KEYWORD_SET(n_tied) THEN BEGIN
    ;;  Tie density to peak in cuts
    beam_peak       = MAX([MAX(dfpar_out,/NAN),MAX(dfper_out,/NAN)],/NAN)
    maxstr          = STRTRIM(STRING(beam_peak[0],FORMAT='(g15.5)'),2L)
    parinfo[0].TIED = maxstr[0]+'*!DPI^(3d0/2d0)*P[1]*P[2]^2'
  ENDIF
  ;;------------------------------------------------------------------------------------
  ;;  Check if user wants to limit drift speeds
  ;;------------------------------------------------------------------------------------
  ;; Set/Reset outputs
  read_out       = ''
  value_out      = 0.
  pro_out        = ["*** Say no to the following unless the beam is not well isolated ***",$
                    "","[Type 'q' to quit at any time]"]
  str_out        = "Do you wish to limit the parallel drift speed (y/n)?  "
  WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
  ENDWHILE
  ;;  Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;  Check answer
  IF (read_out EQ 'y') THEN BEGIN
    ;;  Limit parallel drift speed
    read_in        = 'limit'
    index_out      = 3L
    beam_fit_fit_prompts,param,read_in,PARINFO=parinfo,READ_OUT=read_out,      $
                             VALUE_OUT=value_out,OLD_VALUE=old_value,          $
                             CONSTRAIN=constrain,LIMITED=limited,LIMITS=limits,$
                             CHANGE=change,INDEX_OUT=index_out
    test = TOTAL(change) GT 0
    IF (test) THEN BEGIN
      param      = parinfo.VALUE
    ENDIF
  ENDIF
  ;; Set/Reset outputs
  read_out       = ''
  value_out      = 0.
  pro_out        = ["*** Say no to the following unless the beam is not well isolated ***",$
                    "","[Type 'q' to quit at any time]"]
  str_out        = "Do you wish to limit the perpendicular drift speed (y/n)?  "
  WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
  ENDWHILE
  ;;  Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;  Check answer
  IF (read_out EQ 'y') THEN BEGIN
    ;;  Limit perpendicular drift speed
    read_in        = 'limit'
    index_out      = 4L
    beam_fit_fit_prompts,param,read_in,PARINFO=parinfo,READ_OUT=read_out,      $
                             VALUE_OUT=value_out,OLD_VALUE=old_value,          $
                             CONSTRAIN=constrain,LIMITED=limited,LIMITS=limits,$
                             CHANGE=change,INDEX_OUT=index_out
    test = TOTAL(change) GT 0
    IF (test) THEN BEGIN
      param      = parinfo.VALUE
    ENDIF
  ENDIF
  ;;------------------------------------------------------------------------------------
  ;;  Check if user wants to limit thermal speeds
  ;;------------------------------------------------------------------------------------
  ;; Set/Reset outputs
  read_out       = ''
  value_out      = 0.
  pro_out        = ["*** Say no to the following unless the model lines are not ***",$
                    "*** close to the actual data points in the cut plots       ***",$
                    "","[Type 'q' to quit at any time]"]
  str_out        = "Do you wish to limit the parallel thermal speed (y/n)?  "
  WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
  ENDWHILE
  ;;  Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;  Check answer
  IF (read_out EQ 'y') THEN BEGIN
    ;;  Limit parallel thermal speed
    read_in        = 'limit'
    index_out      = 1L
    beam_fit_fit_prompts,param,read_in,PARINFO=parinfo,READ_OUT=read_out,      $
                             VALUE_OUT=value_out,OLD_VALUE=old_value,          $
                             CONSTRAIN=constrain,LIMITED=limited,LIMITS=limits,$
                             CHANGE=change,INDEX_OUT=index_out
    test = TOTAL(change) GT 0
    IF (test) THEN BEGIN
      param      = parinfo.VALUE
    ENDIF
  ENDIF
  ;; Set/Reset outputs
  read_out       = ''
  value_out      = 0.
  pro_out        = ["*** Say no to the following unless the model lines are not ***",$
                    "*** close to the actual data points in the cut plots       ***",$
                    "","[Type 'q' to quit at any time]"]
  str_out        = "Do you wish to limit the perpendicular thermal speed (y/n)?  "
  WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
  ENDWHILE
  ;;  Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;  Check answer
  IF (read_out EQ 'y') THEN BEGIN
    ;;  Limit perpendicular thermal speed
    read_in        = 'limit'
    index_out      = 2L
    beam_fit_fit_prompts,param,read_in,PARINFO=parinfo,READ_OUT=read_out,      $
                             VALUE_OUT=value_out,OLD_VALUE=old_value,          $
                             CONSTRAIN=constrain,LIMITED=limited,LIMITS=limits,$
                             CHANGE=change,INDEX_OUT=index_out
    test = TOTAL(change) GT 0
    IF (test) THEN BEGIN
      param      = parinfo.VALUE
    ENDIF
  ENDIF
  ;;------------------------------------------------------------------------------------
  ;;  Allow to leave
  ;;------------------------------------------------------------------------------------
  true       = 0
ENDWHILE
;; Clean up
delete_variable,read_in
;;----------------------------------------------------------------------------------------
;;  Replot Moment Analysis Results with constraints
;;----------------------------------------------------------------------------------------
;;  Construct bi-Maxwellian from fit results and plot
x              = vx2d
y              = vy2d
fv_bimax       = bimaxwellian(x,y,param)
;;  Calculate Cuts
fv_cuts        = find_dist_func_cuts(fv_bimax,x,y,V_0X=vox_b[0],V_0Y=voy_b[0],ANGLE=angle)
;;  Define plot params
windn          = 4
WSET,windn[0]
WSHOW,windn[0]
  beam_fit_contour_plot,dat_beam,VCIRC=vcirc,VB_REG=vb_reg,VC_XOFF=vox_b,                 $
                                VC_YOFF=voy_b,MODEL=fv_cuts,EX_VECN=ex_vecn,              $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
iteration      = 0
;;========================================================================================
JUMP_PERC_AGAIN:
;;========================================================================================
IF (iteration GT 0) THEN BEGIN
  windn          = 4
  WSET,windn[0]
  WSHOW,windn[0]
    beam_fit_contour_plot,dat_beam,VCIRC=vcirc,VB_REG=vb_reg,VC_XOFF=vox_b,                 $
                                  VC_YOFF=voy_b,MODEL=fv_cuts,EX_VECN=ex_vecn,              $
                                  PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                  DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                  DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                  VPER_OUT=vper_out
ENDIF
x              = vx2d
y              = vy2d
z              = df2ds
dz             = error
;;  Limit results to f(v) > A_b*PERC_PK
test           = (z GE zmax[0]*perc[0]) AND FINITE(z)
good           = WHERE(test,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
IF (bd GT 0) THEN BEGIN
  z[bad]  = 0d0
  dz[bad] = 0d0
ENDIF

;;  Limit results to |V| < (0.95 * V_Tb) [if in Beam frame]
IF KEYWORD_SET(bframe) THEN BEGIN
  ;; Fits performed in "beam" frame
  max_vb         = 95d-2*vbmax[0]
  good           = WHERE(ABS(x) LT max_vb[0],gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
  IF (gd EQ 0) THEN BEGIN
    badfit_msg = "No finite data within defined 'beam' region..."
    MESSAGE,badfit_msg,/INFORMATIONAL,/CONTINUE
    ;;--------------------------------------------------------------------------------------
    ;;  Add to output structure
    ;;--------------------------------------------------------------------------------------
    prefs          = 'FIT_RESULTS.'
    str_element,data_out,prefs[0]+'FITS',0,/ADD_REPLACE
    str_element,data_out,prefs[0]+'CONSTRAINTS',parinfo,/ADD_REPLACE
    str_element,data_out,prefs[0]+'MODEL.BIMAX',fv_bimax,/ADD_REPLACE
    str_element,data_out,prefs[0]+'MODEL.CUTS',0,/ADD_REPLACE
    str_element,data_out,prefs[0]+'MODEL.CUTS',0,/ADD_REPLACE
    str_element,data_out,'KEYWORDS.PERC_PK',perc[0],/ADD_REPLACE
    ;;--------------------------------------------------------------------------------------
    ;;  Define output
    ;;--------------------------------------------------------------------------------------
    model_out      = 0
    RETURN
  ENDIF
ENDIF ELSE BEGIN
  ;; Fits performed in "core" frame
  good           = LINDGEN(N_ELEMENTS(x))
ENDELSE
z1             = z[good,*]
z2             = z1[*,good]
dz1            = dz[good,*]
dz2            = dz1[*,good]
x2             = x[good]
y2             = y[good]
;;----------------------------------------------------------------------------------------
;;  Fit
;;----------------------------------------------------------------------------------------
bimax_fit      = df_fit_beam_peak(x2,y2,z2,param,func,dz2,QUIET=quiet,FILL=miss[0],$
                                  PARINFO=parinfo)
param_fit      = bimax_fit.MODEL_PARAMS
;;  Construct bi-Maxwellian from fit results and plot
x              = vx2d
y              = vy2d
fv_bimax       = bimaxwellian(x,y,param_fit)
;;  Calculate Cuts
vox_b          = param_fit[3]
voy_b          = param_fit[4]
fv_cuts        = find_dist_func_cuts(fv_bimax,x,y,V_0X=vox_b[0],V_0Y=voy_b[0],ANGLE=angle)
fv_df_para     = fv_cuts.DF_PARA
fv_df_perp     = fv_cuts.DF_PERP
IF KEYWORD_SET(n_tied) THEN BEGIN
  ;; Density is tied to peak in cuts => Update values
  beam_peak       = MAX([MAX(fv_df_para,/NAN),MAX(fv_df_perp,/NAN)],/NAN)
  maxstr          = STRTRIM(STRING(beam_peak[0],FORMAT='(g15.5)'),2L)
  parinfo[0].TIED = maxstr[0]+'*!DPI^(3d0/2d0)*P[1]*P[2]^2'
  ;; Update fits
  bimax_fit       = df_fit_beam_peak(x2,y2,z2,param,func,dz2,QUIET=quiet,FILL=miss[0],$
                                     PARINFO=parinfo)
  param_fit       = bimax_fit.MODEL_PARAMS
  ;;  Construct bi-Maxwellian from fit results and plot
  x               = vx2d
  y               = vy2d
  fv_bimax        = bimaxwellian(x,y,param_fit)
  ;;  Calculate Cuts
  vox_b           = param_fit[3]
  voy_b           = param_fit[4]
  fv_cuts         = find_dist_func_cuts(fv_bimax,x,y,V_0X=vox_b[0],V_0Y=voy_b[0],ANGLE=angle)
ENDIF
;;  Change PARINFO
parinfo[*].VALUE = param_fit
;;  Define parallel/perpendicular cuts
fv_df_para     = fv_cuts.DF_PARA
fv_df_perp     = fv_cuts.DF_PERP
;;----------------------------------------------------------------------------------------
;;  Overplot Fit Results
;;----------------------------------------------------------------------------------------
;;  Change center of "beam" peak offsets
beam_fit___set_common,'v_bx',vox_b,STATUS=status
beam_fit___set_common,'v_by',voy_b,STATUS=status
;;  Define plot params
windn          = 4
WSET,windn[0]
WSHOW,windn[0]
  beam_fit_contour_plot,dat_beam,VCIRC=vcirc,VB_REG=vb_reg,VC_XOFF=vox_b,                 $
                                VC_YOFF=voy_b,MODEL=fv_cuts,EX_VECN=ex_vecn,              $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
;;----------------------------------------------------------------------------------------
;;  Check if user wants to tie the density to A_b [ONLY use if no spurious peaks]
;;----------------------------------------------------------------------------------------
;; Set/Reset outputs
good_jump      = 0b
IF (iteration EQ 0 AND n_tied EQ 0) THEN BEGIN
  read_out       = ''
  pro_out        = ["*** ONLY say yes to the following if there are no spurious peaks ***",$
                    "","[Type 'q' to quit at any time]"]
  str_out        = "Do you wish to tie the density to the thermal speeds and peak (y/n)?  "
  WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
  ENDWHILE
  ;;  Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;  Check answer
  IF (read_out EQ 'y') THEN n_tied = 1 ELSE n_tied = 0
  IF KEYWORD_SET(n_tied) THEN BEGIN
    ;;  Tie density to peak in cuts
    beam_peak       = MAX([MAX(dfpar_out,/NAN),MAX(dfper_out,/NAN)],/NAN)
    maxstr          = STRTRIM(STRING(beam_peak[0],FORMAT='(g15.5)'),2L)
    parinfo[0].TIED = maxstr[0]+'*!DPI^(3d0/2d0)*P[1]*P[2]^2'
    good_jump      += 1
  ENDIF
  iteration      = 1  ;; shut off this prompt
  IF (good_jump GT 0) THEN GOTO,JUMP_PERC_AGAIN
ENDIF ELSE IF (iteration EQ 0) THEN iteration      = 1  ;; shut off this prompt
;;----------------------------------------------------------------------------------------
;;  Check fit results
;;----------------------------------------------------------------------------------------
;; Set/Reset outputs
read_out       = ''               ;; output value of decision
true           = 1
WHILE (true) DO BEGIN
  ;; Set/Reset outputs
  read_out       = ''    ;; output value of decision
  value_out      = 0.    ;; output value for prompt
  pk_str         = STRCOMPRESS(STRING(perc[0]*1d2,FORMAT='(f15.1)')+'%',/REMOVE_ALL)
  str_out        = "Do you wish to try again with using a higher/lower percentage (y/n)?  "
  pro_out        = ["[Type 'q' to quit at any time]","",$
                    "The peak beam amplitude is A_b = "+zmax_str[0]+".",$
                    "You are currently using values > "+pk_str[0]+" of the peak beam amplitude.",$
                    "","Do the model fits suggest that low amplitude points have skewed the results?"]
  WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
  ENDWHILE
  ;;  Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  ;;--------------------------------------------------------------------------------------
  ;;  Change Percentage?
  ;;--------------------------------------------------------------------------------------
  IF (read_out EQ 'y') THEN BEGIN
    err_msg        = ["Input must be < 0.90 !","Try again..."]
    str_out        = "Enter a percentage in decimal form (e.g. 1% = 0.01) less than 0.90:  "
    ;;  User thinks so
    true           = 1
    WHILE (true) DO BEGIN
      value_out      = beam_fit_gen_prompt(STR_OUT=str_out,FORM_OUT=5)
      true           = (ABS(value_out[0]) LT 0.0) AND (ABS(value_out[0]) GE 0.9)
      IF (true AND (ABS(value_out[0]) GE 0.9)) THEN BEGIN
        err_out = beam_fit_gen_prompt(ERRMSG=err_msg,FORM_OUT=7)
      ENDIF
    ENDWHILE
    ;;  Define new percentage and retry fitting
    perc           = ABS(value_out[0])
    ;;  Define Jump Back Logic
    force_per      = 1
  ENDIF ELSE force_per      = 0
  ;;  set jump condition
  good_jump      = force_per
  ;;--------------------------------------------------------------------------------------
  ;;  Tie/Untie density?
  ;;--------------------------------------------------------------------------------------
  ;; Set/Reset outputs
  read_out       = ''    ;; output value of decision
  str_out        = "Do you wish to change the TIED setting (y/n)?  "
  pro_out        = ["[Type 'q' to quit at any time]"]
  WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
  ENDWHILE
  ;;  Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  IF (read_out EQ 'y') THEN BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Check if user wants to tie/untie the density to A_b [ONLY use if no spurious peaks]
    ;;------------------------------------------------------------------------------------
    IF KEYWORD_SET(n_tied) THEN BEGIN
      pro_out        = ["*** Be careful if there are spurious peaks ***",$
                        "","[Type 'q' to quit at any time]"]
      str_out        = "Do you wish to keep the density TIED to the thermal speeds and peak (y/n)?  "
    ENDIF ELSE BEGIN
      pro_out        = ["*** ONLY say yes to the following if there are no spurious peaks ***",$
                        "","[Type 'q' to quit at any time]"]
      str_out        = "Do you wish to TIE the density to the thermal speeds and peak (y/n)?  "
    ENDELSE
    
    read_out       = ''
    WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
      read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
      IF (read_out EQ 'debug') THEN STOP
    ENDWHILE
    ;;  Check if user wishes to quit
    IF (read_out EQ 'q') THEN RETURN
    ;;  Check answer
    test           = (read_out EQ 'n' AND KEYWORD_SET(n_tied)) OR $
                     ((read_out EQ 'y') AND (n_tied EQ 0))
    IF (test) THEN BEGIN
      good_jump     += 1
      test           = (read_out EQ 'n' AND KEYWORD_SET(n_tied))
      IF (test) THEN BEGIN
        ;; user wants to untie the density and thermal speeds
        n_tied         = 0
      ENDIF ELSE BEGIN
        ;; user wants to   tie the density and thermal speeds
        n_tied         = 1
      ENDELSE
    ENDIF
    ;; Check choice
    IF (read_out EQ 'y') THEN n_tied = 1 ELSE n_tied = 0
    IF KEYWORD_SET(n_tied) THEN BEGIN
      ;;  Tie density to peak in cuts
      beam_peak       = MAX([MAX(dfpar_out,/NAN),MAX(dfper_out,/NAN)],/NAN)
      maxstr          = STRTRIM(STRING(beam_peak[0],FORMAT='(g15.5)'),2L)
      parinfo[0].TIED = maxstr[0]+'*!DPI^(3d0/2d0)*P[1]*P[2]^2'
    ENDIF ELSE parinfo[0].TIED = ''
  ENDIF ELSE BEGIN
    IF KEYWORD_SET(n_tied) THEN BEGIN
      ;;  Tie density to peak in cuts
      beam_peak       = MAX([MAX(dfpar_out,/NAN),MAX(dfper_out,/NAN)],/NAN)
      maxstr          = STRTRIM(STRING(beam_peak[0],FORMAT='(g15.5)'),2L)
      parinfo[0].TIED = maxstr[0]+'*!DPI^(3d0/2d0)*P[1]*P[2]^2'
    ENDIF ELSE parinfo[0].TIED = ''
    true = 0
  ENDELSE
  ;;--------------------------------------------------------------------------------------
  ;;  Change Parameters?
  ;;--------------------------------------------------------------------------------------
  ;; Set/Reset outputs
  true           = 1
  read_out       = ''    ;; output value of decision
  str_out        = "Do you wish to change any of the input parameters, constraints, limits, etc. (y/n)?  "
  pro_out        = ["[Type 'q' to quit at any time]"]
  WHILE (read_out NE 'n' AND read_out NE 'y' AND read_out NE 'q') DO BEGIN
    read_out       = beam_fit_gen_prompt(STR_OUT=str_out,PRO_OUT=pro_out,FORM_OUT=7)
    IF (read_out EQ 'debug') THEN STOP
  ENDWHILE
  ;;  Check if user wishes to quit
  IF (read_out EQ 'q') THEN RETURN
  IF (read_out EQ 'y') THEN BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Check if user wants to change any other parameters
    ;;------------------------------------------------------------------------------------
    beam_fit_fit_prompts,param,read_in,PARINFO=parinfo,READ_OUT=read_out,      $
                             VALUE_OUT=value_out,OLD_VALUE=old_value,          $
                             CONSTRAIN=constrain,LIMITED=limited,LIMITS=limits,$
                             CHANGE=change
    test = TOTAL(change) GT 0
    IF (test) THEN BEGIN
      param      = parinfo.VALUE
      good_jump += 1
      true       = 0
    ENDIF
  ENDIF ELSE true = 0
ENDWHILE
;;  If something changed, try again...
IF (good_jump GT 0) THEN GOTO,JUMP_PERC_AGAIN
;;----------------------------------------------------------------------------------------
;;  Re-plot and leave
;;----------------------------------------------------------------------------------------
windn          = 4
WSET,windn[0]
WSHOW,windn[0]
  beam_fit_contour_plot,dat_beam,VCIRC=vcirc,VB_REG=vb_reg,VC_XOFF=vox_b,                 $
                                VC_YOFF=voy_b,MODEL=fv_cuts,EX_VECN=ex_vecn,              $
                                PLOT_STR=plot_str,V_LIM_OUT=vlim_out,DF_RA_OUT=dfra_out,  $
                                DF_MN_OUT=dfmin_out,DF_MX_OUT=dfmax_out,DF_OUT=df_out,    $
                                DFPAR_OUT=dfpar_out,DFPER_OUT=dfper_out,VPAR_OUT=vpar_out,$
                                VPER_OUT=vper_out
;;----------------------------------------------------------------------------------------
;;  Add to output structure
;;----------------------------------------------------------------------------------------
prefs          = 'FIT_RESULTS.'
str_element,data_out,prefs[0]+'FITS',bimax_fit,/ADD_REPLACE
str_element,data_out,prefs[0]+'CONSTRAINTS',parinfo,/ADD_REPLACE
str_element,data_out,prefs[0]+'MODEL.BIMAX',fv_bimax,/ADD_REPLACE
str_element,data_out,prefs[0]+'MODEL.CUTS',fv_cuts,/ADD_REPLACE
str_element,data_out,prefs[0]+'MODEL.CUTS',fv_cuts,/ADD_REPLACE

str_element,data_out,'KEYWORDS.PERC_PK',perc[0],/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Define output
;;----------------------------------------------------------------------------------------
model_out      = fv_cuts
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END

