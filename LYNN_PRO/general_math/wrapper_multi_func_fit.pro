;*****************************************************************************************
;
;  FUNCTION :   f_multi_gradients.pro
;  PURPOSE  :   Calculates the gradients of a specified function with respect to
;                 the variable fit coefficients for the model function.  For instance,
;                 if we used the linear line, Y = A + B X, then the routine would
;                 return the array [[ 1 ], [ X ]].
;
;  CALLED BY:   
;               f_model_powerlaw.pro
;               f_model_exponential_0.pro
;               f_model_loglin_powerlaw.pro
;               f_model_powerlaw_exponential.pro
;               f_model_exponential_1.pro
;               f_model_exponential_2.pro
;               f_model_hyperbolic.pro
;               f_model_logistic.pro
;               f_model_blackbody.pro
;               f_model_logsquare.pro
;
;  CALLS:
;               NA
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                              quantities for the model functions (see below):
;                                PARAM[0] = A
;                                PARAM[1] = B
;                                PARAM[2] = C
;                                PARAM[3] = D
;               PART      :  Scalar [integer] specifying which partial derivative to
;                              return to the user for F = F(A,B,C,D)
;                              [Default  :  1]
;                                1  :  dF/dA
;                                2  :  dF/dB
;                                3  :  dF/dC
;                                4  :  dF/dD
;               FIT_FUNC  :  Scalar [integer] specifying the type of function to use
;                              [Default  :  1]
;                                1  :  F(A,B,C,D,X) = A X^(B) + C
;                                2  :  F(A,B,C,D,X) = A e^(B X) + C
;                                3  :  F(A,B,C,D,X) = A + B Log_{e} |X^C|
;                                4  :  F(A,B,C,D,X) = A X^(B) e^(C X) + D
;                                5  :  F(A,B,C,D,X) = A B^(X) + C
;                                6  :  F(A,B,C,D,X) = A B^(C X) + D
;                                7  :  F(A,B,C,D,X) = ( A + B X )^(-1)
;                                8  :  F(A,B,C,D,X) = ( A B^(X) + C )^(-1)
;                                9  :  F(A,B,C,D,X) = A X^(B) ( e^(C X) + D )^(-1)
;                               10  :  F(A,B,C,D,X) = A + B Log_{10} |X| + C (Log_{10} |X|)^2
;                               11  :  F(A,B,C,D,X) = A X^(B) e^(C X) e^(D X)
;
;  EXAMPLES:    
;               ;;  Find partial of first parameter for model function #10
;               dF_dA = f_multi_gradients(xx,param,1,10)
;
;  KEYWORDS:    
;               NA
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               NA
;
;  REFERENCES:  
;               
;
;   CREATED:  05/02/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_multi_gradients,xx,param,part,fit_func

;;----------------------------------------------------------------------------------------
;;  Call common block
;;----------------------------------------------------------------------------------------
COMMON CHECK_PQ, p_quiet
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check input/keywords
;;----------------------------------------------------------------------------------------
;;  Determine which partial to return
test           = (N_ELEMENTS(part) EQ 0)
IF (test) THEN dfd_ = 1 ELSE dfd_ = (FIX(part[0]) > 1) < 4

;;  Check FIT_FUNC
test           = (N_ELEMENTS(fit_func) EQ 0)
IF (test) THEN fitf = 1 ELSE fitf = (FIX(fit_func[0]) > 1) < 11
;IF (test) THEN fitf = 1 ELSE fitf = (FIX(fit_func[0]) > 1) < 10

;;  Define relevant parameters
nx             = N_ELEMENTS(xx)
zeros          = REPLICATE(0d0,nx)
ones           = REPLICATE(1d0,nx)
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of F = F(A,B,C,D)
;;    dF/dA = ?
;;    dF/dB = ?
;;    dF/dC = ?
;;    dF/dD = ?
;;----------------------------------------------------------------------------------------
IF ~KEYWORD_SET(p_quiet) THEN BEGIN
  PRINT,''
  PRINT,'F0:  FUNC # = ',fitf[0]
  PRINT,'F0:  PDER # = ',dfd_[0]
  PRINT,''
  ;;  Print parameter estimates
  PRINT,''
  PRINT,'F0:  PARAM[0] = ',param[0]
  PRINT,'F0:  PARAM[1] = ',param[1]
  PRINT,'F0:  PARAM[2] = ',param[2]
  PRINT,'F0:  PARAM[3] = ',param[3]
  PRINT,''
ENDIF

CASE fitf[0] OF
  1    : BEGIN
    ;;  Y = A X^(B) + C
    CASE dfd_[0] OF
      1    : pder = xx^(param[1])
      2    : pder = param[0]*xx^(param[1])*ALOG(xx)
      3    : pder = ones
      4    : pder = zeros
      ELSE : pder = xx^(param[1])
    ENDCASE
  END
  2    : BEGIN
    ;;  Y = A e^(B X) + C
    CASE dfd_[0] OF
      1    : pder = EXP(param[1]*xx)
      2    : pder = param[0]*xx*EXP(param[1]*xx)
      3    : pder = ones
      4    : pder = zeros
      ELSE : pder = EXP(param[1]*xx)
    ENDCASE
  END
  3    : BEGIN
    ;;  Y = A + B Log_{e} |X^C|
    CASE dfd_[0] OF
      1    : pder = ones
      2    : pder = ALOG(ABS(xx^param[2]))
      3    : pder = param[1]*ALOG(ABS(xx))
      4    : pder = zeros
      ELSE : pder = ones
    ENDCASE
  END
  4    : BEGIN
    ;;  Y = A X^(B) e^(C X) + D
    CASE dfd_[0] OF
      1    : pder = xx^(param[1])*EXP(param[2]*xx)
      2    : pder = param[0]*xx^(param[1])*EXP(param[2]*xx)*ALOG(xx)
      3    : pder = param[0]*xx^(param[1] + 1d0)*EXP(param[2]*xx)
      4    : pder = ones
      ELSE : pder = xx^(param[1])*EXP(param[2]*xx)
    ENDCASE
  END
  5    : BEGIN
    ;;  Y = A B^(X) + C
    CASE dfd_[0] OF
      1    : pder = param[1]^(xx)
      2    : pder = param[0]*xx*param[1]^(xx - 1d0)
      3    : pder = ones
      4    : pder = zeros
      ELSE : pder = param[1]^(xx)
    ENDCASE
  END
  6    : BEGIN
    ;;  Y = A B^(C X) + D
    CASE dfd_[0] OF
      1    : pder = param[1]^(param[2]*xx)
      2    : pder = param[0]*param[2]*xx*param[1]^(param[2]*xx - 1d0)
      3    : pder = param[0]*param[1]^(param[2]*xx)*xx*ALOG(param[1])
      4    : pder = ones
      ELSE : pder = param[1]^(param[2]*xx)
    ENDCASE
  END
  7    : BEGIN
    ;;  Y = ( A + B X )^(-1)
    CASE dfd_[0] OF
      1    : pder = -1d0/(param[0] + param[1]*xx)^2
      2    : pder = -1d0*xx/(param[0] + param[1]*xx)^2
      3    : pder = zeros
      4    : pder = zeros
      ELSE : pder = -1d0/(param[0] + param[1]*xx)^2
    ENDCASE
  END
  8    : BEGIN
    ;;  Y = ( A B^(X) + C )^(-1)
    CASE dfd_[0] OF
      1    : pder = -1d0*param[1]^(xx)/(param[0]*param[1]^(xx) + param[2])^2
      2    : pder = -1d0*param[0]*xx*param[1]^(xx - 1d0)/(param[0]*param[1]^(xx) + param[2])^2
      3    : pder = -1d0/(param[0]*param[1]^(xx) + param[2])^2
      4    : pder = zeros
      ELSE : pder = -1d0*param[1]^(xx)/(param[0]*param[1]^(xx) + param[2])^2
    ENDCASE
  END
  9    : BEGIN
    ;;  Y = A X^(B) ( e^(C X) + D )^(-1)
    CASE dfd_[0] OF
      1    : pder = xx^(param[1])/denom
      2    : pder = param[0]*xx^(param[1])*ALOG(xx)/denom
      3    : pder = -1d0*param[0]*xx^(param[1] + 1d0)*EXP(param[2]*xx)/denom^2
      4    : pder = -1d0*param[0]*xx^(param[1])/denom^2
      ELSE : pder = xx^(param[1])/denom
    ENDCASE
  END
  10   : BEGIN
    ;;  Y = A + B Log_{10} |X| + C (Log_{10} |X|)^2
    CASE dfd_[0] OF
      1    : pder = ones
      2    : pder = ALOG10(xx)
      3    : pder = ALOG10(xx)^2
      4    : pder = zeros
      ELSE : pder = ones
    ENDCASE
  END
  11   : BEGIN
    ;;  Y = A X^(B) e^(C X) e^(D X)
    CASE dfd_[0] OF
      1    : pder = xx^(param[1])*EXP((param[2] + param[3])*xx)
      2    : pder = param[0]*xx^(param[1])*EXP((param[2] + param[3])*xx)*ALOG(xx)
      3    : pder = param[0]*xx^(param[1] + 1d0)*EXP((param[2] + param[3])*xx)
      4    : pder = param[0]*xx^(param[1] + 1d0)*EXP((param[2] + param[3])*xx)
      ELSE : pder = xx^(param[1])*EXP(param[2]*xx)
    ENDCASE
  END
  ELSE : BEGIN
    ;;  Use default:  Y = A X^(B) + C
    CASE dfd_[0] OF
      1    : pder = xx^(param[1])
      2    : pder = param[0]*xx^(param[1])*ALOG(xx)
      3    : pder = ones
      4    : pder = zeros
      ELSE : pder = xx^(param[1])
    ENDCASE
  END
ENDCASE
IF ~KEYWORD_SET(p_quiet) THEN BEGIN
  PRINT,''
  PRINT,'F0:  Min(pder) = ',MIN(pder,/NAN)
  PRINT,'F0:  Max(pder) = ',MAX(pder,/NAN)
  PRINT,''
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,pder
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_powerlaw.pro
;  PURPOSE  :   Creates a model power-law, from user defined inputs, represented by:
;                 Y = A X^(B) + C
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                              quantities for the model functions (see below):
;                                PARAM[0] = A
;                                PARAM[1] = B
;                                PARAM[2] = C
;                                PARAM[3] = *** Not Used Here ***
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 1
;
;  REFERENCES:  
;               NA
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_powerlaw,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = PARAM[0] * XX^(PARAM[1]) + PARAM[2]
;;----------------------------------------------------------------------------------------
ff             = param[0]*xx^(param[1]) + param[2]
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = A X^(B) + C
;;    dY/dA = X^(B)
;;    dY/dB = A X^(B) Log_{e} |X|
;;    dY/dC = 1
;;    dY/dD = 0
;;----------------------------------------------------------------------------------------

fitf           = 1
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_exponential_0.pro
;  PURPOSE  :   Creates a model , from user defined inputs, represented by:
;                 Y = A e^(B X) + C
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = *** Not Used Here ***
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 2
;
;  REFERENCES:  
;               
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_exponential_0,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = PARAM[0]*EXP(PARAM[1]*X) + PARAM[2]
;;----------------------------------------------------------------------------------------
ff             = param[0]*EXP(param[1]*xx) + param[2]
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = A e^(B X) + C
;;    dY/dA = e^(B X)
;;    dY/dB = A X e^(B X)
;;    dY/dC = 1
;;    dY/dD = 0
;;----------------------------------------------------------------------------------------
fitf           = 2
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_loglin_powerlaw.pro
;  PURPOSE  :   Creates a model , from user defined inputs, represented by:
;                 Y = A + B Log_{e} |X^C|
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = *** Not Used Here ***
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 3
;
;  REFERENCES:  
;               
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_loglin_powerlaw,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = PARAM[0] + PARAM[1]*ALOG(ABS( X^PARAM[2] ))
;;----------------------------------------------------------------------------------------
ff             = param[0] + param[1]*ALOG(ABS(xx^param[2]))
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = A + B Log_{e} |X^C|
;;    dY/dA = 1
;;    dY/dB = Log_{e} |X^C|
;;    dY/dC = B Log_{e} |X|
;;    dY/dD = 0
;;----------------------------------------------------------------------------------------
fitf           = 3
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_powerlaw_exponential.pro
;  PURPOSE  :   Creates a model , from user defined inputs, represented by:
;                 Y = A X^(B) e^(C X) + D
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = D
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 4
;
;  REFERENCES:  
;               
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_powerlaw_exponential,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = PARAM[0] * XX^(PARAM[1]) * EXP(PARAM[2] * XX) + PARAM[3]
;;----------------------------------------------------------------------------------------
ff             = param[0]*xx^(param[1])*EXP(param[2]*xx) + param[3]
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = A X^(B) e^(C X) + D
;;    dY/dA = X^(B) e^(C X)
;;    dY/dB = A X^(B) e^(C X) Log_{e} |X|
;;    dY/dC = A X^(B+1) e^(C X)
;;    dY/dD = 1
;;----------------------------------------------------------------------------------------
fitf           = 4
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_exponential_1.pro
;  PURPOSE  :   Creates a model exponential, from user defined inputs, represented by:
;                 Y = A B^(X) + C
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = *** Not Used Here ***
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 5
;               2)  See also:  IDL bulit-in COMFIT.PRO
;
;  REFERENCES:  
;               
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_exponential_1,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = PARAM[0] * PARAM[1]^(XX) + PARAM[2]
;;----------------------------------------------------------------------------------------
ff             = param[0]*param[1]^(xx) + param[2]
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = A B^(X) + C
;;    dY/dA = B^(X)
;;    dY/dB = A X B^(X - 1)
;;    dY/dC = 1
;;    dY/dD = 0
;;----------------------------------------------------------------------------------------
fitf           = 5
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_exponential_2.pro
;  PURPOSE  :   Creates a model exponential, from user defined inputs, represented by:
;                 Y = A B^(C X) + D
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = D
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 6
;               2)  See also:  IDL bulit-in COMFIT.PRO
;
;  REFERENCES:  
;               
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_exponential_2,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = PARAM[0] * PARAM[1]^(PARAM[2] * XX) + PARAM[3]
;;----------------------------------------------------------------------------------------
ff             = param[0]*param[1]^(param[2]*xx) + param[3]
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = A B^(C X) + D
;;    dY/dA = B^(C X)
;;    dY/dB = A C X B^(C X - 1)
;;    dY/dC = A B^(C X) X Log_{e} |B|
;;    dY/dD = 1
;;----------------------------------------------------------------------------------------
fitf           = 6
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_hyperbolic.pro
;  PURPOSE  :   Creates a model hyperbolic, from user defined inputs, represented by:
;                 Y = ( A + B X )^(-1)
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = *** Not Used Here ***
;                                 PARAM[3] = *** Not Used Here ***
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 7
;               2)  See also:  IDL bulit-in COMFIT.PRO
;
;  REFERENCES:  
;               
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_hyperbolic,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = 1/( PARAM[0] + PARAM[1] * XX )
;;----------------------------------------------------------------------------------------
ff             = 1d0/(param[0] + param[1]*xx)
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = ( A + B X )^(-1)
;;    dY/dA = - ( A + B X )^(-2)
;;    dY/dB = - X ( A + B X )^(-2)
;;    dY/dC = 0
;;    dY/dD = 0
;;----------------------------------------------------------------------------------------
fitf           = 7
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_logistic.pro
;  PURPOSE  :   Creates a model logistic, from user defined inputs, represented by:
;                 Y = ( A B^(X) + C )^(-1)
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = *** Not Used Here ***
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 8
;               2)  See also:  IDL bulit-in COMFIT.PRO
;
;  REFERENCES:  
;               
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_logistic,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = 1/( PARAM[0] * PARAM[1]^(XX) + PARAM[2] )
;;----------------------------------------------------------------------------------------
ff             = 1d0/(param[0]*param[1]^(xx) + param[2])
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = [ A B^(X) + C ]^(-1)
;;    dY/dA = - B^(X) [ A B^(X) + C ]^(-2)
;;    dY/dB = - A X B^(X - 1) [ A B^(X) + C ]^(-2)
;;    dY/dC = - [ A B^(X) + C ]^(-2)
;;    dY/dD = 0
;;----------------------------------------------------------------------------------------
fitf           = 8
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_blackbody.pro
;  PURPOSE  :   Creates a model "black body," from user defined inputs, represented by:
;                 Y = A X^(B) ( e^(C X) + D )^(-1)
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = D
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 9
;
;  REFERENCES:  
;               
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_blackbody,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = PARAM[0] * XX^(PARAM[1])/( EXP(PARAM[2] * XX) + PARAM[3] )
;;----------------------------------------------------------------------------------------
denom          = (EXP(param[2]*xx) + param[3])
ff             = param[0]*xx^(param[1])/denom
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = A X^(B) [ e^(C X) + D ]^(-1)
;;    dY/dA = X^(B) [ e^(C X) + D ]^(-1)
;;    dY/dB = A X^(B) [ e^(C X) + D ]^(-1) Log_{e} |X|   { = Y * Log_{e} |X| }
;;    dY/dC = - A e^(C X) X^(B + 1) [ e^(C X) + D ]^(-2)
;;    dY/dD = - A X^(B) [ e^(C X) + D ]^(-2)
;;----------------------------------------------------------------------------------------
fitf           = 9
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_logsquare.pro
;  PURPOSE  :   Creates a model log-square, from user defined inputs, represented by:
;                 Y = A + B Log_{10} |X| + C (Log_{10} |X|)^2
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = *** Not Used Here ***
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFIT.PRO
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 10
;               2)  See also:  IDL bulit-in COMFIT.PRO
;
;  REFERENCES:  
;               
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_logsquare,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = PARAM[0] + PARAM[1] * ALOG10(XX) + PARAM[2] * ALOG10(XX)^2
;;----------------------------------------------------------------------------------------
ff             = param[0] + param[1]*ALOG10(xx) + param[2]*ALOG10(XX)^2
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = A + B Log_{10} |X| + C (Log_{10} |X|)^2
;;    dY/dA = 1
;;    dY/dB = Log_{10} |X|
;;    dY/dC = (Log_{10} |X|)^2
;;    dY/dD = 0
;;----------------------------------------------------------------------------------------
fitf           = 10
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;*****************************************************************************************
;
;  FUNCTION :   f_model_powerlaw_2exponentials.pro
;  PURPOSE  :   Creates a model , from user defined inputs, represented by:
;                 Y = A X^(B) e^(C X) e^(D X)
;
;  CALLED BY:   
;               wrapper_multi_func_fit.pro
;
;  CALLS:
;               f_multi_gradients.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                               quantities for the model functions (see below):
;                                 PARAM[0] = A
;                                 PARAM[1] = B
;                                 PARAM[2] = C
;                                 PARAM[3] = D
;               PDER      :  [4]-Element array defining for which of the variable
;                              coefficients, A-D, to compute the partial derivatives
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM.  For instance, to take the partial
;                              derivative with respect to only A and C, then do:
;                              PDER = [1,0,1,0]
;                              [Default  :  PDER[*] = 0]
;
;  OUTPUT:
;               PDER      :  On output, the routine returns an [N,4]-element array
;                              containing the partial derivatives of Y with respect to
;                              each element of PARAM that were not set to zero in PDER
;                              on input.
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               FF        :  Set to a named variable to return an [N]-element array of
;                              values corresponding to the evaluated function
;
;   CHANGED:  0)  Created routine
;                                                                   [11/28/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  Called when FIT_FUNC = 11
;               2)  The CHANGED log history is intentionally wrong to allow me to find
;                     and replace CHANGED log histories for all functions included in
;                     wrapper_multi_func_fit.pro rather than each by hand
;
;  REFERENCES:  
;               
;
;   CREATED:  11/28/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************

FUNCTION f_model_powerlaw_2exponentials,xx,param,pder,FF=ff

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  ;;  no input???
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
IF (np LT 4) THEN BEGIN
  ;;  bad input???
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Calculate function
;;    Y = PARAM[0] * XX^(PARAM[1]) * EXP(PARAM[2] * XX) * EXP(PARAM[3] * XX)
;;----------------------------------------------------------------------------------------
ff             = param[0]*xx^(param[1])*EXP(param[2]*xx)*EXP(param[3]*xx)
;;----------------------------------------------------------------------------------------
;;  Calculate partial derivatives of Y = A X^(B) e^(C X) e^(D X)
;;    dY/dA = X^(B) e^(C X) e^(D X)                = Y/A
;;    dY/dB = A X^(B) e^(C X) e^(D X) Log_{e} |X|  = Y Log_{e} |X|
;;    dY/dC = A X^(B+1) e^(C X) e^(D X)            = Y * X
;;    dY/dD = A X^(B+1) e^(C X) e^(D X)            = Y * X
;;----------------------------------------------------------------------------------------
fitf           = 11
IF (N_PARAMS() GT 2) THEN BEGIN
  nx             = N_ELEMENTS(xx)
  ;;  Save original (input) partial derivative settings
  requested      = pder
  pder           = MAKE_ARRAY(nx,np,VALUE=xx[0]*0)  ;;  Define dummy array
  FOR j=0L, np - 1L DO BEGIN
    ;;  Only compute derivatives if user desires it
    IF (requested[j] NE 0) THEN pder[*,j] = f_multi_gradients(xx,param,j[0]+1L,fitf[0])
  ENDFOR
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,ff
END

;+
;*****************************************************************************************
;
;  FUNCTION :   wrapper_multi_func_fit.pro
;  PURPOSE  :   This is a wrapping routine for MPFITFUN.PRO that utilizes a series
;                 of predefined functions and associated partial derivatives.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               f_multi_gradients.pro
;               f_model_powerlaw.pro
;               f_model_exponential_0.pro
;               f_model_loglin_powerlaw.pro
;               f_model_powerlaw_exponential.pro
;               f_model_exponential_1.pro
;               f_model_exponential_2.pro
;               f_model_hyperbolic.pro
;               f_model_logistic.pro
;               f_model_blackbody.pro
;               f_model_logsquare.pro
;               f_model_powerlaw_2exponentials.pro
;
;  CALLS:
;               ;;  Indirectly
;               f_model_powerlaw.pro
;               f_model_exponential_0.pro
;               f_model_loglin_powerlaw.pro
;               f_model_powerlaw_exponential.pro
;               f_model_exponential_1.pro
;               f_model_exponential_2.pro
;               f_model_hyperbolic.pro
;               f_model_logistic.pro
;               f_model_blackbody.pro
;               f_model_logsquare.pro
;               f_model_powerlaw_2exponentials.pro
;               ;;  Directly
;               mpfitfun.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;               2)  Craig B. Markwardt's MPFIT IDL routines
;
;  INPUT:
;               XX        :  [N]-Element array of independent variable values or
;                              abscissa for F [e.g., X_j in F(X_j)]
;               YY        :  [N]-Element array of dependent variable values
;               PARAM     :  [4]-Element array containing the following initialization
;                              quantities for the model functions (see below):
;                                PARAM[0] = A
;                                PARAM[1] = B
;                                PARAM[2] = C
;                                PARAM[3] = D
;
;  EXAMPLES:    
;               .compile /Users/lbwilson/Desktop/temp_idl/wrapper_multi_func_fit.pro
;               ;;------------------------------------------------------------------------
;               ;;  Create a well defined model result for Y = A X^(B) + C
;               ;;------------------------------------------------------------------------
;               nn             = 50L        ;;  debugging prints out values
;               aa             = 4d0/!DPI   ;;    --> too many is too long
;               bb             = 1d0/2d0
;               cc             = SQRT(8.43d0*!DPI)
;               PRINT,';;',aa[0],bb[0],cc[0]
;               ;;       1.2732395      0.50000000       5.1462244
;               xx             = DINDGEN(nn)
;               y_model        = aa[0]*xx^(bb[0]) + cc[0]
;               ;;------------------------------------------------------------------------
;               ;;  Create noise and normalize such that Max(noise) ≤ 0.5
;               ;;------------------------------------------------------------------------
;               noise          = RANDOMN(seed,nn)
;               nfac           = 5d-1/MAX(ABS(noise),/NAN)
;               PRINT,';;',nfac[0],MIN(ABS(noise),/NAN),MAX(ABS(noise),/NAN)
;               ;;      0.28818636    0.0201320      1.73499
;               noise         *= nfac[0]
;               PRINT,';;',MIN(ABS(noise),/NAN),MAX(ABS(noise),/NAN)
;               ;;    0.0058017746      0.50000000
;               
;               ;;------------------------------------------------------------------------
;               ;;  Now make data "realistic" by adding noise
;               ;;------------------------------------------------------------------------
;               yreal          = y_model + noise
;               func           = 1                     ;;  i.e., Y = A X^(B) + C
;               param          = [1d0,0.25d0,3d0,0d0]  ;;  initial guesses
;               test           = wrapper_multi_func_fit(xx,yreal,param,FIT_FUNC=func[0])
;               test           = wrapper_multi_func_fit(xx,yreal,param,FIT_FUNC=func[0],/DEBUG)
;
;  KEYWORDS:    
;               **********************************
;               ***       DIRECT  INPUTS       ***
;               **********************************
;               FIT_FUNC  :  Scalar [integer] specifying the type of function to use
;                              [Default  :  1]
;                              1  :  Y = A X^(B) + C
;                              2  :  Y = A e^(B X) + C
;                              3  :  Y = A + B Log_{e} |X^C|
;                              4  :  Y = A X^(B) e^(C X) + D
;                              5  :  Y = A B^(X) + C
;                              6  :  Y = A B^(C X) + D
;                              7  :  Y = ( A + B X )^(-1)
;                              8  :  Y = ( A B^(X) + C )^(-1)
;                              9  :  Y = A X^(B) ( e^(C X) + D )^(-1)
;                             10  :  Y = A + B Log_{10} |X| + C (Log_{10} |X|)^2
;                             11  :  Y = A X^(B) e^(C X) e^(D X)
;               FIXED_P   :  [4]-Element array containing zeros for each element of
;                              PARAM the user does NOT wish to vary (i.e., if FIXED_P[0]
;                              is = 0, then PARAM[0] will not change when calling
;                              MPFITFUN.PRO).
;                              [Default  :  All elements = 1]
;               ITMAX     :  Scalar [long] defining the maximum number of iterations that
;                              MPFITFUN.PRO will perform before quitting.
;                              [Default  :  20]
;               CTOL      :  Scalar [float/double] defining the desired convergence
;                              tolerance. The routine returns when the relative
;                              decrease in chi-squared is less than CTOL in one
;                              iteration.
;                              [Default  :  1e-3]
;               A_RANGE   :  [4]-Element [float/double] array defining the range of
;                              allowed values to use for A or PARAM[0].  Note, if this
;                              keyword is set, it is equivalent to telling the routine
;                              that A should be limited by these bounds.  Setting this
;                              keyword will define:
;                                PARINFO[0].LIMITED[*] = BYTE(A_RANGE[0:1])
;                                PARINFO[0].LIMITS[*]  = A_RANGE[2:3]
;                              [Default  :  [not set] ]
;               B_RANGE   :  Same as A_RANGE but for B or PARAM[1], PARINFO[1].
;               C_RANGE   :  Same as A_RANGE but for C or PARAM[2], PARINFO[2].
;               D_RANGE   :  Same as A_RANGE but for D or PARAM[3], PARINFO[3].
;               TIED_P    :  [4]-Element [string] array used by PARINFO.TIED (see below)
;                              [Default  :  '']
;               P_QUIET   :  If set, routine will not print output in the routine
;                              f_multi_gradients.pro
;                              [Default  :  FALSE]
;               **********************************
;               ***  INPUTS FOR MPFITFUN.PRO   ***
;               **********************************
;               ERROR     :  [N]-Element array of standard errors for the input
;                              values, YY <--> "measured" 1-sigma uncertainties
;                              [Default = 1% of YY]
;               WEIGHTS   :  [N]-Element array of weights to be used in calculating the
;                              chi-squared value.  Example inputs include:
;                                1/ERROR^2  -->  Normal weighting
;                                                  (i.e., ERROR is measurement error)
;                                1/Y        -->  Poisson weighting
;                                                  (i.e., counting statistics)
;                                1          -->  Unweighted
;                              [Default  :  1/ERROR^2]
;               ******************************************
;               ***  Do not set this keyword yourself  ***
;               ******************************************
;               PARINFO   :  [4]-Element array [structure] used by MPFIT.PRO
;                              where the i-th contains the following tags and
;                              definitions:
;                              VALUE    =  Scalar [float/double] value defined by
;                                            PARAM[i].  The user need not set this value.
;                                            [Default = PARAM[i] ]
;                              FIXED    =  Scalar [boolean] value defining whether to
;                                            allow MPFIT.PRO to vary PARAM[i] or not
;                                            TRUE   :  parameter constrained
;                                                      (i.e., no variation allowed)
;                                            FALSE  :  parameter unconstrained
;                              LIMITED  =  [2]-Element [boolean] array defining if the
;                                            lower/upper bounds defined by LIMITS
;                                            are imposed(TRUE) otherwise it has no effect
;                                            [Default = FALSE]
;                              LIMITS   =  [2]-Element [float/double] array defining the
;                                            [lower,upper] bounds on PARAM[i].  Both
;                                            LIMITED and LIMITS must be given together.
;                                            [Default = [0.,0.] ]
;                              TIED     =  Scalar [string] that mathematically defines
;                                            how PARAM[i] is forcibly constrained.  For
;                                            instance, assume that PARAM[0] is always
;                                            equal to 2 Pi times PARAM[1], then one would
;                                            define the following:
;                                              PARINFO[0].TIED = '2 * !DPI * P[1]'
;                                            [Default = '']
;                              MPSIDE   =  Scalar value with the following
;                                            consequences:
;                                             0 : 1-sided deriv. computed automatically
;                                             1 : 1-sided deriv. (f(x+h) - f(x)  )/h
;                                            -1 : 1-sided deriv. (f(x)   - f(x-h))/h
;                                             2 : 2-sided deriv. (f(x+h) - f(x-h))/(2*h)
;                                             3 : explicit deriv. used for this parameter
;                                            See MPFIT.PRO and MPFITFUN.PRO for more...
;                                            [Default = 0]
;
;   CHANGED:  1)  Continued to write routine and changed to FUNCTION for MPFITFUN.PRO and
;                   added keywords PARINFO, [A,B,C,D]_RANGE, TIED_P
;                                                                   [05/02/2014   v1.0.0]
;             2)  Continued to write routine:
;                   added keyword:  P_QUIET
;                                                                   [09/14/2014   v1.0.0]
;             3)  Continued to write routine
;                                                                   [10/07/2014   v1.0.0]
;             4)  Added new function:  Y = A X^(B) e^(C X) e^(D X)
;                                                                   [11/28/2014   v1.1.0]
;
;   NOTES:      
;               1)  In the functions defined for the keyword FIT_FUNC, spaces imply
;                     multiplication and Log_{Uo} = base-Uo logarithm.
;               2)  To use explicit derivatives, set AUTODERIVATIVE=0 or set MPSIDE=3 for
;                     each parameter for which the user wishes to use explicit
;                     derivatives.
;               3)  **  Do NOT set PARINFO, let the routine set it up for you  **
;               4)  Fit Status Interpretations
;                     > 0 = success
;                     -18 = a fatal execution error has occurred.  More information may
;                           be available in the ERRMSG string.
;                     -16 = a parameter or function value has become infinite or an
;                           undefined number.  This is usually a consequence of numerical
;                           overflow in the user's model function, which must be avoided.
;                     -15 to -1 = 
;                           these are error codes that either MYFUNCT or ITERPROC may
;                           return to terminate the fitting process (see description of
;                           MPFIT_ERROR common below).  If either MYFUNCT or ITERPROC
;                           set ERROR_CODE to a negative number, then that number is
;                           returned in STATUS.  Values from -15 to -1 are reserved for
;                           the user functions and will not clash with MPFIT.
;                     0 = improper input parameters.
;                     1 = both actual and predicted relative reductions in the sum of
;                           squares are at most FTOL.
;                     2 = relative error between two consecutive iterates is at most XTOL
;                     3 = conditions for STATUS = 1 and STATUS = 2 both hold.
;                     4 = the cosine of the angle between fvec and any column of the
;                           jacobian is at most GTOL in absolute value.
;                     5 = the maximum number of iterations has been reached
;                           (may indicate failure to converge)
;                     6 = FTOL is too small. no further reduction in the sum of squares
;                           is possible.
;                     7 = XTOL is too small. no further improvement in the approximate
;                           solution x is possible.
;                     8 = GTOL is too small. fvec is orthogonal to the columns of the
;                           jacobian to machine precision.
;               5)  MPFIT routines can be found at:
;                     http://cow.physics.wisc.edu/~craigm/idl/idl.html
;               6)  Definition of WEIGHTS keyword input for MPFIT routines
;                     Array of weights to be used in calculating the chi-squared
;                     value.  If WEIGHTS is specified then the ERR parameter is
;                     ignored.  The chi-squared value is computed as follows:
;
;                         CHISQ = TOTAL( ( Y - MYFUNCT(X,P) )^2 * ABS(WEIGHTS) )
;
;                     where ERR = the measurement error (yerr variable herein).
;
;                     Here are common values of WEIGHTS for standard weightings:
;                       1D/ERR^2 - Normal or Gaussian weighting
;                       1D/Y     - Poisson weighting (counting statistics)
;                       1D       - Unweighted
;
;                     NOTE: the following special cases apply:
;                       -- if WEIGHTS is zero, then the corresponding data point
;                            is ignored
;                       -- if WEIGHTS is NaN or Infinite, and the NAN keyword is set,
;                            then the corresponding data point is ignored
;                       -- if WEIGHTS is negative, then the absolute value of WEIGHTS
;                            is used
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
;
;   CREATED:  05/01/2014
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/28/2014   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION wrapper_multi_func_fit,x,y,param,FIT_FUNC=fit_func,FIXED_P=fixed_p,     $
                                ERROR=error,WEIGHTS=weights,ITMAX=itmax,         $
                                CTOL=ctol,PARINFO=parinfo,A_RANGE=a_range,       $
                                B_RANGE=b_range,C_RANGE=c_range,D_RANGE=d_range, $
                                TIED_P=tied_p,DEBUG=debug,P_QUIET=p_quiet0

;;----------------------------------------------------------------------------------------
;;  Define common block
;;----------------------------------------------------------------------------------------
COMMON CHECK_PQ;, p_quiet
;;  Check P_QUIET
IF KEYWORD_SET(p_quiet0) THEN p_quiet = 1 ELSE p_quiet = 0
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
struc          = 0
dumb0          = d
dumb2          = REPLICATE(d,2)
dumb4          = REPLICATE(d,4)
dumb10         = REPLICATE(d,10)
;;----------------------------------------------------------------------------------------
;;  Initialize parameters for MPFITFUN.PRO
;;----------------------------------------------------------------------------------------
tags           = ['VALUE','FIXED','LIMITED','LIMITS','TIED','MPSIDE']
;;  Check DEBUG
IF KEYWORD_SET(debug) THEN BEGIN
  tags           = [tags,'MPDERIV_DEBUG','MPDERIV_RELTOL','MPDERIV_ABSTOL']
  pinfo_1        = CREATE_STRUCT(tags,d,0b,[0b,0b],[0d0,0d0],'',3,1,1d-3,1d-7)
  autoderiv      = 0
ENDIF ELSE BEGIN
  ;;  For now, force explicit derivatives
  autoderiv      = 0
  tags           = [tags,'MPDERIV_DEBUG','MPDERIV_RELTOL','MPDERIV_ABSTOL']
  pinfo_1        = CREATE_STRUCT(tags,d,0b,[0b,0b],[0d0,0d0],'',3,0,1d-3,1d-7)
ENDELSE
;;  Define dummy return structure
tags00         = ['YFIT','FIT_PARAMS',  'SIG_PARAM','CHISQ','DOF','N_ITER','STATUS','YERROR','FUNC','PARINFO','PFREE_INDEX','NPEGGED']
struc          = CREATE_STRUCT(tags00,dumb10,dumb4,dumb4,dumb0,dumb0,-1,-1,dumb10,'',pinfo_1,-1,-1)
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 3)
IF (test[0]) THEN BEGIN
  ;;  no input???
  MESSAGE,'Incorrect # of inputs',/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF

np             = N_ELEMENTS(param)
test           = (np[0] LT 4)
IF (test[0]) THEN BEGIN
  ;;  bad input???
  MESSAGE,'Incorrect input format:  PARAM',/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF

test           = (N_ELEMENTS(x) NE N_ELEMENTS(y))
IF (test[0]) THEN BEGIN
  ;;  bad input format???
  MESSAGE,'Incorrect input format:  XX and/or YY',/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define new parameters
;;----------------------------------------------------------------------------------------
xx             = REFORM(x)
yy             = REFORM(y)
pp             = REFORM(param)
nx             = N_ELEMENTS(x)
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check FIXED_P
test           = (N_ELEMENTS(fixed_p) NE 4)
IF (test) THEN fitp = REPLICATE(0b,4) ELSE fitp = (REFORM(fixed_p) EQ 0)
;;  Check ERROR
test           = (N_ELEMENTS(error) NE 1) AND (N_ELEMENTS(error) NE nx)
IF (test) THEN yerr = 1d-2*yy ELSE yerr = REFORM(error)
IF (N_ELEMENTS(yerr) EQ 1) THEN yerr = REPLICATE(yerr[0],nx)
;;  Check WEIGHTS
test           = (N_ELEMENTS(weights) NE 1) AND (N_ELEMENTS(weights) NE nx)
IF (test) THEN wghts = 1d0/yerr^2 ELSE wghts = REFORM(weights)
IF (N_ELEMENTS(wghts) EQ 1) THEN wghts = REPLICATE(wghts[0],nx)

;;  Check [A,B,C,D]_RANGE
p_lmd          = REPLICATE(0b,4L,2L)    ;;  values [logic] used for PARINFO[*].LIMITED
p_lms          = REPLICATE(0d0,4L,2L)   ;;  values [float/double] used for PARINFO[*].LIMITS
test           = [(N_ELEMENTS(a_range) EQ 4),(N_ELEMENTS(b_range) EQ 4),$
                  (N_ELEMENTS(c_range) EQ 4),(N_ELEMENTS(d_range) EQ 4) ]
FOR j=0L, 3L DO BEGIN
  IF (test[j]) THEN BEGIN
    CASE j[0] OF
      0L   : BEGIN
        p_lmd[j,*] = BYTE(a_range[0:1])
        p_lms[j,*] = DOUBLE(a_range[2:3])
      END
      1L   : BEGIN
        p_lmd[j,*] = BYTE(b_range[0:1])
        p_lms[j,*] = DOUBLE(b_range[2:3])
      END
      2L   : BEGIN
        p_lmd[j,*] = BYTE(c_range[0:1])
        p_lms[j,*] = DOUBLE(c_range[2:3])
      END
      3L   : BEGIN
        p_lmd[j,*] = BYTE(d_range[0:1])
        p_lms[j,*] = DOUBLE(d_range[2:3])
      END
      ELSE :  ;;  Do nothing because I don't know how this happened...
    ENDCASE
  ENDIF
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Initialize PARINFO structure
;;----------------------------------------------------------------------------------------
pin            = REPLICATE(pinfo_1[0],4L)
;;  Set VALUE tag
pin[*].VALUE   = pp
;;  Set LIMITED and LIMITS tags
pin[*].LIMITED = TRANSPOSE(p_lmd)
pin[*].LIMITS  = TRANSPOSE(p_lms)
;;  Set FIXED tag
pin[*].FIXED   = fitp
;;  Check TIED_P
test           = (N_ELEMENTS(tied_p) EQ 4) AND (SIZE(tied_p,/TYPE) EQ 7)
IF (test) THEN pin[*].TIED = REFORM(tied_p)
;;----------------------------------------------------------------------------------------
;;  Determine fit function
;;----------------------------------------------------------------------------------------
;;  Check FIT_FUNC
test           = (N_ELEMENTS(fit_func) EQ 0)
IF (test) THEN fitf = 1 ELSE fitf = (FIX(fit_func[0]) > 1) < 11
;IF (test) THEN fitf = 1 ELSE fitf = (FIX(fit_func[0]) > 1) < 10
pder           = REPLICATE(0,4)
ind            = LINDGEN(4)

CASE fitf[0] OF
  1    : BEGIN
    ;;  Y = A X^(B) + C
    func = 'f_model_powerlaw'
    dpon = ind[0:2]
  END
  2    : BEGIN
    ;;  Y = A e^(B X) + C
    func = 'f_model_exponential_0'
    dpon = ind[0:2]
  END
  3    : BEGIN
    ;;  Y = A + B Log_{e} |X^C|
    func = 'f_model_loglin_powerlaw'
    dpon = ind[0:2]
  END
  4    : BEGIN
    ;;  Y = A X^(B) e^(C X) + D
    func = 'f_model_powerlaw_exponential'
    dpon = ind
  END
  5    : BEGIN
    ;;  Y = A B^(X) + C
    func = 'f_model_exponential_1'
    dpon = ind[0:2]
  END
  6    : BEGIN
    ;;  Y = A B^(C X) + D
    func = 'f_model_exponential_2'
    dpon = ind
  END
  7    : BEGIN
    ;;  Y = ( A + B X )^(-1)
    func = 'f_model_hyperbolic'
    dpon = ind[0:1]
  END
  8    : BEGIN
    ;;  Y = ( A B^(X) + C )^(-1)
    func = 'f_model_logistic'
    dpon = ind[0:2]
  END
  9    : BEGIN
    ;;  Y = A X^(B) ( e^(C X) + D )^(-1)
    func = 'f_model_blackbody'
    dpon = ind
  END
  10   : BEGIN
    ;;  Y = A + B Log_{10} |X| + C (Log_{10} |X|)^2
    func = 'f_model_logsquare'
    dpon = ind[0:2]
  END
  11   : BEGIN
    ;;  Y = A X^(B) e^(C X) e^(D X)
    func = 'f_model_powerlaw_2exponentials'
    dpon = ind
  END
  ELSE : BEGIN
    ;;  Use default:  Y = A X^(B) + C
    func = 'f_model_powerlaw'
    dpon = ind[0:2]
  END
ENDCASE
;;  Define FUNCTARGS input
IF KEYWORD_SET(debug) THEN BEGIN
  pin[*].MPSIDE    = 3
  pder[*]          = 1
ENDIF ELSE BEGIN
  ;;  For now, force explicit derivatives
  pin[*].MPSIDE    = 3
  pder[*]          = 1
ENDELSE
;farg           = {PDER:pder,FF:yy}
farg           = {FF:yy}
;;----------------------------------------------------------------------------------------
;;  Calculate Fit
;;----------------------------------------------------------------------------------------
;;  Use mpfitfun.pro instead
;;
;;  To enable explicit derivatives for all parameters, set
;;  AUTODERIVATIVE=0.
;;
;;  When AUTODERIVATIVE=0, the user function is responsible for
;;  calculating the derivatives of the user function with respect to
;;  each parameter.  The user function should be declared as follows:
;;
;;----------------------------------------------------------------------------------------
fit_params     = mpfitfun(func[0],xx,yy,yerr,pp,PARINFO=pin,PERROR=sig_p,    $
                         BESTNORM=chisq,DOF=dof,STATUS=status,NITER=niter,   $
                         YFIT=y_fit,/QUIET,WEIGHTS=wghts,BEST_RESID=yerrors, $
                         FTOL=1d-14,GTOL=1d-14,ERRMSG=errmsg,/NAN,           $
                         AUTODERIVATIVE=autoderiv[0],MAXITER=itmax,          $
                         PFREE_INDEX=pfree_ind,NPEGGED=npegged)

;;----------------------------------------------------------------------------------------
;;   STATUS : 
;;             > 0 = success
;;             -18 = a fatal execution error has occurred.  More information may be
;;                   available in the ERRMSG string.
;;             -16 = a parameter or function value has become infinite or an undefined
;;                   number.  This is usually a consequence of numerical overflow in the
;;                   user's model function, which must be avoided.
;;             -15 to -1 = 
;;                   these are error codes that either MYFUNCT or ITERPROC may return to
;;                   terminate the fitting process (see description of MPFIT_ERROR
;;                   common below).  If either MYFUNCT or ITERPROC set ERROR_CODE to a
;;                   negative number, then that number is returned in STATUS.  Values
;;                   from -15 to -1 are reserved for the user functions and will not
;;                   clash with MPFIT.
;;             0 = improper input parameters.
;;             1 = both actual and predicted relative reductions in the sum of squares
;;                   are at most FTOL.
;;             2 = relative error between two consecutive iterates is at most XTOL
;;             3 = conditions for STATUS = 1 and STATUS = 2 both hold.
;;             4 = the cosine of the angle between fvec and any column of the jacobian
;;                   is at most GTOL in absolute value.
;;             5 = the maximum number of iterations has been reached
;;                   (may indicate failure to converge)
;;             6 = FTOL is too small. no further reduction in the sum of squares is
;;                   possible.
;;             7 = XTOL is too small. no further improvement in the approximate
;;                   solution x is possible.
;;             8 = GTOL is too small. fvec is orthogonal to the columns of the
;;                   jacobian to machine precision.
;;----------------------------------------------------------------------------------------
;;  Check status of computation and define return structure
tags           = ['YFIT','FIT_PARAMS','SIG_PARAM','CHISQ','DOF','N_ITER','STATUS','YERROR','FUNC','PARINFO','PFREE_INDEX','NPEGGED']
test           = (status[0] GT 0)
IF (test[0]) THEN BEGIN
  ;;  Success!  -->  Print out info
  PRINT,''
  PRINT,'A  =  ',fit_params[0],'   +/- ',ABS(sig_p[0])
  PRINT,'B  =  ',fit_params[1],'   +/- ',ABS(sig_p[1])
  PRINT,'C  =  ',fit_params[2],'   +/- ',ABS(sig_p[2])
  PRINT,'D  =  ',fit_params[3],'   +/- ',ABS(sig_p[3])
  PRINT,''
  PRINT,'Model Fit Status                    = ',status[0]
  PRINT,'Number of Iterations                = ',niter[0]
  PRINT,'Degrees of Freedom                  = ',dof[0]
  PRINT,'Chi-Squared                         = ',chisq[0]
  PRINT,'Reduced Chi-Squared                 = ',chisq[0]/dof[0]
  PRINT,''
ENDIF ELSE BEGIN
  ;;  Failed!
  MESSAGE,errmsg[0],/INFORMATIONAL,/CONTINUE
  ;;  Make sure outputs are defined
  IF (SIZE(y_fit,/TYPE) EQ 0)      THEN y_fit = REPLICATE(d,nx)
  IF (SIZE(fit_params,/TYPE) EQ 0) THEN fit_params = REPLICATE(d,4)
  IF (SIZE(sig_p,/TYPE) EQ 0)      THEN sig_p = REPLICATE(d,4)
  IF (SIZE(chisq,/TYPE) EQ 0)      THEN chisq = d
  IF (SIZE(dof,/TYPE) EQ 0)        THEN dof = d
  IF (SIZE(niter,/TYPE) EQ 0)      THEN niter = -1
  IF (SIZE(yerrors,/TYPE) EQ 0)    THEN yerrors = REPLICATE(d,nx)
  IF (SIZE(pin,/TYPE) EQ 0)        THEN pin = pinfo_1
  IF (SIZE(pfree_ind,/TYPE) EQ 0)  THEN pfree_ind = -1
  IF (SIZE(npegged,/TYPE) EQ 0)    THEN npegged = -1
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Define return structure
;;----------------------------------------------------------------------------------------
struc          = CREATE_STRUCT(tags,y_fit,fit_params,sig_p,chisq[0],dof[0],niter[0],$
                                    status[0],yerrors,func[0],pin,pfree_ind,npegged)
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,struc
END




