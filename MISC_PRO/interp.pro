;+
;*****************************************************************************************
;
;  FUNCTION :   interp.pro
;  PURPOSE  :   Linearly Interpolates vectors with an irregular grid.  INTERP is
;                 functionally the same as INTERPOL (with no keywords defining the type
;                 of interpolation), however it is typically much faster for most
;                 applications.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               interp.pro
;               dprint.pro
;               minmax.pro
;
;  REQUIRES:    
;               1)  SPEDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               Y                   :  [N]-Element array of data of any type except
;                                        a string
;               X                   :  [N]-Element absicissae values for Y.
;                                        The values MUST be monotonically ascending
;                                        or descending.
;               U                   :  [M]-Element absicissae values for the result.
;                                        The returned array will have the same number of
;                                        elements as U.
;
;  EXAMPLES:    
;               [calling sequence]
;               result = interp(y, x, u [,INDEX=index] [,/NO_CHECK_MONOTONIC]           $
;                               [,/NO_EXTRAPOLATE] [,INTERP_THRESHOLD=interp_threshold] $
;                               [,/IGNORE_NAN])
;
;  KEYWORDS:    
;               INDEX               :  Set to named variable to return the index of
;                                        the closest X less than U.  Output will have the
;                                        same number of elements as U.
;               NO_CHECK_MONOTONIC  :  If set, program does not check for monotonic data.
;                                        [Default = FALSE]
;               NO_EXTRAPOLATE      :  If set, program will not extrapolate end point data.
;                                        [Default = FALSE]
;               INTERP_THRESHOLD    :  Scalar [numeric] defining the minimum allowable
;                                        gap size in the old absicissae values, X.
;               IGNORE_NAN          :  If set, program removes NaNs prior to
;                                        interpolation
;                                        [Default = FALSE]
;
;   CHANGED:  1)  Davin Larson changed something...
;                                                                   [04/17/2002   v1.0.15]
;             2)  Re-wrote and cleaned up
;                                                                   [10/12/2009   v1.1.0]
;             3)  Updated to be in accordance with newest version of str_element.pro
;                   in TDAS IDL libraries
;                   A)  Cleaned up and added some comments
;                   B)  now calls dprint.pro
;                   C)  new keywords:  IGNORE_NAN
;                   D)  no longer uses () for arrays
;                                                                   [04/04/2012   v1.2.0]
;             4)  Updated Man. page, cleaned up routine, and updated dprint.pro call
;                                                                   [08/09/2016   v1.2.1]
;
;   NOTES:      
;               1)  To avoid spurious spikes or negative data points near the end points
;                     of the input array Y, use the NO_EXTRAPOLATE keyword.
;
;  REFERENCES:  
;               NA
;
;   CREATED:  04/30/1996
;   CREATED BY:  Davin Larson
;    LAST MODIFIED:  08/09/2016   v1.2.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION interp,y,x,u,INDEX=i,NO_CHECK_MONOTONIC=ch_mon,NO_EXTRAPOLATE=no_extrap,$
                      INTERP_THRESHOLD=int_th,IGNORE_NAN=ignore_nan

;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
;  TDAS Update
ndimy          = SIZE(y,/N_DIMENSIONS)
IF (ndimy EQ 2) THEN BEGIN
  ;;  Input Y is 2D --> loop through 2nd dimension
  dimy    = SIZE(y,/DIMENSIONS)
  dimv    = dimy
  dimv[0] = N_ELEMENTS(u)
  nv = MAKE_ARRAY(dimv,TYPE=SIZE(y,/TYPE))
  FOR j=0L, dimy[1] - 1L DO BEGIN
    nv[*,j] = interp(y[*,j],x,u,INDEX=i,NO_CHECK_MONOTONIC=ch_mon,NO_EXTRAPOLATE=no_extrap,$
                     INTERP_THRESHOLD=int_th,IGNORE_NAN=ignore_nan)
  ENDFOR
  RETURN,nv
ENDIF
;  TDAS Update
IF (N_PARAMS() EQ 2) THEN BEGIN
  nx   = N_ELEMENTS(y)
  temp = interp(y,FINDGEN(nx),FINDGEN(x)/(x-1)*(nx-1),INDEX=i,NO_EXTRAPOLATE=no_extrap, $
                INTERP_THRESHOLD=int_th,IGNORE_NAN=ignore_nan)
  RETURN,temp
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check for invalid x values:
;;----------------------------------------------------------------------------------------
nx             = N_ELEMENTS(x)
good           = FINITE(x)                                              ;  TDAS Update
;;  Check IGNORE_NAN keyword
IF KEYWORD_SET(ignore_nan) THEN good = (good AND FINITE(y))             ;  TDAS Update
good           = WHERE(good,c)                                          ;  TDAS Update
;good = WHERE(FINITE(x),c)
IF (c[0] LT 1) THEN BEGIN
;  message,/info,'Not enough valid data points to interpolate.'
  RETURN,REPLICATE(!VALUES.F_NAN,N_ELEMENTS(u))
ENDIF
;;----------------------------------------------------------------------------------------
;;  ensure that all x points are valid
;;----------------------------------------------------------------------------------------
IF (c[0] NE nx[0]) THEN BEGIN
;  temp = interp(y[good],x[good],u,INDEX=i,NO_EXTRAPOLATE=no_extrap,INTERP_THRESHOLD=int_th)
  RETURN,interp(y[good],x[good],u,INDEX=i,NO_EXTRAPOLATE=no_extrap,INTERP_THRESHOLD=int_th)
ENDIF
;;----------------------------------------------------------------------------------------
;;  ensure that x is monotonically increasing
;;----------------------------------------------------------------------------------------
IF (x[0] GT x[nx[0] - 1L]) THEN BEGIN
  RETURN, interp(REVERSE(y),REVERSE(x),u,INDEX=i,INTERP_THRESHOLD=int_th)
ENDIF

IF NOT KEYWORD_SET(ch_mon) THEN BEGIN
  dx    = x - SHIFT(x,1L)
  dx[0] = 0
  bad   = WHERE(dx LT 0,c)
  IF (c[0] NE 0) THEN dprint,'Warning: Data not monotonic!',DLEVEL=2   ;  SPEDAS Update
;  IF (c NE 0) THEN dprint,'Warning: Data not monotonic!'   ;  TDAS Update
;  if c ne 0 then message,/info,'Warning: Data not monotonic!'
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check interpolation gap threshold
;;----------------------------------------------------------------------------------------
IF KEYWORD_SET(int_th) THEN BEGIN
  w = WHERE(FINITE(y),c)
  IF (c[0] EQ 0) THEN w = [0]
  nv = interp(y[w],x[w],u,INDEX=i,NO_EXTRAPOLATE=no_extrap)
  dx = (x[w])[i + 1L] - (x[w])[i]
  w = WHERE(dx GT int_th,c)
  IF (c[0] NE 0) THEN nv[w] = !VALUES.F_NAN
  RETURN, nv
ENDIF
;;----------------------------------------------------------------------------------------
;;  Determine indices for interpolation
;;----------------------------------------------------------------------------------------
;;  Initialize indices
mn             = LONG(u)  &  mn[*] = 0L
mx             = LONG(u)  &  mx[*] = nx - 1L
;;  This loop should execute approximately log2(nx) times
REPEAT BEGIN
  i      = (mx + mn)/2L
  tst    = (x[i] LT u)
  ntst   = (tst EQ 0)
  mn     =  tst*i + ntst*mn
  mx     = ntst*i +  tst*mx
ENDREP UNTIL MAX(mx - mn,/NAN) LE 1L
;;  Define index array for input arrays
i              = (mx + mn)/2L
;;  Interpolate to new absicissae values, U
nv             = y[i] + (u - x[i])*(y[i+1] - y[i])/(x[i+1] - x[i])
;;----------------------------------------------------------------------------------------
;;  Kill end points
;;----------------------------------------------------------------------------------------
;;  Check NO_EXTRAPOLATE keyword
IF KEYWORD_SET(no_extrap) THEN BEGIN
  mxmx = minmax(x)
  w    = WHERE((u LT mxmx[0]) OR (u GT mxmx[1]),nbad)
  IF (nbad[0] GT 0) THEN nv[w] = !VALUES.F_NAN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,nv
END
