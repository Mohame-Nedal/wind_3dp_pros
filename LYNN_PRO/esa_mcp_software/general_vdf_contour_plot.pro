;*****************************************************************************************
;
;  FUNCTION :   defaults_vdf_contour_plot.pro
;  PURPOSE  :   This routine sets up and defines the default settings for keywords
;                 not set by the user.
;
;  CALLED BY:   
;               general_vdf_contour_plot.pro
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               is_a_number.pro
;               is_a_3_vector.pro
;               mag__vec.pro
;               test_plot_axis_range.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               VDF      :  [N]-Element [float/double] array defining particle velocity
;                             distribution function (VDF) in units of phase space density
;                             [e.g., # s^(+3) km^(-3) cm^(-3)]
;               VELXYZ   :  [N,3]-Element [float/double] array defining the particle
;                             velocity 3-vectors for each element of VDF
;
;  EXAMPLES:    
;               [calling sequence]
;               tests = defaults_vdf_contour_plot(vdf, velxyz [,VFRAME=vframe]           $
;                                                 [,VEC1=vec1] [,VEC2=vec2] [,VLIM=vlim] $
;                                                 [,NLEV=nlev] [,XNAME=xname]            $
;                                                 [,YNAME=yname] [,SM_CUTS=sm_cuts]      $
;                                                 [,SM_CONT=sm_cont] [,NSMCUT=nsmcut]    $
;                                                 [,NSMCON=nsmcon] [,PLANE=plane]        $
;                                                 [,DFMIN=dfmin] [,DFMAX=dfmax]          $
;                                                 [,DFRA=dfra] [,V_0X=v_0x] [,V_0Y=v_0y])
;
;  KEYWORDS:    
;               ***  INPUTS  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  [all of the following have default settings]  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               VFRAME   :  [3]-Element [float/double] array defining the 3-vector
;                             velocity of the K'-frame relative to the K-frame [km/s]
;                             to use to transform the velocity distribution into the
;                             bulk flow reference frame
;                             [ Default = [10,0,0] ]
;               VEC1     :  [3]-Element vector to be used for "parallel" direction in
;                             a 3D rotation of the input data
;                             [e.g. see rotate_3dp_structure.pro]
;                             [ Default = [1.,0.,0.] ]
;               VEC2     :  [3]--Element vector to be used with VEC1 to define a 3D
;                             rotation matrix.  The new basis will have the following:
;                               X'  :  parallel to VEC1
;                               Z'  :  parallel to (VEC1 x VEC2)
;                               Y'  :  completes the right-handed set
;                             [ Default = [0.,1.,0.] ]
;               VLIM     :  Scalar [numeric] defining the velocity [km/s] limit for x-y
;                             velocity axes over which to plot data
;                             [Default = [-1,1]*MAX(ABS(VELXYZ))]
;               NLEV     :  Scalar [numeric] defining the # of contour levels to plot
;                             [Default = 30L]
;               XNAME    :  Scalar [string] defining the name of vector associated with
;                             the VEC1 input
;                             [Default = 'X']
;               YNAME    :  Scalar [string] defining the name of vector associated with
;                             the VEC2 input
;                             [Default = 'Y']
;               SM_CUTS  :  If set, program smoothes the cuts of the VDF before plotting
;                             [Default = FALSE]
;               SM_CONT  :  If set, program smoothes the contours of the VDF before
;                             plotting
;                             [Default = FALSE]
;               NSMCUT   :  Scalar [numeric] defining the # of points over which to
;                             smooth the 1D cuts of the VDF before plotting
;                             [Default = 3]
;               NSMCON   :  Scalar [numeric] defining the # of points over which to
;                             smooth the 2D contour of the VDF before plotting
;                             [Default = 3]
;               PLANE    :  Scalar [string] defining the plane projection to plot with
;                             corresponding cuts [Let V1 = VEC1, V2 = VEC2]
;                               'xy'  :  horizontal axis parallel to V1 and normal
;                                          vector to plane defined by (V1 x V2)
;                                          [default]
;                               'xz'  :  horizontal axis parallel to (V1 x V2) and
;                                          vertical axis parallel to V1
;                               'yz'  :  horizontal axis defined by (V1 x V2) x V1
;                                          and vertical axis (V1 x V2)
;                             [Default = 'xy']
;               DFMIN    :  Scalar [numeric] defining the minimum allowable phase space
;                             density to plot, which is useful for ion distributions with
;                             large angular gaps in data (prevents lower bound from
;                             falling below DFMIN)
;                             [Default = 1d-20]
;               DFMAX    :  Scalar [numeric] defining the maximum allowable phase space
;                             density to plot, which is useful for distributions with
;                             data spikes (prevents upper bound from exceeding DFMAX)
;                             [Default = 1d-2]
;               DFRA     :  [2]-Element [numeric] array specifying the VDF range in phase
;                             space density [e.g., # s^(+3) km^(-3) cm^(-3)] for the
;                             cuts and contour plots
;                             [Default = [MIN(VDF),MAX(VDF)]]
;               V_0X     :  Scalar [float/double] defining the velocity [km/s] along the
;                             X-Axis (horizontal) to shift the location where the
;                             perpendicular (vertical) cut of the DF will be performed
;                             [Default = 0.0]
;               V_0Y     :  Scalar [float/double] defining the velocity [km/s] along the
;                             Y-Axis (vertical) to shift the location where the
;                             parallel (horizontal) cut of the DF will be performed
;                             [Default = 0.0]
;
;   CHANGED:  1)  Fixed a bug that occurs when VDF input contains zeros
;                                                                  [05/16/2016   v1.0.1]
;             2)  Fixed a bug that occurs when user sets the EX_INFO keyword
;                                                                  [05/17/2016   v1.0.2]
;             3)  Added keyword C_LOG to main routine
;                                                                  [05/26/2017   v1.0.3]
;             4)  Cleaned up
;                                                                  [05/26/2017   v1.0.4]
;             5)  Added keyword P_LOG to main routine
;                                                                  [05/30/2017   v1.0.5]
;
;   NOTES:      
;               1)  Setting DFRA trumps any values set in DFMIN and DFMAX
;               2)  All inputs will be altered on output
;               3)  All keywords will be altered on output
;               4)  There are checks to make sure user's settings cannot produce useless
;                     plots, e.g., V_0X and V_0Y cannot fall outside 80% of VLIM
;               5)  There must be at least 10 finite VDF values with associated finite
;                     VELXYZ vector magnitudes and those ≥10 VDF values must be unique
;
;  REFERENCES:  
;               NA
;
;   CREATED:  04/07/2016
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  05/30/2017   v1.0.5
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION defaults_vdf_contour_plot,vdf,velxyz,VFRAME=vframe,VEC1=vec1,VEC2=vec2,          $
                             VLIM=vlim,NLEV=nlev,XNAME=xname,YNAME=yname,SM_CUTS=sm_cuts, $
                             SM_CONT=sm_cont,NSMCUT=nsmcut,NSMCON=nsmcon,PLANE=plane,     $
                             DFMIN=dfmin,DFMAX=dfmax,DFRA=dfra,V_0X=v_0x,V_0Y=v_0y

FORWARD_FUNCTION is_a_number, is_a_3_vector, mag__vec, test_plot_axis_range
;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
vec_str        = ['x','y','z']
vec_col        = [250,150,50]
all_planes     = ['xy','xz','yz']
;;  Position of contour plot [square]
;;               Xo    Yo    X1    Y1
pos_0con       = [0.22941,0.515,0.77059,0.915]
;;  Position of 1st DF cuts [square]
pos_0cut       = [0.22941,0.050,0.77059,0.450]
;;  Dummy error messages
no_inpt_msg    = 'User must supply a VDF and a corresponding array of 3-vector velocities...'
badvfor_msg    = 'Incorrect input format:  VDF and VELXYZ must have the same size first dimensions...'
nofinite_mssg  = 'Not enough finite and unique data was supplied...'
;;----------------------------------------------------------------------------------------
;;  Defaults
;;----------------------------------------------------------------------------------------
;;  Default frame and coordinates
def_vframe     = [1d1,0d0,0d0]          ;;  Assumes km/s units on input
def_vec1       = [1d0,0d0,0d0]
def_vec2       = [0d0,1d0,0d0]
;;  Default plot stuff
def_nlev       = 30L
def_xname      = 'X'
def_yname      = 'Y'
def_sm_cuts    = 0b
def_sm_cont    = 0b
def_nsmcut     = 3L
def_nsmcon     = 3L
def_plane      = 'xy'
def_con_xttl   = '(V dot '+def_xname[0]+') [1000 km/s]'
def_con_yttl   = '('+def_xname[0]+' x '+def_yname[0]+') x '+def_xname[0]+' [1000 km/s]'
def_con_zttl   = '('+def_xname[0]+' x '+def_yname[0]+') [1000 km/s]'
def_units_vdf  = '[sec!U3!N km!U-3!N cm!U-3!N'+']'
def_cut_yttl   = '1D VDF Cuts'+'!C'+def_units_vdf[0]
def_cut_xttl   = 'Velocity [1000 km/sec]'
;;  Define lower/upper bound on phase space densities
lower_lim      = 1e-20  ;;  Lowest expected value for DF [s^(+3) cm^(-3) km^(-3)]
upper_lim      = 1e-2   ;;  Highest expected value for DF [s^(+3) cm^(-3) km^(-3)]
def_dfnx       = [lower_lim[0],upper_lim[0]]
;;  Default crosshair location for cuts
def_vox        = 0d0
def_voy        = 0d0
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 2) OR (is_a_number(vdf,/NOMSSG) EQ 0) OR  $
                 (is_a_3_vector(velxyz,V_OUT=vxyz,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  MESSAGE,no_inpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
szdvdf         = SIZE(vdf,/DIMENSIONS)
szdvel         = SIZE(vxyz,/DIMENSIONS)
test           = (szdvdf[0] NE szdvel[0]) OR (szdvdf[0] LT 10)
IF (test[0]) THEN BEGIN
  MESSAGE,badvfor_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Now that we know these are at least formatted correct, test values
vmag           = mag__vec(vxyz,/NAN)
test           = (TOTAL(FINITE(vdf)) LT 10) OR (TOTAL(FINITE(vmag)) LT 10)
IF (test[0]) THEN BEGIN
  MESSAGE,'0: '+nofinite_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Define default VLIM and DFRA
def_vlim       = MAX(ABS(vmag),/NAN)*1.05
def_dfra       = [MIN(ABS(vdf),/NAN) > def_dfnx[0],MAX(ABS(vdf),/NAN) < def_dfnx[1]]
;def_dfra       = [MIN(ABS(vdf),/NAN),MAX(ABS(vdf),/NAN)]
;;  Make sure values are unique and have a finite range
test           = (test_plot_axis_range(def_dfra,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  MESSAGE,'1: '+nofinite_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Inflate by ±5%
def_dfra      *= [0.95,1.05]
test           = (TOTAL(def_dfra LE 0) GT 0)
IF (test[0]) THEN def_dfra = def_dfnx  ;;  revert to default limits
;;----------------------------------------------------------------------------------------
;;  Check keywords [Inputs]
;;----------------------------------------------------------------------------------------
;;  Check VFRAME
test           = (is_a_3_vector(vframe,V_OUT=vtrans,/NOMSSG) EQ 0)
IF (test[0]) THEN vframe = def_vframe ELSE vframe = vtrans
;;  Check VEC1 and VEC2
test           = (is_a_3_vector(vec1,V_OUT=v1out,/NOMSSG) EQ 0)
IF (test[0]) THEN vec1 = def_vec1 ELSE vec1 = v1out
test           = (is_a_3_vector(vec2,V_OUT=v2out,/NOMSSG) EQ 0)
IF (test[0]) THEN vec2 = def_vec2 ELSE vec2 = v2out
;;  Check VLIM
test           = (is_a_number(vlim,/NOMSSG) EQ 0)
IF (test[0]) THEN vlim = def_vlim[0] ELSE vlim = ABS(vlim[0])
test           = (vlim[0] LE MIN(ABS(vmag),/NAN))
IF (test[0]) THEN vlim = def_vlim[0]
;;  Check NLEV
test           = (is_a_number(nlev,/NOMSSG) EQ 0)
IF (test[0]) THEN nlev = def_nlev[0] ELSE nlev = LONG(ABS(nlev[0]))
test           = (nlev[0] LE 3)
IF (test[0]) THEN nlev = def_nlev[0]
;;  Check XNAME and YNAME
test           = (SIZE(xname,/TYPE) NE 7)
IF (test[0]) THEN xname = def_xname[0] ELSE xname = xname[0]
test           = (SIZE(yname,/TYPE) NE 7)
IF (test[0]) THEN yname = def_yname[0] ELSE yname = yname[0]
;;  Check SM_CUTS and SM_CONT
test           = KEYWORD_SET(sm_cuts) AND (N_ELEMENTS(sm_cuts) GT 0)
IF (test[0]) THEN sm_cuts = 1b ELSE sm_cuts = def_sm_cuts[0]
test           = KEYWORD_SET(sm_cont) AND (N_ELEMENTS(sm_cont) GT 0)
IF (test[0]) THEN sm_cont = 1b ELSE sm_cont = def_sm_cuts[0]
;;  Check NSMCUT and NSMCON
test           = (is_a_number(nsmcut,/NOMSSG) EQ 0)
IF (test[0]) THEN nsmcut = def_nsmcut[0] ELSE nsmcut = LONG(ABS(nsmcut[0]))
test           = (is_a_number(nsmcon,/NOMSSG) EQ 0)
IF (test[0]) THEN nsmcon = def_nsmcon[0] ELSE nsmcon = LONG(ABS(nsmcon[0]))
;;  Check PLANE
test           = (SIZE(plane,/TYPE) NE 7)
IF (test[0]) THEN plane = def_plane[0] ELSE plane = STRLOWCASE(plane[0])
test           = (TOTAL(plane[0] EQ all_planes) LT 1)
IF (test[0]) THEN plane = def_plane[0]
;;  Check for DFMIN, DFMAX, and DFRA
tests          = [is_a_number(dfmin,/NOMSSG),is_a_number(dfmax,/NOMSSG),$
                  (is_a_number(dfra,/NOMSSG) AND (N_ELEMENTS(dfra) GE 2))]
;;  Check DFMIN and DFMAX
test           = (is_a_number(dfmin,/NOMSSG) EQ 0)
IF (test[0]) THEN dfmin = def_dfnx[0] ELSE dfmin = ABS(dfmin[0])
test           = (is_a_number(dfmax,/NOMSSG) EQ 0)
IF (test[0]) THEN dfmax = def_dfnx[1] ELSE dfmax = ABS(dfmax[0])
;;  Check DFRA
test           = (is_a_number(dfra,/NOMSSG) EQ 0) OR (N_ELEMENTS(dfra) LT 2)
IF (test[0]) THEN dfra = def_dfra ELSE dfra = ABS(dfra)
test           = (test_plot_axis_range(dfra,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  dfra     = def_dfra
  tests[2] = 0b    ;;  shut off user defined DFRA
ENDIF
;;  Now let user-defined keyword(s), if present, trump default values
IF (tests[2]) THEN BEGIN
  ;;  User correctly set DFRA --> redefine DFMIN and DFMAX
  dfmin = 0.95*dfra[0]
  dfmax = 1.05*dfra[1]
ENDIF ELSE BEGIN
  ;;  Check if user set DFMIN or DFMAX
  IF (tests[0]) THEN BEGIN
    ;;  User correctly set DFMIN --> redefine DFRA[0]
    dfra[0] = dfmin[0]
  ENDIF
  IF (tests[1]) THEN BEGIN
    ;;  User correctly set DFMAX --> redefine DFRA[1]
    dfra[1] = dfmax[0]
  ENDIF
ENDELSE
;;  Check V_0X and V_0Y
test           = (is_a_number(v_0x,/NOMSSG) EQ 0)
IF (test[0]) THEN v_0x = def_vox[0] ELSE v_0x = v_0x[0]
test           = (is_a_number(v_0y,/NOMSSG) EQ 0)
IF (test[0]) THEN v_0y = def_voy[0] ELSE v_0y = v_0y[0]
;;----------------------------------------------------------------------------------------
;;  Now make sure user hasn't set "dumb" values (i.e., make sure data falls within ranges)
;;----------------------------------------------------------------------------------------
test_dfra      = (TOTAL(vdf GE dfra[0] AND vdf LE dfra[1]) LT 10)
test_vvra      = (TOTAL(vmag GE 0d0 AND vmag LE vlim[0]) LT 10)
IF (test_dfra[0]) THEN BEGIN
  ;;  User set "bad" DFRA --> redefine DFMIN, DFMAX, and DFRA to defaults
  dfra  = def_dfra
  dfmin = 0.95*dfra[0]
  dfmax = 1.05*dfra[1]
  tests = REPLICATE(0b,3L)
ENDIF
IF (test_vvra[0]) THEN BEGIN
  ;;  User set "bad" VLIM --> redefine VLIM to default
  vlim  = def_vlim[0]
ENDIF
;;  Make sure V_0X and V_0Y are not outside 80% of VLIM
test           = (ABS(v_0x[0]) GE 8d-1*vlim[0])
IF (test[0]) THEN v_0x = def_vox[0]
test           = (ABS(v_0y[0]) GE 8d-1*vlim[0])
IF (test[0]) THEN v_0y = def_voy[0]
;;----------------------------------------------------------------------------------------
;;  Redefine input for output
;;----------------------------------------------------------------------------------------
vdf            = REFORM(TEMPORARY(vdf))
velxyz         = vxyz
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,tests
END


;+
;*****************************************************************************************
;
;  PROCEDURE:   general_vdf_contour_plot.pro
;  PURPOSE  :   This is a generalized plotting routine for velocity distribution
;                 functions (VDFs) observed by spacecraft.  It is generalized because
;                 it only requests the phase space density and corresponding velocity
;                 3-vectors on input and does not depend upon any routines specific
;                 to any instrument.  It is a specified routine because it is only
;                 meant for particle VDFs.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               defaults_vdf_contour_plot.pro
;
;  CALLS:
;               is_a_number.pro
;               is_a_3_vector.pro
;               mag__vec.pro
;               test_plot_axis_range.pro
;               defaults_vdf_contour_plot.pro
;               rot_matrix_array_dfs.pro
;               rel_lorentz_trans_3vec.pro
;               rotate_and_triangulate_dfs.pro
;               find_1d_cuts_2d_dist.pro
;               format_vector_string.pro
;               log10_tickmarks.pro
;               routine_version.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               VDF      :  [N]-Element [float/double] array defining particle velocity
;                             distribution function (VDF) in units of phase space density
;                             [e.g., # s^(+3) km^(-3) cm^(-3)]
;               VELXYZ   :  [N,3]-Element [float/double] array defining the particle
;                             velocity 3-vectors for each element of VDF
;
;  EXAMPLES:    
;               [calling sequence]
;               general_vdf_contour_plot, vdf, velxyz [,VFRAME=vframe] [,VEC1=vec1]      $
;                                      [,VEC2=vec2] [,VLIM=vlim] [,NLEV=nlev]            $
;                                      [,XNAME=xname] [,YNAME=yname] [,SM_CUTS=sm_cuts]  $
;                                      [,SM_CONT=sm_cont] [,NSMCUT=nsmcut]               $
;                                      [,NSMCON=nsmcon] [,PLANE=plane] [,DFMIN=dfmin]    $
;                                      [,DFMAX=dfmax] [,DFRA=dfra] [,V_0X=v_0x]          $
;                                      [,V_0Y=v_0y] [,C_LOG=c_log] [,NGRID=ngrid]        $
;                                      [,SLICE2D=slice2d] [,CIRCS=circs]                 $
;                                      [,EX_VECS=ex_vecs] [,EX_INFO=ex_info]
;
;  KEYWORDS:    
;               ***  INPUTS  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  [all of the following have default settings]  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               VFRAME   :  [3]-Element [float/double] array defining the 3-vector
;                             velocity of the K'-frame relative to the K-frame [km/s]
;                             to use to transform the velocity distribution into the
;                             bulk flow reference frame
;                             [ Default = [10,0,0] ]
;               VEC1     :  [3]-Element vector to be used for "parallel" direction in
;                             a 3D rotation of the input data
;                             [e.g. see rotate_3dp_structure.pro]
;                             [ Default = [1.,0.,0.] ]
;               VEC2     :  [3]--Element vector to be used with VEC1 to define a 3D
;                             rotation matrix.  The new basis will have the following:
;                               X'  :  parallel to VEC1
;                               Z'  :  parallel to (VEC1 x VEC2)
;                               Y'  :  completes the right-handed set
;                             [ Default = [0.,1.,0.] ]
;               VLIM     :  Scalar [numeric] defining the velocity [km/s] limit for x-y
;                             velocity axes over which to plot data
;                             [Default = [-1,1]*MAX(ABS(VELXYZ))]
;               NLEV     :  Scalar [numeric] defining the # of contour levels to plot
;                             [Default = 30L]
;               XNAME    :  Scalar [string] defining the name of vector associated with
;                             the VEC1 input
;                             [Default = 'X']
;               YNAME    :  Scalar [string] defining the name of vector associated with
;                             the VEC2 input
;                             [Default = 'Y']
;               SM_CUTS  :  If set, program smoothes the cuts of the VDF before plotting
;                             [Default = FALSE]
;               SM_CONT  :  If set, program smoothes the contours of the VDF before
;                             plotting
;                             [Default = FALSE]
;               NSMCUT   :  Scalar [numeric] defining the # of points over which to
;                             smooth the 1D cuts of the VDF before plotting
;                             [Default = 3]
;               NSMCON   :  Scalar [numeric] defining the # of points over which to
;                             smooth the 2D contour of the VDF before plotting
;                             [Default = 3]
;               PLANE    :  Scalar [string] defining the plane projection to plot with
;                             corresponding cuts [Let V1 = VEC1, V2 = VEC2]
;                               'xy'  :  horizontal axis parallel to V1 and normal
;                                          vector to plane defined by (V1 x V2)
;                                          [default]
;                               'xz'  :  horizontal axis parallel to (V1 x V2) and
;                                          vertical axis parallel to V1
;                               'yz'  :  horizontal axis defined by (V1 x V2) x V1
;                                          and vertical axis (V1 x V2)
;                             [Default = 'xy']
;               DFMIN    :  Scalar [numeric] defining the minimum allowable phase space
;                             density to plot, which is useful for ion distributions with
;                             large angular gaps in data (prevents lower bound from
;                             falling below DFMIN)
;                             [Default = 1d-20]
;               DFMAX    :  Scalar [numeric] defining the maximum allowable phase space
;                             density to plot, which is useful for distributions with
;                             data spikes (prevents upper bound from exceeding DFMAX)
;                             [Default = 1d-2]
;               DFRA     :  [2]-Element [numeric] array specifying the VDF range in phase
;                             space density [e.g., # s^(+3) km^(-3) cm^(-3)] for the
;                             cuts and contour plots
;                             [Default = [MIN(VDF),MAX(VDF)]]
;               V_0X     :  Scalar [float/double] defining the velocity [km/s] along the
;                             X-Axis (horizontal) to shift the location where the
;                             perpendicular (vertical) cut of the DF will be performed
;                             [Default = 0.0]
;               V_0Y     :  Scalar [float/double] defining the velocity [km/s] along the
;                             Y-Axis (vertical) to shift the location where the
;                             parallel (horizontal) cut of the DF will be performed
;                             [Default = 0.0]
;               C_LOG    :  If set, routine will compute and plot VDF in logarithmic
;                             instead of linear space (good for sparse data)
;                             ***  Still Testing this keyword  ***
;                             [Default = FALSE]
;               NGRID    :  Scalar [numeric] defining the number of grid points in each
;                             direction to use when triangulating the data.  The input
;                             will be limited to values between 30 and 300.
;                             [Default = 101]
;               SLICE2D  :  If set, routine will return a 2D slice instead of a 3D
;                             projection
;                             [Default = FALSE]
;               P_LOG    :  If set, routine will compute the VDF in linear space but
;                             plot the base-10 log of the VDF.  If set, this keyword
;                             supercedes the C_LOG keyword and shuts it off to avoid
;                             infinite plot range errors, among other issues
;                             [Default = FALSE]
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  [none of the following have default settings]  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               CIRCS    :  [C]-Element [structure] array containing the center
;                             locations and radii of circles the user wishes to
;                             project onto the contour and cut plots, each with
;                             the following format:
;                               VRAD  :  Scalar defining the velocity radius of the
;                                          circle to project centered at {VOX,VOY}
;                               VOX   :  Scalar defining the velocity offset along
;                                          X-Axis [Default = 0.0]
;                               VOY   :  Scalar defining the velocity offset along
;                                          Y-Axis [Default = 0.0]
;               EX_VECS  :  [V]-Element [structure] array containing extra vectors the
;                             user wishes to project onto the contour, each with
;                             the following format:
;                               VEC   :  [3]-Element [numeric] array of 3-vectors in the
;                                          same coordinate system as VELXYZ to be
;                                          projected onto the contour plot
;                                          [e.g. VEC[0] = along X-Axis]
;                               NAME  :  Scalar [string] used as a name for each VEC
;                                          to output onto the contour plot
;                                          [Default = 'Vec_j', j = index of EX_VECS]
;               EX_INFO  :  Scalar [structure] containing information relevant to the
;                             VDF with the following format [*** units matter here ***]:
;                               SCPOT  :  Scalar [numeric] defining the spacecraft
;                                           electrostatic potential [eV] at the time of
;                                           the VDF
;                               VSW    :  [3]-Element [numeric] array defining to the
;                                           bulk flow velocity [km/s] 3-vector at the
;                                           time of the VDF
;                               MAGF   :  [3]-Element [numeric] array defining to the
;                                           quasi-static magnetic field [nT] 3-vector at
;                                           the time of the VDF
;
;   CHANGED:  1)  Fixed a bug that occurs when VDF input contains zeros
;                                                                  [05/16/2016   v1.0.1]
;             2)  Fixed a bug that occurs when user sets the EX_INFO keyword
;                                                                  [05/17/2016   v1.0.2]
;             3)  Added keyword: C_LOG
;                                                                  [05/26/2017   v1.0.3]
;             4)  Cleaned up
;                                                                  [05/26/2017   v1.0.4]
;             5)  Added keywords: SLICE2D and NGRID
;                                                                  [05/27/2017   v1.1.0]
;             6)  Added keyword: P_LOG
;                                                                  [05/30/2017   v1.1.1]
;
;   NOTES:      
;               1)  Setting DFRA trumps any values set in DFMIN and DFMAX
;               2)  All inputs will be altered on output
;               3)  All keywords will be altered on output
;               4)  There are checks to make sure user's settings cannot produce useless
;                     plots, e.g., V_0X and V_0Y cannot fall outside 80% of VLIM
;               5)  There must be at least 10 finite VDF values with associated finite
;                     VELXYZ vector magnitudes and those ≥10 VDF values must be unique
;               6)  Velocity and VDF units should be 'km/s' and 's^(3) cm^(-3) km^(-3)'
;                     on input since output results and axes labels assume this
;               7)  If set, P_LOG will supercede the C_LOG keyword settings
;
;  REFERENCES:  
;               NA
;
;   CREATED:  04/07/2016
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  05/30/2017   v1.1.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO general_vdf_contour_plot,vdf,velxyz,VFRAME=vframe,VEC1=vec1,VEC2=vec2,VLIM=vlim,  $
                             NLEV=nlev,XNAME=xname,YNAME=yname,SM_CUTS=sm_cuts,       $
                             SM_CONT=sm_cont,NSMCUT=nsmcut,NSMCON=nsmcon,PLANE=plane, $
                             DFMIN=dfmin,DFMAX=dfmax,DFRA=dfra,V_0X=v_0x,V_0Y=v_0y,   $
                             C_LOG=c_log,NGRID=ngrid,SLICE2D=slice2d,P_LOG=p_log,     $
                             CIRCS=circs,EX_VECS=ex_vecs,EX_INFO=ex_info

FORWARD_FUNCTION is_a_number, is_a_3_vector, mag__vec, test_plot_axis_range,              $
                 defaults_vdf_contour_plot, rot_matrix_array_dfs, rel_lorentz_trans_3vec, $
                 rotate_and_triangulate_dfs, find_1d_cuts_2d_dist, format_vector_string,  $
                 log10_tickmarks, routine_version
;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
vec_str        = ['x','y','z']
vec_col        = [250,150,50]
;;  Dummy plot labels
def_units_vdf  = '[sec!U3!N km!U-3!N cm!U-3!N'+']'
def_cut_yttl   = '1D VDF Cuts'+'!C'+def_units_vdf[0]
def_cut_xttl   = 'Velocity [1000 km/sec]'
;;  Position of contour plot [square]
;;               Xo    Yo    X1    Y1
pos_0con       = [0.22941,0.515,0.77059,0.915]
;;  Position of 1st DF cuts [square]
pos_0cut       = [0.22941,0.050,0.77059,0.450]
;;  Dummy error messages
no_inpt_msg    = 'User must supply a VDF and a corresponding array of 3-vector velocities...'
badvfor_msg    = 'Incorrect input format:  VDF and VELXYZ must have the same size first dimensions...'
nofinite_mssg  = 'Not enough finite and unique data was supplied...'
;;  Defined user symbol for outputing locations of data on contour
xxo            = FINDGEN(17)*(!PI*2./16.)
USERSYM,0.27*COS(xxo),0.27*SIN(xxo),/FILL
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 2) OR (is_a_number(vdf,/NOMSSG) EQ 0) OR  $
                 (is_a_3_vector(velxyz,V_OUT=vxyz,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  ;;  Incorrect inputs --> exit without plotting
  MESSAGE,no_inpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
df1d           = REFORM(vdf)
szdvdf         = SIZE(df1d,/DIMENSIONS)
szdvel         = SIZE(vxyz,/DIMENSIONS)
test           = (szdvdf[0] NE szdvel[0]) OR (szdvdf[0] LT 10)
IF (test[0]) THEN BEGIN
  ;;  Incorrect input format --> exit without plotting
  MESSAGE,badvfor_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;  Now that we know these are at least formatted correct, test values
vmag           = mag__vec(vxyz,/NAN)
test           = (TOTAL(FINITE(df1d)) LT 10) OR (TOTAL(FINITE(vmag)) LT 10)
IF (test[0]) THEN BEGIN
  ;;  VDF or VELXYZ have fewer than 10 finite points --> exit without plotting
  MESSAGE,'0: '+nofinite_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;  Make sure values are unique and have a finite range
def_dfra       = [MIN(ABS(df1d),/NAN),MAX(ABS(df1d),/NAN)]
test           = (test_plot_axis_range(def_dfra,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  ;;  VDF is either all one value or has no finite values --> exit without plotting
  MESSAGE,'1: '+nofinite_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check keywords with default options
;;----------------------------------------------------------------------------------------
tests          = defaults_vdf_contour_plot(df1d,vxyz,VFRAME=vframe,VEC1=vec1,VEC2=vec2,  $
                                           VLIM=vlim,NLEV=nlev,XNAME=xname,YNAME=yname,  $
                                           SM_CUTS=sm_cuts,SM_CONT=sm_cont,NSMCUT=nsmcut,$
                                           NSMCON=nsmcon,PLANE=plane,DFMIN=dfmin,        $
                                           DFMAX=dfmax,DFRA=dfra,V_0X=v_0x,V_0Y=v_0y)
test           = (N_ELEMENTS(tests) EQ 1)
IF (test[0]) THEN RETURN      ;;  Something failed --> exit without plotting
;;  Check P_LOG
test           = (N_ELEMENTS(p_log) EQ 1) AND KEYWORD_SET(p_log)
IF (test[0]) THEN plog_on = 1b ELSE plog_on = 0b
;;  Check C_LOG
test           = (N_ELEMENTS(c_log) GE 1) AND KEYWORD_SET(c_log) AND ~plog_on[0]
IF (test[0]) THEN BEGIN
  ;;  User wants to plot in log-space, not linear space
  df1do   = ALOG10(df1d)
  dfrao   = ALOG10(dfra)
  clog_on = 1b
  plog_on = 1b           ;;  Turn on logarithmic plotting
ENDIF ELSE BEGIN
  df1do   = df1d
  dfrao   = dfra
  clog_on = 0b
ENDELSE
;;  Check NGRID
test           = (N_ELEMENTS(ngrid) EQ 0) OR (is_a_number(ngrid,/NOMSSG) EQ 0)
IF (test[0]) THEN nm = 101L ELSE nm = (LONG(ngrid[0]) > 30L) < 300L
;;  Check SLICE2D
test           = (N_ELEMENTS(slice2d) EQ 1) AND KEYWORD_SET(slice2d)
IF (test[0]) THEN slice_on = 1b ELSE slice_on = 0b
;;----------------------------------------------------------------------------------------
;;  Check keywords without default options
;;----------------------------------------------------------------------------------------
;;  Check CIRCS
test           = (SIZE(circs,/TYPE) EQ 8)
IF (test[0]) THEN BEGIN
  ;;  Check structure format
  def_tags       = ['vrad','vox','voy']
  tags           = STRLOWCASE(TAG_NAMES(circs))
  nmatch         = 0
  FOR j=0L, 2L DO nmatch += TOTAL(def_tags[j] EQ tags)
  IF (nmatch[0] EQ 3) THEN BEGIN
    ;;  User set correct tags --> check value formats
    test       = is_a_number(circs[0].(0),/NOMSSG) AND is_a_number(circs[0].(1),/NOMSSG) $
                 AND is_a_number(circs[0].(2),/NOMSSG)
    IF (test[0]) THEN circle_str = circs  ;;  correct format --> define new structure(s)
  ENDIF
ENDIF
;;  Check EX_VECS
test           = (SIZE(ex_vecs,/TYPE) EQ 8)
IF (test[0]) THEN BEGIN
  ;;  Check structure format
  def_tags       = ['vec','name']
  tags           = STRLOWCASE(TAG_NAMES(ex_vecs))
  nmatch         = 0
  FOR j=0L, 1L DO nmatch += TOTAL(def_tags[j] EQ tags)
  IF (nmatch[0] EQ 2) THEN BEGIN
    ;;  User set correct tags --> check value formats
    test       = is_a_3_vector(ex_vecs[0].(0),/NOMSSG) AND (SIZE(ex_vecs[0].(1),/TYPE) EQ 7)
    IF (test[0]) THEN exvec_str = ex_vecs  ;;  correct format --> define new structure(s)
  ENDIF
ENDIF
;;  Check EX_INFO
test           = (SIZE(ex_info,/TYPE) EQ 8)
IF (test[0]) THEN BEGIN
  ;;  Check structure format
  def_tags       = ['scpot','vsw','magf']
  tags           = STRLOWCASE(TAG_NAMES(ex_info))
  nmatch         = 0
  FOR j=0L, 2L DO nmatch += TOTAL(def_tags[j] EQ tags)
  IF (nmatch[0] EQ 3) THEN BEGIN
    ;;  User set correct tags --> check value formats
    test       =   is_a_number(ex_info[0].(0),/NOMSSG) AND $
                 is_a_3_vector(ex_info[0].(1),/NOMSSG) AND $
                 is_a_3_vector(ex_info[0].(2),/NOMSSG)
    IF (test[0]) THEN tran_info = ex_info  ;;  correct format --> define new structure(s)
  ENDIF
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define rotation matrices
;;----------------------------------------------------------------------------------------
kk             = N_ELEMENTS(df1do)                      ;;  # of phase space density values
;;  Expand to make [K,3]-element arrays
v1             = REPLICATE(1d0,kk[0]) # vec1           ;; [K,3]-Element array
v2             = REPLICATE(1d0,kk[0]) # vec2           ;; [K,3]-Element array
;;  Define rotation matrices equivalent to cal_rot.pro
;;    CAL_ROT = TRUE  --> Primed unit basis vectors are given by:
;;           X'  :  V1
;;           Z'  :  (V1 x V2)       = (X x V2)
;;           Y'  :  (V1 x V2) x V1  = (Z x X)
rotm           = rot_matrix_array_dfs(v1,v2,/CAL_ROT)  ;;  [K,3,3]-element array
;;  Define rotation matrices equivalent to rot_mat.pro
;;    CAL_ROT = FALSE  --> Primed unit basis vectors are given by:
;;           Z'  :  V1
;;           Y'  :  (V1 x V2)       = (Z x V2)
;;           X'  :  (V1 x V2) x V1  = (Y x Z)
rotz           = rot_matrix_array_dfs(v1,v2)           ;;  [K,3,3]-element array
;;----------------------------------------------------------------------------------------
;;  Transform VDF into VFRAME
;;----------------------------------------------------------------------------------------
vtrxyz         = rel_lorentz_trans_3vec(vxyz,vframe)
;;----------------------------------------------------------------------------------------
;;  Rotate velocities and VDF into new coordinate basis and triangulate
;;----------------------------------------------------------------------------------------
;r_vels         = rotate_and_triangulate_dfs(FLOAT(vtrxyz),df1do,rotm,rotz,VLIM=vlim[0],C_LOG=clog_on)
r_vels         = rotate_and_triangulate_dfs(FLOAT(vtrxyz),df1do,rotm,rotz,VLIM=vlim[0],$
                                            C_LOG=clog_on[0],NGRID=nm[0],              $
                                            SLICE2D=slice_on[0]                        )
;;----------------------------------------------------------------------------------------
;;  Define parameters for contour plots
;;----------------------------------------------------------------------------------------
def_con_xttl   = '(V dot '+xname[0]+') [1000 km/s]'
def_con_yttl   = '('+xname[0]+' x '+yname[0]+') x '+xname[0]+' [1000 km/s]'
def_con_zttl   = '('+xname[0]+' x '+yname[0]+') [1000 km/s]'
;;  Define regularly gridded velocities (for contour plots) [km/s]
;;    [Note:  These should equal the outputs of str_??.V?_GRID_?? below]
vx2d           = r_vels.VX2D
vy2d           = r_vels.VY2D
nnct           = N_ELEMENTS(vx2d)
CASE plane[0] OF
  'xy'  : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  plot Y vs. X
    ;;------------------------------------------------------------------------------------
    ;;  Define rotation matrix
    rmat     = REFORM(rotm[0,*,*])
    ;;  Define contour axis titles
    con_xttl = def_con_xttl[0]
    con_yttl = def_con_yttl[0]
    ;;  Define data projection
    df2d     = r_vels.PLANE_XY.DF2D_XY
    ;;  Define actual velocities for contour plot
    vxpts    = r_vels.PLANE_XY.VELX_XY
    vypts    = r_vels.PLANE_XY.VELY_XY
    vzpts    = r_vels.PLANE_XY.VELZ_XY
    ;;  Define elements [x,y]
    gels     = [0L,1L]
  END
  'xz'  : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  plot X vs. Z
    ;;------------------------------------------------------------------------------------
    ;;  Define rotation matrix
    rmat     = REFORM(rotm[0,*,*])
    ;;  Define contour axis titles
    con_xttl = def_con_zttl[0]
    con_yttl = def_con_xttl[0]
    ;;  Define data projection
    df2d     = r_vels.PLANE_XZ.DF2D_XZ
    ;;  define actual velocities for contour plot
    vxpts    = r_vels.PLANE_XZ.VELX_XZ
    vypts    = r_vels.PLANE_XZ.VELY_XZ
    vzpts    = r_vels.PLANE_XZ.VELZ_XZ
    ;;  Define elements [x,y]
    gels     = [2L,0L]
  END
  'yz'  : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  plot Z vs. Y
    ;;------------------------------------------------------------------------------------
    ;;  Define rotation matrix
    rmat     = REFORM(rotz[0,*,*])
    ;;  Define contour axis titles
    con_xttl = def_con_yttl[0]
    con_yttl = def_con_zttl[0]
    ;;  Define data projection
    df2d     = r_vels.PLANE_YZ.DF2D_YZ
    ;;  define actual velocities for contour plot
    vxpts    = r_vels.PLANE_YZ.VELX_YZ
    vypts    = r_vels.PLANE_YZ.VELY_YZ
    vzpts    = r_vels.PLANE_YZ.VELZ_YZ
    ;;  define elements [x,y]
    gels     = [0L,1L]
  END
  ELSE  : BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  use default:  Y vs. X
    ;;------------------------------------------------------------------------------------
    ;;  Define rotation matrix
    rmat     = REFORM(rotm[0,*,*])
    ;;  Define contour axis titles
    con_xttl = xaxist
    con_yttl = yaxist
    ;;  Define data projection
    df2d     = r_vels.PLANE_XY.DF2D_XY
    ;;  Define actual velocities for contour plot
    vxpts    = r_vels.PLANE_XY.VELX_XY
    vypts    = r_vels.PLANE_XY.VELY_XY
    vzpts    = r_vels.PLANE_XY.VELZ_XY
    ;;  Define elements [x,y]
    gels     = [0L,1L]
  END
ENDCASE
;;----------------------------------------------------------------------------------------
;;  Define cut through f(x,y) at offset {V_0X, V_0Y}
;;----------------------------------------------------------------------------------------
cuts_struc     = find_1d_cuts_2d_dist(df2d,vx2d,vy2d,X_0=v_0x,Y_0=v_0y)
vdf_para_cut   = cuts_struc.X_1D_FXY
vdf_perp_cut   = cuts_struc.Y_1D_FXY
vpara_cut      = cuts_struc.X_CUT_COORD*1d-3   ;;  km --> Mm  (looks better when plotted)
vperp_cut      = cuts_struc.Y_CUT_COORD*1d-3   ;;  km --> Mm  (looks better when plotted)
hori_crsshair  = cuts_struc.X_XY_COORD*1d-3    ;;  [K,2]-Element array, VAL[*,0] = X, VAL[*,1] = Y
vert_crsshair  = cuts_struc.Y_XY_COORD*1d-3
hori_offset    = v_0x[0]*1d-3                  ;;  horizontal offset of crosshairs
vert_offset    = v_0y[0]*1d-3                  ;;  vertical offset of crosshairs
;;----------------------------------------------------------------------------------------
;;  Define the 2D projection of the extra vectors in EX_VECS
;;----------------------------------------------------------------------------------------
exvec_on       = (SIZE(exvec_str,/TYPE) EQ 8)
IF (exvec_on[0]) THEN BEGIN
  n_exvec   = N_ELEMENTS(exvec_str)
  dumb      = {VEC:REPLICATE(d,3L),NAME:''}
  exvec_rot = REPLICATE(dumb[0],n_exvec[0])
  vec_cols  = LINDGEN(n_exvec[0])*(250L - 30L)/(n_exvec[0] - 1L) + 30L
  FOR j=0L, n_exvec[0] - 1L DO BEGIN
    tvec   = exvec_str[j].VEC
    tnam   = exvec_str[j].NAME
    ;;  Normalize vector first
    uvec   = REFORM(unit_vec(tvec))
    ;;  Rotate
    rvec   = REFORM(rmat ## uvec)
    ;;  Normalize to in-plane values only
    uv2d   = rvec[gels]/SQRT(TOTAL(rvec[gels]^2,/NAN))
    ;;  Scale to plot output
    v_mfac = (vlim[0]*95d-2)*1d-3        ;;  km --> Mm  (looks better when plotted)
    vscld  = uv2d*v_mfac[0]
    ;;  Fill j-th structure
    exvec_rot[j].VEC  = vscld
    exvec_rot[j].NAME = tnam[0]
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Re-scale values in CIRCS
;;----------------------------------------------------------------------------------------
circs_on       = (SIZE(circle_str,/TYPE) EQ 8)
IF (circs_on[0]) THEN BEGIN
  ;;  User wants to overplot circles of constant energy
  n_circs    = N_ELEMENTS(circle_str)
  nn         = 100L
  thetas     = DINDGEN(nn[0])*2d0*!DPI/(nn[0] - 1L)
  vc_lx      = DBLARR(n_circs[0])             ;;  Min. X-Location of circle in cut plot
  vc_xx      = DBLARR(n_circs[0])             ;;  Max. X-Location of circle in cut plot
  vc_x       = DBLARR(nn[0],n_circs[0])       ;;  X-Component of circles
  vc_y       = DBLARR(nn[0],n_circs[0])       ;;  Y-Component of circles
  FOR j=0L, n_circs[0] - 1L DO BEGIN
    trad      = circle_str[j].VRAD*1d-3       ;;  km --> Mm  (looks better when plotted)
    tvox      = circle_str[j].VOX*1d-3        ;;  km --> Mm  (looks better when plotted)
    tvoy      = circle_str[j].VOY*1d-3        ;;  km --> Mm  (looks better when plotted)
    ;;  Fill j-th arrays
    vc_x[*,j] = trad[0]*COS(thetas) + tvox[0]
    vc_y[*,j] = trad[0]*SIN(thetas) + tvoy[0]
    vc_lx[j]  = MIN(vc_x[*,j],/NAN)
    vc_xx[j]  = MAX(vc_x[*,j],/NAN)
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Format EX_INFO output
;;----------------------------------------------------------------------------------------
tran_on        = (SIZE(tran_info,/TYPE) EQ 8)
IF (tran_on[0]) THEN BEGIN
  ;;  Define string for spacecraft potential output
  scpot          = STRTRIM(STRING(FORMAT='(f10.2)',tran_info[0].SCPOT),2)
  plus           = STRMID(scpot[0],0L,1L) NE '-'
  IF (plus) THEN scpot = '+'+scpot[0]
  sc_pot_str     = 'SC Pot.  :  '+scpot[0]+' [eV]'
  ;;  Define string for bulk flow velocity and quasi-static magnetic field outputs
  vbulk          = format_vector_string(tran_info[0].VSW,PREC=2)+' [km/s]'
  magf           = format_vector_string(tran_info[0].MAGF,PREC=2)+' [nT]'
  v__out_str     = 'Vbulk    :  '+vbulk[0]
  b__out_str     = 'Bo       :  '+magf[0]
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define contour levels
;;----------------------------------------------------------------------------------------
df_ran         = dfrao
IF (clog_on[0]) THEN range = df_ran ELSE range = ALOG10(df_ran) ;;  Make levels evenly spaced in log base-10 space
log10levs      = DINDGEN(nlev[0])*(range[1] - range[0])/(nlev[0] - 1L) + range[0]
IF (plog_on[0]) THEN levels = log10levs ELSE levels = 1d1^log10levs ;;  contour level values in phase space density [e.g., s^(+3) cm^(-3) km^(-3)]
;IF (clog_on[0]) THEN levels = log10levs ELSE levels = 1d1^log10levs ;;  contour level values in phase space density [e.g., s^(+3) cm^(-3) km^(-3)]
;;  Define colors for contour levels
minclr         = 30L
c_cols         = minclr[0] + LINDGEN(nlev[0])*(250L - minclr[0])/(nlev[0] - 1L)
;;  Define inputs for log10_tickmarks.pro
IF (clog_on[0]) THEN BEGIN
  df2d01 = REFORM(1d1^df2d,N_ELEMENTS(df2d))
  yrange = 1d1^df_ran
ENDIF ELSE BEGIN
  df2d01 = df2d
  yrange = df_ran
ENDELSE
;;  Define Y-axis tick marks for cuts plot
tick_str       = log10_tickmarks(df2d01,RANGE=yrange,/FORCE_RA)
IF (plog_on[0]) THEN BEGIN
;IF (clog_on[0]) THEN BEGIN
;  df2d01         = REFORM(1d1^df2d,N_ELEMENTS(df2d))
  ylog_cut       = 0b
  ymin_cut       = 10
ENDIF ELSE BEGIN
  ylog_cut       = 1b
  ymin_cut       = 9
ENDELSE
;;  Define the tick names, values, and number of ticks
cut_ytn        = tick_str.TICKNAME
cut_yts        = tick_str.TICKS
IF (plog_on[0]) THEN cut_ytv = ALOG10(tick_str.TICKV) ELSE cut_ytv = tick_str.TICKV
;IF (clog_on[0]) THEN cut_ytv = ALOG10(tick_str.TICKV) ELSE cut_ytv = tick_str.TICKV
;;----------------------------------------------------------------------------------------
;;  Smooth cuts and contour if desired [typically necessary for ions or noisy data]
;;----------------------------------------------------------------------------------------
test           = KEYWORD_SET(sm_cuts)
IF (test[0]) THEN BEGIN
  ;;  Smooth cuts
  vdf_cut_para0  = SMOOTH(vdf_para_cut,nsmcut[0],/NAN,/EDGE_TRUNCATE)
  vdf_cut_perp0  = SMOOTH(vdf_perp_cut,nsmcut[0],/NAN,/EDGE_TRUNCATE)
ENDIF ELSE BEGIN
  vdf_cut_para0  = vdf_para_cut
  vdf_cut_perp0  = vdf_perp_cut
ENDELSE
test           = KEYWORD_SET(sm_cont)
IF (test[0]) THEN BEGIN
  ;;  Smooth contour
  df2ds0 = SMOOTH(df2d,nsmcon[0],/NAN,/EDGE_TRUNCATE)
ENDIF ELSE BEGIN
  df2ds0 = df2d
ENDELSE
;;  Check if user wants to plot in logarithmic space but computed everything linearly
test           = plog_on[0] AND ~clog_on[0]
IF (test[0]) THEN BEGIN
  df2ds          = ALOG10(df2ds0)
  vdf_cut_para   = ALOG10(vdf_cut_para0)
  vdf_cut_perp   = ALOG10(vdf_cut_perp0)
  cut_yrange     = ALOG10(df_ran)
ENDIF ELSE BEGIN
  df2ds          = df2ds0
  vdf_cut_para   = vdf_cut_para0
  vdf_cut_perp   = vdf_cut_perp0
  cut_yrange     = df_ran
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Define plot limits structures for contour and cuts plots
;;----------------------------------------------------------------------------------------
con_xyran      = [-1d0,1d0]*vlim[0]*1d-3     ;;  km  -->  Mm  [just looks better when plotted]
con_pttl       = 'Contours of constant PSD'  ;;  *** change later ***
;;  Contour plot setup structure
base_lim_cn    = {XRANGE:con_xyran,XSTYLE:1,XLOG:0,XMINOR:10, $
                  YRANGE:con_xyran,YSTYLE:1,YLOG:0,YMINOR:10, $
                  XTITLE:con_xttl[0],YTITLE:con_yttl[0],      $
                  POSITION:pos_0con,TITLE:con_pttl[0],NODATA:1}
;;  Structures for CONTOUR.PRO
con_lim        = {OVERPLOT:1,LEVELS:levels,NLEVELS:nlev[0],C_COLORS:c_cols}      ;;  should be the same for all planes
;;  Define cut plot setup structures
base_lim_ct    = {XRANGE:con_xyran, XSTYLE:1,XLOG:0,          XTITLE:def_cut_xttl[0],XMINOR:10,           $
                  YRANGE:cut_yrange,YSTYLE:1,YLOG:ylog_cut[0],YTITLE:def_cut_yttl[0],YMINOR:ymin_cut[0],  $
                  POSITION:pos_0cut,TITLE:' ',NODATA:1,YTICKS:cut_yts[0],                                $
                  YTICKV:cut_ytv,YTICKNAME:cut_ytn}
;base_lim_ct    = {XRANGE:con_xyran,XSTYLE:1,XLOG:0,          XTITLE:def_cut_xttl[0],XMINOR:10,           $
;                  YRANGE:df_ran,   YSTYLE:1,YLOG:ylog_cut[0],YTITLE:def_cut_yttl[0],YMINOR:ymin_cut[0],  $
;                  POSITION:pos_0cut,TITLE:' ',NODATA:1,YTICKS:cut_yts[0],                                $
;                  YTICKV:cut_ytv,YTICKNAME:cut_ytn}
;;  Define routine version
IF (slice_on[0]) THEN vers_suffx = ';;  2D Slice' ELSE vers_suffx = ';;  3D Projection'
vers           = routine_version('general_vdf_contour_plot.pro')+vers_suffx[0]
;;  Set up plot stuff
!P.MULTI       = [0,1,2]
IF (STRLOWCASE(!D.NAME) EQ 'ps') THEN l_thick  = 3 ELSE l_thick  = 2
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Plot Contour
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Set up plot area for contour
PLOT,[0.0,1.0],[0.0,1.0],_EXTRA=base_lim_cn
  ;;  Output actual locations of data in plane
  OPLOT,vxpts*1d-3,vypts*1d-3,PSYM=8,SYMSIZE=1.0,COLOR=100L
  ;;  Output contour plot
  CONTOUR,df2ds,vx2d*1d-3,vy2d*1d-3,_EXTRA=con_lim
  ;;--------------------------------------------------------------------------------------
  ;;  Output arrows for EX_VECS
  ;;--------------------------------------------------------------------------------------
  IF (exvec_on[0]) THEN BEGIN
    xyposi = 94d-2*con_xyran
    FOR j=0L, n_exvec[0] - 1L DO BEGIN
      tvec   = exvec_rot[j].VEC
      tnam   = exvec_rot[j].NAME
      tcol   = vec_cols[j]
      ;;  Project arrow onto contour
      ARROW,0.,0.,tvec[0],tvec[1],/DATA,THICK=l_thick[0],COLOR=tcol[0]
      ;;  Output arrow label
      XYOUTS,xyposi[0],xyposi[1],tnam[0],/DATA,COLOR=tcol[0]
      ;;  Shift label position in negative Y-Direction
      xyposi[1] -= 0.08*con_xyran[1]
    ENDFOR
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  Output circles for CIRCS
  ;;--------------------------------------------------------------------------------------
  IF (circs_on[0]) THEN BEGIN
    FOR j=0L, n_circs[0] - 1L DO BEGIN
      OPLOT,vc_x[*,j],vc_y[*,j],LINESTYLE=2,THICK=l_thick[0]
    ENDFOR
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  Output crosshairs onto contour
  ;;--------------------------------------------------------------------------------------
  OPLOT,hori_crsshair[*,0],hori_crsshair[*,1],COLOR=250,THICK=l_thick[0]
  OPLOT,vert_crsshair[*,0],vert_crsshair[*,1],COLOR= 50,THICK=l_thick[0]
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Plot Cuts
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Set up plot area for cuts
PLOT,[0.0,1.0],[0.0,1.0],_EXTRA=base_lim_ct
  ;;  Output cuts point-by-point
  OPLOT,vpara_cut,vdf_cut_para,COLOR=250,PSYM=4  ;;  diamonds
  OPLOT,vperp_cut,vdf_cut_perp,COLOR= 50,PSYM=5  ;;  triangles
  ;;  Output cuts as solid lines
  OPLOT,vpara_cut,vdf_cut_para,COLOR=250,LINESTYLE=0
  OPLOT,vperp_cut,vdf_cut_perp,COLOR= 50,LINESTYLE=0
  ;;  Output cut labels
  xyposi     = [4d-1*con_xyran[0],4d0*df_ran[0]]
  XYOUTS,xyposi[0],xyposi[1],'Para. Cut',/DATA,COLOR=250
  xyposi[1] *= 0.7
  XYOUTS,xyposi[0],xyposi[1],'Perp. Cut',/DATA,COLOR= 50
  ;;--------------------------------------------------------------------------------------
  ;;  Output vertical lines for Max/Min values of CIRCS
  ;;--------------------------------------------------------------------------------------
  IF (circs_on[0]) THEN BEGIN
    FOR j=0L, n_circs[0] - 1L DO BEGIN
      OPLOT,[vc_lx[j],vc_lx[j]],df_ran,LINESTYLE=2,THICK=l_thick[0]
      OPLOT,[vc_xx[j],vc_xx[j]],df_ran,LINESTYLE=2,THICK=l_thick[0]
    ENDFOR
  ENDIF
;;----------------------------------------------------------------------------------------
;;  Output EX_INFO if present
;;----------------------------------------------------------------------------------------
IF (tran_on[0]) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Output SC Potential [eV]
  ;;--------------------------------------------------------------------------------------
  chsz           = 0.80
  yposi          = 0.20
  xposi          = 0.26
  XYOUTS,xposi[0],yposi[0],sc_pot_str[0],/NORMAL,ORIENTATION=90,CHARSIZE=chsz[0],COLOR=30
  ;;--------------------------------------------------------------------------------------
  ;;  Output Bulk Flow Velocity [km/s]
  ;;--------------------------------------------------------------------------------------
  xposi         += 0.02
  XYOUTS,xposi[0],yposi[0],v__out_str[0],/NORMAL,ORIENTATION=90,CHARSIZE=chsz[0],COLOR=30
  ;;--------------------------------------------------------------------------------------
  ;;  Output Magnetic Field Vector [nT]
  ;;--------------------------------------------------------------------------------------
  xposi         += 0.02
  XYOUTS,xposi[0],yposi[0],b__out_str[0],/NORMAL,ORIENTATION=90,CHARSIZE=chsz[0],COLOR=30
ENDIF
;;----------------------------------------------------------------------------------------
;;  Output version # and date produced
;;----------------------------------------------------------------------------------------
XYOUTS,0.795,0.06,vers[0],CHARSIZE=.65,/NORMAL,ORIENTATION=90.
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END







