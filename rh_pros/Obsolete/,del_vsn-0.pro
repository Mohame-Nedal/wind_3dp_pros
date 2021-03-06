;+
;*****************************************************************************************
;
;  FUNCTION :   del_vsn.pro
;  PURPOSE  :   Returns the difference between an input velocity, V, parallel to a
;                 unit normal vector, n, and the shock normal speed.
;
;               **Note:  These values must be in the spacecraft (SC) frame of reference**
;
;  CALLED BY:   
;               rh_eq_gen.pro
;
;  CALLS:
;               NA
;
;  REQUIRES:    
;               NA
;
;  INPUT:
;               V    :  3-Element velocity vector             [X-Basis, Y-Units]
;               N    :  [N,3]-Element unit normal vectors     [X-Basis]
;               VS   :  [N]-Element array of shock normal speeds in SC-frame [Y-Units]
;
;  EXAMPLES:    
;               
;
;  KEYWORDS:    
;               VEC  :  Determines which specific difference to return to user
;                         0 = (V . n - Vs)  {scalar}
;                         1 = (V - Vs n)    {vector}
;
;   CHANGED:  1)  NA [MM/DD/YYYY   v1.0.0]
;
;   NOTES:      
;               1)  The units of V and VS do not matter so long as they are the same
;               2)  The N-Elements of VS must correspond to the [N,3] shock normals
;               3)  user should not call this routine
;
;  REFERENCES:  
;               1)  Vinas, A.F. and J.D. Scudder (1986), "Fast and Optimal Solution to
;                      the 'Rankine-Hugoniot Problem'," J. Geophys. Res. 91, pp. 39-58.
;               2)  A. Szabo (1994), "An improved solution to the 'Rankine-Hugoniot'
;                      problem," J. Geophys. Res. 99, pp. 14,737-14,746.
;               3)  Koval, A. and A. Szabo (2008), "Modified 'Rankine-Hugoniot' shock
;                      fitting technique:  Simultaneous solution for shock normal and
;                      speed," J. Geophys. Res. 113, pp. A10110.
;
;   CREATED:  06/21/2011
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  06/21/2011   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION del_vsn,v,n,vs,VEC=vec

;-----------------------------------------------------------------------------------------
; => Define dummy variables
;-----------------------------------------------------------------------------------------
f          = !VALUES.F_NAN
d          = !VALUES.D_NAN
;-----------------------------------------------------------------------------------------
; => Check input
;-----------------------------------------------------------------------------------------
IF (N_PARAMS() NE 3) THEN RETURN,d

v1       = REFORM(v)        ; => Input velocity
n1       = REFORM(n)        ; => Input normal vector
vs1      = REFORM(vs)       ; => Input shock normal speed in SC-Frame

szv      = SIZE(v1,/DIMENSIONS)
szn      = SIZE(n1,/DIMENSIONS)
test     = ((szv[0] NE 3) OR (szn[1] NE 3))
IF (test) THEN RETURN,d

IF KEYWORD_SET(vec) THEN vv = 1 ELSE vv = 0
;-----------------------------------------------------------------------------------------
; => Define parameters
;-----------------------------------------------------------------------------------------
; => Assume n = normal unit vector, so renormalize just in case rounding errors have
;      made it so (|n| NE 1)
nmag     = SQRT(TOTAL(n1^2,2L,/NAN)) # REPLICATE(1,3)  ; => [N,3]-Element array
n1       = n1/nmag
szn      = SIZE(n1,/DIMENSIONS)
; => Calculate normal component of V
; =>  v_n = V . n        [page 357 Eq. 8.22 {n = z here} of Jackson E&M 3rd Edition]
vn       = v1[0]*n1[*,0] + v1[1]*n1[*,1] + v1[2]*n1[*,2]
; => Define (Vs n)
nvs      = REPLICATE(d,szn[0],3)
nvs[*,0] = vs1*n1[*,0]
nvs[*,1] = vs1*n1[*,1]
nvs[*,2] = vs1*n1[*,2]

;-----------------------------------------------------------------------------------------
; => Define normal velocity difference
;-----------------------------------------------------------------------------------------
CASE vv[0] OF
  0  :  BEGIN
    vdiff = vn - vs1                          ; => [N]-Element array
  END
  1  :  BEGIN
    vdiff = (REPLICATE(1,szn[0]) # v1) - nvs  ; => [N,3]-Element array
  END
  ELSE : vdiff = d                            ; => This should not be possible
ENDCASE

RETURN,vdiff
END
