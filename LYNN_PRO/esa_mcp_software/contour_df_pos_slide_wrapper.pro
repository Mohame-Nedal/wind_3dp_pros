;+
;*****************************************************************************************
;
;  FUNCTION :   format_timeseries_for_contour.pro
;  PURPOSE  :   This routine formats the timeseries input so that it can be used by
;                 the routine, contour_df_pos_slide_plot.pro.
;
;  CALLED BY:   
;               contour_df_pos_slide_wrapper.pro
;
;  CALLS:
;               tnames.pro
;               get_data.pro
;               str_element.pro
;               time_range_define.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               TIMENAME    :  [2]-Element array of TPLOT handles to plot below the
;                                3 DFs shown on top
;
;  EXAMPLES:    
;               
;
;  KEYWORDS:    
;               TRANGE      :  [2]-Element array specifying the outer range of the
;                                timeseries to plot [Unix time]
;               FILE_PREF   :  Set to a named variable to return the file name prefix
;                                associated with the TPLOT handles in TIMENAME
;               TRA_OUT     :  Set to a named variable to return the time range
;                                determined by time_range_define.pro
;               TSNAMES     :  Scalar string specifying the file prefix to be used for
;                                the two timeseries' associated with TIMENAME
;
;   CHANGED:  1)  NA [MM/DD/YYYY   v1.0.0]
;
;   NOTES:      
;               
;
;   CREATED:  04/05/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  04/05/2012   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION format_timeseries_for_contour,timename,TRANGE=trange,FILE_PREF=ts_pref,$
                                       TRA_OUT=tra_out,TSNAMES=tsnames

;-----------------------------------------------------------------------------------------
; => Define some constants and dummy variables
;-----------------------------------------------------------------------------------------
f          = !VALUES.F_NAN
d          = !VALUES.D_NAN
; => Dummy error messages
noinpt_msg = 'No input supplied...'
notstr_msg = 'Must be a [2]-element string array...'
nofint_msg = 'No finite data...'
nottpn_msg = 'Not valid TPLOT handles'
;-----------------------------------------------------------------------------------------
; => Check TIMENAME
;-----------------------------------------------------------------------------------------
IF (SIZE(timename,/TYPE) NE 7 OR N_ELEMENTS(timename) NE 2) THEN BEGIN
  MESSAGE,notstr_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
check      = tnames(REFORM(timename))
bad        = TOTAL(check EQ '') GT 0
IF (bad) THEN BEGIN
  ; => no input???
  MESSAGE,nottpn_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;-----------------------------------------------------------------------------------------
; => Get time series and format structure
;-----------------------------------------------------------------------------------------
t_name     = REFORM(timename)
get_data,t_name[0],DATA=tp_name0,DLIMITS_STR=dlim_0,LIMITS_STR=lim_0
get_data,t_name[1],DATA=tp_name1,DLIMITS_STR=dlim_1,LIMITS_STR=lim_1

dat0       = tp_name0
szy0       = SIZE(dat0.Y,/N_DIMENSIONS)
str_element,dlim_0,'YTITLE',yttl0
IF (N_ELEMENTS(yttl0) EQ 0) THEN str_element,lim_0,'YTITLE',yttl0
IF (N_ELEMENTS(yttl0) EQ 0) THEN yttl0 = 'Data 1'
;  LBW III  04/05/2012   v1.1.1
str_element,dlim_0,'YSUBTITLE',ysub0
IF (N_ELEMENTS(ysub0) EQ 0) THEN str_element,lim_0,'YSUBTITLE',ysub0
IF (N_ELEMENTS(ysub0) EQ 0) THEN ysub0 = ''
yttle0     = yttl0[0]+'!C'+ysub0[0]
str_element,dat0,'LIM',{YTITLE:yttle0[0],YSTYLE:1,XSTYLE:1,XMINOR:5},/ADD_REPLACE

dat1       = tp_name1
szy1       = SIZE(dat1.Y,/N_DIMENSIONS)
str_element,dlim_1,'YTITLE',yttl1
IF (N_ELEMENTS(yttl1) EQ 0) THEN str_element,lim_1,'YTITLE',yttl1
IF (N_ELEMENTS(yttl1) EQ 0) THEN yttl1 = 'Data 1'
;  LBW III  04/05/2012   v1.1.1
str_element,dlim_1,'YSUBTITLE',ysub1
IF (N_ELEMENTS(ysub1) EQ 0) THEN str_element,lim_1,'YSUBTITLE',ysub1
IF (N_ELEMENTS(ysub1) EQ 0) THEN ysub1 = ''
yttle1     = yttl1[0]+'!C'+ysub1[0]
str_element,dat1,'LIM',{YTITLE:yttle1[0],YSTYLE:1,XSTYLE:1,XMINOR:5},/ADD_REPLACE
;-----------------------------------------------------------------------------------------
; => Determine time range of interest
;-----------------------------------------------------------------------------------------
all_time   = [dat0.X,dat1.X]
out_tra    = [MIN(all_time,/NAN),MAX(all_time,/NAN)] + [-6d1,6d1]
IF ~KEYWORD_SET(trange) THEN tra_out = out_tra ELSE tra_out = trange
time_ra    = time_range_define(TRANGE=tra_out)
tra_out    = time_ra.TR_UNIX

good_0     = WHERE(dat0.X GE tra_out[0] AND dat0.X LE tra_out[1],gd0)
good_1     = WHERE(dat1.X GE tra_out[0] AND dat1.X LE tra_out[1],gd1)
IF (gd0 EQ 0 OR gd1 EQ 0) THEN BEGIN
  badtra = 'No TPLOT data within desired time range...'
  MESSAGE,badtra[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF ELSE BEGIN
  ; => Redefine time series data
  ;---------------------------------------------------------------------------------------
  ; 1st time series of data
  ;---------------------------------------------------------------------------------------
  str_element,dat0,'X',dat0.X[good_0],/ADD_REPLACE
  IF (szy0 EQ 1) THEN data_y0 = dat0.Y[good_0]
  IF (szy0 EQ 2) THEN data_y0 = dat0.Y[good_0,*]
  IF (szy0 EQ 3) THEN data_y0 = dat0.Y[good_0,*,*]
  str_element,dat0,'Y',data_y0,/ADD_REPLACE
  ; => yranges
  ymax  = MAX(ABS(data_y0),/NAN)*1.05
  neg   = TOTAL(WHERE(data_y0 LT 0)) GT 0
  IF (neg) THEN BEGIN
    ; => data is both +/-
    yra   = [-1d0,1d0]*ymax[0]
  ENDIF ELSE BEGIN
    ; => data is + only
    ymin  = MIN(ABS(data_y0),/NAN)*0.95
    yra   = [ymin[0],ymax[0]]
  ENDELSE
  str_element,dat0,'LIM.YRANGE',yra,/ADD_REPLACE
  ;---------------------------------------------------------------------------------------
  ; 2nd time series of data
  ;---------------------------------------------------------------------------------------
  str_element,dat1,'X',dat1.X[good_1],/ADD_REPLACE
  IF (szy1 EQ 1) THEN data_y1 = dat1.Y[good_1]
  IF (szy1 EQ 2) THEN data_y1 = dat1.Y[good_1,*]
  IF (szy1 EQ 3) THEN data_y1 = dat1.Y[good_1,*,*]
  str_element,dat1,'Y',data_y1,/ADD_REPLACE
  ; => yranges
  ymax  = MAX(ABS(data_y1),/NAN)*1.05
  neg   = TOTAL(WHERE(data_y1 LT 0)) GT 0
  IF (neg) THEN BEGIN
    ; => data is both +/-
    yra   = [-1d0,1d0]*ymax[0]
  ENDIF ELSE BEGIN
    ; => data is + only
    ymin  = MIN(ABS(data_y1),/NAN)*0.95
    yra   = [ymin[0],ymax[0]]
  ENDELSE
  str_element,dat1,'LIM.YRANGE',yra,/ADD_REPLACE
ENDELSE
; => Define TIMESERIES input for contour_df_pos_slide_plot.pro
timeseries = {T0:dat0,T1:dat1}
;-----------------------------------------------------------------------------------------
; => Determine file name prefix for time series
;-----------------------------------------------------------------------------------------
dumb_pr    = t_name[0]+'_'+t_name[1]+'_'
IF ~KEYWORD_SET(tsnames) THEN BEGIN
  ; => No prefix given, use default
  ts_pref = dumb_pr[0]
ENDIF ELSE BEGIN
  IF (SIZE(tsnames,/TYPE) NE 7) THEN ts_pref = dumb_pr[0] ELSE ts_pref = tsnames[0]
ENDELSE


RETURN,timeseries
END


;+
;*****************************************************************************************
;
;  FUNCTION :   format_df_for_contour.pro
;  PURPOSE  :   This routine formats the particle distribution input so that they
;                 can be used by the routine, contour_df_pos_slide_plot.pro.
;
;  CALLED BY:   
;               contour_df_pos_slide_wrapper.pro
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               pesa_high_bad_bins.pro
;               convert_ph_units.pro
;               conv_units.pro
;               dat_themis_esa_str_names.pro
;               modify_themis_esa_struc.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT         :  [M]-Element array of particle distributions from either
;                                Wind/3DP or THEMIS ESA
;
;  EXAMPLES:    
;               
;
;  KEYWORDS:    
;               NOKILL_PH   :  If set, program will not call pesa_high_bad_bins.pro for
;                                PESA High structures to remove "bad" data bins
;                                [Default = 0]
;               FILE_PREF   :  Set to a named variable to return the file name prefix
;                                associated with the particle distributions in DAT
;               
;
;   CHANGED:  1)  NA [MM/DD/YYYY   v1.0.0]
;
;   NOTES:      
;               
;
;   CREATED:  04/05/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  04/05/2012   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION format_df_for_contour,dat,NOKILL_PH=nokill_ph,FILE_PREF=fpref

;-----------------------------------------------------------------------------------------
; => Define some constants and dummy variables
;-----------------------------------------------------------------------------------------
f          = !VALUES.F_NAN
d          = !VALUES.D_NAN
; => Dummy error messages
noinpt_msg = 'No input supplied...'
notstr_msg = 'Must be a [2]-element string array...'
nofint_msg = 'No finite data...'
nottpn_msg = 'Not valid TPLOT handles'
notidl_msg = 'DAT must be an array of IDL structures...'
;-----------------------------------------------------------------------------------------
; => Check DAT structure format
;-----------------------------------------------------------------------------------------
test0      = test_wind_vs_themis_esa_struct(dat,/NOM)
test       = (test0.(0) + test0.(1)) NE 1
IF (test) THEN BEGIN
  MESSAGE,notidl_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;-----------------------------------------------------------------------------------------
; => Check which spacecraft is being used
;-----------------------------------------------------------------------------------------
data       = dat
IF (test0.(0)) THEN BEGIN
  ;---------------------------------------------------------------------------------------
  ; Wind
  ;---------------------------------------------------------------------------------------
  ; => Check which instrument is being used
  strns   = dat_3dp_str_names(data[0])
  IF (SIZE(strns,/TYPE) NE 8) THEN BEGIN
    RETURN,0
  ENDIF
  s_name  = strns.SN[0]  ; e.g. 'phb'
  shnme   = STRLOWCASE(STRMID(s_name[0],0L,2L))
  itype   = STRLOWCASE(STRMID(s_name[0],0L,1L))
  prsfx   = (['_','_Burst_'])[STRLEN(s_name[0]) EQ 3]
  lhfo_t  = WHERE(STRLOWCASE(STRMID(s_name[0],1L,1L)) EQ ['l','h','f','o'])
  CASE itype[0] OF
    'p'  : BEGIN
      ; => PESA
      IF (lhfo_t[0] EQ 1) THEN BEGIN
        ; => PESA High
        IF NOT KEYWORD_SET(nokill_ph) THEN BEGIN
          pesa_high_bad_bins,data
        ENDIF
        ; => convert to 'df' units
        convert_ph_units,data,'df'
      ENDIF ELSE BEGIN
        ; => PESA Low
        ;    => Not OK, so return
        badmssg = 'Cannot plot contours for PESA Low due to low FOV...'
        MESSAGE,badmssg[0],/INFORMATIONAL,/CONTINUE
        RETURN,0
      ENDELSE
      ; => Define file prefix
      fpref = 'PESA_High'+prsfx[0]
    END
    'e'  : BEGIN
      ; => EESA
      IF (lhfo_t[0] EQ 1) THEN BEGIN
        ; => EESA High
        fpref = 'EESA_High'+prsfx[0]
      ENDIF ELSE BEGIN
        ; => EESA Low
        fpref = 'EESA_Low'+prsfx[0]
      ENDELSE
      ; => convert to 'df' units
      data  = conv_units(data,'df')
    END
    ELSE : BEGIN
      ; => SST
      badmssg = 'Cannot plot contours for Wind SST yet...'
      MESSAGE,badmssg[0],/INFORMATIONAL,/CONTINUE
      RETURN,0
    END
  ENDCASE
  ; => Add Spacecraft name onto file name
  fpref = fpref[0]+'Wind_'
ENDIF ELSE BEGIN
  ;---------------------------------------------------------------------------------------
  ; THEMIS
  ;---------------------------------------------------------------------------------------
  strns = dat_themis_esa_str_names(data[0])
  IF (SIZE(strns,/TYPE) NE 8) THEN BEGIN
    RETURN,0
  ENDIF
  s_name  = strns.SN[0]  ; e.g. 'peir'
  type_sf = ['Full','Reduced','Burst']
  shnme   = STRLOWCASE(STRMID(s_name[0],1L,2L))
  stype   = WHERE(STRLOWCASE(STRMID(s_name[0],3L)) EQ ['f','r','b'])
  CASE shnme[0] OF
    'ee' : BEGIN
      fpref = 'EESA_'+type_sf[stype[0]]+'_TH-'
    END
    'ei' : BEGIN
      fpref = 'IESA_'+type_sf[stype[0]]+'_TH-'
    END
    ELSE : BEGIN
      badmssg = 'Cannot plot contours for THEMIS SST yet...'
      MESSAGE,badmssg[0],/INFORMATIONAL,/CONTINUE
      RETURN,0
    END
  ENDCASE
  fpref   = fpref[0]+data[0].SPACECRAFT[0]+'_'
  ; => make sure the structure has been modified
  test_un = STRLOWCASE(data[0].UNITS_PROCEDURE) NE 'thm_convert_esa_units_lbwiii'
  IF (test_un) THEN BEGIN
    bad_in = 'If THEMIS ESA structures used, then they must be modified using modify_themis_esa_struc.pro'
    MESSAGE,bad_in[0],/INFORMATIONAL,/CONTINUE
    ; => Modify THEMIS structures
    modify_themis_esa_struc,data
  ENDIF
  ; => structure modified appropriately so convert units
  data  = conv_units(data,'df')
ENDELSE
;-----------------------------------------------------------------------------------------
; => Return
;-----------------------------------------------------------------------------------------

RETURN,data
END


;+
;*****************************************************************************************
;
;  PROCEDURE:   contour_df_pos_slide_ffmpeg.pro
;  PURPOSE  :   Creates a movie from a series of snapshots using ffmpeg.
;
;  CALLED BY:   
;               contour_df_pos_slide_wrapper.pro
;
;  CALLS:
;               time_string.pro
;               str_element.pro
;               contour_df_pos_slide_plot.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               TIMESERIES  :  [N]-Element array of data structures, each with a
;                                tag = 'Tj', where j = 0,1,...,N-1 and inside each of
;                                these structures is another structure with the
;                                following format:
;                                    X    :  Unix time stamps
;                                    Y    :  [N,3]- or [N]-Element array of data
;                                    LIM  :  Structure containing relevant plot
;                                              information and tags consistent with
;                                              those accepted by PLOT.PRO
;               DAT         :  [M]-Element array of particle distributions from either
;                                Wind/3DP or THEMIS ESA
;
;  EXAMPLES:    
;               
;
;  KEYWORDS:    
;               VLIM        :  Limit for x-y velocity axes over which to plot data
;                                [Default = max vel. from energy bin values]
;               NGRID       :  # of isotropic velocity grids to use to triangulate the
;                                data [Default = 30L]
;               XNAME       :  Scalar string defining the name of vector associated
;                                with the VECTOR1 keyword
;                                [Default = 'X']
;               YNAME       :  Scalar string defining the name of vector associated with
;                                the VECTOR2 keyword
;                                [Default = 'Y']
;               DFRA        :  2-Element array specifying a DF range (s^3/km^3/cm^3)
;                                for the cuts of the contour plot
;                                [Default = defined by range of data]
;               VCIRC       :  Scalar or array defining the value(s) to plot as a
;                                circle(s) of constant speed [km/s] on the contour
;                                plot [e.g. gyrospeed of specularly reflected ion]
;               EX_VEC0     :  3-Element unit vector for a quantity like heat flux or
;                                a wave vector, etc.
;               EX_VN0      :  A string name associated with EX_VEC0
;                                [Default = 'Vec 1']
;               EX_VEC1     :  3-Element unit vector for another quantity like the sun
;                                direction or shock normal vector vector, etc.
;               EX_VN1      :  A string name associated with EX_VEC1
;                                [Default = 'Vec 2']
;               NOKILL_PH   :  If set, program will not call pesa_high_bad_bins.pro for
;                                PESA High structures to remove "bad" data bins
;                                [Default = 0]
;               PLANE       :  Scalar string defining the plane projection to plot with
;                                corresponding cuts [Let V1 = VECTOR1, V2 = VECTOR2]
;                                  'xy'  :  horizontal axis parallel to V1 and normal
;                                             vector to plane defined by (V1 x V2)
;                                             [default]
;                                  'xz'  :  horizontal axis parallel to (V1 x V2) and
;                                             vertical axis parallel to V1
;                                  'yz'  :  horizontal axis defined by (V1 x V2) x V1
;                                             and vertical axis (V1 x V2)
;               NO_TRANS    :  If set, routine will not transform data into SW frame
;                                [Default = 0 (i.e. DAT transformed into SW frame)]
;               INTERP      :  If set, data is interpolated to original energy estimates
;                                after transforming into new reference frame
;               SM_CONT     :  If set, program plots the smoothed contours of DF
;                                [Note:  Smoothed to the minimum # of points]
;               DFMIN       :  Scalar defining the minimum allowable phase space density
;                                to plot, which is useful for ion distributions with
;                                large angular gaps in data
;                                [prevents lower bound from falling below DFMIN]
;               DFMAX       :  Scalar defining the maximum allowable phase space density
;                                to plot, which is useful for distributions with data
;                                spikes
;                                [prevents upper bound from exceeding DFMAX]
;               TRANGE      :  [2]-Element array specifying the range of the time-
;                                series to plot [Unix time]
;               MOVIENAME   :  Scalar string defining the name to use when saving the
;                                movie file
;               FRAMERATE   :  Scaler value defining the frame rate of output movie
;                                [Default = 25]
;               KEEP_SNAPS  :  If set, routine will not delete image directory full of
;                                PNG files created by this routine
;                                [Default = 0]
;               TROUTER     :  Scalar defining the amount of time [s] on either side of
;                                the 3 DFs shown in the center of the plot
;                                [Default = 21.0 (also minimum allowed)]
;               VERSION     :  Scalar string defining the name and version of the
;                                ploting routine called in this routine
;               VECTOR1     :  [M,3]-Element vector to be used for horizontal axis in
;                                a 2D-projected contour plot [e.g. see eh_cont3d.pro]
;                                [Default = dat.MAGF]
;               VECTOR2     :  [M,3]-Element vector to be used to define the plane made
;                                with VECTOR1  [Default = dat.VSW]
;
;   CHANGED:  1)  Added "-f mov" syntax to ffmpeg call which forces the output file
;                   format to a QuickTime movie
;                                                                   [04/21/2012   v1.1.0]
;
;   NOTES:      
;               
;
;   CREATED:  04/05/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  04/21/2012   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO contour_df_pos_slide_ffmpeg,timeseries,dat,VLIM=vlim,NGRID=ngrid,XNAME=xname,      $
                                YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,     $
                                EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,           $
                                NOKILL_PH=nokill_ph,PLANE=plane,NO_TRANS=no_trans,     $
                                INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax,$
                                TRANGE=trange,MOVIENAME=moviename,FRAMERATE=framerate, $
                                KEEP_SNAPS=keep_sn,TROUTER=trouter,VERSION=version,$
                                VECTOR1=vector1,VECTOR2=vector2

;-----------------------------------------------------------------------------------------
; => Define some constants and dummy variables
;-----------------------------------------------------------------------------------------
;;  define a dummy image directory
imgdir = 'movie_'+STRCOMPRESS(STRING(RANDOMU(SYSTIME(1),/LONG)),/REMOVE_ALL)
;;  create temporary directory
SPAWN,'mkdir '+imgdir[0]

trout_min  = 21d0
IF ~KEYWORD_SET(trouter)   THEN trout = trout_min[0] ELSE trout = trouter[0] > trout_min[0]
IF ~KEYWORD_SET(moviename) THEN movienm = imgdir[0]+'.mov' ELSE movienm = moviename[0]
;-----------------------------------------------------------------------------------------
; => Define values related to particle distributions
;-----------------------------------------------------------------------------------------
data          = dat
ndat          = N_ELEMENTS(data)
nsub          = ndat - 2L          ;  # of subintervals
i0            = LINDGEN(nsub)
i1            = i0 + 1L
i2            = i1 + 1L
dat_i0        = data[i0]
dat_i1        = data[i1]
dat_i2        = data[i2]
;;  define sub-interval vectors
vec1_0        = vector1[i0,*]
vec1_1        = vector1[i1,*]
vec1_2        = vector1[i2,*]
vec2_0        = vector2[i0,*]
vec2_1        = vector2[i1,*]
vec2_2        = vector2[i2,*]

tsub_tra      = DBLARR(nsub,2L)
tsub_tra[*,0] = dat_i0.TIME[0] - trout[0]
tsub_tra[*,1] = dat_i2.END_TIME[0] + trout[0]
;-----------------------------------------------------------------------------------------
; => Plot DFs
;-----------------------------------------------------------------------------------------
j          = 0L
cc         = 0L
test       = 1
WHILE (test) DO BEGIN
  timeser = timeseries
  dat_df  = [dat_i0[j],dat_i1[j],dat_i2[j]]
  vec1    = [vec1_0[j,*],vec1_1[j,*],vec1_2[j,*]]
  vec2    = [vec2_0[j,*],vec2_1[j,*],vec2_2[j,*]]
  tra     = REFORM(tsub_tra[j,*])
  ;---------------------------------------------------------------------------------------
  ; => Define time ticks so they do not move in window
  ;---------------------------------------------------------------------------------------
  nn      = 5L
  xtv     = DBLARR(nn)
  xtn     = STRARR(nn)
  xts     = nn - 1L   ; want 5 tick marks
  ; => determine width of window
  difft   = ABS(tra[1] - tra[0])
  t_intv  = difft[0]/xts[0]  ;  tick interval
  FOR ii=0L, 3L DO xtv[ii] = tra[0] + t_intv[0]*ii
  xtv[nn - 1L]  = tra[1]
  ; => determine tick names
  tnme0   = time_string(xtv,PREC=3)
  xtn     = STRMID(tnme0[*],0L,10L)+'!C'+STRMID(tnme0[*],11L)
  ;---------------------------------------------------------------------------------------
  ; => Add these to limits structures
  ;---------------------------------------------------------------------------------------
  str_element,timeser,'T0.LIM.XTICKNAME',xtn,/ADD_REPLACE
  str_element,timeser,'T0.LIM.XTICKV'   ,xtv,/ADD_REPLACE
  str_element,timeser,'T0.LIM.XTICKS'   ,xts,/ADD_REPLACE
  str_element,timeser,'T1.LIM.XTICKNAME',xtn,/ADD_REPLACE
  str_element,timeser,'T1.LIM.XTICKV'   ,xtv,/ADD_REPLACE
  str_element,timeser,'T1.LIM.XTICKS'   ,xts,/ADD_REPLACE
  ; => Force X-RANGE and -STYLE
  str_element,timeser,'T0.LIM.XRANGE'   ,tra,/ADD_REPLACE
  str_element,timeser,'T0.LIM.XSTYLE'   , 1 ,/ADD_REPLACE
  str_element,timeser,'T1.LIM.XRANGE'   ,tra,/ADD_REPLACE
  str_element,timeser,'T1.LIM.XSTYLE'   , 1 ,/ADD_REPLACE
  ;---------------------------------------------------------------------------------
  ; => Plot data with contours
  ;---------------------------------------------------------------------------------
  contour_df_pos_slide_plot,timeser,dat_df,VLIM=vlim,NGRID=ngrid,XNAME=xname,       $
                            YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,      $
                            EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,            $
                            NOKILL_PH=nokill_ph,PLANE=plane,NO_TRANS=no_trans,      $
                            INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax, $
                            TRANGE=tra,VERSION=version,VECTOR1=vec1,VECTOR2=vec2
  ;;--------------------------------------------------------------------------------------
  ;; write image to png file
  ;;--------------------------------------------------------------------------------------
  stringcount   = STRING(j,FORMAT='(i4.4)')
  fname_0       = imgdir[0]+'/image_'+stringcount[0]+'.png'
  WRITE_PNG,fname_0[0],TVRD(/TRUE)
  ;; increment counters
  test          = (j LT nsub - 1L)
  IF (j MOD 10 EQ 0) THEN PRINT,'Frame # saved: ',j
  j            += test
ENDWHILE
;-----------------------------------------------------------------------------------
; => Encode, save, and close MPEG
;-----------------------------------------------------------------------------------
;  specify the frame rate
IF KEYWORD_SET(framerate) THEN frmra = LONG(framerate[0]) < 60L ELSE frmra = 25L
frm_str = STRING(FORMAT='(I2.2)',frmra[0])

PRINT,''
PRINT,'Encoding movie: '+movienm[0]
PRINT,''
;;  ffmpeg options
;;  -r 60   = 60 frames/s
;;  -f mov  = Force file format to QuickTime movie
;;  -i      = input file name
;;  %04d    = 0000, 0001, 0002, ... , nnnn
;;  -qscale = from 1 (best) to 31 (worst) quality
pref_encode    = 'ffmpeg -r '+frm_str[0]+' -i '+imgdir[0]
;;encode_command = pref_encode[0]+'/image_%04d.png -qscale 2 -f mov '+movienm[0]
encode_command = pref_encode[0]+'/image_%04d.png -qscale 2 '+movienm[0]
SPAWN,encode_command[0]
;-----------------------------------------------------------------------------------
; => Clean up images
;-----------------------------------------------------------------------------------
rmcommand = 'rm -rf '+imgdir[0]
IF ~KEYWORD_SET(keep_sn) THEN SPAWN,rmcommand
;-----------------------------------------------------------------------------------
; => Return
;-----------------------------------------------------------------------------------

RETURN
END


;+
;*****************************************************************************************
;
;  PROCEDURE:   contour_df_pos_slide_idlmpeg.pro
;  PURPOSE  :   Creates a movie from a series of snapshots using IDL's MPEG_* routines
;
;  CALLED BY:   
;               contour_df_pos_slide_wrapper.pro
;
;  CALLS:
;               time_string.pro
;               str_element.pro
;               contour_df_pos_slide_plot.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               TIMESERIES  :  [N]-Element array of data structures, each with a
;                                tag = 'Tj', where j = 0,1,...,N-1 and inside each of
;                                these structures is another structure with the
;                                following format:
;                                    X    :  Unix time stamps
;                                    Y    :  [N,3]- or [N]-Element array of data
;                                    LIM  :  Structure containing relevant plot
;                                              information and tags consistent with
;                                              those accepted by PLOT.PRO
;               DAT         :  [M]-Element array of particle distributions from either
;                                Wind/3DP or THEMIS ESA
;
;  EXAMPLES:    
;               
;
;  KEYWORDS:    
;               VLIM        :  Limit for x-y velocity axes over which to plot data
;                                [Default = max vel. from energy bin values]
;               NGRID       :  # of isotropic velocity grids to use to triangulate the
;                                data [Default = 30L]
;               XNAME       :  Scalar string defining the name of vector associated
;                                with the VECTOR1 keyword
;                                [Default = 'X']
;               YNAME       :  Scalar string defining the name of vector associated with
;                                the VECTOR2 keyword
;                                [Default = 'Y']
;               DFRA        :  2-Element array specifying a DF range (s^3/km^3/cm^3)
;                                for the cuts of the contour plot
;                                [Default = defined by range of data]
;               VCIRC       :  Scalar or array defining the value(s) to plot as a
;                                circle(s) of constant speed [km/s] on the contour
;                                plot [e.g. gyrospeed of specularly reflected ion]
;               EX_VEC0     :  3-Element unit vector for a quantity like heat flux or
;                                a wave vector, etc.
;               EX_VN0      :  A string name associated with EX_VEC0
;                                [Default = 'Vec 1']
;               EX_VEC1     :  3-Element unit vector for another quantity like the sun
;                                direction or shock normal vector vector, etc.
;               EX_VN1      :  A string name associated with EX_VEC1
;                                [Default = 'Vec 2']
;               NOKILL_PH   :  If set, program will not call pesa_high_bad_bins.pro for
;                                PESA High structures to remove "bad" data bins
;                                [Default = 0]
;               PLANE       :  Scalar string defining the plane projection to plot with
;                                corresponding cuts [Let V1 = VECTOR1, V2 = VECTOR2]
;                                  'xy'  :  horizontal axis parallel to V1 and normal
;                                             vector to plane defined by (V1 x V2)
;                                             [default]
;                                  'xz'  :  horizontal axis parallel to (V1 x V2) and
;                                             vertical axis parallel to V1
;                                  'yz'  :  horizontal axis defined by (V1 x V2) x V1
;                                             and vertical axis (V1 x V2)
;               NO_TRANS    :  If set, routine will not transform data into SW frame
;                                [Default = 0 (i.e. DAT transformed into SW frame)]
;               INTERP      :  If set, data is interpolated to original energy estimates
;                                after transforming into new reference frame
;               SM_CONT     :  If set, program plots the smoothed contours of DF
;                                [Note:  Smoothed to the minimum # of points]
;               DFMIN       :  Scalar defining the minimum allowable phase space density
;                                to plot, which is useful for ion distributions with
;                                large angular gaps in data
;                                [prevents lower bound from falling below DFMIN]
;               DFMAX       :  Scalar defining the maximum allowable phase space density
;                                to plot, which is useful for distributions with data
;                                spikes
;                                [prevents upper bound from exceeding DFMAX]
;               TRANGE      :  [2]-Element array specifying the range of the time-
;                                series to plot [Unix time]
;               MOVIENAME   :  Scalar string defining the name to use when saving the
;                                movie file
;               KEEP_SNAPS  :  If set, routine will not delete image directory full of
;                                PNG files created by this routine
;                                [Default = 0]
;               TROUTER     :  Scalar defining the amount of time [s] on either side of
;                                the 3 DFs shown in the center of the plot
;                                [Default = 21.0 (also minimum allowed)]
;               QUALITY     :  Scalar value from 0-100 defining the MPEG and JPEG quality
;                                [Default = 100]
;                                [see WRITE_JPEG.PRO and MPEG_OPEN.PRO documentation]
;               EXFRAMES    :  Scalar value defining the number of times to copy any
;                                given frame in a MPEG to slow down the playback
;                                [Default = 0]
;               VERSION     :  Scalar string defining the name and version of the
;                                ploting routine called in this routine
;               VECTOR1     :  [M,3]-Element vector to be used for horizontal axis in
;                                a 2D-projected contour plot [e.g. see eh_cont3d.pro]
;                                [Default = dat.MAGF]
;               VECTOR2     :  [M,3]-Element vector to be used to define the plane made
;                                with VECTOR1  [Default = dat.VSW]
;
;   CHANGED:  1)  NA [MM/DD/YYYY   v1.0.0]
;
;   NOTES:      
;               
;
;   CREATED:  04/05/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  04/05/2012   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO contour_df_pos_slide_idlmpeg,timeseries,dat,VLIM=vlim,NGRID=ngrid,XNAME=xname,      $
                                 YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,     $
                                 EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,           $
                                 NOKILL_PH=nokill_ph,PLANE=plane,NO_TRANS=no_trans,     $
                                 INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax,$
                                 TRANGE=trange,MOVIENAME=moviename,KEEP_SNAPS=keep_sn,  $
                                 TROUTER=trouter,QUALITY=quality,EXFRAMES=exframes,     $
                                 VERSION=version,VECTOR1=vector1,VECTOR2=vector2

;-----------------------------------------------------------------------------------------
; => Define some constants and dummy variables
;-----------------------------------------------------------------------------------------
;;  define a dummy image directory
imgdir = 'snapshots_'+STRCOMPRESS(STRING(RANDOMU(SYSTIME(1),/LONG)),/REMOVE_ALL)
;;  create temporary directory
IF KEYWORD_SET(keep_sn) THEN SPAWN,'mkdir '+imgdir[0]

trout_min  = 21d0
IF ~KEYWORD_SET(trouter)   THEN trout = trout_min[0] ELSE trout = trouter[0] > trout_min[0]
IF ~KEYWORD_SET(moviename) THEN movienm = imgdir[0]+'.mov' ELSE movienm = moviename[0]

;;  define the image quality
IF KEYWORD_SET(quality) THEN qual = quality[0] ELSE qual = 100
;-----------------------------------------------------------------------------------------
; => Define values related to particle distributions
;-----------------------------------------------------------------------------------------
data          = dat
ndat          = N_ELEMENTS(data)
nsub          = ndat - 2L          ;  # of subintervals
i0            = LINDGEN(nsub)
i1            = i0 + 1L
i2            = i1 + 1L
dat_i0        = data[i0]
dat_i1        = data[i1]
dat_i2        = data[i2]
;;  define sub-interval vectors
vec1_0        = vector1[i0,*]
vec1_1        = vector1[i1,*]
vec1_2        = vector1[i2,*]
vec2_0        = vector2[i0,*]
vec2_1        = vector2[i1,*]
vec2_2        = vector2[i2,*]

tsub_tra      = DBLARR(nsub,2L)
tsub_tra[*,0] = dat_i0.TIME[0] - trout[0]
tsub_tra[*,1] = dat_i2.END_TIME[0] + trout[0]
;-----------------------------------------------------------------------------------------
; => QUAL -> defines image quality
;-----------------------------------------------------------------------------------------
IF ~KEYWORD_SET(xsize) THEN xsize = 1200
IF ~KEYWORD_SET(ysize) THEN ysize = 1000
; => Open an MPEG file
mpegID     = MPEG_OPEN([xsize,ysize],QUALITY=qual[0])
;-----------------------------------------------------------------------------------------
; => Plot DFs
;-----------------------------------------------------------------------------------------
j          = 0L
cc         = 0L
test       = 1
IF ~KEYWORD_SET(exframes) THEN exf = 0L ELSE exf = exframes[0] > 0
WHILE (test) DO BEGIN
  timeser = timeseries
  dat_df  = [dat_i0[j],dat_i1[j],dat_i2[j]]
  vec1    = [vec1_0[j,*],vec1_1[j,*],vec1_2[j,*]]
  vec2    = [vec2_0[j,*],vec2_1[j,*],vec2_2[j,*]]
  tra     = REFORM(tsub_tra[j,*])
  ;---------------------------------------------------------------------------------
  ; => Define time ticks so they do not move in window
  ;---------------------------------------------------------------------------------
  nn      = 5L
  xtv     = DBLARR(nn)
  xtn     = STRARR(nn)
  xts     = nn - 1L   ; want 5 tick marks
  ; => determine width of window
  difft   = ABS(tra[1] - tra[0])
  t_intv  = difft[0]/xts[0]  ;  tick interval
  FOR ii=0L, 3L DO xtv[ii] = tra[0] + t_intv[0]*ii
  xtv[nn - 1L]  = tra[1]
  ; => determine tick names
  tnme0   = time_string(xtv,PREC=3)
  xtn     = STRMID(tnme0[*],0L,10L)+'!C'+STRMID(tnme0[*],11L)
  ; => Add these to limits structures
  str_element,timeser,'T0.LIM.XTICKNAME',xtn,/ADD_REPLACE
  str_element,timeser,'T0.LIM.XTICKV',xtv,/ADD_REPLACE
  str_element,timeser,'T0.LIM.XTICKS',xts,/ADD_REPLACE
  str_element,timeser,'T1.LIM.XTICKNAME',xtn,/ADD_REPLACE
  str_element,timeser,'T1.LIM.XTICKV',xtv,/ADD_REPLACE
  str_element,timeser,'T1.LIM.XTICKS',xts,/ADD_REPLACE
  ;---------------------------------------------------------------------------------
  ; => Plot data with contours
  ;---------------------------------------------------------------------------------
  contour_df_pos_slide_plot,timeser,dat_df,VLIM=vlim,NGRID=ngrid,XNAME=xname,       $
                            YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,      $
                            EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,            $
                            NOKILL_PH=nokill_ph,PLANE=plane,NO_TRANS=no_trans,      $
                            INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax, $
                            TRANGE=tra,VERSION=version,VECTOR1=vec1,VECTOR2=vec2
  ;---------------------------------------------------------------------------------
  ; => Add frame to movie
  ;---------------------------------------------------------------------------------
;  FOR ff=0L, exf[0] - 1L DO BEGIN
  FOR ff=0L, exf[0] DO BEGIN
    ;;;;;;;;;;;
    IF (j EQ 0 AND cc EQ 0) THEN fnum = 0L ELSE fnum += 1L
    MPEG_PUT,mpegID,IMAGE=TVRD(TRUE=1),FRAME=fnum[0],/ORDER
    ; => test
    test = (j LT nsub - 1L)
    IF (exf[0] GT 0) THEN BEGIN
      ; => Add extra frames to MPEG
      fr_test = cc[0] EQ exf[0]
      IF (fr_test) THEN BEGIN
        ; => extra frames already added, so reset counter and index j
        cc = 0L
        IF (j MOD 10 EQ 0) THEN PRINT,'Frame # saved: ',j
        j += test
      ENDIF ELSE BEGIN
        ; => index counter
        cc += 1L
      ENDELSE
    ENDIF ELSE BEGIN
      ; => No extra frames
      IF (j MOD 10 EQ 0) THEN PRINT,'Frame # saved: ',j
      j   += test
    ENDELSE
  ;;;;;;;;;;;
  ENDFOR
  ;---------------------------------------------------------------------------------
  ; => Write JPEGs to image directory
  ;---------------------------------------------------------------------------------
  IF KEYWORD_SET(keep_sn) THEN BEGIN
    stringcount = STRING(j,FORMAT='(i4.4)')
    j_name      = imgdir[0]+'/snapshot_'+stringcount[0]+'.jpg'
    WRITE_JPEG,j_name[0],TVRD(TRUE=1),TRUE=1,QUALITY=qual[0]
  ENDIF
ENDWHILE
;-----------------------------------------------------------------------------------
; => Encode, save, and close MPEG
;-----------------------------------------------------------------------------------
PRINT,''
PRINT,'Encoding movie: '+moviename[0]
PRINT,''
; => save
MPEG_SAVE,mpegID,FILENAME=moviename[0]
; => Close MPEG
MPEG_CLOSE,mpegID
PRINT,''
PRINT,'Movie named: '+moviename[0]+' has been saved...'
PRINT,''
;-----------------------------------------------------------------------------------
; => Return
;-----------------------------------------------------------------------------------

RETURN
END


;+
;*****************************************************************************************
;
;  PROCEDURE:   contour_df_pos_slide_wrapper.pro
;  PURPOSE  :   This is a wrapping routine for contour_df_pos_slide_plot.pro.  The user
;                 can interactively plot 3 DFs to an X-Window or create a series of
;                 PS files or create an MPEG movie.  The user specifies 2 TPLOT handles
;                 that they wish to plot below 3 particle distributions with vertical
;                 red/blue lines indicating where the corresponding start/end times for
;                 each DF are.  In snapshot mode, the routine creates PS files of the
;                 same images used to create the frames for the MPEG movie.
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               format_timeseries_for_contour.pro
;               str_element.pro
;               contour_df_pos_slide_wrapper.pro
;               format_df_for_contour.pro
;               file_name_times.pro
;               read_gen_ascii.pro
;               contour_df_pos_slide_ffmpeg.pro
;               contour_df_pos_slide_idlmpeg.pro
;               time_string.pro
;               contour_df_pos_slide_plot.pro
;               popen.pro
;               pclose.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               TIMENAME    :  [2]-Element array of TPLOT handles to plot below the
;                                3 DFs shown on top
;               DAT         :  [M]-Element array of particle distributions from either
;                                Wind/3DP or THEMIS ESA
;
;  EXAMPLES:    
;               
;
;  KEYWORDS:    
;               VLIM        :  Limit for x-y velocity axes over which to plot data
;                                [Default = max vel. from energy bin values]
;               NGRID       :  # of isotropic velocity grids to use to triangulate the
;                                data [Default = 30L]
;               XNAME       :  Scalar string defining the name of vector associated
;                                with the VECTOR1 keyword
;                                [Default = 'X']
;               YNAME       :  Scalar string defining the name of vector associated with
;                                the VECTOR2 keyword
;                                [Default = 'Y']
;               DFRA        :  [2]-Element array specifying a DF range (s^3/km^3/cm^3)
;                                for the cuts of the contour plot
;                                [Default = defined by range of data]
;               VCIRC       :  Scalar or array defining the value(s) to plot as a
;                                circle(s) of constant speed [km/s] on the contour
;                                plot [e.g. gyrospeed of specularly reflected ion]
;               EX_VEC0     :  3-Element unit vector for a quantity like heat flux or
;                                a wave vector, etc.
;               EX_VN0      :  A string name associated with EX_VEC0
;                                [Default = 'Vec 1']
;               EX_VEC1     :  3-Element unit vector for another quantity like the sun
;                                direction or shock normal vector vector, etc.
;               EX_VN1      :  A string name associated with EX_VEC1
;                                [Default = 'Vec 2']
;               NOKILL_PH   :  If set, program will not call pesa_high_bad_bins.pro for
;                                PESA High structures to remove "bad" data bins
;                                [Default = 0]
;               PLANE       :  Scalar string defining the plane projection to plot with
;                                corresponding cuts [Let V1 = VECTOR1, V2 = VECTOR2]
;                                  'xy'  :  horizontal axis parallel to V1 and normal
;                                             vector to plane defined by (V1 x V2)
;                                             [default]
;                                  'xz'  :  horizontal axis parallel to (V1 x V2) and
;                                             vertical axis parallel to V1
;                                  'yz'  :  horizontal axis defined by (V1 x V2) x V1
;                                             and vertical axis (V1 x V2)
;               NO_TRANS    :  If set, routine will not transform data into SW frame
;                                [Default = 0 (i.e. DAT transformed into SW frame)]
;               INTERP      :  If set, data is interpolated to original energy estimates
;                                after transforming into new reference frame
;               SM_CONT     :  If set, program plots the smoothed contours of DF
;                                [Note:  Smoothed to the minimum # of points]
;               DFMIN       :  Scalar defining the minimum allowable phase space density
;                                to plot, which is useful for ion distributions with
;                                large angular gaps in data
;                                [prevents lower bound from falling below DFMIN]
;               DFMAX       :  Scalar defining the maximum allowable phase space density
;                                to plot, which is useful for distributions with data
;                                spikes
;                                [prevents upper bound from exceeding DFMAX]
;               TRANGE      :  [2]-Element array specifying the outer range of the
;                                timeseries to plot [Unix time]
;               TROUTER     :  Scalar defining the amount of time [s] on either side of
;                                the 3 DFs shown in the center of the plot
;                                [Default = 21.0 (also minimum allowed)]
;               LIVE        :  If set, routine will wait for user input to move from one
;                                plot to the next [Default = 0]
;               CUTS        :  If set, routine plots cuts of DF instead of contours
;                                [Default = 0]
;                                [** Not included yet **]
;               SNAPSHOTS   :  If set, routine creates a directory and plots the
;                                snapshots of the plots
;               QUALITY     :  Scalar value from 0-100 defining the MPEG and JPEG quality
;                                [Default = 100]
;                                [see WRITE_JPEG.PRO and MPEG_OPEN.PRO documentation]
;               TSNAMES     :  Scalar string specifying the file prefix to be used for
;                                the two timeseries' associated with TIMENAME
;               EXFRAMES    :  Scalar value defining the number of times to copy any
;                                given frame in a MPEG to slow down the playback
;                                [Default = 0]
;               FRAMERATE   :  Scaler value defining the frame rate of output movie
;                                [Default = 25]
;               KEEP_SNAPS  :  If set, routine will not delete image directory full of
;                                PNG files created by this routine
;                                [Default = 0]
;               VECTOR1     :  [M,3]-Element vector to be used for horizontal axis in
;                                a 2D-projected contour plot [e.g. see eh_cont3d.pro]
;                                [Default = dat.MAGF]
;               VECTOR2     :  [M,3]-Element vector to be used to define the plane made
;                                with VECTOR1  [Default = dat.VSW]
;
;   CHANGED:  1)  Added messages which tell user the runtime and some additional
;                   comments                                        [04/03/2012   v1.0.1]
;             2)  Now allows for use of ffmpeg if available and changable frame rates
;                                                                   [04/03/2012   v1.1.0]
;             3)  Made small modifications to plot options used prior to sending
;                   to contour_df_pos_slide_plot.pro                [04/05/2012   v1.1.1]
;             4)  Cleaned up and rewrote:
;                   A)  no longer calls  :  tnames.pro, get_data.pro,
;                         time_range_define.pro, test_wind_vs_themis_esa_struct.pro,
;                         dat_3dp_str_names.pro, pesa_high_bad_bins.pro,
;                         convert_ph_units.pro, conv_units.pro,
;                         dat_themis_esa_str_names.pro, modify_themis_esa_struc.pro
;                   B)  now calls        :  format_timeseries_for_contour.pro,
;                         format_df_for_contour.pro, contour_df_pos_slide_ffmpeg.pro,
;                         contour_df_pos_slide_idlmpeg.pro, and read_gen_ascii.pro
;                   C)  added keywords:  KEEP_SNAPS, VECTOR1, and VECTOR2
;                                                                   [04/05/2012   v2.0.0]
;             5)  Added "-f mov" syntax to ffmpeg call which forces the output file
;                   format to a QuickTime movie [contour_df_pos_slide_ffmpeg.pro]
;                                                                   [04/21/2012   v2.1.0]
;             6)  Fixed an indexing error in the vector identification used for the
;                   horizontal/vertical axes
;                                                                   [06/08/2012   v2.1.1]
;
;   NOTES:      
;               1)  The value specified by TRANGE should identify the total time range
;                     of data to plot, with each plot will be a subinterval of TRANGE.
;               2)  If SNAPSHOTS is not set and LIVE is not set, then routine creates a
;                     MPEG movie of output
;               3)  The use of this routine is similar to that of contour_3d_1plane.pro
;               4)  See also:  contour_df_pos_slide_plot.pro
;               5)  The more frames used due to longer periods of time require smaller
;                     values for EXFRAMES
;               6)  If ffmpeg is available, then user can define a new framerate to slow
;                     down movies
;               7)  For ease of viewing in movie mode, it is useful to set VECTOR1
;                     and VECTOR2 to static vectors which do not change throughout
;
;   CREATED:  04/02/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  06/08/2012   v2.1.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO contour_df_pos_slide_wrapper,timename,dat,VLIM=vlim,NGRID=ngrid,XNAME=xname,         $
                                 YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,      $
                                 EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,            $
                                 NOKILL_PH=nokill_ph,PLANE=plane,NO_TRANS=no_trans,      $
                                 INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax, $
                                 TRANGE=trange,TROUTER=trouter,LIVE=live,CUTS=cuts,      $
                                 SNAPSHOTS=snapshots,QUALITY=quality,TSNAMES=tsnames,    $
                                 EXFRAMES=exframes,FRAMERATE=framerate,                  $
                                 KEEP_SNAPS=keep_sn,VECTOR1=vector1,VECTOR2=vector2

;*****************************************************************************************
ex_start = SYSTIME(1)
;*****************************************************************************************
;-----------------------------------------------------------------------------------------
; => Define some constants and dummy variables
;-----------------------------------------------------------------------------------------
f          = !VALUES.F_NAN
d          = !VALUES.D_NAN
; => Dummy error messages
noinpt_msg = 'No input supplied...'
notstr_msg = 'Must be a [2]-element string array...'
nofint_msg = 'No finite data...'
nottpn_msg = 'Not valid TPLOT handles'
notidl_msg = 'DAT must be an array of IDL structures...'

badv1_mssg = 'VECTOR1 must be an [M,3]-element array...'
badv2_mssg = 'VECTOR2 must be an [M,3]-element array...'
; => Define dummy file names
;xyzvecs    = ['(V.B)','(BxV)xB','(BxV)']
;xyzvecf    = ['V.B','BxVxB','BxV']
xyzvecs    = ['(v.V1)','(V1xV2)xV1','(V1xV2)']
xyzvecf    = ['V1','V1xV2xV1','V1xV2']

planes     = ['xy','xz','yz']
xy_suff    = '_'+xyzvecf[1]+'_vs_'+xyzvecf[0]
xz_suff    = '_'+xyzvecf[0]+'_vs_'+xyzvecf[2]
yz_suff    = '_'+xyzvecf[2]+'_vs_'+xyzvecf[1]
plane_sff  = [xy_suff[0],xz_suff[0],yz_suff[0]]
IF ~KEYWORD_SET(cuts) THEN cut_nm = 0 ELSE cut_nm = 1
midstr     = ('_'+['Contours','Cuts']+'-DF')[cut_nm]
IF NOT KEYWORD_SET(plane)    THEN projxy = 'xy'    ELSE projxy = STRLOWCASE(plane[0])
; => Define # of levels to use for contour.pro
IF NOT KEYWORD_SET(ngrid) THEN ngrid = 30L 
good_pln   = WHERE(projxy[0] EQ planes,gdpl)
IF (gdpl GT 0) THEN BEGIN
  mid_fname = plane_sff[good_pln[0]]+midstr[0]
ENDIF ELSE BEGIN
  ; => use default
  projxy    = 'xy'
  mid_fname = plane_sff[0]+midstr[0]
ENDELSE
;-----------------------------------------------------------------------------------------
; => Check input
;-----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ; => no input???
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;-----------------------------------------------------------------------------------------
; => Format TIMENAME input for contour_df_pos_slide_plot.pro
;-----------------------------------------------------------------------------------------
timeseries = format_timeseries_for_contour(timename,TRANGE=trange,FILE_PREF=ts_pref,$
                                           TRA_OUT=tra_out,TSNAMES=tsnames)
; => Make sure routine returned a structure
IF (SIZE(timeseries,/TYPE) NE 8) THEN BEGIN
  MESSAGE,nottpn_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;-----------------------------------------------------------------------------------------
; => Determine time range outside of 3 DFs in middle of plot
;-----------------------------------------------------------------------------------------
trout_min  = 21d0
IF ~KEYWORD_SET(trouter) THEN trout = trout_min[0] ELSE trout = trouter[0] > trout_min[0]
; => make sure time range is large enough to handle space on either side of DFs
tr_mid     = (tra_out[0] + tra_out[1])/2d0
test       = ((tr_mid[0] - trout[0]) LT tra_out[0]) OR $
             ((tr_mid[0] + trout[0]) GT tra_out[1])
IF (test) THEN BEGIN
  badmss0 = 'Time range is too small...'
  badmss1 = 'Trying default...'
  MESSAGE,badmss0[0],/INFORMATIONAL,/CONTINUE
  IF (trout[0] EQ trout_min[0]) THEN RETURN
  ; => re-call the routine
  MESSAGE,badmss1[0],/INFORMATIONAL,/CONTINUE
  contour_df_pos_slide_wrapper,t_name,dat,VLIM=vlim,NGRID=ngrid,XNAME=xname,          $
                              YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,      $
                              EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,            $
                              NOKILL_PH=nokill_ph,PLANE=plane,NO_TRANS=no_trans,      $
                              INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax, $
                              TRANGE=tra_out,TROUTER=2d1,LIVE=live,CUTS=cuts,         $
                              SNAPSHOTS=snapshots,QUALITY=quality,TSNAMES=tsnames,    $
                              EXFRAMES=exframes,FRAMERATE=framerate,VECTOR1=vector1,  $
                              VECTOR2=vector2
ENDIF
;-----------------------------------------------------------------------------------------
; => Format DAT structures for contour_df_pos_slide_plot.pro
;-----------------------------------------------------------------------------------------
data    = format_df_for_contour(dat,NOKILL_PH=nokill_ph,FILE_PREF=fpref)
; => Make sure routine returned a structure
IF (SIZE(data,/TYPE) NE 8) THEN BEGIN
  MESSAGE,notidl_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
; => Add timeseries prefix to file prefix
fpref   = ts_pref[0]+fpref[0]
;-----------------------------------------------------------------------------------------
; => Make sure DF time span is inside TPLOT variables
;-----------------------------------------------------------------------------------------
ndat0      = N_ELEMENTS(data)
tra_df0    = tra_out + [1d0,-1d0]*trout[0]  ; shrink DF range so none on edge of window
good_d     = WHERE(data.TIME GT tra_df0[0] AND data.END_TIME LT tra_df0[1],gdd)
IF (gdd GT 3) THEN BEGIN
  data = data[good_d]
ENDIF ELSE BEGIN
  badmssg = 'No particle DFs in selected time range...'
  MESSAGE,badmssg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDELSE
ndat       = N_ELEMENTS(data)
df_tra     = [MIN(data.TIME,/NAN),MAX(data.END_TIME,/NAN)]
;-----------------------------------------------------------------------------------------
; => Check if vectors are set
;-----------------------------------------------------------------------------------------
;;  define defaults
def_vec1      = TRANSPOSE(data.MAGF)
def_vec2      = TRANSPOSE(data.VSW)
dumbv         = REPLICATE(d,ndat0,3L)
szv1          = SIZE(vector1,/DIMENSIONS)
szv2          = SIZE(vector2,/DIMENSIONS)
;;  Vector 1
CASE N_ELEMENTS(szv1) OF
  2L   :  BEGIN
    ; => Vector 1 set and 2D
    test = TOTAL(szv1 EQ ndat0) NE 1
    IF (test) THEN BEGIN
      MESSAGE,badv1_mssg[0],/INFORMATIONAL,/CONTINUE
      vector1 = def_vec1
      xname   = 'B!Do!N'
    ENDIF ELSE BEGIN
      good1 = WHERE(szv1 EQ ndat0)
      IF (good1[0] NE 0) THEN vector1 = TRANSPOSE(vector1)
    ENDELSE
  END
  ELSE :  BEGIN
    ; => Vector 1 set incorrectly
    MESSAGE,badv1_mssg[0],/INFORMATIONAL,/CONTINUE
    vector1 = def_vec1
    xname   = 'B!Do!N'  ;;  redefine XNAME
  END
ENDCASE
;;  Vector 2
CASE N_ELEMENTS(szv2) OF
  2L   :  BEGIN
    ; => Vector 2 set and 2D
    test = TOTAL(szv2 EQ ndat0) NE 1
    IF (test) THEN BEGIN
      MESSAGE,badv2_mssg[0],/INFORMATIONAL,/CONTINUE
      vector2 = def_vec2
      yname   = 'V!Dsw!N'  ;;  redefine YNAME
    ENDIF ELSE BEGIN
      good1 = WHERE(szv2 EQ ndat0)
      IF (good1[0] NE 0) THEN vector2 = TRANSPOSE(vector2)
    ENDELSE
  END
  ELSE :  BEGIN
    ; => Vector 2 set incorrectly
    MESSAGE,badv2_mssg[0],/INFORMATIONAL,/CONTINUE
    vector2 = def_vec2
    yname   = 'V!Dsw!N'  ;;  redefine YNAME
  END
ENDCASE
;; => make # of elements match DFs
szv11         = SIZE(vector1,/DIMENSIONS)
szv21         = SIZE(vector2,/DIMENSIONS)
;; V1
IF (szv11[0] NE ndat) THEN BEGIN
  vec1 = vector1[good_d,*]
ENDIF ELSE BEGIN
  vec1 = vector1
ENDELSE
;; V2
IF (szv21[0] NE ndat) THEN BEGIN
  vec2 = vector2[good_d,*]
ENDIF ELSE BEGIN
  vec2 = vector2
ENDELSE
;-----------------------------------------------------------------------------------------
; => Define subinterval time ranges
;-----------------------------------------------------------------------------------------
nsub       = ndat - 2L
i0         = LINDGEN(nsub)
i1         = i0 + 1L
i2         = i1 + 1L
dat_i0     = data[i0]
dat_i1     = data[i1]
dat_i2     = data[i2]

tsub_tra   = DBLARR(nsub,2L)
tsub_tra[*,0] = dat_i0.TIME[0] - trout[0]
tsub_tra[*,1] = dat_i2.END_TIME[0] + trout[0]
;-----------------------------------------------------------------------------------------
; => Define file names
;-----------------------------------------------------------------------------------------
; => Define velocity limit (km/s)
IF NOT KEYWORD_SET(vlim) THEN BEGIN
  allener = dat_all.ENERGY
  allvlim = SQRT(2d0*allener/dat_all[0].MASS)
  vlim    = MAX(allvlim,/NAN)
ENDIF ELSE BEGIN
  vlim    = DOUBLE(vlim[0])
ENDELSE

fnm_s   = file_name_times(tsub_tra[*,0],PREC=3)
fnm_e   = file_name_times(tsub_tra[*,1],PREC=3)
ftime_s = fnm_s.F_TIME          ; e.g. 1998-08-09_0801x09.494
ftime_e = fnm_e.F_TIME          ; e.g. 1998-08-09_0801x09.494
ftimes  = ftime_s+'_'+ftime_e

vlim_st = STRING(vlim[0],FORMAT='(I5.5)')
grid_st = STRING(ngrid[0],FORMAT='(I2.2)')
f_pref  = fpref[0]+ftimes+'_'+grid_st[0]+'Grids_'+vlim_st[0]+'km-s'
fnames  = f_pref+mid_fname[0]
;;########################################################################################
;; => Define version of plotting routine for output
;;########################################################################################
mdir       = FILE_EXPAND_PATH('wind_3dp_pros/LYNN_PRO/')+'/'
file       = FILE_SEARCH(mdir,'contour_df_pos_slide_plot.pro')
;fstring    = read_gen_ascii(file[0],FIRST_NL=600L)
fstring    = read_gen_ascii(file[0])
shifts     = STRLEN(';    LAST MODIFIED:  ')
test       = STRPOS(STRMID(fstring,0L,shifts[0]),';    LAST MODIFIED:  ') GE 0
gposi      = WHERE(test,gpf)
IF (gpf GT 1) THEN f_str_g = fstring[gposi[gpf - 1L]] ELSE f_str_g = fstring[gposi[0]]
vers       = STRMID(f_str_g[0],shifts[0])
vers0      = 'contour_df_pos_slide_plot.pro : '+vers[0]+', '
version    = vers0[0]+time_string(SYSTIME(1,/SECONDS),PREC=3)
;-----------------------------------------------------------------------------------------
; => Plot DFs with TIMESERIES
;-----------------------------------------------------------------------------------------
IF ~KEYWORD_SET(live) THEN BEGIN
  ;---------------------------------------------------------------------------------------
  ; => Save mode
  ;---------------------------------------------------------------------------------------
  IF ~KEYWORD_SET(snapshots) THEN BEGIN
    ;-------------------------------------------------------------------------------------
    ; => Load some parameters
    ;-------------------------------------------------------------------------------------
    old_chars      = !P.CHARSIZE
    old_cthck      = !P.CHARTHICK
    !P.CHARSIZE    = 1.5
    !P.CHARTHICK   = 1.2
    ;-------------------------------------------------------------------------------------
    ; => Define movie name
    ;-------------------------------------------------------------------------------------
    tra       = [MIN(tsub_tra[*,0],/NAN),MAX(tsub_tra[*,1],/NAN)]
    fnm       = file_name_times(tra,PREC=3)
    ftimes    = fnm.F_TIME[0]+'_'+fnm.F_TIME[1]
    ;-------------------------------------------------------------------------------------
    ; => Check to see if ffmpeg is installed
    ;-------------------------------------------------------------------------------------
    SPAWN,'which ffmpeg',result
    IF (result[0] NE '') THEN BEGIN
      ;-----------------------------------------------------------------------------------
      ; set up Z-Buffer
      ;-----------------------------------------------------------------------------------
      IF ~KEYWORD_SET(xsize) THEN xsize = 1300
      IF ~KEYWORD_SET(ysize) THEN ysize = 1000
      SET_PLOT,'Z'
      DEVICE,SET_PIXEL_DEPTH=24,SET_RESOLUTION=[xsize,ysize]
      DEVICE,DECOMPOSED=0
      LOADCT,39,/SILENT
      ;  specify the frame rate
      IF KEYWORD_SET(framerate) THEN frmra = LONG(framerate[0]) < 60L ELSE frmra = 25L
      frm_str = STRING(FORMAT='(I2.2)',frmra[0])
      ;;  define movie name
      move_pref = fpref[0]+ftimes[0]+'_'+grid_st[0]+'Grids_'+vlim_st[0]
      moviename = move_pref[0]+'km-s'+mid_fname[0]+'_'+frm_str[0]+'fps.mov'
      ;-----------------------------------------------------------------------------------
      ;-----------------------------------------------------------------------------------
      ; => Create movie using PNG snapshots with ffmpeg
      ;-----------------------------------------------------------------------------------
      ;-----------------------------------------------------------------------------------
      contour_df_pos_slide_ffmpeg,timeseries,data,VLIM=vlim,NGRID=ngrid,XNAME=xname,      $
                                  YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,      $
                                  EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,            $
                                  NOKILL_PH=nokill_ph,PLANE=projxy[0],NO_TRANS=no_trans,  $
                                  INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax, $
                                  TRANGE=tra,MOVIENAME=moviename[0],FRAMERATE=frmra[0],   $
                                  KEEP_SNAPS=keep_sn,TROUTER=trout[0],VERSION=version,    $
                                  VECTOR1=vec1,VECTOR2=vec2
      ;-----------------------------------------------------------------------------------
      ; => Return plot window to original state
      ;-----------------------------------------------------------------------------------
      !P.MULTI    = 0
      SET_PLOT,'X'
      !P.CHARSIZE  = old_chars[0]
      !P.CHARTHICK = old_cthck[0]
      ;***********************************************************************************
      ex_time = SYSTIME(1) - ex_start
      MESSAGE,STRING(ex_time)+' seconds execution time.',/INFORMATIONAL,/CONTINUE
      ;***********************************************************************************
      RETURN
    ENDIF ELSE BEGIN
      ;-----------------------------------------------------------------------------------
      ; set up Z-Buffer
      ;-----------------------------------------------------------------------------------
      IF ~KEYWORD_SET(xsize) THEN xsize = 1200
      IF ~KEYWORD_SET(ysize) THEN ysize = 1000
      SET_PLOT,'Z'
      DEVICE,SET_PIXEL_DEPTH=24,SET_RESOLUTION=[xsize,ysize]
      DEVICE,DECOMPOSED=0
      LOADCT,39,/SILENT
      ;;  define movie name
      moviename = fpref[0]+ftimes[0]+'_'+grid_st[0]+'Grids_'+vlim_st[0]+'km-s'+mid_fname[0]+'.mpeg'
      ;;  specify the image quality
      IF KEYWORD_SET(quality) THEN qual = quality[0] ELSE qual = 100
      ;;  specify if extra frames should be added
      IF ~KEYWORD_SET(exframes) THEN exf = 0L ELSE exf = exframes[0] > 0
      ;-----------------------------------------------------------------------------------
      ;-----------------------------------------------------------------------------------
      ; => Create MPEG movie of snapshots
      ;-----------------------------------------------------------------------------------
      ;-----------------------------------------------------------------------------------
      contour_df_pos_slide_idlmpeg,timeseries,data,VLIM=vlim,NGRID=ngrid,XNAME=xname,     $
                                  YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,      $
                                  EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,            $
                                  NOKILL_PH=nokill_ph,PLANE=projxy[0],NO_TRANS=no_trans,  $
                                  INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax, $
                                  TRANGE=tra,MOVIENAME=moviename[0],KEEP_SNAPS=keep_sn,   $
                                  TROUTER=trout[0],QUALITY=qual[0],EXFRAMES=exf[0],       $
                                  VERSION=version,VECTOR1=vec1,VECTOR2=vec2
      ;-----------------------------------------------------------------------------------
      ; => Return plot window to original state
      ;-----------------------------------------------------------------------------------
      !P.MULTI    = 0
      SET_PLOT,'X'
      !P.CHARSIZE  = old_chars[0]
      !P.CHARTHICK = old_cthck[0]
      ;***********************************************************************************
      ex_time = SYSTIME(1) - ex_start
      MESSAGE,STRING(ex_time)+' seconds execution time.',/INFORMATIONAL,/CONTINUE
      ;***********************************************************************************
      RETURN
    ENDELSE
  ENDIF ELSE BEGIN
    ;-------------------------------------------------------------------------------------
    ;-------------------------------------------------------------------------------------
    ; => Save snapshots
    ;-------------------------------------------------------------------------------------
    ;-------------------------------------------------------------------------------------
    FOR j=0L, nsub - 1L DO BEGIN
      timeser = timeseries
      dat_df  = [dat_i0[j],dat_i1[j],dat_i2[j]]
      tra     = REFORM(tsub_tra[j,*])
      ;-----------------------------------------------------------------------------------
      ; => Define time ticks so they do not move in window
      ;-----------------------------------------------------------------------------------
      nn      = 5L
      xtv     = DBLARR(nn)
      xtn     = STRARR(nn)
      xts     = nn - 1L   ; want 5 tick marks
      ; => determine width of window
      difft   = ABS(tra[1] - tra[0])
      t_intv  = difft[0]/xts[0]  ;  tick interval
      FOR ii=0L, 3L DO xtv[ii] = tra[0] + t_intv[0]*ii
      xtv[nn - 1L]  = tra[1]
      ; => determine tick names
      tnme0   = time_string(xtv,PREC=3)
      xtn     = STRMID(tnme0[*],0L,10L)+'!C'+STRMID(tnme0[*],11L)
      ; => Add these to limits structures
      str_element,timeser,'T0.LIM.XTICKNAME',xtn,/ADD_REPLACE
      str_element,timeser,'T0.LIM.XTICKV',xtv,/ADD_REPLACE
      str_element,timeser,'T0.LIM.XTICKS',xts,/ADD_REPLACE
      str_element,timeser,'T1.LIM.XTICKNAME',xtn,/ADD_REPLACE
      str_element,timeser,'T1.LIM.XTICKV',xtv,/ADD_REPLACE
      str_element,timeser,'T1.LIM.XTICKS',xts,/ADD_REPLACE
      ; => Save Plots
      popen,fnames[j],/LAND
        contour_df_pos_slide_plot,timeser,dat_df,VLIM=vlim,NGRID=ngrid,XNAME=xname,         $
                                    YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,      $
                                    EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,            $
                                    NOKILL_PH=nokill_ph,PLANE=projxy[0],NO_TRANS=no_trans,  $
                                    INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax, $
                                    TRANGE=tra,VERSION=version,VECTOR1=vec1,VECTOR2=vec2
      pclose
    ENDFOR
    ;*************************************************************************************
    ex_time = SYSTIME(1) - ex_start
    MESSAGE,STRING(ex_time)+' seconds execution time.',/INFORMATIONAL,/CONTINUE
    ;*************************************************************************************
  ENDELSE
ENDIF ELSE BEGIN
  ;---------------------------------------------------------------------------------------
  ;---------------------------------------------------------------------------------------
  ; => Live mode
  ;---------------------------------------------------------------------------------------
  ;---------------------------------------------------------------------------------------
  ind  = 0L
  test = 1
  WHILE (test) DO BEGIN
    timeser = timeseries
    dat_df  = [dat_i0[ind],dat_i1[ind],dat_i2[ind]]
    tra     = REFORM(tsub_tra[ind,*])
    contour_df_pos_slide_plot,timeser,dat_df,VLIM=vlim,NGRID=ngrid,XNAME=xname,       $
                              YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,      $
                              EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,            $
                              NOKILL_PH=nokill_ph,PLANE=projxy[0],NO_TRANS=no_trans,  $
                              INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax, $
                              TRANGE=tra,VERSION=version,VECTOR1=vec1,VECTOR2=vec2
    ;-------------------------------------------------------------------------------------
    ; => tests
    ;-------------------------------------------------------------------------------------
    test_r     = 1
    read_pause = ''
    line0      = 'Please enter one of the following commands:  '
    line1      = '  n  =  shift to the next DFs [j + 1]'
    line2      = '  p  =  shift to the previous DFs [j - 1]'
    line3      = '  i  =  specify the index of the desired DFs [j = i]'
    line4      = '  q  =  quit'
    listmsg    = "Enter your command [type '?' for a list of options]:  "
    WHILE (test_r) DO BEGIN
      ; => prompt user
      PRINT,''
      READ,read_pause,PROMPT=listmsg[0]
      test_r = ((read_pause NE '' ) AND (read_pause NE 'q') AND $
                (read_pause NE 'n') AND (read_pause NE 'p') AND $
                (read_pause NE 'i') AND (read_pause NE '?'))
      IF (read_pause EQ '?') THEN BEGIN
        PRINT,''
        PRINT,line0[0]
        PRINT,line1[0]
        PRINT,line2[0]
        PRINT,line3[0]
        PRINT,line4[0]
        PRINT,''
        test_r = 1
        read_pause = ''
      ENDIF
    ENDWHILE
    CASE read_pause[0] OF
      ''  : BEGIN
        ; => no change, just replot
        test    = test[0]
        ind     = ind[0]
      END
      'n' : BEGIN
        ; => plot next time range
        test    = ind[0] LT (nsub - 1L)
        ind    += test
      END
      'p' : BEGIN
        ; => plot previous time range
        test    = ind[0] GT 0L
        ind    -= test
      END
      'i' : BEGIN
        ; => plot specified index
        indmssg = 'Enter a number between 0000 - '+STRING(nsub - 1L,FORMAT='(I4.4)')+': '
        p_ind   = -1L
        WHILE (p_ind LT 0L OR p_ind GT nsub - 1L) DO BEGIN
          PRINT,''
          READ,p_ind,PROMPT=indmssg[0]
        ENDWHILE
        test    = 1
        ind     = p_ind[0]
        tout_0  = time_string(REFORM(tsub_tra[ind,*]),PREC=3)
        tout_1  = tout_0[0]+' - '+STRMID(tout_0[1],11L)
        PRINT,''
        PRINT,'Plotting time range:  '+tout_1[0]
        PRINT,''
      END
      'q' : BEGIN
        ; => quit
        RETURN
      END
    ENDCASE
  ENDWHILE
ENDELSE
;-----------------------------------------------------------------------------------------
; => Return
;-----------------------------------------------------------------------------------------

RETURN
END
