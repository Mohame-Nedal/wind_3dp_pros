;+
;*****************************************************************************************
;
;  FUNCTION :   format_input_for_contour_slide.pro
;  PURPOSE  :   This routine formats the timeseries and particle distribution input
;                 so that they can be used by the routine, contour_df_pos_slide_plot.pro.
;                 The routine also determines the plot limits structures necessary for
;                 formating the timeseries plot axes appropriately.
;
;  CALLED BY:   
;               contour_df_pos_slide_plot.pro
;
;  CALLS:
;               str_element.pro
;               time_range_define.pro
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               pesa_high_bad_bins.pro
;               convert_ph_units.pro
;               conv_units.pro
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
;               LIMIT_0     :  Set to a named variable to return the plot limits
;                                structure for the 1st TPLOT handle in TIMESERIES
;               LIMIT_1     :  Set to a named variable to return the plot limits
;                                structure for the 2nd TPLOT handle in TIMESERIES
;               TRANGE      :  [2]-Element array specifying the range of the time-
;                                series to plot [Unix time]
;               TRA_OUT     :  Set to a named variable to return the time range
;                                determined by time_range_define.pro
;               NOKILL_PH   :  If set, program will not call pesa_high_bad_bins.pro for
;                                PESA High structures to remove "bad" data bins
;                                [Default = 0]
;               AXIS_LIMIT  :  Set to a named variable to return the plot limits
;                                structures for the calls to AXIS.PRO
;               XNAME       :  Scalar string defining the name of vector associated
;                                with the VECTOR1 keyword
;                                [Default = 'X']
;               YNAME       :  Scalar string defining the name of vector associated with
;                                the VECTOR2 keyword
;                                [Default = 'Y']
;               VECTOR1     :  [M,3]-Element vector to be used for horizontal axis in
;                                a 2D-projected contour plot [e.g. see eh_cont3d.pro]
;                                [Default = dat.MAGF]
;               VECTOR2     :  [M,3]-Element vector to be used to define the plane made
;                                with VECTOR1  [Default = dat.VSW]
;               VNAME       :  Set to a named variable to return the name used for the
;                                bulk flow vector
;               BNAME       :  Set to a named variable to return the name used for the
;                                ambient magnetic field vector
;               NO_TRANS    :  If set, routine will not transform data into SW frame
;                                [Default = 0 (i.e. DAT transformed into SW frame)]
;               V_VSWS      :  Set to a named variable to return a structure containing
;                                the 3 bulk flow vectors associated with the 3 returned
;                                particle distributions
;               V_MAGF      :  Same as V_VSWS, but returns the ambient magnetic field
;                                vectors
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

FUNCTION format_input_for_contour_slide,timeseries,dat,LIMIT_0=lim_00,LIMIT_1=lim_11,   $
                                        TRANGE=trange,TRA_OUT=tra_out,                  $
                                        NOKILL_PH=nokill_ph,XTN_NULL=xtn_empty,         $
                                        AXIS_LIMIT=axis_limit,XNAME=xname,YNAME=yname,  $
                                        VECTOR1=vec1,VECTOR2=vec2,VNAME=vname,          $
                                        BNAME=bname,NO_TRANS=notran,V_VSWS=v_vsws,      $
                                        V_MAGF=v_magf

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
; => Position of all contour plots
;               Xo    Yo    X1    Y1
pos_acon   = [0.10,0.65,0.90,0.90]
; => Position of 1st contour plot
pos_0con   = [0.10,0.65,0.35,0.95]
; => Position of 2nd contour plot
pos_1con   = [0.37,0.65,0.62,0.95]
; => Position of 3rd contour plot
pos_2con   = [0.64,0.65,0.89,0.95]
; => Position of time series plots
;      [includes all plots]
pos_atime  = [0.10,0.10,0.90,0.60]
pos_0time  = [0.10,0.35,0.90,0.60]
pos_1time  = [0.10,0.10,0.90,0.35]
; => positions of the middle of each DF [X,Y]
middf0     = [(pos_0con[2] + pos_0con[0])/2d0,pos_0con[1]]
middf1     = [(pos_1con[2] + pos_1con[0])/2d0,pos_1con[1]]
middf2     = [(pos_2con[2] + pos_2con[0])/2d0,pos_2con[1]]
;-----------------------------------------------------------------------------------------
; => Check TIMESERIES structure format
;-----------------------------------------------------------------------------------------
IF (SIZE(timeseries,/TYPE) NE 8) THEN BEGIN
  MESSAGE,notstr_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
; => check for appropriate tags
n_str      = 2L                 ;  # of different timeseries plots
data_y0    = timeseries.T0.Y    ;  |B| [nT]
data_x0    = timeseries.T0.X    ;  Unix times for |B|
lim_00     = timeseries.T0.LIM  ;  plot limits structure
szy0       = SIZE(data_y0,/N_DIMENSIONS)
str_element,lim_00,'POSITION',pos_0time,/ADD_REPLACE
str_element,lim_00,'XSTYLE',5,/ADD_REPLACE
str_element,lim_00,'XMINOR',5,/ADD_REPLACE
data_y1    = timeseries.T1.Y    ;  B [(Coords), nT]
data_x1    = timeseries.T1.X    ;  Unix times for |B|
lim_11     = timeseries.T1.LIM  ;  plot limits structure
szy1       = SIZE(data_y1,/N_DIMENSIONS)
str_element,lim_11,'POSITION',pos_1time,/ADD_REPLACE
str_element,lim_11,'XSTYLE',5,/ADD_REPLACE
str_element,lim_11,'XMINOR',5,/ADD_REPLACE
;-----------------------------------------------------------------------------------------
; => Determine time range of interest
;-----------------------------------------------------------------------------------------
out_tra    = [MIN([data_x0,data_x1],/NAN),MAX([data_x0,data_x1],/NAN)] + [-6d1,6d1]
IF ~KEYWORD_SET(trange) THEN tra = out_tra ELSE tra = trange
time_ra    = time_range_define(TRANGE=tra)
tra        = time_ra.TR_UNIX
tra_out    = tra

good_0     = WHERE(data_x0 GE tra[0] AND data_x0 LE tra[1],gd0)
good_1     = WHERE(data_x1 GE tra[0] AND data_x1 LE tra[1],gd1)
IF (gd0 GT 0) THEN BEGIN
  IF (szy0 EQ 1) THEN data_y0 = data_y0[good_0]
  IF (szy0 EQ 2) THEN data_y0 = data_y0[good_0,*]
  IF (szy0 EQ 3) THEN data_y0 = data_y0[good_0,*,*]
  data_x0 = data_x0[good_0]
ENDIF ELSE BEGIN
  n_str   = 1
  data_x0 = 0
  data_y0 = 0
  lim_00  = 0
ENDELSE

IF (gd1 GT 0) THEN BEGIN
  IF (szy1 EQ 1) THEN data_y1 = data_y1[good_1]
  IF (szy1 EQ 2) THEN data_y1 = data_y1[good_1,*]
  IF (szy1 EQ 3) THEN data_y1 = data_y1[good_1,*,*]
  data_x1 = data_x1[good_1]
ENDIF ELSE BEGIN
  n_str   = 0
  data_x1 = 0
  data_y1 = 0
  lim_11  = 0
ENDELSE

IF (n_str LT 1) THEN BEGIN
  MESSAGE,notstr_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;-----------------------------------------------------------------------------------------
; => Check existing plot limits values
;-----------------------------------------------------------------------------------------
;  YRANGE
str_element,lim_00,'YRANGE',yra_00
IF (N_ELEMENTS(yra_00) EQ 0) THEN BEGIN
  ymax  = MAX(ABS(data_y0),/NAN)*1.05
  neg   = TOTAL(WHERE(data_y0 LT 0)) GT 0
  IF (neg) THEN BEGIN
    yra   = [-1d0,1d0]*ymax[0]
  ENDIF ELSE BEGIN
    ymin  = MIN(ABS(data_y0),/NAN)*0.95
    yra   = [ymin[0],ymax[0]]
  ENDELSE
ENDIF ELSE BEGIN
  yra   = yra_00
ENDELSE
str_element,lim_00,'YRANGE',yra,/ADD_REPLACE
;  Y-Axis Tick Stuff
str_element,lim_00,'XTICKNAME',xtn_00
str_element,lim_00,'XTICKV',xtv_00
str_element,lim_00,'XTICKS',xts_00
test      = (N_ELEMENTS(xtv_00) EQ 0) OR (N_ELEMENTS(xtn_00) EQ 0)
IF (test) THEN BEGIN
  ; => Need to define tick marks
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
ENDIF ELSE BEGIN
  xtv     = xtv_00
  ; => determine tick names
  tnme0   = time_string(xtv,PREC=3)
  xtn     = STRMID(tnme0[*],0L,10L)+'!C'+STRMID(tnme0[*],11L)
  xts     = N_ELEMENTS(xtn) - 1L
ENDELSE
xtn_empty = REPLICATE(' ',N_ELEMENTS(xtn))  ;  empty string for plotting without tick names

;  YRANGE
str_element,lim_11,'YRANGE',yra_11
IF (N_ELEMENTS(yra_11) EQ 0) THEN BEGIN
  ymax  = MAX(ABS(data_y1),/NAN)*1.05
  neg   = TOTAL(WHERE(data_y1 LT 0)) GT 0
  IF (neg) THEN BEGIN
    yra   = [-1d0,1d0]*ymax[0]
  ENDIF ELSE BEGIN
    ymin  = MIN(ABS(data_y1),/NAN)*0.95
    yra   = [ymin[0],ymax[0]]
  ENDELSE
ENDIF ELSE BEGIN
  yra   = yra_11
ENDELSE
str_element,lim_11,'YRANGE',yra,/ADD_REPLACE
;  Y-Axis Tick Stuff
; => add values to this structure
str_element,lim_11,'XTICKNAME',xtn,/ADD_REPLACE
str_element,lim_11,'XTICKV',xtv,/ADD_REPLACE
str_element,lim_11,'XTICKS',xts,/ADD_REPLACE
; => Make sure these share a common time range
str_element,lim_00,'XRANGE',tra,/ADD_REPLACE
str_element,lim_11,'XRANGE',tra,/ADD_REPLACE
;-----------------------------------------------------------------------------------------
; => Define plot limits appropriate for each step in timeseries plot
;-----------------------------------------------------------------------------------------
; 1st call to AXIS.PRO [top x-axis line (1st timeseries)]
lim_axis_0 = lim_00
str_element,lim_axis_0,'XTICKNAME',xtn_empty,/ADD_REPLACE
str_element,lim_axis_0,'XSTYLE',1,/ADD_REPLACE
str_element,lim_axis_0,'XAXIS',1,/ADD_REPLACE
str_element,lim_axis_0,'POSITION',/DELETE
; 2nd call to AXIS.PRO [bottom x-axis line (1st timeseries)]
lim_axis_1 = lim_00
str_element,lim_axis_1,'XTICKNAME',xtn_empty,/ADD_REPLACE
str_element,lim_axis_1,'XSTYLE',1,/ADD_REPLACE
str_element,lim_axis_1,'XAXIS',0,/ADD_REPLACE
str_element,lim_axis_1,'POSITION',/DELETE
; 3rd call to AXIS.PRO [top x-axis line (2nd timeseries)]
lim_axis_2 = lim_11
str_element,lim_axis_2,'XTICKNAME',xtn_empty,/ADD_REPLACE
str_element,lim_axis_2,'XSTYLE',1,/ADD_REPLACE
str_element,lim_axis_2,'XAXIS',1,/ADD_REPLACE
str_element,lim_axis_2,'POSITION',/DELETE
; 4th call to AXIS.PRO [bottom x-axis line (2nd timeseries)]
lim_axis_3 = lim_11
str_element,lim_axis_3,'XTICKNAME',xtn,/ADD_REPLACE
str_element,lim_axis_3,'XTICKV',xtv,/ADD_REPLACE
str_element,lim_axis_3,'XTICKS',xts,/ADD_REPLACE
str_element,lim_axis_3,'XSTYLE',1,/ADD_REPLACE
str_element,lim_axis_3,'XAXIS',0,/ADD_REPLACE
str_element,lim_axis_3,'CHARSIZE',1.75,/ADD_REPLACE
str_element,lim_axis_3,'POSITION',/DELETE
; => Define axis limits for return
axis_limit = {A0:lim_axis_0,A1:lim_axis_1,A2:lim_axis_2,A3:lim_axis_3}

; => Add NOERASE and NODATA to structures used by PLOT
str_element,lim_00,'NOERASE',1,/ADD_REPLACE
str_element,lim_00,'NODATA',1,/ADD_REPLACE
str_element,lim_11,'NOERASE',1,/ADD_REPLACE
str_element,lim_11,'NODATA',1,/ADD_REPLACE
;-----------------------------------------------------------------------------------------
; => Check DAT structure format
;-----------------------------------------------------------------------------------------
test0      = test_wind_vs_themis_esa_struct(dat,/NOM)
test       = (test0.(0) + test0.(1)) NE 1
IF (test) THEN BEGIN
  MESSAGE,notstr_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;-----------------------------------------------------------------------------------------
; => Check which spacecraft is being used
;-----------------------------------------------------------------------------------------
data       = dat
IF (test0.(0)) THEN BEGIN
  ;-------------------------------------------
  ; Wind
  ;-------------------------------------------
  ; => Check which instrument is being used
  strns   = dat_3dp_str_names(data[0])
  IF (SIZE(strns,/TYPE) NE 8) THEN BEGIN
    RETURN,0
  ENDIF
  shnme   = STRLOWCASE(STRMID(strns.SN[0],0L,2L))
  CASE shnme[0] OF
    'ph' : BEGIN
      ; => Remove data glitch if necessary in PH data
      IF NOT KEYWORD_SET(nokill_ph) THEN BEGIN
        pesa_high_bad_bins,data
        IF (SIZE(onec,/TYPE) EQ 8) THEN BEGIN
          pesa_high_bad_bins,onec
        ENDIF
      ENDIF
      convert_ph_units,data,'df'
    END
    ELSE : BEGIN
      data  = conv_units(data,'df')
    END
  ENDCASE
ENDIF ELSE BEGIN
  ;-------------------------------------------
  ; THEMIS
  ;-------------------------------------------
  ; => make sure the structure has been modified
  test_un = STRLOWCASE(data[0].UNITS_PROCEDURE) NE 'thm_convert_esa_units_lbwiii'
  IF (test_un) THEN BEGIN
    bad_in = 'If THEMIS ESA structures used, then they must be modified using modify_themis_esa_struc.pro'
    MESSAGE,bad_in[0],/INFORMATIONAL,/CONTINUE
    RETURN,0
  ENDIF
  ; => structure modified appropriately so convert units
  data  = conv_units(data,'df')
ENDELSE
;-----------------------------------------------------------------------------------------
; => Find 3 data structures in middle of time range
;-----------------------------------------------------------------------------------------
ndat       = N_ELEMENTS(data)
good_d     = WHERE(data.TIME GE tra[0] AND data.END_TIME LE tra[1],gdd)
IF (gdd GE 3) THEN BEGIN
  data  = data[good_d]
  dumbv = REPLICATE(d,gdd,3L)
  szv1  = SIZE(vec1,/DIMENSIONS)
  szv2  = SIZE(vec2,/DIMENSIONS)
  IF (szv1[0] EQ 0) THEN vector1 = dumbv
  IF (szv2[0] EQ 0) THEN vector2 = dumbv
  IF (N_ELEMENTS(szv1) EQ 2) THEN IF (szv1[0] EQ ndat) THEN vector1 = vec1[good_d,*]
  IF (N_ELEMENTS(szv2) EQ 2) THEN IF (szv2[0] EQ ndat) THEN vector2 = vec2[good_d,*]
  ;;  check if they are set yet...
  IF (SIZE(vector1,/N_DIMENSIONS) EQ 0) THEN vector1 = dumbv
  IF (SIZE(vector2,/N_DIMENSIONS) EQ 0) THEN vector2 = dumbv
ENDIF ELSE BEGIN
  badmssg = 'No particle DFs in selected time range...'
  MESSAGE,badmssg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDELSE
ndat       = N_ELEMENTS(data)
tavg       = (data.TIME + data.END_TIME)/2d0
tr_mid     = (tra[0] + tra[1])/2d0
t_diff     = ABS(tavg - tr_mid[0])
mid_mn     = MIN(t_diff,midel,/NAN)
; make sure MIDEL is not at the start or end
test       = (midel[0] EQ 0L) OR (midel[0] EQ (ndat - 1L))
IF (test) THEN BEGIN
  badmssg = 'Not enough particle DFs in selected time range...'
  MESSAGE,badmssg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF

gels       = midel[0] + [-1L,0L,1L]
dat_00     = data[gels[0]]       ;  1st DF to plot
dat_11     = data[gels[1]]       ;  2nd DF to plot
dat_22     = data[gels[2]]       ;  3rd DF to plot
dat_all    = data[gels]
;;  redefine vectors
vector1    = vector1[gels,*]     ; 3x3 vector array
vector2    = vector2[gels,*]     ; 3x3 vector array
;-----------------------------------------------------------------------------------------
; => Check for finite vectors in VSW and MAGF IDL structure tags
;-----------------------------------------------------------------------------------------
tags     = 'T'+STRING(FORMAT='(I1.1)',LINDGEN(3))
v_vsw0   = TRANSPOSE(REFORM(dat_all.VSW))
v_mag0   = TRANSPOSE(REFORM(dat_all.MAGF))
test_v   = TOTAL(FINITE(v_vsw0)) NE 9
test_b   = TOTAL(FINITE(v_mag0)) NE 9

IF (test_b) THEN BEGIN
  ; => MAGF values are not finite
  v_magf          = CREATE_STRUCT(tags,[1.,0.,0.],[1.,0.,0.],[1.,0.,0.])
  dat_all.MAGF[0] = 1.
  dat_all.MAGF[1] = 0.
  dat_all.MAGF[2] = 0.
  bname           = 'X!DGSE!N'
ENDIF ELSE BEGIN
  ; => MAGF values are okay
  bname        = 'B!Do!N'
  v_magf       = CREATE_STRUCT(tags,dat_all[0].MAGF,dat_all[1].MAGF,dat_all[2].MAGF)
ENDELSE

IF (test_v) THEN BEGIN
  ; => VSW values are not finite
  v_temp          = [0.,1.,0.]
  v_vsws          = CREATE_STRUCT(tags,v_temp,v_temp,v_temp)
  dat_all.VSW[0]  = 0.
  dat_all.VSW[1]  = 1.
  dat_all.VSW[2]  = 0.
  vname           = 'Y!DGSE!N'
  notran          = 1
ENDIF ELSE BEGIN
  ; => VSW values are okay
  vname        = 'V!Dsw!N'
  IF NOT KEYWORD_SET(notran) THEN notran = 0 ELSE notran = notran[0]
  v_vsws       = CREATE_STRUCT(tags,dat_all[0].VSW,dat_all[1].VSW,dat_all[2].VSW)
ENDELSE
;-----------------------------------------------------------------------------------------
; => Check keywords
;-----------------------------------------------------------------------------------------
IF (N_ELEMENTS(vec1) EQ 0) THEN BEGIN
  ; => V1 is NOT set
  xname = bname[0]
  vecs1 = v_magf  ;  structure
ENDIF ELSE BEGIN
  ; => V1 is set
  tags  = 'T'+STRING(FORMAT='(I1.1)',LINDGEN(3))
  IF NOT KEYWORD_SET(xname) THEN xname = 'X' ELSE xname = xname[0]
  vecs1 = CREATE_STRUCT(tags,REFORM(vector1[0,*]),REFORM(vector1[1,*]),REFORM(vector1[2,*]))
ENDELSE

IF (N_ELEMENTS(vec2) EQ 0) THEN BEGIN
  ; => V2 is NOT set
  yname = vname[0]
  vecs2 = v_vsws  ;  structure
ENDIF ELSE BEGIN
  ; => V2 is set
  IF NOT KEYWORD_SET(yname) THEN yname = 'Y' ELSE yname = yname[0]
  vecs2 = CREATE_STRUCT(tags,REFORM(vector2[0,*]),REFORM(vector2[1,*]),REFORM(vector2[2,*]))
ENDELSE
;-----------------------------------------------------------------------------------------
; => Define return structure
;-----------------------------------------------------------------------------------------
times_0    = {X:data_x0,Y:data_y0}
times_1    = {X:data_x1,Y:data_y1}
struct     = {TIME0:times_0,TIME1:times_1,DATA:dat_all,VECS:{V0:vecs1,V1:vecs2}}

RETURN,struct
END


;+
;*****************************************************************************************
;
;  PROCEDURE:   contour_df_pos_slide_plot.pro
;  PURPOSE  :   Takes an input array of particle distribution structures and a set of
;                 time series plots and plots the 3 DFs in the middle of the defined
;                 time range with locations.
;
;  CALLED BY:   
;               contour_df_pos_slide_wrapper.pro
;
;  CALLS:
;               format_input_for_contour_slide.pro
;               time_string.pro
;               read_gen_ascii.pro
;               transform_vframe_3d.pro
;               rotate_3dp_structure.pro
;               str_element.pro
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
;               NA
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
;               VERSION     :  Scalar string defining the name and version of this
;                                routine
;                                [saves time if one version is sent when making movies]
;               VECTOR1     :  [M,3]-Element vector to be used for horizontal axis in
;                                a 2D-projected contour plot [e.g. see eh_cont3d.pro]
;                                [Default = dat.MAGF]
;               VECTOR2     :  [M,3]-Element vector to be used to define the plane made
;                                with VECTOR1  [Default = dat.VSW]
;
;   CHANGED:  1)  Continued to write the routine                   [04/02/2012   v1.0.0]
;             2)  Fixed an issue of conflicting data structures after translating into
;                   bulk frame and rotating into desired frame and 
;                   changed line thickness when in MPEG mode       [04/03/2012   v1.0.1]
;             3)  Changed size of blue dots marking velocity point measurements,
;                   thickness of timeseries lines, and contour line thickness
;                                                                  [04/05/2012   v1.0.2]
;             4)  Cleaned up and rewrote:
;                   A)  no longer calls  :  time_range_define.pro,
;                         test_wind_vs_themis_esa_struct.pro, dat_3dp_str_names.pro,
;                         pesa_high_bad_bins.pro, convert_ph_units.pro,
;                         conv_units.pro
;                   B)  now calls        :  format_input_for_contour_slide.pro
;                                                                  [04/05/2012   v2.0.0]
;             5)  Fixed an indexing error in the wrapping routine
;                                                                  [06/08/2012   v2.0.1]
;
;   NOTES:      
;               1)  Use contour_df_pos_slide_wrapper.pro to call this program
;               2)  See also:  contour_df_pos_slide_wrapper.pro
;
;   CREATED:  03/30/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  06/08/2012   v2.0.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO contour_df_pos_slide_plot,timeseries,dat,VLIM=vlim,NGRID=ngrid,XNAME=xname,        $
                              YNAME=yname,DFRA=dfra,VCIRC=vcirc,EX_VEC0=ex_vec0,       $
                              EX_VN0=ex_vn0,EX_VEC1=ex_vec1,EX_VN1=ex_vn1,             $
                              NOKILL_PH=nokill_ph,PLANE=plane,NO_TRANS=no_trans,       $
                              INTERP=interpo,SM_CONT=sm_cont,DFMIN=dfmin,DFMAX=dfmax,  $
                              TRANGE=trange,VERSION=version,VECTOR1=vector1,           $
                              VECTOR2=vector2

;-----------------------------------------------------------------------------------------
; => Define some constants and dummy variables
;-----------------------------------------------------------------------------------------
f          = !VALUES.F_NAN
d          = !VALUES.D_NAN

; => Position of all contour plots
;               Xo    Yo    X1    Y1
pos_acon   = [0.10,0.65,0.90,0.90]
; => Position of 1st contour plot
pos_0con   = [0.10,0.65,0.35,0.95]
; => Position of 2nd contour plot
pos_1con   = [0.37,0.65,0.62,0.95]
; => Position of 3rd contour plot
pos_2con   = [0.64,0.65,0.89,0.95]
; => Position of time series plots
;      [includes all plots]
pos_atime  = [0.10,0.10,0.90,0.60]
pos_0time  = [0.10,0.35,0.90,0.60]
pos_1time  = [0.10,0.10,0.90,0.35]
; => positions of the middle of each DF [X,Y]
middf0     = [(pos_0con[2] + pos_0con[0])/2d0,pos_0con[1]]
middf1     = [(pos_1con[2] + pos_1con[0])/2d0,pos_1con[1]]
middf2     = [(pos_2con[2] + pos_2con[0])/2d0,pos_2con[1]]

; => Dummy error messages
noinpt_msg = 'No input supplied...'
notstr_msg = 'Must be an IDL structure...'
nofint_msg = 'No finite data...'
notidl_msg = 'DAT must be an array of IDL structures...'

lower_lim  = 1e-20  ; => Lowest expected value for DF
upper_lim  = 1e-2   ; => Highest expected value for DF
; => Dummy tick mark arrays
exp_val    = LINDGEN(50) - 50L                    ; => Array of exponent values
ytns       = '10!U'+STRTRIM(exp_val[*],2L)+'!N'   ; => Y-Axis tick names
ytvs       = 1d1^FLOAT(exp_val[*])                ; => Y-Axis tick values
;-----------------------------------------------------------------------------------------
; => Check input
;-----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ; => no input???
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  ; => Create empty plot
  !P.MULTI = 0
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA
  RETURN
ENDIF
;-----------------------------------------------------------------------------------------
; => Format TIMESERIES and DAT
;-----------------------------------------------------------------------------------------
IF ~KEYWORD_SET(xname) THEN xn_out = '' ELSE xn_out = xname[0]
IF ~KEYWORD_SET(yname) THEN yn_out = '' ELSE yn_out = yname[0]

time_dat = format_input_for_contour_slide(timeseries,dat,LIMIT_0=lim_00,LIMIT_1=lim_11,  $
                                          TRANGE=trange,TRA_OUT=tra,NOKILL_PH=nokill_ph, $
                                          XTN_NULL=xtn_empty,AXIS_LIMIT=axis_limit,      $
                                          XNAME=xn_out,YNAME=yn_out,VECTOR1=vector1,     $
                                          VECTOR2=vector2,VNAME=vname,BNAME=bname,$
                                          NO_TRANS=no_trans,V_VSWS=v_vsws,V_MAGF=v_magf)
; => Make sure routine returned a structure
IF (SIZE(time_dat,/TYPE) NE 8) THEN BEGIN
  ; => Create empty plot
  !P.MULTI = 0
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA
  RETURN
ENDIF
; => Define XY-Data
data_x0    = time_dat.TIME0.X    ;  1st timeseries Unix times
data_y0    = time_dat.TIME0.Y    ;  1st timeseries data
data_x1    = time_dat.TIME1.X    ;  2nd timeseries Unix times
data_y1    = time_dat.TIME1.Y    ;  2nd timeseries data
szy0       = SIZE(data_y0,/N_DIMENSIONS)
szy1       = SIZE(data_y1,/N_DIMENSIONS)
; => Define AXIS limits structures
; 1st call to AXIS.PRO [top x-axis line (1st timeseries)]
axis_lim_0 = axis_limit.A0
; 2nd call to AXIS.PRO [bottom x-axis line (1st timeseries)]
axis_lim_1 = axis_limit.A1
; 3rd call to AXIS.PRO [top x-axis line (2nd timeseries)]
axis_lim_2 = axis_limit.A2
; 4th call to AXIS.PRO [bottom x-axis line (2nd timeseries)]
axis_lim_3 = axis_limit.A3

; => Define 3 data structures in middle of time range
dat_all    = time_dat.DATA
dat_00     = dat_all[0L]         ;  1st DF to plot
dat_11     = dat_all[1L]         ;  2nd DF to plot
dat_22     = dat_all[2L]         ;  3rd DF to plot
; => Define 2 vector structures which define the plane of projection for our interests
vec1       = time_dat.VECS.V0    ;  horizontal axis [if XY plane chosen]
vec2       = time_dat.VECS.V1    ;  "almost" vertical axis [if XY plane chosen]
;-----------------------------------------------------------------------------------------
; => Define contour plot titles
;-----------------------------------------------------------------------------------------
title0     = dat_all.PROJECT_NAME[0]+'  '+dat_all.DATA_NAME[0]
tra_s      = time_string(dat_all.TIME[0])
tra_e      = time_string(dat_all.END_TIME[0])
tra_out    = tra_s+' - '+STRMID(tra_e[*],11)
con_ttl    = title0+'!C'+tra_out
;;########################################################################################
;; => Define version for output
;;########################################################################################
IF ~KEYWORD_SET(version) THEN BEGIN
  mdir       = FILE_EXPAND_PATH('wind_3dp_pros/LYNN_PRO/')+'/'
  file       = FILE_SEARCH(mdir,'contour_df_pos_slide_plot.pro')
  fstring    = read_gen_ascii(file[0],FIRST_NC=50L)
  shifts     = STRLEN(';    LAST MODIFIED:  ')
  test       = STRPOS(STRMID(fstring,0L,shifts[0]),';    LAST MODIFIED:  ') GE 0
  gposi      = WHERE(test,gpf)
  IF (gpf GT 1) THEN f_str_g = fstring[gposi[gpf - 1L]] ELSE f_str_g = fstring[gposi[0]]
  vers       = STRMID(f_str_g[0],shifts[0])
  vers0      = 'contour_df_pos_slide_plot.pro : '+vers[0]+', '
  version    = vers0[0]+time_string(SYSTIME(1,/SECONDS),PREC=3)
ENDIF
;-----------------------------------------------------------------------------------------
; => Check keywords
;-----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(no_redf)  THEN noredf = 0       ELSE noredf = no_redf[0]
IF NOT KEYWORD_SET(plane)    THEN projxy = 'xy'    ELSE projxy = STRLOWCASE(plane[0])
IF NOT KEYWORD_SET(sm_cont)  THEN sm_con = 0       ELSE sm_con = 1

; => Define # of levels to use for contour.pro
IF NOT KEYWORD_SET(ngrid) THEN ngrid = 30L 
; => Define velocity limit (km/s)
IF NOT KEYWORD_SET(vlim) THEN BEGIN
  allener = dat_all.ENERGY
  allvlim = SQRT(2d0*allener/dat_all[0].MASS)
  vlim    = MAX(allvlim,/NAN)
ENDIF ELSE BEGIN
  vlim    = DOUBLE(vlim[0])
ENDELSE
;-----------------------------------------------------------------------------------------
; => Convert into solar wind frame
;-----------------------------------------------------------------------------------------
transform_vframe_3d,dat_00,/EASY_TRAN,NO_TRANS=notran,INTERP=interpo
transform_vframe_3d,dat_11,/EASY_TRAN,NO_TRANS=notran,INTERP=interpo
transform_vframe_3d,dat_22,/EASY_TRAN,NO_TRANS=notran,INTERP=interpo
;-----------------------------------------------------------------------------------------
; => Calculate distribution function in rotated reference frame
;-----------------------------------------------------------------------------------------
rotate_3dp_structure,dat_00,vec1.(0L),vec2.(0L),VLIM=vlim[0]
rotate_3dp_structure,dat_11,vec1.(1L),vec2.(1L),VLIM=vlim[0]
rotate_3dp_structure,dat_22,vec1.(2L),vec2.(2L),VLIM=vlim[0]
;-----------------------------------------------------------------------------------------
; => Define plot parameters
;-----------------------------------------------------------------------------------------
xaxist = '(V dot '+xn_out[0]+') [1000 km/s]'
yaxist = '('+xn_out[0]+' x '+yn_out[0]+') x '+xn_out[0]+' [1000 km/s]'
zaxist = '('+xn_out[0]+' x '+yn_out[0]+') [1000 km/s]'
; => Create structures for each...
tags     = 'T'+STRING(FORMAT='(I1.1)',LINDGEN(3))
CASE projxy[0] OF
  'xy'  : BEGIN
    ;-------------------------------------------------------------------------------------
    ; => plot Y vs. X
    ;-------------------------------------------------------------------------------------
    ; => Define horizontal and vertical axis titles
    xttl00 = xaxist
    yttl00 = yaxist
    ; => Define rotation matrices
    rmat   = CREATE_STRUCT(tags,dat_00.ROT_MAT,dat_11.ROT_MAT,dat_22.ROT_MAT)
    ; => Define data projection
    df2d   = CREATE_STRUCT(tags,dat_00.DF2D_XY,dat_11.DF2D_XY,dat_22.DF2D_XY)
    ; => Define actual velocities for contour plot
    vxpts  = CREATE_STRUCT(tags,dat_00.VELX_XY,dat_11.VELX_XY,dat_22.VELX_XY)
    vypts  = CREATE_STRUCT(tags,dat_00.VELY_XY,dat_11.VELY_XY,dat_22.VELY_XY)
    vzpts  = CREATE_STRUCT(tags,dat_00.VELZ_XY,dat_11.VELZ_XY,dat_22.VELZ_XY)
    ; => define elements [x,y]
    gels   = [0L,1L]
  END
  'xz'  : BEGIN
    ;-------------------------------------------------------------------------------------
    ; => plot X vs. Z
    ;-------------------------------------------------------------------------------------
    ; => Define horizontal and vertical axis titles
    xttl00 = zaxist
    yttl00 = xaxist
    ; => Define rotation matrices
    rmat   = CREATE_STRUCT(tags,dat_00.ROT_MAT,dat_11.ROT_MAT,dat_22.ROT_MAT)
    ; => Define data projection
    df2d   = CREATE_STRUCT(tags,dat_00.DF2D_XZ,dat_11.DF2D_XZ,dat_22.DF2D_XZ)
    ; => Define actual velocities for contour plot
    vxpts  = CREATE_STRUCT(tags,dat_00.VELX_XZ,dat_11.VELX_XZ,dat_22.VELX_XZ)
    vypts  = CREATE_STRUCT(tags,dat_00.VELY_XZ,dat_11.VELY_XZ,dat_22.VELY_XZ)
    vzpts  = CREATE_STRUCT(tags,dat_00.VELZ_XZ,dat_11.VELZ_XZ,dat_22.VELZ_XZ)
    ; => define elements [x,y]
    gels   = [2L,0L]
  END
  'yz'  : BEGIN
    ;-------------------------------------------------------------------------------------
    ; => plot Z vs. Y
    ;-------------------------------------------------------------------------------------
    ; => Define horizontal and vertical axis titles
    xttl00 = yaxist
    yttl00 = zaxist
    ; => Define rotation matrices
    rmat   = CREATE_STRUCT(tags,dat_00.ROT_MAT_Z,dat_11.ROT_MAT_Z,dat_22.ROT_MAT_Z)
    ; => Define data projection
    df2d   = CREATE_STRUCT(tags,dat_00.DF2D_YZ,dat_11.DF2D_YZ,dat_22.DF2D_YZ)
    ; => Define actual velocities for contour plot
    vxpts  = CREATE_STRUCT(tags,dat_00.VELX_YZ,dat_11.VELX_YZ,dat_22.VELX_YZ)
    vypts  = CREATE_STRUCT(tags,dat_00.VELY_YZ,dat_11.VELY_YZ,dat_22.VELY_YZ)
    vzpts  = CREATE_STRUCT(tags,dat_00.VELZ_YZ,dat_11.VELZ_YZ,dat_22.VELZ_YZ)
    ; => define elements [x,y]
    gels   = [0L,1L]
  END
  ELSE  : BEGIN
    ;-------------------------------------------------------------------------------------
    ; => use default:  Y vs. X
    ;-------------------------------------------------------------------------------------
    ; => Define horizontal and vertical axis titles
    xttl00 = xaxist
    yttl00 = yaxist
    ; => Define rotation matrices
    rmat   = CREATE_STRUCT(tags,dat_00.ROT_MAT,dat_11.ROT_MAT,dat_22.ROT_MAT)
    ; => Define data projection
    df2d   = CREATE_STRUCT(tags,dat_00.DF2D_XY,dat_11.DF2D_XY,dat_22.DF2D_XY)
    ; => Define actual velocities for contour plot
    vxpts  = CREATE_STRUCT(tags,dat_00.VELX_XY,dat_11.VELX_XY,dat_22.VELX_XY)
    vypts  = CREATE_STRUCT(tags,dat_00.VELY_XY,dat_11.VELY_XY,dat_22.VELY_XY)
    vzpts  = CREATE_STRUCT(tags,dat_00.VELZ_XY,dat_11.VELZ_XY,dat_22.VELZ_XY)
    ; => define elements [x,y]
    gels   = [0L,1L]
  END
ENDCASE
; => Define regularly gridded velocities for contour plot
vx2d   = CREATE_STRUCT(tags,dat_00.VX2D,dat_11.VX2D,dat_22.VX2D)
vy2d   = CREATE_STRUCT(tags,dat_00.VY2D,dat_11.VY2D,dat_22.VY2D)
;-----------------------------------------------------------------------------------------
; => Define the 2D projection of the VSW IDL structure tag in DAT and other vectors
;-----------------------------------------------------------------------------------------
test_b   = SIZE(v_magf,/TYPE) NE 8
test_v   = SIZE(v_vsws,/TYPE) NE 8
d3df     = REPLICATE(f,3)
IF (test_v) THEN v_vsws = CREATE_STRUCT(tags,d3df,d3df,d3df)
IF (test_b) THEN v_magf = CREATE_STRUCT(tags,d3df,d3df,d3df)
;;  define a normalization factor for projections
v_mfac   = (vlim[0]*95d-2)*1d-3
v_mag    = DBLARR(3L)
FOR j=0L, 2L DO v_mag[j] = SQRT(TOTAL(v_vsws.(j)^2,/NAN))

IF (test_v EQ 0) THEN BEGIN
  vswname = '- - - : '+vname[0]+' Projection'
  vxy_pro = DBLARR(3L,3L)
  vsw2d00 = DBLARR(3L,2L)
  FOR j=0L, 2L DO BEGIN
    ; => Define the unit vector projection onto the plane of interest
    vxy_pro = REFORM(rmat.(j) ## v_vsws.(j))/v_mag[j]
    ; => Scale the projection to the appropriate plot limits
    vsw2d00 = vxy_pro[gels]/SQRT(TOTAL(vxy_pro[gels]^2,/NAN))*v_mfac[0]
    ; => Create structures of rotated, scaled, and projected Vsw vectors
    str_element,vsw2dx,tags[j],[0.,vsw2d00[0]],/ADD_REPLACE
    str_element,vsw2dy,tags[j],[0.,vsw2d00[1]],/ADD_REPLACE
  ENDFOR
ENDIF ELSE BEGIN
  vswname = ''
  d2f     = REPLICATE(f,2)
  vsw2dx  = CREATE_STRUCT(tags,d2f,d2f,d2f)
  vsw2dy  = CREATE_STRUCT(tags,d2f,d2f,d2f)
ENDELSE
;-----------------------------------------------------------------------------------------
; => Check for EX_VEC0 and EX_VEC1
;-----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(ex_vec0) THEN evec0 = REPLICATE(f,3) ELSE evec0 = FLOAT(REFORM(ex_vec0))
IF NOT KEYWORD_SET(ex_vec1) THEN evec1 = REPLICATE(f,3) ELSE evec1 = FLOAT(REFORM(ex_vec1))
; => Define logic variables for output later
IF (TOTAL(FINITE(evec0)) NE 3) THEN out_v0 = 0 ELSE out_v0 = 1
IF (TOTAL(FINITE(evec1)) NE 3) THEN out_v1 = 0 ELSE out_v1 = 1
IF NOT KEYWORD_SET(ex_vn0) THEN vec0n = 'Vec 1' ELSE vec0n = ex_vn0[0]
IF NOT KEYWORD_SET(ex_vn1) THEN vec1n = 'Vec 2' ELSE vec1n = ex_vn1[0]
; => Rotate 1st extra vector
IF (out_v0) THEN BEGIN
  FOR j=0L, 2L DO BEGIN
    evec_r0 = REFORM(rmat.(j) ## evec0)/NORM(evec0)
    ; => renormalize
    evec_r0 = evec_r0/SQRT(TOTAL(evec_r0[gels]^2,/NAN))*v_mfac[0]
    ; => store data
    str_element,evec_0x,tags[j],[0.,evec_r0[gels[0L]]],/ADD_REPLACE
    str_element,evec_0y,tags[j],[0.,evec_r0[gels[1L]]],/ADD_REPLACE
  ENDFOR
ENDIF ELSE BEGIN
  FOR j=0L, 2L DO BEGIN
    str_element,evec_0x,tags[j],REPLICATE(f,2),/ADD_REPLACE
    str_element,evec_0y,tags[j],REPLICATE(f,2),/ADD_REPLACE
  ENDFOR
ENDELSE
; => Rotate 2nd extra vector
IF (out_v1) THEN BEGIN
  FOR j=0L, 2L DO BEGIN
    evec_r1 = REFORM(rmat.(j) ## evec1)/NORM(evec1)
    ; => renormalize
    evec_r1 = evec_r1/SQRT(TOTAL(evec_r1[gels]^2,/NAN))*v_mfac[0]
    ; => store data
    str_element,evec_1x,tags[j],[0.,evec_r1[gels[0L]]],/ADD_REPLACE
    str_element,evec_1y,tags[j],[0.,evec_r1[gels[1L]]],/ADD_REPLACE
  ENDFOR
ENDIF ELSE BEGIN
  FOR j=0L, 2L DO BEGIN
    str_element,evec_1x,tags[j],REPLICATE(f,2),/ADD_REPLACE
    str_element,evec_1y,tags[j],REPLICATE(f,2),/ADD_REPLACE
  ENDFOR
ENDELSE
;-----------------------------------------------------------------------------------------
; => Define dummy DF ranges of values
;-----------------------------------------------------------------------------------------
cf       = 0L  ;  used to count which DFs have finite data
FOR j=0L, 2L DO BEGIN
  vel_2d   = (vx2d.(j) # vy2d.(j))/vlim[0]
  test_vr  = (ABS(vel_2d) LE 0.75*vlim[0])
  test_df  = (df2d.(j) GT 0.) AND FINITE(df2d.(j))
  good     = WHERE(test_vr AND test_df,gd)
  good2    = WHERE(test_df,gd2)
  IF (gd GT 0) THEN BEGIN
    ; => Finite data within 75% of Vmax
    mndf0  = MIN(ABS(df2d.(j)[good]),/NAN) > lower_lim[0]
    mxdf0  = MAX(ABS(df2d.(j)[good]),/NAN) < upper_lim[0]
    cf    += 1L
  ENDIF ELSE BEGIN
    IF (gd2 GT 0) THEN BEGIN
      ; => some finite data exists
      mndf0  = MIN(ABS(df2d.(j)[good2]),/NAN) > lower_lim[0]
      mxdf0  = MAX(ABS(df2d.(j)[good2]),/NAN) < upper_lim[0]
      cf    += 1L
    ENDIF ELSE BEGIN
      ; => no finite data exists
      mndf0  = d
      mxdf0  = d
    ENDELSE
  ENDELSE
  str_element,mndf,tags[j],mndf0[0],/ADD_REPLACE
  str_element,mxdf,tags[j],mxdf0[0],/ADD_REPLACE
ENDFOR

IF (cf LT 1) THEN BEGIN
  ; => no finite data
  MESSAGE,nofint_msg[0],/INFORMATIONAL,/CONTINUE
  ; => Create empty plot
  !P.MULTI = 0
  PLOT,[0.0,1.0],[0.0,1.0],/NODATA
  RETURN
ENDIF
;-----------------------------------------------------------------------------------------
; => Define DF range and corresponding contour levels, colors, etc.
;-----------------------------------------------------------------------------------------
mx_dfra  = MAX([mxdf.(0L),mxdf.(1L),mxdf.(2L)],/NAN)*1.05d0
mn_dfra  = MIN([mndf.(0L),mndf.(1L),mndf.(2L)],/NAN)*0.95d0
; => Use ONE scale for all 3 DF plots
IF NOT KEYWORD_SET(dfra) THEN df_ran = [mn_dfra[0],mx_dfra[0]] ELSE df_ran = dfra
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
;-----------------------------------------------------------------------------------------
; => Define plot limits structures
;-----------------------------------------------------------------------------------------
xyran    = [-1d0,1d0]*vlim[0]*1d-3
xyra3    = xyran*3d0
; => structures for contour plots
;      [used to set up plot area]
lim_cont = {XRANGE:xyra3,XSTYLE:5,XLOG:0,XTITLE:xttl00,XMINOR:11, $
            YRANGE:xyran,YSTYLE:5,YLOG:0,YTITLE:yttl00,YMINOR:11, $
            NODATA:1,POSITION:pos_acon}
;      [used to set up plots for each contour]
lim_cn0  = {XRANGE:xyran,XSTYLE:1,XLOG:0,XTITLE:xttl00,XMINOR:11, $
            YRANGE:xyran,YSTYLE:1,YLOG:0,YTITLE:yttl00,YMINOR:11, $
            POSITION:pos_0con,TITLE:con_ttl[0L],NODATA:1}
lim_cn1  = {XRANGE:xyran,XSTYLE:1,XLOG:0,XTITLE:xttl00,XMINOR:11, $
            YRANGE:xyran,YSTYLE:1,YLOG:0,YMINOR:11, $
            POSITION:pos_1con,TITLE:con_ttl[1L],NODATA:1}
lim_cn2  = {XRANGE:xyran,XSTYLE:1,XLOG:0,XTITLE:xttl00,XMINOR:11, $
            YRANGE:xyran,YSTYLE:1,YLOG:0,YMINOR:11, $
            POSITION:pos_2con,TITLE:con_ttl[2L],NODATA:1}
lim_cns  = CREATE_STRUCT(tags,lim_cn0,lim_cn1,lim_cn2)
;      [used to plot contours]
con_lim  = {OVERPLOT:1,LEVELS:levels,C_COLORS:c_cols}

; => Smooth contours if desired
IF KEYWORD_SET(sm_con) THEN BEGIN
  FOR j=0L, 2L DO BEGIN
    df2d_0 = SMOOTH(df2d.(j),3L,/EDGE_TRUNCATE,/NAN)
    str_element,df2ds,tags[j],df2d_0,/ADD_REPLACE
  ENDFOR
ENDIF ELSE BEGIN
  df2ds   = df2d
ENDELSE
;-----------------------------------------------------------------------------------------
; => Plot
;-----------------------------------------------------------------------------------------
;          [plots left, # cols, # rows, # stacked (z-dir), direction of plots]
; !P.MULTI[4] :  False = (left-to-right, top-to-bottom)
;                True  = (top-to-bottom, left-to-right)
;-----------------------------------------------------------------------------------------
!P.MULTI = [5,1,3,0,0]
IF (STRLOWCASE(!D.NAME) EQ 'z') THEN ps_chsz  = 1.00 ELSE ps_chsz  = 0.50
IF (STRLOWCASE(!D.NAME) EQ 'z') THEN l_thick  = 3    ELSE l_thick  = 2
IF (STRLOWCASE(!D.NAME) EQ 'z') THEN lnstyle  = 0L   ELSE lnstyle  = 2L
;  [don't use dashed lines for movies... they "move"]
IF (STRLOWCASE(!D.NAME) EQ 'z') THEN ch_thick = 1    ELSE ch_thick = 2
;  color of EX_VEC1 and EX_VN1 output
IF (STRLOWCASE(!D.NAME) EQ 'z') THEN vc2_col  = 100L ELSE vc2_col  = 50L
vc1_col    = 250L  ;  color of EX_VEC0 and EX_VN0 output
;  change contour line thickness if movie
IF (STRLOWCASE(!D.NAME) EQ 'z') THEN c_thick  = 1.15 ELSE c_thick  = 1.0
; => Defined user symbol for outputing locations of data on contour
IF (STRLOWCASE(!D.NAME) EQ 'z') THEN dotsz    = 0.15 ELSE dotsz    = 0.27
xxo        = FINDGEN(17)*(!PI*2./16.)
USERSYM,dotsz[0]*COS(xxo),dotsz[0]*SIN(xxo),/FILL
;-----------------------------------------------------------------------------------------
; => Set up and plot contours
;-----------------------------------------------------------------------------------------
FOR kk=0L, 2L DO BEGIN
  PLOT,[0.0,1.0],[0.0,1.0],_EXTRA=lim_cns.(kk),CHARTHICK=ch_thick[0]
    ; => Project locations of actual data points onto kk-th contour
    OPLOT,vxpts.(kk)*1d-3,vypts.(kk)*1d-3,PSYM=8,SYMSIZE=1.0,COLOR=100
    ;-------------------------------------------------------------------------------------
    ; => Draw kk-th contour
    ;-------------------------------------------------------------------------------------
    CONTOUR,df2ds.(kk),vx2d.(kk)*1d-3,vy2d.(kk)*1d-3,_EXTRA=con_lim,C_THICK=c_thick[0]
    ;-------------------------------------------------------------------------------------
    ; => Project V_sw onto contour
    ;-------------------------------------------------------------------------------------
    OPLOT,vsw2dx.(kk),vsw2dy.(kk),LINESTYLE=0,THICK=l_thick[0]*1.10d0
    xyposi = [-1d0*.90*vlim[0],0.90*vlim[0]]*1d-3
    IF (test_v EQ 0) THEN BEGIN
      IF (STRLOWCASE(!D.NAME) EQ 'x') THEN BEGIN
        XYOUTS,xyposi[0],xyposi[1],vswname[0],/DATA,CHARTHICK=ch_thick[0]
      ENDIF ELSE BEGIN
        XYOUTS,xyposi[0],xyposi[1],vswname[0],/DATA,CHARSIZE=ps_chsz[0],CHARTHICK=ch_thick[0]
      ENDELSE
      ; => Shift in negative Y-Direction
      xyposi[1] -= 0.08*vlim*1d-3
    ENDIF
    ;-------------------------------------------------------------------------------------
    ; => Project 1st extra vector onto contour
    ;-------------------------------------------------------------------------------------
    ;  [don't use dashed lines for movies... they "move"]
    OPLOT,evec_0x.(kk),evec_0y.(kk),LINESTYLE=lnstyle[0],COLOR=vc1_col[0],$
                                    THICK=l_thick[0]*1.15d0
    IF (out_v0) THEN BEGIN
      IF (STRLOWCASE(!D.NAME) EQ 'x') THEN BEGIN
        XYOUTS,xyposi[0],xyposi[1],vec0n[0],/DATA,COLOR=vc1_col[0],CHARTHICK=ch_thick[0]
      ENDIF ELSE BEGIN
        XYOUTS,xyposi[0],xyposi[1],vec0n[0],/DATA,COLOR=vc1_col[0],$
               CHARSIZE=ps_chsz[0],CHARTHICK=ch_thick[0]
      ENDELSE
      ; => Shift in negative Y-Direction
      xyposi[1] -= 0.08*vlim*1d-3
    ENDIF
    ;-------------------------------------------------------------------------------------
    ; => Project 2nd extra vector onto contour
    ;-------------------------------------------------------------------------------------
    ;  [don't use dashed lines for movies... they "move"]
    OPLOT,evec_1x.(kk),evec_1y.(kk),LINESTYLE=lnstyle[0],COLOR=vc2_col[0],$
                                    THICK=l_thick[0]*1.15d0
    IF (out_v1) THEN BEGIN
      IF (STRLOWCASE(!D.NAME) EQ 'x') THEN BEGIN
        XYOUTS,xyposi[0],xyposi[1],vec1n[0],/DATA,COLOR=vc2_col[0],CHARTHICK=ch_thick[0]
      ENDIF ELSE BEGIN
        XYOUTS,xyposi[0],xyposi[1],vec1n[0],/DATA,COLOR=vc2_col[0],$
               CHARSIZE=ps_chsz[0],CHARTHICK=ch_thick[0]
      ENDELSE
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
        ;  [don't use dashed lines for movies... they "move"]
        OPLOT,vxcirc,vycirc,LINESTYLE=lnstyle[0],THICK=l_thick[0]
      ENDFOR
    ENDIF
ENDFOR
;-----------------------------------------------------------------------------------------
; => Plot 1st time series
;-----------------------------------------------------------------------------------------
IF (STRLOWCASE(!D.NAME) EQ 'z') THEN l_thick = 1.75 ELSE l_thick = 1
PLOT,data_x0,data_y0,_EXTRA=lim_00,CHARTHICK=ch_thick[0]
  ; => Put top X-Axes on plot
  AXIS,_EXTRA=axis_lim_0
  AXIS,_EXTRA=axis_lim_1
  IF (szy0 EQ 2) THEN BEGIN
    ; => 2D data
    OPLOT,data_x0,data_y0[*,0],COLOR=250L,THICK=l_thick[0]
    OPLOT,data_x0,data_y0[*,1],COLOR=150L,THICK=l_thick[0]
    OPLOT,data_x0,data_y0[*,2],COLOR= 50L,THICK=l_thick[0]
  ENDIF ELSE BEGIN
    ; => 1D data
    OPLOT,data_x0,data_y0,THICK=l_thick[0]
  ENDELSE
  ;---------------------------------------------------------------------------------------
  ; => Draw ESA Times on plot
  ;---------------------------------------------------------------------------------------
  yra     = lim_00.YRANGE
  s_tims  = [dat_00.TIME,dat_11.TIME,dat_22.TIME]
  e_tims  = [dat_00.END_TIME,dat_11.END_TIME,dat_22.END_TIME]
  deltd   = MAX(e_tims,/NAN) - MIN(s_tims,/NAN)
  deltr   = MAX(tra,/NAN) - MIN(tra,/NAN)
  ;  start times
  FOR i=0L, 2L DO OPLOT,[s_tims[i],s_tims[i]],yra,COLOR=250L,THICK=l_thick[0]
  ;  plot last end time
  OPLOT,[e_tims[2],e_tims[2]],yra,COLOR= 30L,THICK=l_thick[0]
  ; => Plot lines from vertical to DFs
  xdat    = s_tims
  ydat    = REPLICATE(yra[1],3L)
  dat2nor = CONVERT_COORD(xdat,ydat,/DATA,/TO_NORMAL)
  xnor    = REFORM(dat2nor[0L,*])
  ynor    = REFORM(dat2nor[1L,*])
  hsize   = 1d-4
  ; => Arrow to 1st DF
  ARROW,xnor[0],ynor[0],middf0[0],middf0[1],/NORMALIZED,COLOR=250L,HSIZE=hsize[0],THICK=l_thick[0]
  ; => Arrow to 2nd DF
  ARROW,xnor[1],ynor[1],middf1[0],middf1[1],/NORMALIZED,COLOR=250L,HSIZE=hsize[0],THICK=l_thick[0]
  ; => Arrow to 3rd DF
  ARROW,xnor[2],ynor[2],middf2[0],middf2[1],/NORMALIZED,COLOR=250L,HSIZE=hsize[0],THICK=l_thick[0]
;-----------------------------------------------------------------------------------------
; => Plot 2nd time series
;-----------------------------------------------------------------------------------------
PLOT,data_x1,data_y1,_EXTRA=lim_11,CHARTHICK=ch_thick[0]
  ; => Put top X-Axes on plot
  AXIS,_EXTRA=axis_lim_2
  AXIS,_EXTRA=axis_lim_3,CHARTHICK=ch_thick[0]
  IF (szy1 EQ 2) THEN BEGIN
    ; => 2D data
    OPLOT,data_x1,data_y1[*,0],COLOR=250L,THICK=l_thick[0]
    OPLOT,data_x1,data_y1[*,1],COLOR=150L,THICK=l_thick[0]
    OPLOT,data_x1,data_y1[*,2],COLOR= 50L,THICK=l_thick[0]
  ENDIF ELSE BEGIN
    ; => 1D data
    OPLOT,data_x1,data_y1,THICK=l_thick[0]
  ENDELSE
  ;---------------------------------------------------------------------------------------
  ; => Draw ESA Times on plot
  ;---------------------------------------------------------------------------------------
  ;  start times
  yra     = lim_11.YRANGE
  ;  start times
  FOR i=0L, 2L DO OPLOT,[s_tims[i],s_tims[i]],yra,COLOR=250L,THICK=l_thick[0]
  ;  plot last end time
  OPLOT,[e_tims[2],e_tims[2]],yra,COLOR= 30L,THICK=l_thick[0]
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;-----------------------------------------------------------------------------------------
; => Output version # and date produced
;-----------------------------------------------------------------------------------------
IF (STRLOWCASE(!D.NAME) EQ 'x') THEN chsz = 0.85 ELSE chsz = 0.65
XYOUTS,0.915,0.10,version[0],CHARSIZE=chsz[0],/NORMAL,ORIENTATION=90.,CHARTHICK=ch_thick[0]
;-----------------------------------------------------------------------------------------
; => Return
;-----------------------------------------------------------------------------------------
!P.MULTI = 0

RETURN
END







