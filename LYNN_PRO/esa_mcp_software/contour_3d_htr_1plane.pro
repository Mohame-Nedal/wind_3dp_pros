;+
;*****************************************************************************************
;
;  PROCEDURE:   contour_3d_htr_1plane.pro
;  PURPOSE  :   Produces a contour plot of the distribution function (DF) with parallel
;                 and perpendicular cuts with respect to the user defined input vectors.
;                 The contour plot does NOT assume gyrotropy, so the features in the DF
;                 may illustrate anisotropies more easily.  This routine uses the
;                 high time resolution (HTR) magnetic field data, not one single vector
;                 for the entire DF.
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               conv_units.pro
;               format_keys_contour_df.pro
;               read_wind_spinphase.pro
;               interp.pro
;               routine_version.pro
;               transform_vframe_3d.pro
;               rotate_3dp_structure.pro
;               rotate_3dp_htr_structure.pro
;               string_replace_char.pro
;               time_string.pro
;               cgColor.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT        :  3DP data structure either from get_??.pro
;                               with defined structure tag quantities for VSW
;               BGSE_HTR   :  HTR B-field structure of format:
;                               {X:Unix Times, Y:[K,3]-Element Vector}
;               VECTOR2    :  3-Element vector to be used with BGSE_HTR to define a 3D
;                               rotation matrix.  The new basis will have the following:
;                                 X'  :  parallel to BGSE_HTR
;                                 Z'  :  parallel to (BGSE_HTR x VECTOR2)
;                                 Y'  :  completes the right-handed set
;                               [Default = VSW ELSE {0.,1.,0.}]
;
;  EXAMPLES:    
;               ;;....................................................................
;               ;; => Define a time of interest
;               ;;....................................................................
;               to      = time_double('1998-08-09/16:00:00')
;               ;;....................................................................
;               ;; => Get a Wind 3DP EESA Low data structure from level zero files
;               ;;....................................................................
;               dat     = get_el(to)
;               ;;....................................................................
;               ;; => in the following lines, the strings correspond to TPLOT handles
;               ;;      and thus may be different for each user's preference
;               ;;....................................................................
;               add_vsw2,dat,'V_sw2'          ; => Add solar wind velocity to struct.
;               add_magf2,dat,'wi_B3(GSE)'    ; => Add magnetic field to struct.
;               add_scpot,dat,'sc_pot_3'      ; => Add spacecraft potential to struct.
;               ;;....................................................................
;               ;; => Plot contours of phase space density
;               ;;....................................................................
;               get_data,'wi_BHTR_GSE',DATA=bgse_htr
;               vec2     = dat.VSW
;               vlim     = 2d4                 ; => velocity range limit [km/s]
;               ngrid    = 30L                 ; => # of grids to use
;               dfra     = [1e-17,2e-10]       ; => define a range for contour levels
;               xname    = 'B'
;               yname    = 'Vsw'
;               contour_3d_htr_1plane,dat,bgse_htr,vec2,VLIM=vlim,NGRID=ngrid,$
;                                     XNAME=xname,YNAME=yname,/ONE_C,         $
;                                     DFRA=dfra,VCIRC=1e4
;
;  KEYWORDS:    
;               VLIM       :  Limit for x-y velocity axes over which to plot data
;                               [Default = max vel. from energy bin values]
;               NGRID      :  # of isotropic velocity grids to use to triangulate the data
;                               [Default = 30L]
;               XNAME      :  Scalar string defining the name of vector associated with
;                               the VECTOR1 input
;                               [Default = 'B!Do!N'+'[HTR]']
;               YNAME      :  Scalar string defining the name of vector associated with
;                               the VECTOR2 input
;                               [Default = 'Y']
;               SM_CUTS    :  If set, program plots the smoothed cuts of the DF
;                               [Default:  Not Smoothed]
;               NSMOOTH    :  Scalar # of points over which to smooth the DF
;                               [Default = 3]
;               ONE_C      :  If set, program makes a copy of the input array, redefines
;                               the data points equal to 1.0, and then calculates the 
;                               parallel cut and overplots it as the One Count Level
;               DFRA       :  2-Element array specifying a DF range (s^3/km^3/cm^3) for the
;                               cuts of the contour plot
;                               [Default = defined by range of data]
;               VCIRC      :  Scalar or array defining the value(s) to plot as a
;                               circle(s) of constant speed [km/s] on the contour
;                               plot [e.g. gyrospeed of specularly reflected ion]
;               EX_VEC0    :  3-Element unit vector for a quantity like heat flux or
;                               a wave vector, etc.
;               EX_VN0     :  A string name associated with EX_VEC0
;                               [Default = 'Vec 1']
;               EX_VEC1    :  3-Element unit vector for another quantity like the sun
;                               direction or shock normal vector vector, etc.
;               EX_VN1     :  A string name associated with EX_VEC1
;                               [Default = 'Vec 2']
;               NO_REDF    :  If set, program will plot only cuts of the distribution,
;                               not quasi-reduced distributions
;                               [Default:  program plots quasi-reduced distributions]
;               PLANE      :  Scalar string defining the plane projection to plot with
;                               corresponding cuts [Let V1 = VECTOR1, V2 = VECTOR2]
;                                 'xy'  :  horizontal axis parallel to V1 and normal
;                                            vector to plane defined by (V1 x V2)
;                                            [default]
;                                 'xz'  :  horizontal axis parallel to (V1 x V2) and
;                                            vertical axis parallel to V1
;                                 'yz'  :  horizontal axis defined by (V1 x V2) x V1
;                                            and vertical axis (V1 x V2)
;               NO_TRANS   :  If set, routine will not transform data into SW frame
;                               [Default = 0 (i.e. DAT transformed into SW frame)]
;               INTERP     :  If set, data is interpolated to original energy estimates
;                               after transforming into new reference frame
;               SM_CONT    :  If set, program plots the smoothed contours of DF
;                               [Note:  Smoothed to the minimum # of points]
;               DFMIN      :  Scalar defining the minimum allowable phase space density
;                               to plot, which is useful for ion distributions with
;                               large angular gaps in data
;                               [prevents lower bound from falling below DFMIN]
;               DFMAX      :  Scalar defining the maximum allowable phase space density
;                               to plot, which is useful for distributions with data
;                               spikes
;                               [prevents upper bound from exceeding DFMAX]
;
;   CHANGED:  1)  Fixed axis label typo for PLANE 'xz'             [02/10/2012   v1.0.1]
;             2)  Now removes energies < 1.3 * (SC Pot) and
;                   Added keywords:  INTERP and SM_CONT
;                                                                  [02/22/2012   v1.1.0]
;             3)  Changed maximum level of contours allowed        [03/14/2012   v1.1.1]
;             4)  Added keywords:  DFMIN and DFMAX and
;                   changed default minimum level of contours allowed and
;                   changed the number of minor tick marks
;                                                                  [03/29/2012   v1.2.0]
;             5)  Now calls test_wind_vs_themis_esa_struct.pro and no longer calls
;                   test_3dp_struc_format.pro                      [03/29/2012   v1.3.0]
;             6)  Fixed a typo dealing with VECTOR1 error handling that only
;                   affected output if the # of elements did not equal 3
;                                                                  [03/30/2012   v1.3.1]
;             7)  Changed thickness of projected lines and circles on contours and
;                   fixed the number of minor tick marks on plots and
;                   changed Vsw output and added % of vector in plane of projection
;                                                                  [04/17/2012   v1.3.2]
;             **************************************************************************
;             8)  New routine that uses HTR B-field created        [05/24/2012   v2.0.0]
;             9)  Now outputs the SC Potential [eV], Vsw [km/s], and Bo [nT] used
;                   to create the distribution function plots
;                                                                  [07/09/2012   v2.1.0]
;            10)  Now calls format_keys_contour_df.pro and routine_version.pro and
;                   no longer calls tplot_struct_format_test.pro and read_gen_ascii.pro
;                   and removed obsolete keyword NOKILL_PH
;                                                                  [08/08/2012   v2.2.0]
;
;   NOTES:      
;               1)  Input structure, DAT, must have UNITS_NAME = 'Counts'
;               2)  See also:  eh_cont3d.pro, df_contours_3d.pro,
;                              df_htr_contours_3d.pro, and contour_3d_1plane.pro
;               3)  This routine is only verified for EESA Low so far!!!
;
;   CREATED:  05/24/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/08/2012   v2.2.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO contour_3d_htr_1plane,dat,bgse_htr,vector2,VLIM=vlim,NGRID=ngrid,XNAME=xname,   $
                          YNAME=yname,SM_CUTS=sm_cuts,NSMOOTH=nsmooth,ONE_C=one_c,  $
                          DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,EX_VN0=ex_vn0,      $
                          EX_VEC1=ex_vec1,EX_VN1=ex_vn1,NO_REDF=no_redf,PLANE=plane,$
                          NO_TRANS=no_trans,INTERP=interpo,SM_CONT=sm_cont,         $
                          DFMIN=dfmin,DFMAX=dfmax

;;----------------------------------------------------------------------------------------
;; => Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f          = !VALUES.F_NAN
d          = !VALUES.D_NAN

; => Position of contour plot [square]
;               Xo    Yo    X1    Y1
pos_0con   = [0.22941,0.515,0.77059,0.915]
; => Position of 1st DF cuts [square]
pos_0cut   = [0.22941,0.050,0.77059,0.450]
; => Dummy plot labels
units_df   = '(sec!U3!N km!U-3!N cm!U-3!N'+')'
units_rdf  = '(sec!U2!N km!U-2!N cm!U-3!N'+')'
dumbytr    = 'quasi-reduced df '+units_rdf[0]
dumbytc    = 'cuts of df '+units_df[0]
suffc      = [' Cut',' Reduced DF']
cut_xttl   = 'Velocity (1000 km/sec)'
;---------------------------------
; => Dummy error messages
;---------------------------------
noinpt_msg     = 'No input supplied...'
notstr_msg     = 'Must be an IDL structure...'
nofint_msg     = 'No finite data...'
nottplot_mssg  = 'BGSE_HTR must be an appropriate TPLOT structure...'
notel_mssg     = 'This routine is only verified for EESA Low so far!!!'

lower_lim  = 1e-20  ; => Lowest expected value for DF
upper_lim  = 1e-2   ; => Highest expected value for DF
; => Dummy tick mark arrays
exp_val    = LINDGEN(50) - 50L                    ; => Array of exponent values
ytns       = '10!U'+STRTRIM(exp_val[*],2L)+'!N'   ; => Y-Axis tick names
ytvs       = 1d1^FLOAT(exp_val[*])                ; => Y-Axis tick values
; => Defined user symbol for outputing locations of data on contour
xxo        = FINDGEN(17)*(!PI*2./16.)
USERSYM,0.27*COS(xxo),0.27*SIN(xxo),/FILL
;-----------------------------------------------------------------------------------------
; => Check input
;-----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 1) THEN BEGIN
  ; => no input???
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  ; => Create empty plot
  !P.MULTI = 0
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;; => Check DAT structure format
;;----------------------------------------------------------------------------------------
test0      = test_wind_vs_themis_esa_struct(dat,/NOM)
test       = (test0.(0) + test0.(1)) NE 1
IF (test) THEN BEGIN
  MESSAGE,notstr_msg[0],/INFORMATIONAL,/CONTINUE
  ; => Create empty plot
  !P.MULTI = 0
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA
  RETURN
ENDIF
; => Define dummy data structure to avoid changing input
data       = dat[0]
IF KEYWORD_SET(one_c) THEN BEGIN
  onec         = data[0]
  onec[0].DATA = 1.0       ; => redefine all data points to 1 count
ENDIF

; => Check which spacecraft is being used
IF (test0.(0)) THEN BEGIN
  ;-------------------------------------------
  ; Wind
  ;-------------------------------------------
  ; => Check which instrument is being used
  strns   = dat_3dp_str_names(data[0])
  IF (SIZE(strns,/TYPE) NE 8) THEN BEGIN
    RETURN
  ENDIF
  shnme   = STRLOWCASE(STRMID(strns.SN[0],0L,2L))
  CASE shnme[0] OF
    'el' : BEGIN
      data   = conv_units(data,'df')
    END
    ELSE : BEGIN
      MESSAGE,notel_mssg[0],/INFORMATIONAL,/CONTINUE
      RETURN
    END
  ENDCASE
ENDIF ELSE BEGIN
  ;-------------------------------------------
  ; Not a Wind 3DP structure
  ;-------------------------------------------
  MESSAGE,notel_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDELSE
;;----------------------------------------------------------------------------------------
;; => Format keywords
;;----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(no_redf)  THEN noredf = 0              ELSE noredf = no_redf[0]
IF NOT KEYWORD_SET(plane)    THEN projxy = 'xy'           ELSE projxy = STRLOWCASE(plane[0])
IF NOT KEYWORD_SET(sm_cont)  THEN sm_con = 0              ELSE sm_con = sm_cont[0]
IF NOT KEYWORD_SET(nsmooth)  THEN ns     = 3              ELSE ns     = LONG(nsmooth)
IF NOT KEYWORD_SET(no_trans) THEN notran = 0              ELSE notran = no_trans[0]

IF NOT KEYWORD_SET(ex_vec0)  THEN evec0  = REPLICATE(f,3) ELSE evec0  = FLOAT(REFORM(ex_vec0))
IF NOT KEYWORD_SET(ex_vec1)  THEN evec1  = REPLICATE(f,3) ELSE evec1  = FLOAT(REFORM(ex_vec1))
IF NOT KEYWORD_SET(ex_vn0)   THEN vec0n  = 'Vec 1'        ELSE vec0n  = ex_vn0[0]
IF NOT KEYWORD_SET(ex_vn1)   THEN vec1n  = 'Vec 2'        ELSE vec1n  = ex_vn1[0]


format_keys_contour_df,dat,bgse_htr,vector2,VLIM=vlim,NGRID=ngrid,XNAME=xname,       $
                       YNAME=yname,SM_CUTS=sm_cuts,NSMOOTH=ns,ONE_C=one_c,           $
                       EX_VEC0=evec0,EX_VN0=vec0n,EX_VEC1=evec1,EX_VN1=vec1n,        $
                       NO_REDF=noredf,PLANE=projxy,NO_TRANS=notran,INTERP=interpo,   $
                       SM_CONT=sm_con,LOG_HTR=log_htr,VEC1=vec1,VEC2=vec2,           $
                       V_VSWS=v_vsws,V_MAGF=v_magf,VNAME=vname,BNAME=bname

test_v   = TOTAL(FINITE(v_vsws)) NE 3
test_b   = TOTAL(FINITE(v_magf)) NE 3
;-----------------------------------------------------------------------------------------
; => Check for spin phase information
;-----------------------------------------------------------------------------------------
t0       = data.TIME[0]
t1       = data.END_TIME[0]
tr3      = [t0[0],t1[0]] + [-6d2,6d2]
wi_spin  = read_wind_spinphase(TRANGE=tr3)
IF (SIZE(wi_spin,/TYPE) EQ 8) THEN BEGIN
  wi_spru  = wi_spin.UNIX         ; => Unix times
  wi_sprd  = wi_spin.SPIN_RATE_D  ; => Wind spin rate [deg/s]
  sprated  = interp(wi_sprd,wi_spru,t0[0],INDEX=ind)
  sprated  = wi_sprd[ind]
ENDIF ELSE BEGIN
  ;; => Use 3s B-field value instead
  vec1    = v_magf
  log_htr = 0
ENDELSE
;;########################################################################################
;; => Define version for output
;;########################################################################################
mdir     = FILE_EXPAND_PATH('wind_3dp_pros/LYNN_PRO/')+'/'
file     = 'contour_3d_htr_1plane.pro'
;file     = FILE_SEARCH(mdir,'contour_3d_htr_1plane.pro')
version  = routine_version(file,mdir)
;;----------------------------------------------------------------------------------------
;; => Convert into solar wind frame
;;----------------------------------------------------------------------------------------
transform_vframe_3d,data,/EASY_TRAN,NO_TRANS=notran,INTERP=interpo
IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
  transform_vframe_3d,onec,/EASY_TRAN,NO_TRANS=notran,INTERP=interpo
ENDIF
;;----------------------------------------------------------------------------------------
;; => Rotate DF into new reference frame
;;----------------------------------------------------------------------------------------
IF (log_htr EQ 0) THEN BEGIN
  ;; => Use 3s B-field values
  rotate_3dp_structure,data,vec1,vec2,VLIM=vlim
  ;; => Define B-field at start of DF
  magf_st = vec1
ENDIF ELSE BEGIN
  ;; => Use HTR B-field values
  rotate_3dp_htr_structure,data,bgse_htr,vec2,sprated[0],VLIM=vlim
  ;; => Define B-field at start of DF
  t00     = data.TIME
  magx    = interp(bgse_htr.Y[*,0],bgse_htr.X,t00,/NO_EXTRAP)
  magy    = interp(bgse_htr.Y[*,1],bgse_htr.X,t00,/NO_EXTRAP)
  magz    = interp(bgse_htr.Y[*,2],bgse_htr.X,t00,/NO_EXTRAP)
  magf_st = [magx,magy,magz]
ENDELSE
;; => Get 1-count level if desired
IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
  rotate_3dp_structure,onec,vec1,vec2,VLIM=vlim
ENDIF
;-----------------------------------------------------------------------------------------
; => Define contour plot title
;-----------------------------------------------------------------------------------------
IF (log_htr EQ 0) THEN BEGIN
  htr_suff = ' [3s MFI]'
ENDIF ELSE BEGIN
  htr_suff = ' [HTR MFI]'
ENDELSE
t_ttle     = data[0].PROJECT_NAME[0]
t_ttle2    = STRTRIM(string_replace_char(t_ttle,'3D Plasma','3DP'),2L)
title0     = t_ttle2[0]+' '+data[0].DATA_NAME[0]+htr_suff[0]
tra_s      = time_string([data.TIME,data.END_TIME])
tra_out    = tra_s[0]+' - '+STRMID(tra_s[1],11)
con_ttl    = title0+'!C'+tra_out
;;----------------------------------------------------------------------------------------
;; => Define plot parameters
;;----------------------------------------------------------------------------------------
xaxist = '(V dot '+xname[0]+') [1000 km/s]'
yaxist = '('+xname[0]+' x '+yname[0]+') x '+xname[0]+' [1000 km/s]'
zaxist = '('+xname[0]+' x '+yname[0]+') [1000 km/s]'
CASE projxy[0] OF
  'xy'  : BEGIN
    ;-------------------------------------------------------------------------------------
    ; => plot Y vs. X
    ;-------------------------------------------------------------------------------------
    xttl00 = xaxist
    yttl00 = yaxist
    ; => define data projection
    df2d   = data.DF2D_XY
    ; => define actual velocities for contour plot
    vxpts  = data.VELX_XY
    vypts  = data.VELY_XY
    vzpts  = data.VELZ_XY
    IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
      ; => define one-count projection and velocities
      df1c   = onec.DF2D_XY
      vx1c   = onec.VX2D
    ENDIF
    ; => define elements [x,y]
    gels   = [0L,1L]
  END
  'xz'  : BEGIN
    ;-------------------------------------------------------------------------------------
    ; => plot X vs. Z
    ;-------------------------------------------------------------------------------------
    xttl00 = zaxist
    yttl00 = xaxist
    ; => define data projection
    df2d   = data.DF2D_XZ
    ; => define actual velocities for contour plot
    vxpts  = data.VELX_XZ
    vypts  = data.VELY_XZ
    vzpts  = data.VELZ_XZ
    IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
      ; => define one-count projection and velocities
      df1c   = onec.DF2D_XZ
      vx1c   = onec.VX2D
    ENDIF
    ; => define elements [x,y]
    gels   = [2L,0L]
  END
  'yz'  : BEGIN
    ;-------------------------------------------------------------------------------------
    ; => plot Z vs. Y
    ;-------------------------------------------------------------------------------------
    xttl00 = yaxist
    yttl00 = zaxist
    ; => define data projection
    df2d   = data.DF2D_YZ
    ; => define actual velocities for contour plot
    vxpts  = data.VELX_YZ
    vypts  = data.VELY_YZ
    vzpts  = data.VELZ_YZ
    IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
      ; => define one-count projection and velocities
      df1c   = onec.DF2D_YZ
      vx1c   = onec.VX2D
    ENDIF
    ; => define elements [x,y]
    gels   = [0L,1L]
  END
  ELSE  : BEGIN
    ;-------------------------------------------------------------------------------------
    ; => use default:  Y vs. X
    ;-------------------------------------------------------------------------------------
    xttl00 = xaxist
    yttl00 = yaxist
    ; => define data projection
    df2d   = data.DF2D_XY
    ; => define actual velocities for contour plot
    vxpts  = data.VELX_XY
    vypts  = data.VELY_XY
    vzpts  = data.VELZ_XY
    IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
      ; => define one-count projection and velocities
      df1c   = onec.DF2D_XY
      vx1c   = onec.VX2D
    ENDIF
    ; => define elements [x,y]
    gels   = [0L,1L]
  END
ENDCASE
; => Define rotation matrices used to rotate the data
IF (projxy[0] EQ 'yz') THEN rmat0 = data.ROT_MAT_Z ELSE rmat0  = data.ROT_MAT
IF (log_htr EQ 0) THEN BEGIN
  ;; => Used 3s B-field values
  ;;    => [3,3]-Element array
  rmat = rmat0
ENDIF ELSE BEGIN
  ;; => Used HTR B-field values
  ;;    => [K,3,3]-Element array
  rmat = REFORM(rmat0[0L,*,*])  ;; use just the first rotation matrix
ENDELSE
; => Define regularly gridded velocities for contour plot
vx2d   = data.VX2D
vy2d   = data.VY2D
;;----------------------------------------------------------------------------------------
;; => Define the 2D projection of the VSW IDL structure tag in DAT and other vectors
;;----------------------------------------------------------------------------------------
v_mfac   = (vlim[0]*95d-2)*1d-3
v_mag    = SQRT(TOTAL(v_vsws^2,/NAN))
IF (test_v EQ 0) THEN BEGIN
  vxy_pro = REFORM(rmat ## v_vsws)/v_mag[0]
  vxy_per = SQRT(TOTAL(vxy_pro[gels]^2,/NAN))/SQRT(TOTAL(vxy_pro^2,/NAN))*1d2
  vswname = vname[0]+' ('+STRTRIM(STRING(vxy_per[0],FORMAT='(f10.1)'),2L)+'% in Plane)'
  vsw2d00 = vxy_pro[gels]/SQRT(TOTAL(vxy_pro[gels]^2,/NAN))*v_mfac[0]
  vsw2dx  = [0.,vsw2d00[0]]
  vsw2dy  = [0.,vsw2d00[1]]
ENDIF ELSE BEGIN
  vswname = ''
  vsw2dx  = REPLICATE(f,2)
  vsw2dy  = REPLICATE(f,2)
ENDELSE
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;; => Check for EX_VEC0 and EX_VEC1
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; => Define logic variables for output later
IF (TOTAL(FINITE(evec0)) NE 3) THEN out_v0 = 0 ELSE out_v0 = 1
IF (TOTAL(FINITE(evec1)) NE 3) THEN out_v1 = 0 ELSE out_v1 = 1
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;; => Rotate 1st extra vector
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
IF (out_v0) THEN BEGIN
  evec_0r  = REFORM(rmat ## evec0)/NORM(evec0)
  vec0_per = SQRT(TOTAL(evec_0r[gels]^2,/NAN))/SQRT(TOTAL(evec_0r^2,/NAN))*1d2
  vec0n    = vec0n[0]+' ('+STRTRIM(STRING(vec0_per[0],FORMAT='(f10.1)'),2L)+'% in Plane)'
ENDIF ELSE BEGIN
  evec_0r  = REPLICATE(f,3)
ENDELSE
; => renormalize
evec_0r  = evec_0r/SQRT(TOTAL(evec_0r[gels]^2,/NAN))*v_mfac[0]
evec_0x  = [0.,evec_0r[gels[0]]]
evec_0y  = [0.,evec_0r[gels[1]]]
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;; => Rotate 2nd extra vector
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
IF (out_v1) THEN BEGIN
  evec_1r  = REFORM(rmat ## evec1)/NORM(evec1)
  vec1_per = SQRT(TOTAL(evec_1r[gels]^2,/NAN))/SQRT(TOTAL(evec_1r^2,/NAN))*1d2
  vec1n    = vec1n[0]+' ('+STRTRIM(STRING(vec1_per[0],FORMAT='(f10.1)'),2L)+'% in Plane)'
ENDIF ELSE BEGIN
  evec_1r  = REPLICATE(f,3)
ENDELSE
; => renormalize
evec_1r  = evec_1r/SQRT(TOTAL(evec_1r[gels]^2,/NAN))*v_mfac[0]
evec_1x  = [0.,evec_1r[gels[0]]]
evec_1y  = [0.,evec_1r[gels[1]]]
;;----------------------------------------------------------------------------------------
;; => Define dummy DF range of values
;;----------------------------------------------------------------------------------------
vel_2d   = (vx2d # vy2d)/vlim[0]
test_vr  = (ABS(vel_2d) LE 0.75*vlim[0])
test_df  = (df2d GT 0.) AND FINITE(df2d)
good     = WHERE(test_vr AND test_df,gd)
good2    = WHERE(test_df,gd2)
IF (gd GT 0) THEN BEGIN
  mndf  = MIN(ABS(df2d[good]),/NAN) > lower_lim[0]
  mxdf  = MAX(ABS(df2d[good]),/NAN) < upper_lim[0]
ENDIF ELSE BEGIN
  IF (gd2 GT 0) THEN BEGIN
    ; => some finite data
    mndf  = MIN(ABS(df2d[good2]),/NAN) > lower_lim[0]
    mxdf  = MAX(ABS(df2d[good2]),/NAN) < upper_lim[0]
  ENDIF ELSE BEGIN
    ; => no finite data
    MESSAGE,nofint_msg[0],/INFORMATIONAL,/CONTINUE
    ; => Create empty plot
    !P.MULTI = 0
    PLOT,[0.0,1.0],[0.0,1.0],/NODATA
    RETURN
  ENDELSE
ENDELSE
;;----------------------------------------------------------------------------------------
;; => Define cuts
;;----------------------------------------------------------------------------------------
IF KEYWORD_SET(noredf) THEN BEGIN
  ; => Cuts of DFs
  c_suff  = suffc[0]
  yttlct  = dumbytc[0]  ; => cut Y-Title
  ndf     = (SIZE(df2d,/DIMENSIONS))[0]/2L + 1L
  ; => Calculate Cuts of DFs
  dfpara  = REFORM(df2d[*,ndf[0]])                                  ; => Para. Cut of DF
  dfperp  = REFORM(df2d[ndf[0],*])                                  ; => Perp. Cut of DF
  IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
    ; => Calculate one-count parallel Cut
    onec_para = REFORM(df1c[*,ndf[0]])
  ENDIF
ENDIF ELSE BEGIN
  ; => Quasi-Reduced DFs
  c_suff  = suffc[1]
  yttlct  = dumbytr[0]
  ;---------------------------------------------------------------------------------------
  ; => Define volume element
  ;---------------------------------------------------------------------------------------
  dvx     = (MAX(vx2d,/NAN) - MIN(vx2d,/NAN))/(N_ELEMENTS(vx2d) - 1L)
  dvy     = (MAX(vy2d,/NAN) - MIN(vy2d,/NAN))/(N_ELEMENTS(vy2d) - 1L)
  ; => Calculate Quasi-Reduced DFs
  red_fx  = REFORM(!DPI*dvy[0]*(df2d # ABS(vy2d)))
  red_fy  = REFORM(!DPI*dvx[0]*(ABS(vx2d) # df2d))
  ;---------------------------------------------------------------------------------------
  ; => Normalize Quasi-Reduced DFs
  ;---------------------------------------------------------------------------------------
  dfpara  = red_fx/( (TOTAL(FINITE(red_fx)) - 2d0)*MAX(ABS([vx2d,vy2d]),/NAN) )
  dfperp  = red_fy/( (TOTAL(FINITE(red_fy)) - 2d0)*MAX(ABS([vx2d,vy2d]),/NAN) )
  test_f0 = FINITE(dfpara) AND FINITE(dfperp)
  test_f1 = (dfpara GT 0.) AND (dfperp GT 0.)
  good    = WHERE(test_f0 AND test_f1,gd)
  ; => Check dummy DF ranges
  IF (gd EQ 0)THEN BEGIN
    ; => no finite data
    MESSAGE,nofint_msg[0],/INFORMATIONAL,/CONTINUE
    ; => Create empty plot
    !P.MULTI = 0
    PLOT,[0.0,1.0],[0.0,1.0],/NODATA
    RETURN
  ENDIF
  mxdf    = (mxdf[0] > MAX(ABS([dfpara[good],dfperp[good]]),/NAN)) < upper_lim[0]
  mndf    = (mndf[0] < MIN(ABS([dfpara[good],dfperp[good]]),/NAN)) > lower_lim[0]
  IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
    ; => Calculate one-count parallel Quasi-Reduced DFs
    red_1cx   = REFORM(!DPI*dvy[0]*(df1c # ABS(vy2d)))
    onec_para = red_1cx/(TOTAL(FINITE(red_1cx))*MAX(ABS([vx2d,vy2d]),/NAN))
  ENDIF
ENDELSE
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;; => Smooth cuts if desired
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
IF KEYWORD_SET(sm_cuts) THEN BEGIN
  dfpars   = SMOOTH(dfpara,ns[0],/EDGE_TRUNCATE,/NAN)
  dfpers   = SMOOTH(dfperp,ns[0],/EDGE_TRUNCATE,/NAN)
  onec_par = SMOOTH(onec_para,ns[0],/EDGE_TRUNCATE,/NAN)
ENDIF ELSE BEGIN
  dfpars   = dfpara
  dfpers   = dfperp
  onec_par = onec_para
ENDELSE
;;----------------------------------------------------------------------------------------
;; => Define DF range and corresponding contour levels, colors, etc.
;;----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(dfra) THEN df_ran = [mndf[0],mxdf[0]]*[0.95,1.05] ELSE df_ran = dfra
; => Check if DFMIN is set
IF KEYWORD_SET(dfmin) THEN df_ran[0] = df_ran[0] > dfmin[0]
; => Check if DFMAX is set
IF KEYWORD_SET(dfmax) THEN df_ran[1] = df_ran[1] < dfmax[0]

range    = ALOG10(df_ran)
lg_levs  = DINDGEN(ngrid)*(range[1] - range[0])/(ngrid - 1L) + range[0]
levels   = 1d1^lg_levs
nlevs    = N_ELEMENTS(levels)
minclr   = 30L
c_cols   = minclr + LINDGEN(ngrid)*(250L - minclr)/(ngrid - 1L)
;;----------------------------------------------------------------------------------------
;; => Define plot limits structures
;;----------------------------------------------------------------------------------------
xyran    = [-1d0,1d0]*vlim[0]*1d-3
; => structures for contour plot
lim_cn0  = {XRANGE:xyran,XSTYLE:1,XLOG:0,XTITLE:xttl00,XMINOR:10, $
            YRANGE:xyran,YSTYLE:1,YLOG:0,YTITLE:yttl00,YMINOR:10, $
            POSITION:pos_0con,TITLE:con_ttl,NODATA:1}
con_lim  = {OVERPLOT:1,LEVELS:levels,C_COLORS:c_cols}
; => Define Y-Axis tick marks for cuts
goodyl   = WHERE(ytvs LE df_ran[1] AND ytvs GE df_ran[0],gdyl)
IF (gdyl LT 20 AND gdyl GT 0) THEN BEGIN
  ; => structure for cuts plot with tick mark labels set
  lim_ct0  = {XRANGE:xyran, XSTYLE:1,XLOG:0,XTITLE:cut_xttl,XMINOR:10, $
              YRANGE:df_ran,YSTYLE:1,YLOG:1,YTITLE:yttlct,  YMINOR:9,  $
              POSITION:pos_0cut,TITLE:' ',NODATA:1,YTICKS:gdyl-1L,     $
              YTICKV:ytvs[goodyl],YTICKNAME:ytns[goodyl]}
ENDIF ELSE BEGIN
  ; => structure for cuts plot without tick mark labels set
  lim_ct0  = {XRANGE:xyran, XSTYLE:1,XLOG:0,XTITLE:cut_xttl,XMINOR:10, $
              YRANGE:df_ran,YSTYLE:1,YLOG:1,YTITLE:yttlct,  YMINOR:9,  $
              POSITION:pos_0cut,TITLE:' ',NODATA:1}
ENDELSE

; => Smooth contour if desired
IF KEYWORD_SET(sm_con) THEN BEGIN
  df2ds   = SMOOTH(df2d,3L,/EDGE_TRUNCATE,/NAN)
ENDIF ELSE BEGIN
  df2ds   = df2d
ENDELSE
;;----------------------------------------------------------------------------------------
;; => Get colors
;;----------------------------------------------------------------------------------------
magenta   = cgColor('magenta')
cyan      = cgColor('cyan')
blue      = cgColor('blue')
red       = cgColor('red')
pineg     = cgColor('forestgreen')
steelblue = cgColor('steelblue')
teal      = cgColor('teal')
gold      = cgColor('gold')
dodgeblue = cgColor('dodger blue')

vc1_col   = magenta[0]
vc2_col   = dodgeblue[0]
;;----------------------------------------------------------------------------------------
;; => Plot
;;----------------------------------------------------------------------------------------
!P.MULTI = [0,1,2]
IF (STRLOWCASE(!D.NAME) EQ 'ps') THEN l_thick  = 4 ELSE l_thick  = 2
;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
PLOT,[0.0,1.0],[0.0,1.0],_EXTRA=lim_cn0
  ; => Project locations of actual data points onto contour
  OPLOT,vxpts*1d-3,vypts*1d-3,PSYM=8,SYMSIZE=1.0,COLOR=cyan[0]
  ;---------------------------------------------------------------------------------------
  ; => Draw contours
  ;---------------------------------------------------------------------------------------
  CONTOUR,df2ds,vx2d*1d-3,vy2d*1d-3,_EXTRA=con_lim
    ;-------------------------------------------------------------------------------------
    ; => Project V_sw onto contour
    ;-------------------------------------------------------------------------------------
    ARROW,vsw2dx[0],vsw2dy[0],vsw2dx[1],vsw2dy[1],/DATA,THICK=l_thick[0]
    xyposi = [-1d0*.94*vlim[0],0.94*vlim[0]]*1d-3
    IF (test_v EQ 0) THEN BEGIN
      XYOUTS,xyposi[0],xyposi[1],vswname[0],/DATA
      ; => Shift in negative Y-Direction
      xyposi[1] -= 0.08*vlim*1d-3
    ENDIF
    ;-------------------------------------------------------------------------------------
    ; => Project 1st extra vector onto contour
    ;-------------------------------------------------------------------------------------
    ARROW,evec_0x[0],evec_0y[0],evec_0x[1],evec_0y[1],/DATA,THICK=l_thick[0],COLOR=vc1_col[0]
    IF (out_v0) THEN BEGIN
      XYOUTS,xyposi[0],xyposi[1],vec0n[0],/DATA,COLOR=vc1_col[0]
      ; => Shift in negative Y-Direction
      xyposi[1] -= 0.08*vlim*1d-3
    ENDIF
    ;-------------------------------------------------------------------------------------
    ; => Project 2nd extra vector onto contour
    ;-------------------------------------------------------------------------------------
    ARROW,evec_1x[0],evec_1y[0],evec_1x[1],evec_1y[1],/DATA,THICK=l_thick[0],COLOR=vc2_col[0]
    IF (out_v1) THEN BEGIN
      XYOUTS,xyposi[0],xyposi[1],vec1n[0],/DATA,COLOR=vc2_col[0]
      ; => Shift in negative Y-Direction
      xyposi[1] -= 0.08*vlim*1d-3
    ENDIF
    ;-------------------------------------------------------------------------------------
    ; => Project circle of constant speed onto contour
    ;-------------------------------------------------------------------------------------
    IF KEYWORD_SET(vcirc) THEN BEGIN
      n_circ = N_ELEMENTS(vcirc)
      thetas = DINDGEN(500)*2d0*!DPI/499L
      FOR j=0L, n_circ - 1L DO BEGIN
        vxcirc = vcirc[j]*1d-3*COS(thetas)
        vycirc = vcirc[j]*1d-3*SIN(thetas)
        OPLOT,vxcirc,vycirc,LINESTYLE=2,THICK=l_thick[0]
      ENDFOR
    ENDIF
;;----------------------------------------------------------------------------------------
;; => Plot cuts of DF
;;----------------------------------------------------------------------------------------
PLOT,[0.0,1.0],[0.0,1.0],_EXTRA=lim_ct0
  ; => Plot point-by-point
  OPLOT,vx2d*1d-3,dfpars,COLOR=red[0],PSYM=4
  OPLOT,vy2d*1d-3,dfpers,COLOR=blue[0],PSYM=5
  ; => Plot lines
  OPLOT,vx2d*1d-3,dfpars,COLOR=red[0],LINESTYLE=0
  OPLOT,vy2d*1d-3,dfpers,COLOR=blue[0],LINESTYLE=2
  ;---------------------------------------------------------------------------------------
  ; => Determine where to put labels
  ;---------------------------------------------------------------------------------------
  fmin       = lim_ct0.YRANGE[0]
  xyposi     = [-1d0*4e-1*vlim[0]*1d-3,fmin[0]*4e0]
  ; => Output label for para
  XYOUTS,xyposi[0],xyposi[1],'+++ : Parallel'+c_suff[0],/DATA,COLOR=red[0]
  ; => Shift in negative Y-Direction
  xyposi[1] *= 0.7
  ; => Output label for perp
  XYOUTS,xyposi[0],xyposi[1],'*** : Perpendicular'+c_suff[0],COLOR=blue[0],/DATA
  ;---------------------------------------------------------------------------------------
  ; => Plot 1-Count Level if desired
  ;---------------------------------------------------------------------------------------
  IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
    OPLOT,vx1c*1d-3,onec_par,COLOR=pineg[0],LINESTYLE=4
    ; => Shift in negative Y-Direction
    xyposi[1] *= 0.7
    XYOUTS,xyposi[0],xyposi[1],'- - - : One-Count Level',COLOR=pineg[0],/DATA
  ENDIF
  ;---------------------------------------------------------------------------------------
  ; => Plot vertical lines for circle of constant speed if desired
  ;---------------------------------------------------------------------------------------
  IF KEYWORD_SET(vcirc) THEN BEGIN
    n_circ = N_ELEMENTS(vcirc)
    yras   = lim_ct0.YRANGE
    FOR j=0L, n_circ - 1L DO BEGIN
      OPLOT,[vcirc[j],vcirc[j]]*1d-3,yras,LINESTYLE=2,THICK=l_thick[0]
      OPLOT,-1d0*[vcirc[j],vcirc[j]]*1d-3,yras,LINESTYLE=2,THICK=l_thick[0]
    ENDFOR
  ENDIF
;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;-----------------------------------------------------------------------------------------
; => Output SC Potential [eV]
;-----------------------------------------------------------------------------------------
chsz        = 0.80
yposi       = 0.20
xposi       = 0.26
sc_pot_str  = STRTRIM(STRING(FORMAT='(f10.2)',data.SC_POT),2)
XYOUTS,xposi[0],yposi[0],'SC Potential : '+sc_pot_str[0]+' [eV]',/NORMAL,ORIENTATION=90,$
       CHARSIZE=chsz[0],COLOR=30L
;-----------------------------------------------------------------------------------------
; => Output SW Velocity [km/s]
;-----------------------------------------------------------------------------------------
vsw_str     = STRTRIM(STRING(FORMAT='(f10.2)',v_vsws),2)
str_out     = '<'+vsw_str[0]+','+vsw_str[1]+','+vsw_str[2]+'> [km/s]'
xposi      += 0.02
XYOUTS,xposi[0],yposi[0],'Vsw : '+str_out[0],/NORMAL,ORIENTATION=90,$
       CHARSIZE=chsz[0],COLOR=30L
;-----------------------------------------------------------------------------------------
; => Output Magnetic Field Vector [nT]  {at start of DF}
;-----------------------------------------------------------------------------------------
mag_str     = STRTRIM(STRING(FORMAT='(f10.2)',magf_st),2)
str_out     = '<'+mag_str[0]+','+mag_str[1]+','+mag_str[2]+'> [nT]'
xposi      += 0.02
XYOUTS,xposi[0],yposi[0],'Bo : '+str_out[0],/NORMAL,ORIENTATION=90,$
       CHARSIZE=chsz[0],COLOR=30L
;-----------------------------------------------------------------------------------------
; => Output version # and date produced
;-----------------------------------------------------------------------------------------
XYOUTS,0.795,0.06,version[0],CHARSIZE=.65,/NORMAL,ORIENTATION=90.
;-----------------------------------------------------------------------------------------
; => Return
;-----------------------------------------------------------------------------------------
!P.MULTI = 0

RETURN
END



