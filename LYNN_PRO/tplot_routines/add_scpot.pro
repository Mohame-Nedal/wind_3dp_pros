;+
;*****************************************************************************************
;
;  PROCEDURE:   add_scpot.pro
;  PURPOSE  :   Adds the spacecraft (SC) potential (eV) to an array of 3DP or ESA data
;                 structures obtained from get_??.pro (e.g. ?? = el, eh, sf, phb, etc.)
;                 by changing the tag SC_POT values.
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               get_data.pro
;               interp.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT          :  [N]-Element array of THEMIS ESA data structures
;               SOURCE       :  Scalar TPLOT handle or data structure specifying the data
;                                to use for magnetic field vector (nT) estimates
;                                [TPLOT Structure Format:  {X:(N-Unix Times),Y:[N,3]-Vectors}]
;               INT_THRESH   :  If set, routine uses 20x's the ESA duration for an
;                                 interpolation threshold [used by interp.pro]
;
;  EXAMPLES:    
;               ;; => Get ALL EESA Low Burst data structures within time range, tr
;               elb  = get_3dp_structs('elb',TRANGE=tr)
;               del  = elb.DATA
;               add_scpot,del,'sc_pot'  ;; If 'sc_pot' is a TPLOT handle
;
;  KEYWORDS:    
;               LEAVE_ALONE  :  If set, routine only alters the MAGF tag values of the
;                                structures within the time range of the specified
;                                SOURCE
;                                [Default:  sets values to NaNs outside time range]
;
;   CHANGED:  1)  Rewrote entire program to resemble add_magf2.pro
;                   for increased speed                        [11/06/2008   v2.0.0]
;             2)  Changed function INTERPOL.PRO to interp.pro  [11/07/2008   v2.0.1]
;             3)  Updated man page                             [06/17/2009   v2.0.2]
;             4)  Rewrote to optimize a few parts and clean up some cludgy parts
;                                                              [06/22/2009   v2.1.0]
;             5)  Changed a little syntax                      [07/13/2009   v2.1.1]
;             6)  Fixed a syntax error                         [07/13/2009   v2.1.2]
;             7)  Changed a little syntax                      [08/28/2009   v2.1.3]
;             8)  Added error handling to check if DAT is a data structure and
;                   added NO_EXTRAP option to interp.pro call
;                                                              [12/15/2011   v2.1.4]
;             9)  Updated to be in accordance with newest version of TDAS IDL libraries
;                   A)  Cleaned up and updated man page
;                   B)  Added keyword:  LEAVE_ALONE
;                   C)  Removed a lot of unnecessary code
;                   D)  Added use of INTERP_THRESHOLD in interp.pro call
;                                                              [04/19/2012   v3.0.0]
;            10)  Added keyword:  INT_THRESH                   [05/24/2012   v3.1.0]
;
;   NOTES:      
;               1)  If DAT and SOURCE time ranges do not overlap, then tag values
;                     not overlapping are changed to NaNs if LEAVE_ALONE keyword is
;                     not set
;
;   ADAPTED FROM: add_magf.pro and add_vsw.pro  BY: Davin Larson
;   CREATED:  04/27/2008
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  05/24/2012   v3.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO add_scpot,dat,source,LEAVE_ALONE=leave,INT_THRESH=int_thr

;-----------------------------------------------------------------------------------------
; => Define some defaults
;-----------------------------------------------------------------------------------------
noscdt_msg  = 'No spacecraft potential data loaded...'
nottpn_msg  = 'Not valid TPLOT handle or structure...'
noscpt_msg  = 'No spacecraft potential data at time of data structures...'
notstr_mssg = 'DAT must be an IDL structure...'
;-----------------------------------------------------------------------------------------
; => Check input parameters
;-----------------------------------------------------------------------------------------
;*****************************************************************************************
ex_start = SYSTIME(1)
;*****************************************************************************************
IF (N_PARAMS() NE 2) THEN RETURN

IF (SIZE(dat[0],/TYPE) NE 8L) THEN BEGIN
  MESSAGE,notstr_mssg[0],/CONTINUE,/INFORMATIONAL
  RETURN
ENDIF

CASE SIZE(source[0],/TYPE) OF
  8    : BEGIN
    ;; => SOURCE is a structure
    magf = source[0]
  END
  7    : BEGIN
    ;; => SOURCE is a TPLOT handle
    get_data,source[0],DATA=scpot
    IF (SIZE(scpot[0],/TYPE) NE 8L) THEN BEGIN
      MESSAGE,noscdt_msg[0],/CONTINUE,/INFORMATIONAL
      RETURN
    ENDIF
  END
  ELSE : BEGIN
    MESSAGE,nottpn_msg[0],/CONTINUE,/INFORMATIONAL
    RETURN
  END
ENDCASE
;-----------------------------------------------------------------------------------------
; => Define some parameters
;-----------------------------------------------------------------------------------------
n       = N_ELEMENTS(dat)
dumb    = REPLICATE(!VALUES.F_NAN,n)
b       = FLTARR(n,3)
;-----------------------------------------------------------------------------------------
; => Define time ranges
;-----------------------------------------------------------------------------------------
delt    = MIN(dat.END_TIME - dat.TIME,/NAN)*2d0   ; => 2x's minimum duration of data
IF KEYWORD_SET(int_thr) THEN BEGIN
  dtmax   = 1d1*delt[0]
ENDIF ELSE BEGIN
  dtmax   = (MAX(dat.END_TIME,/NAN) - MIN(dat.TIME,/NAN))*1d3
ENDELSE
myavt   = (dat.TIME + dat.END_TIME)/2d0
tra     = [MIN(dat.TIME,/NAN),MAX(dat.END_TIME,/NAN)] + [-1d0,1d0]*delt[0]
mxmn_bt = [MIN(scpot.X,/NAN),MAX(scpot.X,/NAN)]

del_t0  = dat.TIME - mxmn_bt[0]
del_t1  = mxmn_bt[1] - dat.END_TIME
test_tt = (del_t0 GT 0) AND (del_t1 GT 0)

good    = WHERE(test_tt,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
IF (gd GT 0) THEN BEGIN
  d_t              = myavt
  sc_p             = FLOAT(interp(scpot.Y,scpot.X,d_t,/NO_EXTRAP,INTERP_THRESHOLD=dtmax[0]))
  ;;  alter "good" values
  dat[good].SC_POT = REFORM(sc_p[good])
  test             = (NOT KEYWORD_SET(leave)) AND (bd GT 0)
  IF (test) THEN dat[bad].SC_POT  = REFORM(dumb[bad])
ENDIF ELSE BEGIN
  MESSAGE,noscpt_msg[0],/CONTINUE,/INFORMATIONAL
  IF ~KEYWORD_SET(leave) THEN dat.SC_POT = REFORM(dumb)
ENDELSE
;-----------------------------------------------------------------------------------------
; => Return
;-----------------------------------------------------------------------------------------
;*****************************************************************************************
ex_time = SYSTIME(1) - ex_start
MESSAGE,STRING(ex_time)+' seconds execution time.',/CONTINUE,/INFORMATIONAL
;*****************************************************************************************
RETURN
END
