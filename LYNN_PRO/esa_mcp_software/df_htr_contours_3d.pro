;+
;*****************************************************************************************
;
;  FUNCTION :   df_htr_contours_3d.pro
;  PURPOSE  :   Produces a contour plot of the distribution function (DF) with parallel
;                 and perpendicular cuts shown for each projection.  The plot on the left
;                 shows the plane containing the vectors associated with the VSW IDL
;                 structure tag and the HTR MFI B-field, B_h.  The plot on the right
;                 contains the vector associated with B_h and the vector orthogonal to
;                 the plane on the left (e.g. - Vsw x Bo).
;
;  CALLED BY:   
;               
;
;  CALLS:
;               test_3dp_struc_format.pro
;               dat_3dp_str_names.pro
;               tplot_struct_format_test.pro
;               read_wind_spinphase.pro
;               interp.pro
;               trans_vframe_htr.pro
;               extract_tags.pro
;               str_element.pro
;               df_2_contours_plot.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT        :  3DP data structure either from get_??.pro
;                               with defined structure tag quantities for VSW and
;                               MAGF
;               BGSE_HTR   :  HTR B-field structure of format:
;                               {X:Unix Times, Y:[K,3]-Element Vector}
;
;  EXAMPLES:    
;               
;
;  KEYWORDS:    
;               VLIM       :  Limit for x-y velocity axes over which to plot data
;                               [Default = max vel. from energy bin values]
;               NGRID      :  # of isotropic velocity grids to use to triangulate the data
;                               [Default = 30L]
;               BNAME      :  Scalar string defining the name of vector associated with
;                               the MAGF IDL structure tag in DAT
;                               [Default = 'Bo']
;               VNAME      :  Scalar string defining the name of vector associated with
;                               the VSW IDL structure tag in DAT
;                               [Default = 'Vsw']
;               SM_CUTS    :  If set, program plots the smoothed cuts of the DF
;                               [Note:  Smoothed to the minimum # of points]
;               NSMOOTH    :  Scalar # of points over which to smooth the DF
;                               [Default = 3]
;               ONE_C      :  If set, program makes a copy of the input array, redefines
;                               the data points equal to 1.0, and then calculates the 
;                               parallel cut and overplots it as the One Count Level
;               DFRA       :  2-Element array specifying a DF range (s^3/km^3/cm^3) for the
;                               cuts of the contour plot
;               VCIRC      :  Scalar or array defining the value(s) to plot as a
;                               circle(s) of constant speed [km/s] on the contour
;                               plot [e.g. gyrospeed of specularly reflected ion]
;               EX_VEC0    :  3-Element unit vector for another quantity like heat flux or 
;                               a wave vector
;               EX_VN0     :  A string name associated with EX_VEC0
;                               [Default = 'Vec 1']
;               EX_VEC1    :  3-Element unit vector for another quantity like heat flux or 
;                               a wave vector
;               EX_VN1     :  A string name associated with EX_VEC1
;                               [Default = 'Vec 2']
;               NOKILL_PH  :  If set, data_velocity_transform.pro will not call
;                               pesa_high_bad_bins.pro
;               NO_REDF    :  If set, program will plot only cuts of the distribution,
;                               not quasi-reduced distributions
;                               [Default:  program plots quasi-reduced distributions]
;               SPIN_R     :  Scalar defining the spacecraft spin rate [deg/s]
;
;   CHANGED:  1)  Now removes energies < 1.3 * (SC Pot)            [02/22/2012   v1.1.0]
;
;   NOTES:      
;               1)  HTR = High Time Resolution
;               2)  MFI = Magnetic Field Investigation
;               3)  This routine is only verified for EESA Low so far!!!
;               4)  Make sure that the structure tags MAGF and VSW have finite
;                    values
;               5)  DAT does not need to be from the Wind 3DP experiment so long as it
;                    contains similar structure tags
;               6)  See also:
;                    eh_cont3d.pro and df_contours_3d.pro
;
;   CREATED:  02/01/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  02/22/2012   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO df_htr_contours_3d,dat,bgse_htr,VLIM=vlim,NGRID=ngrid,BNAME=bname,VNAME=vname, $
                       SM_CUTS=sm_cuts,NSMOOTH=nsmooth,ONE_C=one_c,DFRA=dfra,      $
                       VCIRC=vcirc,EX_VEC0=ex_vec0,EX_VN0=ex_vn0,EX_VEC1=ex_vec1,  $
                       EX_VN1=ex_vn1,NOKILL_PH=nokill_ph,NO_REDF=no_redf,          $
                       SPIN_R=spin_r

;-----------------------------------------------------------------------------------------
; => Define some constants and dummy variables
;-----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN

badinp_mssg    = 'Incorrect input format:  TIME_ANGS'
notstr_mssg    = 'Must be an IDL structure...'
nottplot_mssg  = 'Not an appropriate TPLOT structure...'
badstr_mssg    = 'Not an appropriate 3DP structure...'
notel_mssg     = 'This routine is only verified for EESA Low so far!!!'

dumbytr        = 'quasi-reduced df (sec!U3!N/km!U3!N/cm!U3!N)'
dumbytc        = 'cuts of df (sec!U3!N/km!U3!N/cm!U3!N)'
suffc          = [' Cut',' Reduced DF']
;-----------------------------------------------------------------------------------------
; => Check input
;-----------------------------------------------------------------------------------------
IF (N_PARAMS() LE 1) THEN RETURN
data  = dat[0]   ; => in case it is an array of structures of the same format

; => Check DAT structure format
test  = test_3dp_struc_format(data)
IF (NOT test) THEN BEGIN
  MESSAGE,notstr_mssg,/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF

; => Make sure we are looking at EESA Low only
strns   = dat_3dp_str_names(data[0])
shnme   = STRLOWCASE(STRMID(strns.SN[0],0L,2L))
IF (shnme[0] NE 'el') THEN BEGIN
  MESSAGE,notel_mssg,/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF

; => Check BGSE_HTR structure format
test  = tplot_struct_format_test(bgse_htr,/YVECT)
IF (NOT test) THEN BEGIN
  MESSAGE,nottplot_mssg,/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;-----------------------------------------------------------------------------------------
; => Check keywords
;-----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(ngrid) THEN ngrid = 30L ; => # of levels to use for contour.pro
IF NOT KEYWORD_SET(vlim) THEN BEGIN
  vlim = MAX(SQRT(2*data[0].ENERGY/data[0].MASS),/NAN)  ; => velocity limit (km/s)
ENDIF ELSE BEGIN
  vlim = FLOAT(vlim)  ; => velocity limit (km/s)
ENDELSE
;-----------------------------------------------------------------------------------------
; => Check for finite vectors in VSW and MAGF IDL structure tags
;-----------------------------------------------------------------------------------------
v_vsws   = REFORM(data[0].VSW)
v_magf   = REFORM(data[0].MAGF)
test_v   = TOTAL(FINITE(v_vsws)) NE 3
test_b   = TOTAL(FINITE(v_magf)) NE 3
; => If only test_v = TRUE, then use Sun Direction
IF (test_v) THEN BEGIN
  v_vsws     = [1.,0.,0.]
  data[0].VSW = v_vsws
  vname      = 'X!DGSE!N'
ENDIF

IF (test_b) THEN BEGIN
  errmsg = 'DAT must have finite values in VSW and MAGF tags!'
  MESSAGE,errmsg[0],/INFORMATION,/CONTINUE
  !P.MULTI = 0
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA
  RETURN
ENDIF

IF NOT KEYWORD_SET(bname) THEN bname = 'B!Do!N' ELSE bname = bname[0]
IF NOT KEYWORD_SET(vname) THEN vname = 'V!Dsw!N' ELSE vname = vname[0]
;;########################################################################################
;; => Define version for output
;;########################################################################################
mdir     = FILE_EXPAND_PATH('wind_3dp_pros/LYNN_PRO/')+'/'
file     = FILE_SEARCH(mdir,'df_htr_contours_3d.pro')
fstring  = read_gen_ascii(file[0])
test     = STRPOS(fstring,';    LAST MODIFIED:  ') GE 0
gposi    = WHERE(test,gpf)
shifts   = STRLEN(';    LAST MODIFIED:  ')
vers     = STRMID(fstring[gposi[0]],shifts[0])
vers0    = 'df_htr_contours_3d.pro : '+vers[0]+', '
;-----------------------------------------------------------------------------------------
; => Determine spacecraft spin rate
;-----------------------------------------------------------------------------------------
IF (N_ELEMENTS(spin_r) NE 1) THEN BEGIN
  t0       = data.TIME[0]
  t1       = data.END_TIME[0]
  tr3      = [t0[0],t1[0]] + [-6d1,6d1]
  wi_spin  = read_wind_spinphase(TRANGE=tr3)
  wi_spru  = wi_spin.UNIX         ; => Unix times
  wi_sprd  = wi_spin.SPIN_RATE_D  ; => Wind spin rate [deg/s]
  sprated  = interp(wi_sprd,wi_spru,t0[0],INDEX=ind)
  sprated  = wi_sprd[ind]
ENDIF ELSE BEGIN
  sprated  = spin_r[0]
ENDELSE
;-----------------------------------------------------------------------------------------
; => Convert to solar wind frame in field-aligned coordinates
;-----------------------------------------------------------------------------------------
trans_vframe_htr,data,bgse_htr,sprated[0],VLIM=vlim,NGRID=ngrid
; => Define triangulated DFs
plane1   = data.NEW_DFS.PLANE_1         ; => Plane defined by Bo and Vsw
plane2   = data.NEW_DFS.PLANE_2         ; => Plane defined by Bo and Esw
;-----------------------------------------------------------------------------------------
; => Calculate cuts or quasi-reduced DFs
;-----------------------------------------------------------------------------------------
df2d1    = plane1.DF2D
df2d2    = plane2.DF2D
IF KEYWORD_SET(no_redf) THEN BEGIN
  ndf     = (SIZE(df2d1,/DIMENSIONS))[0]/2L + 1L
  ; => Calculate Cuts of DFs
  dfpar_1 = REFORM(df2d1[*,ndf[0]])                                   ; => Para. Cut of DF
  dfper_1 = REFORM(df2d1[ndf[0],*])                                   ; => Perp. Cut of DF
  dfpar_2 = REFORM(df2d2[*,ndf[0]])                                   ; => Para. Cut of DF
  dfper_2 = REFORM(df2d2[ndf[0],*])                                   ; => Perp. Cut of DF
ENDIF ELSE BEGIN
  ; => Calculate Quasi-Reduced DFs
  dfpar_1 = TOTAL(df2d1,2L,/NAN)/SQRT(TOTAL(FINITE(df2d1),2L,/NAN))   ; => Para. Cut of DF
  dfper_1 = TOTAL(df2d1,1L,/NAN)/SQRT(TOTAL(FINITE(df2d1),1L,/NAN))   ; => Perp. Cut of DF
  dfpar_2 = TOTAL(df2d2,2L,/NAN)/SQRT(TOTAL(FINITE(df2d2),2L,/NAN))   ; => Para. Cut of DF
  dfper_2 = TOTAL(df2d2,1L,/NAN)/SQRT(TOTAL(FINITE(df2d2),1L,/NAN))   ; => Perp. Cut of DF
ENDELSE
;-----------------------------------------------------------------------------------------
; => Smooth the data
;-----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(nsmooth) THEN ns = 3 ELSE ns = LONG(nsmooth)

df2ds_1 = SMOOTH(df2d1,ns[0],/EDGE_TRUNCATE,/NAN)
df2ds_2 = SMOOTH(df2d2,ns[0],/EDGE_TRUNCATE,/NAN)
badsm   = WHERE(df2ds_1 LE 0d0,bdsm)
IF (bdsm GT 0L) THEN BEGIN
  bind  = ARRAY_INDICES(df2ds_1,badsm)
  df2ds_1[bind[0,*],bind[1,*]] = d
ENDIF
badsm   = WHERE(df2ds_2 LE 0d0,bdsm)
IF (bdsm GT 0L) THEN BEGIN
  bind  = ARRAY_INDICES(df2ds_2,badsm)
  df2ds_2[bind[0,*],bind[1,*]] = d
ENDIF
;-----------------------------------------------------------------------------------------
; => Put structure tags into 2 new structures
;-----------------------------------------------------------------------------------------
tad1  = data[0]
tad2  = data[0]

extract_tags,tad1,plane1
str_element,tad1,'DF_SMOOTH',df2ds_1,/ADD_REPLACE
str_element,tad1,'DF_PARA',dfpar_1,/ADD_REPLACE
str_element,tad1,'DF_PERP',dfper_1,/ADD_REPLACE

extract_tags,tad2,plane2
str_element,tad2,'DF_SMOOTH',df2ds_2,/ADD_REPLACE
str_element,tad2,'DF_PARA',dfpar_2,/ADD_REPLACE
str_element,tad2,'DF_PERP',dfper_2,/ADD_REPLACE
;-----------------------------------------------------------------------------------------
; => Plot data
;-----------------------------------------------------------------------------------------
df_2_contours_plot,tad1,tad2,VLIM=vlim,NGRID=ngrid,BNAME=bname,VNAME=vname,    $
                   SM_CUTS=sm_cuts,NSMOOTH=nsmooth,ONE_C=one_c,DFRA=dfra,      $
                   VCIRC=vcirc,EX_VEC0=ex_vec0,EX_VN0=ex_vn0,EX_VEC1=ex_vec1,  $
                   EX_VN1=ex_vn1,NOKILL_PH=nokill_ph,NO_REDF=no_redf,          $
                   VERSION=vers0
;-----------------------------------------------------------------------------------------
; => Return
;-----------------------------------------------------------------------------------------
!P.MULTI = 0

RETURN
END