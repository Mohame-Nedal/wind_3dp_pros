;+
;*****************************************************************************************
;
;  PROCEDURE:   contour_vdf.pro
;  PURPOSE  :   This is a generalized routine that is used by the particle velocity
;                 distribution function (DF) contour plotting routines in the UMN
;                 Modified Wind/3DP IDL Libraries.  Since all the routines have the same
;                 general format in the plotting portion of the code, this routine was
;                 written to replace those 300+ lines into a few.
;
;  CALLED BY:   
;               contour_beam_plot.pro
;
;  CALLS:
;               get_font_symbol.pro
;               get_color_by_name.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               CONT_STRUC  :  Structure [scalar] containing the following:
;                                LIMITS_0     :  sets up contour plot area
;                                LIMITS_1     :  limits structure for CONTOUR.PRO
;                                V[X,Y]_PTS   :  [E*A]-Element array of [X,Y]-velocity
;                                                  [km/s] locations of the observed data
;                                V[X,Y]_GRID  :  [G]-Element array of gridded velocities
;                                DF_GRID      :  [G,G]-Element array of gridded phase
;                                                  (velocity) space densities
;                                                  [cm^(-3) km^(-3) s^(3)]
;               CUTS_STRUC  :  Structure [scalar] containing the following:
;                                LIMITS_0     :  sets up contour plot area
;                                VPARA        :  [G]-Element array of velocities [km/s]
;                                                  parallel to X-Axis
;                                                  [Note:  this may be offset from zero]
;                                VPERP        :  [G]-Element array of velocities [km/s]
;                                                  parallel to Y-Axis
;                                                  [Note:  this may be offset from zero]
;                                DFPARA       :  [G]-Element array of phase (velocity)
;                                                  space densities [cm^(-3) km^(-3) s^(3)]
;                                                  along VPARA
;                                DFPERP       :  [G]-Element array of phase (velocity)
;                                                  space densities [cm^(-3) km^(-3) s^(3)]
;                                                  along VPERP
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               ***  INPUT  ***
;               MODEL_STR   :  Structure [scalar] containing cuts of a model fit with the
;                                same format as CUTS_STRUC except for the LIMITS_0 tag
;               EX_VECS     :  [V]-Element structure array containing extra vectors the
;                                user wishes to project onto the contour, each with
;                                the following format:
;                                  VEC   :  [2]-Element vector already rotated into the
;                                             coordinate system associated with the
;                                             contour plot projection
;                                             [e.g. VEC[0] = along X-Axis]
;                                  NAME  :  Scalar [string] used as a name for VEC
;                                             output onto the contour plot
;                                             [Default = 'Vec_j', j = index of EX_VECS]
;               CIRCLE_STR  :  [C]-Element structure array containing the center
;                                locations and radii of circles the user wishes to
;                                project onto the contour and cut plots, each with
;                                the following format:
;                                  VRAD  :  Scalar defining the velocity radius of the
;                                             circle to project centered at {VOX,VOY}
;                                  VOX   :  Scalar defining the velocity offset along
;                                             X-Axis [Default = 0.0]
;                                  VOY   :  Scalar defining the velocity offset along
;                                             Y-Axis [Default = 0.0]
;               VERSION     :  Scalar [string] defining the version number of the calling
;                                routine, and the date/time of the output
;               TRAN_INFO   :  Structure [scalar] containing information relevant to the
;                                DF with the following format [units matter here]:
;                                  SCPOT  :  Scalar defining the spacecraft potential [eV]
;                                  VSW    :  [3]-Element vector defining to the bulk flow
;                                              velocity [km/s]
;                                  MAGF   :  [3]-Element vector defining to the quasi-
;                                              static magnetic field [nT]
;               V_0X        :  Scalar [float/double] defining the velocity along the
;                                X-Axis (horizontal) to shift the location where the
;                                perpendicular (vertical) cut of the DF will be performed
;                                [Default = 0.0]
;               V_0Y        :  Scalar [float/double] defining the velocity along the
;                                Y-Axis (vertical) to shift the location where the
;                                parallel (horizontal) cut of the DF will be performed
;                                [Default = 0.0]
;               VB_REG      :  [4]-element array specifying the velocity coordinates
;                                [X0,Y0,X1,Y1] associated with a rectangular region
;                                that encompasses a "beam" to be overplotted onto the
;                                contour plot [km/s]
;
;  KEYWORDS:    
;               ***  OUTPUT  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  [all the following changed on output]  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               XYDP_CON    :  Structure [scalar] containing structures associated with
;                                the system variables !X, !Y, !D, and !P for the
;                                contour plot
;               XYDP_CUT    :  Structure [scalar] containing structures associated with
;                                the system variables !X, !Y, !D, and !P for the
;                                cuts plot
;
;   CHANGED:  1)  Fixed a typo in an error handling statement      [09/04/2012   v1.0.1]
;             2)  Changed color of first vector depending on !D.NAME
;                                                                  [09/11/2012   v1.0.2]
;
;   NOTES:      
;               1)  This routine should NOT be called by user!
;               2)  Technically, the units do not matter so long as they are consistent
;                     for each type of variable [e.g. velocity] between all inputs and
;                     the plot labels/titles reflect the same [except for TRAN_INFO]
;               3)  Max # of extra vectors [EX_VECS] is 7
;
;   CREATED:  08/25/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  09/11/2012   v1.0.2
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO contour_vdf,cont_struc,cuts_struc,MODEL_STR=model,EX_VECS=ex_vecs,     $
                CIRCLE_STR=circle_str,VERSION=version,TRAN_INFO=tran_info, $
                V_0X=v_0x,V_0Y=v_0y,VB_REG=vb_reg,XYDP_CON=xydp_con,       $
                XYDP_CUT=xydp_cut

;;----------------------------------------------------------------------------------------
;; => Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;; => Dummy error messages
noinpt_msg     = 'No input supplied...'
badstr_msg0    = 'Incorrect CONT_STRUC structure format [see manual page]...'
badstr_msg1    = 'Incorrect CUTS_STRUC structure format [see manual page]...'
;; => Position of contour plot [square]
;;               Xo    Yo    X1    Y1
pos_0con       = [0.22941,0.515,0.77059,0.915]
;; => Position of 1st DF cuts [square]
pos_0cut       = [0.22941,0.050,0.77059,0.450]
;; => Define strings associated with a diamond and triangle for legend on plot
tri_str        = get_font_symbol('triangle')
dia_str        = get_font_symbol('diamond')
tri_str        = STRJOIN(REPLICATE(tri_str[0],3L),/SINGLE)
dia_str        = STRJOIN(REPLICATE(dia_str[0],3L),/SINGLE)
;; => Define default colors [byte]
magenta        = get_color_by_name('magenta')
cyan           = get_color_by_name('cyan')
orange         = get_color_by_name('orange')
blue           = get_color_by_name('blue')
red            = get_color_by_name('red')
pineg          = get_color_by_name('forestgreen')
purple         = get_color_by_name('purple')
steelblue      = get_color_by_name('steelblue')
teal           = get_color_by_name('teal')
dodgeblue      = get_color_by_name('dodger blue')
black          = get_color_by_name('black')
white          = get_color_by_name('white')
IF (STRLOWCASE(!D.NAME) EQ 'x') THEN first = white[0] ELSE first = black[0]
vec_colors     = [first[0],magenta[0],dodgeblue[0],red[0],pineg[0],cyan[0],teal[0]]

;; => Define default structure tags
tags_con       = ['LIMITS_0','LIMITS_1','VX_PTS','VY_PTS','VX_GRID','VY_GRID','DF_GRID']
tags_cut       = ['LIMITS_0','VPARA','VPERP','DFPARA','DFPERP']
tags_mod       = ['VPARA','VPERP','DFPARA','DFPERP']
tags_exv       = ['VEC','NAME']
tags_cir       = ['VRAD','VOX','VOY']
tags_tra       = ['SCPOT','VSW','MAGF']
;; => Get the Decomposed State
DEVICE, GET_DECOMPOSED=decomp
;;----------------------------------------------------------------------------------------
;; => Check input
;;----------------------------------------------------------------------------------------
test           = (SIZE(cont_struc,/TYPE) NE 8) OR (SIZE(cuts_struc,/TYPE) NE 8) OR $
                 (N_PARAMS() NE 2)
IF (test) THEN BEGIN
  ;; => no input???
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  ;; => Create empty plots
  !P.MULTI = [0,1,2]
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA,POSITION=pos_0con
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA,POSITION=pos_0cut
  !P.MULTI = 0
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;; => Check CONT_STRUC structure format
;;----------------------------------------------------------------------------------------
tagnm          = STRLOWCASE(TAG_NAMES(cont_struc))
ntag           = N_TAGS(cont_struc)
testn          = (ntag NE N_ELEMENTS(tags_con))
testt          = TOTAL(tagnm EQ STRLOWCASE(tags_con)) NE N_ELEMENTS(tags_con)
test           = testn OR testt
IF (test) THEN BEGIN
  ;; => bad CONT_STRUC input!
  MESSAGE,badstr_msg0[0],/INFORMATIONAL,/CONTINUE
  ;; => Create empty plots
  !P.MULTI = [0,1,2]
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA,POSITION=pos_0con
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA,POSITION=pos_0cut
  !P.MULTI = 0
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;; => Check CUTS_STRUC structure format
;;----------------------------------------------------------------------------------------
tagnm          = STRLOWCASE(TAG_NAMES(cuts_struc))
ntag           = N_TAGS(cuts_struc)
testn          = (ntag NE N_ELEMENTS(tags_cut))
testt          = TOTAL(tagnm EQ STRLOWCASE(tags_cut)) NE N_ELEMENTS(tags_cut)
test           = testn OR testt
IF (test) THEN BEGIN
  ;; => bad CUTS_STRUC input!
  MESSAGE,badstr_msg1[0],/INFORMATIONAL,/CONTINUE
  ;; => Create empty plots
  !P.MULTI = [0,1,2]
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA,POSITION=pos_0con
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA,POSITION=pos_0cut
  !P.MULTI = 0
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;; => Check keywords
;;----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(version)  THEN vers   = ''   ELSE vers   = version[0]
IF (N_ELEMENTS(v_0x)  NE 1)  THEN vox    = 0d0  ELSE vox    = v_0x[0]*1d-3
IF (N_ELEMENTS(v_0y)  NE 1)  THEN voy    = 0d0  ELSE voy    = v_0y[0]*1d-3
;;-------------------------------------------
;; Check CIRCLE_STR
;;-------------------------------------------
test           = KEYWORD_SET(circle_str) AND (SIZE(circle_str,/TYPE) EQ 8)
IF (test) THEN BEGIN
  ;; => Check CIRCLE_STR structure format
  ncirc          = N_ELEMENTS(circle_str)
  tagnm          = STRLOWCASE(TAG_NAMES(circle_str[0]))
  ntag           = N_TAGS(circle_str[0])
  testn          = (ntag NE N_ELEMENTS(tags_cir))
  testt          = TOTAL(tagnm EQ STRLOWCASE(tags_cir)) NE N_ELEMENTS(tags_cir)
  testc          = testn OR testt
  IF (testc) THEN BEGIN
    vcirc          = 0
  ENDIF ELSE BEGIN
    nn     = 200L
    thetas = DINDGEN(nn)*2d0*!DPI/(nn - 1L)
    vc_lx  = DBLARR(ncirc)          ;;  Min. X-Location of circle in cut plot
    vc_xx  = DBLARR(ncirc)          ;;  Max. X-Location of circle in cut plot
    vc_x   = DBLARR(nn,ncirc)       ;;  X-Component of circles
    vc_y   = DBLARR(nn,ncirc)       ;;  Y-Component of circles
    FOR j=0L, ncirc - 1L DO BEGIN
      vrad      = circle_str[j].VRAD[0]
      vc_ox     = circle_str[j].VOX[0]
      vc_oy     = circle_str[j].VOY[0]
      vc_x[*,j] = vrad[0]*COS(thetas) + vc_ox[0]
      vc_y[*,j] = vrad[0]*SIN(thetas) + vc_oy[0]
      vc_lx[j]  = MIN(vc_x[*,j],/NAN)
      vc_xx[j]  = MAX(vc_x[*,j],/NAN)
    ENDFOR
    vcirc          = 1
  ENDELSE
ENDIF ELSE BEGIN
  vcirc          = 0
ENDELSE
;;-------------------------------------------
;; Check MODEL_STR
;;-------------------------------------------
test           = KEYWORD_SET(model) AND (SIZE(model,/TYPE) EQ 8)
IF (test) THEN BEGIN
  ;; => Check MODEL_STR structure format
  tagnm          = STRLOWCASE(TAG_NAMES(model[0]))
  ntag           = N_TAGS(model[0])
  testn          = (ntag NE N_ELEMENTS(tags_mod))
  testt          = TOTAL(tagnm EQ STRLOWCASE(tags_mod)) NE N_ELEMENTS(tags_mod)
  testm          = testn OR testt
  IF (testm) THEN BEGIN
    mode           = 0
  ENDIF ELSE BEGIN
    vpara_mod      = model.VPARA
    vperp_mod      = model.VPERP
    dfpar_mod      = model.DFPARA
    dfper_mod      = model.DFPERP
    mode           = 1
  ENDELSE
ENDIF ELSE BEGIN
  mode           = 0
ENDELSE
;;-------------------------------------------
;; Check EX_VECS
;;-------------------------------------------
test           = KEYWORD_SET(ex_vecs) AND (SIZE(ex_vecs,/TYPE) EQ 8)
IF (test) THEN BEGIN
  ;; => Check EX_VECS structure format
  nexvc          = N_ELEMENTS(ex_vecs)
  tagnm          = STRLOWCASE(TAG_NAMES(ex_vecs[0]))
  ntag           = N_TAGS(ex_vecs[0])
  testn          = (ntag NE N_ELEMENTS(tags_exv))
  testt          = TOTAL(tagnm EQ STRLOWCASE(tags_exv)) NE N_ELEMENTS(tags_exv)
  teste          = testn OR testt
  IF (teste) THEN BEGIN
    exvc           = 0
  ENDIF ELSE BEGIN
    IF (nexvc GT N_ELEMENTS(vec_colors)) THEN BEGIN
      ;; too many extra vectors
      ex_vec           = ex_vecs[0L:6L]
    ENDIF ELSE BEGIN
      ex_vec           = ex_vecs
    ENDELSE
    nexvc            = N_ELEMENTS(ex_vec)
    ex_vect          = REPLICATE(d,nexvc,2L)
    ex_name          = REPLICATE('',nexvc)
    vec_col          = REPLICATE('',nexvc)
    FOR j=0L, nexvc - 1L DO BEGIN
      vec0           = ex_vec[j].VEC
      name0          = ex_vec[j].NAME
      testb          = (N_ELEMENTS(vec0) GE 2)
      IF (testb) THEN BEGIN
        ex_vect[j,*] = vec0[0L:1L]
        IF (SIZE(name0[0],/TYPE) EQ 7) THEN ex_name[j] = name0[0]
        vec_col[j]   = vec_colors[j]
      ENDIF
    ENDFOR
    exvc           = 1
  ENDELSE
ENDIF ELSE BEGIN
  exvc           = 0
ENDELSE
;;-------------------------------------------
;; Check TRAN_INFO
;;-------------------------------------------
test           = KEYWORD_SET(tran_info) AND (SIZE(tran_info,/TYPE) EQ 8)
IF (test) THEN BEGIN
  ;; => Check TRAN_INFO structure format
  tagnm          = STRLOWCASE(TAG_NAMES(tran_info[0]))
  ntag           = N_TAGS(tran_info[0])
  testn          = (ntag NE N_ELEMENTS(tags_tra))
  testt          = TOTAL(tagnm EQ STRLOWCASE(tags_tra)) NE N_ELEMENTS(tags_tra)
  testi          = testn OR testt
  IF (teste) THEN BEGIN
    sc_pot_str     = 'SC Pot.  :  NaN [eV]'
    v__out_str     = 'Vsw      :  < NaN, NaN, NaN> [km/s]'
    b__out_str     = 'Bo       :  < NaN, NaN, NaN> [nT]'
  ENDIF ELSE BEGIN
    scpot          = STRTRIM(STRING(FORMAT='(f10.2)',tran_info[0].SCPOT),2)
    plus           = STRMID(scpot[0],0L,1L) NE '-'
    IF (plus) THEN scpot = '+'+scpot[0]
    vsw            = STRTRIM(STRING(FORMAT='(f10.2)',tran_info[0].VSW),2)
    magf           = STRTRIM(STRING(FORMAT='(f10.2)',tran_info[0].MAGF),2)
    FOR j=0L, 2L DO BEGIN
      plus = STRMID(vsw[j],0L,1L) NE '-'
      IF (plus) THEN vsw[j] = '+'+vsw[j]
      plus = STRMID(magf[j],0L,1L) NE '-'
      IF (plus) THEN magf[j] = '+'+magf[j]
    ENDFOR
    ;; put vectors in <>'s
    v_out          = '<'+vsw[0]+', '+vsw[1]+', '+vsw[2]+'> [km/s]'
    b_out          = '<'+magf[0]+', '+magf[1]+', '+magf[2]+'> [nT]'
    sc_pot_str     = 'SC Pot.  :  '+scpot[0]+' [eV]'
    v__out_str     = 'Vsw      :  '+v_out[0]
    b__out_str     = 'Bo       :  '+b_out[0]
  ENDELSE
ENDIF ELSE BEGIN
  sc_pot_str     = 'SC Pot.  :  NaN [eV]'
  v__out_str     = 'Vsw      :  < NaN, NaN, NaN> [km/s]'
  b__out_str     = 'Bo       :  < NaN, NaN, NaN> [nT]'
ENDELSE
;;----------------------------------------------------------------------------------------
;; => Define CONT_STRUC parameters
;;----------------------------------------------------------------------------------------
lim_con0       = cont_struc.LIMITS_0  ;; sets up contour plot area
lim_con1       = cont_struc.LIMITS_1  ;; defines parameters specific to CONTOUR.PRO
vxpts          = cont_struc.VX_PTS    ;; velocity locations of actual observations [X]
vypts          = cont_struc.VY_PTS    ;; velocity locations of actual observations [Y]
vx2d           = cont_struc.VX_GRID   ;; velocity locations of gridded data [X]
vy2d           = cont_struc.VY_GRID   ;; velocity locations of gridded data [X]
df2ds          = cont_struc.DF_GRID   ;; gridded phase (velocity) space densities

vlim           = lim_con0.XRANGE[1]
;;----------------------------------------------------------------------------------------
;; => Define CUTS_STRUC parameters
;;----------------------------------------------------------------------------------------
lim_cut        = cuts_struc.LIMITS_0
v_c_para       = cuts_struc.VPARA
v_c_perp       = cuts_struc.VPERP
dfpars         = cuts_struc.DFPARA
dfpers         = cuts_struc.DFPERP

yra_cut        = lim_cut.YRANGE
;;----------------------------------------------------------------------------------------
;; => Set up plot
;;----------------------------------------------------------------------------------------
!P.MULTI       = [0,1,2]
IF (STRLOWCASE(!D.NAME) EQ 'ps') THEN l_thick  = 3 ELSE l_thick  = 2
;;----------------------------------------------------------------------------------------
;; => Plot Contour
;;----------------------------------------------------------------------------------------
;;  Set up plot area
PLOT,[0.0,1.0],[0.0,1.0],_EXTRA=lim_con0
;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ;; => Project locations of actual data points onto contour
  OPLOT,vxpts,vypts,PSYM=8,SYMSIZE=1.0,COLOR=cyan[0]
  ;;--------------------------------------------------------------------------------------
  ;; => Overplot contours
  ;;--------------------------------------------------------------------------------------
  CONTOUR,df2ds,vx2d,vy2d,_EXTRA=lim_con1
    ;;------------------------------------------------------------------------------------
    ;; => Project EX_VECS onto contour
    ;;------------------------------------------------------------------------------------
    xyposi = [-1d0*.94*vlim[0],0.94*vlim[0]]
    IF KEYWORD_SET(exvc) THEN BEGIN
      FOR j=0L, nexvc - 1L DO BEGIN
        ;; project arrow onto contour
        ARROW,0.,0.,ex_vect[j,0],ex_vect[j,1],/DATA,THICK=l_thick[0],COLOR=vec_col[j]
        ;; output arrow label
        XYOUTS,xyposi[0],xyposi[1],ex_name[j],/DATA,COLOR=vec_col[j]
        ;; => Shift output position in negative Y-Direction
        xyposi[1] -= 0.08*vlim[0]
      ENDFOR
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;; => Project circle of constant speed onto contour
    ;;------------------------------------------------------------------------------------
    IF KEYWORD_SET(vcirc) THEN BEGIN
      FOR j=0L, ncirc - 1L DO BEGIN
        OPLOT,vc_x[*,j],vc_y[*,j],LINESTYLE=2,THICK=l_thick[0]
      ENDFOR
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;; => Project crosshairs onto contour
    ;;------------------------------------------------------------------------------------
    vx00 = [-1d0,1d0]*vlim[0]
    vy00 = [voy[0],voy[0]]
    vx11 = [vox[0],vox[0]]
    vy11 = [-1d0,1d0]*vlim[0]
    OPLOT,vx00,vy00,COLOR=red[0], THICK=l_thick[0]
    OPLOT,vx11,vy11,COLOR=blue[0],THICK=l_thick[0]
    ;;------------------------------------------------------------------------------------
    ;; => Project rectangle onto contour
    ;;------------------------------------------------------------------------------------
    IF KEYWORD_SET(vb_reg) THEN BEGIN
      n_rect = N_ELEMENTS(vb_reg)
      IF (n_rect EQ 4) THEN BEGIN
        vb_reg *= 1d-3
        ;; left side
        OPLOT,[vb_reg[0],vb_reg[0]],[vb_reg[1],vb_reg[3]],LINESTYLE=2,THICK=l_thick[0]*75d-2
        ;; right side
        OPLOT,[vb_reg[2],vb_reg[2]],[vb_reg[1],vb_reg[3]],LINESTYLE=2,THICK=l_thick[0]*75d-2
        ;; top side
        OPLOT,[vb_reg[0],vb_reg[2]],[vb_reg[3],vb_reg[3]],LINESTYLE=2,THICK=l_thick[0]*75d-2
        ;; bottom side
        OPLOT,[vb_reg[0],vb_reg[2]],[vb_reg[1],vb_reg[1]],LINESTYLE=2,THICK=l_thick[0]*75d-2
      ENDIF
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;; => Define plot structure to return to calling routine
    ;;------------------------------------------------------------------------------------
    xydp_con = {X:!X,Y:!Y,P:!P,D:!D}
;;----------------------------------------------------------------------------------------
;; => Plot Cuts of DF
;;----------------------------------------------------------------------------------------
PLOT,[0.0,1.0],[0.0,1.0],_EXTRA=lim_cut
  ;; => Overplot point-by-point
  OPLOT,v_c_para,dfpars,COLOR=red[0], PSYM=4  ;; diamonds
  OPLOT,v_c_perp,dfpers,COLOR=blue[0],PSYM=5  ;; triangles
  ;; => Overplot lines [if MODEL not set]
  IF ~KEYWORD_SET(mode) THEN BEGIN
    OPLOT,v_c_para,dfpars,COLOR=red[0], LINESTYLE=0
    OPLOT,v_c_perp,dfpers,COLOR=blue[0],LINESTYLE=2
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;; => Determine where to put labels
  ;;--------------------------------------------------------------------------------------
  fmin       = yra_cut[0]
  xyposi     = [-1d0*4e-1*vlim[0],fmin[0]*4e0]
  ;; => Output label for para
  XYOUTS,xyposi[0],xyposi[1],dia_str[0]+' : Parallel Cut',/DATA,COLOR=red[0]
  ;; => Shift in negative Y-Direction
  xyposi[1] *= 0.7
  ;; => Output label for perp
  XYOUTS,xyposi[0],xyposi[1],tri_str[0]+' : Perpendicular Cut',COLOR=blue[0],/DATA
  ;; => Reset font to old settings
  ;;--------------------------------------------------------------------------------------
  ;; => Plot vertical lines for circle of constant speed if desired
  ;;--------------------------------------------------------------------------------------
  IF KEYWORD_SET(vcirc) THEN BEGIN
    FOR j=0L, ncirc - 1L DO BEGIN
      OPLOT,[vc_lx[j],vc_lx[j]],yra_cut,LINESTYLE=2,THICK=l_thick[0]
      OPLOT,[vc_xx[j],vc_xx[j]],yra_cut,LINESTYLE=2,THICK=l_thick[0]
    ENDFOR
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;; => Check for Model Fits
  ;;--------------------------------------------------------------------------------------
  IF KEYWORD_SET(mode) THEN BEGIN
    ;; => Overplot model fit results
    OPLOT,vpara_mod,dfpar_mod,LINESTYLE=3,COLOR=orange[0],THICK=l_thick[0]*0.75d0
    OPLOT,vperp_mod,dfper_mod,LINESTYLE=3,COLOR=cyan[0],THICK=l_thick[0]*0.75d0
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;; => Define plot structure to return to calling routine
  ;;--------------------------------------------------------------------------------------
  xydp_cut = {X:!X,Y:!Y,P:!P,D:!D}
;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;;--------------------------------------------------------
;; => Output SC Potential [eV]
;;--------------------------------------------------------
chsz           = 0.80
yposi          = 0.20
xposi          = 0.26
XYOUTS,xposi[0],yposi[0],sc_pot_str[0],/NORMAL,ORIENTATION=90,CHARSIZE=chsz[0],COLOR=purple[0]
;;--------------------------------------------------------
;; => Output SW Velocity [km/s]
;;--------------------------------------------------------
xposi         += 0.02
XYOUTS,xposi[0],yposi[0],v__out_str[0],/NORMAL,ORIENTATION=90,CHARSIZE=chsz[0],COLOR=purple[0]
;;--------------------------------------------------------
;; => Output Magnetic Field Vector [nT]  {at start of DF}
;;--------------------------------------------------------
xposi         += 0.02
XYOUTS,xposi[0],yposi[0],b__out_str[0],/NORMAL,ORIENTATION=90,CHARSIZE=chsz[0],COLOR=purple[0]
;;--------------------------------------------------------
;;  Output MODEL labels
;;--------------------------------------------------------
IF KEYWORD_SET(mode) THEN BEGIN
  xposi         += 0.02
  XYOUTS,xposi[0],yposi[0],'Para. bi-Maxwellian Fit',/NORMAL,ORIENTATION=90,$
         CHARSIZE=chsz[0],COLOR=orange[0]
  xposi         += 0.02
  XYOUTS,xposi[0],yposi[0],'Perp. bi-Maxwellian Fit',/NORMAL,ORIENTATION=90,$
         CHARSIZE=chsz[0],COLOR=cyan[0]
ENDIF
;;--------------------------------------------------------
;; => Output version # and date produced
;;--------------------------------------------------------
XYOUTS,0.795,0.06,vers[0],CHARSIZE=.65,/NORMAL,ORIENTATION=90.
;;----------------------------------------------------------------------------------------
;; => Return to user
;;----------------------------------------------------------------------------------------

RETURN
END
