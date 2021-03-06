; Note: This file is obsolete please use the procedure fit.pro







;PROCEDURE xfer_parameters
;PURPOSE:
;  transfers values between an array and a structure.
;  Used only by the fitfunc function.
;USAGE:
;  xfer_parameters,stuct,names,array,/array_to_struct
;or:
;  xfer_parameters,stuct,names,array,/struct_to_array
; 

pro xfer_parameters,params,names, a,  fullnames=fullnames, num_params=pos ,$
    struct_to_array=struct_to_array, $
    array_to_struct=array_to_struct

if data_type(params) ne 8 then return
tags = tag_names(params)


if not keyword_set(names) then begin
   dts = data_type(params,/struct)
   w = where(dts eq 5 or dts eq 8,c)
   if c ne 0 then p_names = tags[w]
endif else begin
   if data_type(names) le 3 then p_names=tags[names] else begin
      if ndimen(names) eq 0 then p_names=str_sep(names,' ') else p_names=names
   endelse
endelse

a_to_s = keyword_set(array_to_struct)

np = n_elements(p_names)

if a_to_s eq 0 then a = 0.d
fullnames = ''
pos = 0

for n=0,np-1  do begin
   name = strupcase(p_names[n])
   dotpos = strpos(name,'.',0)
   if dotpos gt 0 then begin
      subnames = strmid(name,dotpos+1,100)
      subnames = str_sep(subnames,':')
      name = strmid(name,0,dotpos)
   endif else subnames = ''
   indnum = 0
   parenpos1 = strpos(name,'[',0)
   if parenpos1 gt 0 then begin
      parenpos2 = strpos(name,']',parenpos1)
      indnum = strmid(name,parenpos1+1,parenpos2-parenpos1-1)
      indnum = fix(str_sep(indnum,','))  
      name = strmid(name,0,parenpos1)
   endif
   ind = (where(name eq tags,count))[0]
   if count ge 1 then begin
      v = params.(ind)
      if data_type(v) eq 8 then begin
         at = a[pos:*]
         xfer_parameters,v,subnames,at,fullnames=elnames,num_p=size ,array_to_struct=a_to_s
         if a_to_s eq 0 then v = at
         postfix = '.'+elnames
      endif else begin
         ndim = ndimen(v)
         if ndim ge 1 then begin
            if not keyword_set(indnum) then indnum = indgen(n_elements(v))
            size = n_elements(indnum)
            if a_to_s then v[indnum] = a[pos:pos+size-1] else v = v[indnum]
            postfix = string(indnum,fo="('[',i0.0,']')")
         endif else begin
            if a_to_s then v = a[pos]
            size = 1
            postfix = ''
         endelse
      endelse
      if a_to_s then  params.(ind) = v  else  a=[a,v]
      fullnames = [fullnames,name+postfix]
      pos = pos + size
   endif
endfor

if pos gt 0 then begin
   if a_to_s eq 0 then a = a[1:*]
   fullnames= fullnames[1:*]
endif

return
end






;
; NAME:
;       FITFUNC
;
; PURPOSE:
;       Obsolete.  Use the procedure "fit" instead.
;       Non-linear least squares fit to a user defined function.
;       This procedure is an improved version of CURVEFIT that allows fitting
;       to a subset of the function parameters.
;       The function may be any non-linear function.
;       If available, partial derivatives can be calculated by 
;       the user function, else this routine will estimate partial derivatives
;       with a forward difference approximation.
;
; CATEGORY:
;       E2 - Curve and Surface Fitting.
;
; CALLING SEQUENCE:
;       Result = FITFUNC(X, Y, PARAMETERS=par, P_NAMES=strarray, $
;             FUNCTION_NAME=string, ITMAX=ITMAX, ITER=ITER, TOL=TOL, $
;             /NODERIVATIVE)
;
; INPUTS:
;       X:  A row vector of independent variables.  This routine does
;		not manipulate or use values in X, it simply passes X
;		to the user-written function.
;
;       Y:  A row vector containing the dependent variable.
;
; KEYWORD INPUTS:
;
;       FUNCTION_NAME:  The name of the function to fit.
;          If omitted, "FUNCT" is used. The procedure must be written as
;          described under RESTRICTIONS, below.
;
;       PARAMETERS:  A structure containing the starting parameter values
;          for the function.  Final values are also passed back through 
;          this variable.  The fitting function must accept this keyword.
;          If omitted, this structure is obtained from the user defined
;          function.
;
;       NAMES: The parameters to be fit.  Several options exist:
;          A string with parameter names delimited by spaces.
;          A string array specifying which parameters to fit.
;          An integer array corresponding to elements within the PARAMETERS structure.
;          If undefined, then fitfunc will attemp to fit to all double precision
;          elements of the PARAMETERS structure.
;
;       WEIGHT:   A row vector of weights, the same length as Y.
;          For no weighting,
;            w(i) = 1.0.
;          For instrumental weighting,
;            w(i) = 1.0/y(i), etc.
;          if not set then w is set to all one's  (equal weighting)
;
;       DY:  A row vector of errors in Y.  If set, then WEIGHTS are set to:
;               W = 1/DY^2 and previous values of the WEIGHTS are replaced.
;
;       ERROR_FACTOR: set this keyword to have DY set to ERROR_FACTOR * Y. 
;
;       ITMAX:  Maximum number of iterations. Default = 20.
;
;       TOL:    The convergence tolerance. The routine returns when the
;               relative decrease in chi-squared is less than TOL in an 
;               interation. Default = 1.e-5.
;
;       NODERIVATIVE:  (optional)
;            If set to 1 then the partial derivatives will be estimated in CURVEFIT using 
;               forward differences. 
;            If set to 0 then the user function is forced to provide
;               partial derivatives.
;            If not provided then partial derivatives will be determined
;               from the user function only if it has the proper keyword 
;               arguments.
;
;       SILENT:  If this keyword is set then no fit information is printed.
;       
; KEYWORD OUTPUTS:
;       ITER:   The actual number of iterations which were performed.
;
;       CHI2:   The value of chi-squared on exit.
;
;       FULLNAMES:  A string array containing the parameter names.
;       
;       P_VALUES:  A vector with same dimensions as FULLNAMES, that 
;           contains the final values for each parameter.  These values
;           will be the same as the values returned in PARAMETERS.
;      
;       P_SIGMA:  A vector containing the estimated uncertainties in P_VALUES.
;
; OUTPUT
;       Returns a vector of calculated values.
;
; COMMON BLOCKS:
;       NONE.
;
; RESTRICTIONS:
;       The function to be fit must be defined and called FUNCT,
;       unless the FUNCTION_NAME keyword is supplied.  This function,
;       must accept values of X (the independent variable), the keyword 
;       PARAMETERS, and return F (the function's value at X).
;       if the NODERIV keyword is not set. then the function must also accept
;       the keywords: P_NAMES and PDER (a 2d array of partial derivatives).
;       For an example, see "GAUSSIAN".
;
;   The calling sequence is:
;
;       CASE 1:    (NODERIV is set)
;          F = FUNCT(X,PAR=par)               ; if NODERIV is set  or:
;             where:
;          X = Variable passed into CURVEFIT.  It is the job of the user-written
;             function to interpret this variable.
;          PAR = structure containing function parameters, input.
;          F = Vector of NPOINT values of function, y(i) = funct(x), output.
;
;       CASE 2:     (NODERIV is not set)
;          F = FUNCT(X,PAR=par,NAMES=names,PDER=pder)
;             where:
;          NAMES = string array of parameters to be fit.
;          PDER = Array, (NPOINT, NTERMS), of partial derivatives of funct.
;             PDER(I,J) = Derivative of function at ith point with
;             respect to jth parameter.  Optional output parameter.
;             PDER should not be calculated if P_NAMES is not
;             supplied in call. If the /NODERIVATIVE keyword is set in the
;             call to FITFUNC then the user routine will never need to
;             calculate PDER.
;
; PROCEDURE:
;       Copied from "CURFIT", least squares fit to a non-linear
;       function, pages 237-239, Bevington, Data Reduction and Error
;       Analysis for the Physical Sciences.
;
;       "This method is the Gradient-expansion algorithm which
;       combines the best features of the gradient search with
;       the method of linearizing the fitting function."
;
;       Iterations are performed until the chi square changes by
;       only TOL or until ITMAX iterations have been performed.
;
;       The initial guess of the parameter values should be
;       as close to the actual values as possible or the solution
;       may not converge.
;
;EXAMPLE:  Fit to a gaussian plus a quadratic background:
;  Here is the user-written procedure to return F(x) and the partials, given x:
;
;See the function "GAUSSIAN" for an example function to fit to.
;
;x=findgen(10)-4.5                          ; Initialize independent variables.
;y=[1.7,1.9,2.1,2.7,4.6,5.5,4.4,1.7,0.5,0.3]; Initialize dependent variables.
;plot,x,y,psym=4                            ; Plot data.
;xv = findgen(100)/10.-5.                   ; get better resolution abscissa.
;oplot,xv,gaussian(xv,par=p)                ; Plot initial guess.
;help,p,/structure                          ; Display initial guess.
;f = fitfunc(x,y,func='gaussian',par=p)     ; Fit to all parameters.
;oplot,x,f,psym=1                           ; Use '+' to plot fitted values.
;oplot,xv,gaussian(xv,par=p)                ; Plot fitted function.
;help,p,/structure                          ; Display new parameter values.
;
;names =tag_names(p)                        ; Obtain parameter names.
;p.a2 = 0                                   ; set quadratic term to 0.
;names = names([0,1,2,3,4])                 ; Choose a subset of parameters.
;print,names                                ; Display subset of names
;f = fitfunc(x,y,func='gaussian',par=p,names=names) ; Fit to subset.
;
;   Please Note:  Typically the initial guess for parameters must be reasonably
;   good, otherwise the routine will not converge.  In this example the data
;   was selected so that the default parameters would converge.
;
;The following functions can be used with FITFUNC:
;   "gaussian", "polycurve", "power_law", "exponential"
;
;KNOWN BUGS: 
;   Do NOT trust the P_SIGMA Values (uncertainty in the parameters) if the
;   the value of flambda gets large. I believe
;   That some error (relating to flambda) was carried over from CURVEFIT. -Davin
;
;MODIFICATION HISTORY:
;       Function copied from CURVEFIT Written, DMS, RSI, September, 1982
;       and last modified by Mark Rivers, U. of Chicago, Febuary 12, 1995.
;       Davin Larson, U of California, November 1995, MAJOR MODIFICATIONS:
;           - Changed FUNCTION_NAME to a function (instead of procedure) that
;             accepts a structure to hold the parameters.  This makes the usage
;             much more user friendly, and allows a subset of parameters to
;             be fit.
;           - Allowed vectors and recursively searched structures to be fit as well.
;

function fitfunc, x, yt, $
          FUNCTION_NAME = Function_Name, $
          weight = w,  $
          dy     =dy,  $
          error_factor = error_fac, $
          parameters = params, $
          names = p_names,  $
          p_names = p_names_obs, $
          p_values = a, $
          p_sigma  = sigmaa, $
          fullnames = fullnames, $
          itmax=itmax, iter=iter, tol=tol, chi2=chi2, $
          maxprint=maxprint, $
          noderivative=noderivative, $
          logfit = logfit, $
          silent = silent

;       on_error,2              ;Return to caller if error

       logf = keyword_set(logfit)

; SET ALL DEFAULTS:
       ;Name of function to fit
       if n_elements(function_name) le 0 then function_name = "FUNCT"
       if n_elements(tol) eq 0 then tol = 1.e-6		;Convergence tolerance
       if n_elements(itmax) eq 0 then itmax = 20	;Maximum # iterations

       derstr = 'Partial derivatives computed '+ [ 'analytically','numerically' ]
       ;check for derivative option:
       if n_elements(NODERIVATIVE) eq 0 then begin
           wh = where(routine_info(/functions) eq strupcase(function_name), compiled)
           if compiled eq 0 then resolve_routine,/is_function,function_name
           args = routine_info(function_name,/funct,/param)
           kw_args = strmid(args.kw_args,0,4)
           wh = where((kw_args eq 'PDER') or (kw_args eq 'P_NA'),c)
           NODERIVATIVE = c ne 2
       endif

       if not keyword_set(silent) then print,derstr[NODERIVATIVE]

       ; If we will be estimating partial derivatives then compute machine
       ; precision
       if NODERIVATIVE then begin
          res = machar(DOUBLE=0)
          eps = sqrt(res.eps)
       endif


;Get params structure if not defined
       if not keyword_set(params) then $
           yfit = call_function( Function_name, param=params)

       type = data_type(params)
       if type ne 8 then begin
           message,'PARAMETERS must be a structure.'
       endif

   if keyword_set(p_names_obs) then begin
       p_names=p_names_obs
;       if not keyword_set(verbose) then $
          message,/info,"P_NAMES keyword is replaced by NAMES"
   endif



       xfer_parameters,params,p_names,a,fullna=fullnames,num_p=nterms,/struct_to_arr
       if nterms eq 0 then begin
          message,/info,'No parameters to fit'
          return,0
       endif

       y = yt(*)
       if keyword_set(error_fac) then dy = error_fac*y
       if keyword_set(dy) then begin 
         if logf then w = (y/dy(*))^2 else w=1/(dy(*))^2
       endif
       if logf then y = alog(y)
       if n_elements(w) eq 0 then w = replicate(1.d, n_elements(y) ) 

       nfree = n_elements(y) - nterms ; Degrees of freedom
       if nfree lt 0 then message, 'Not enough data points.'
       flambda = 0.001          ;Initial lambda
       diag = lindgen(nterms)*(nterms+1) ; Subscripts of diagonal elements

       pder = dblarr(n_elements(y),nterms)

       if not keyword_set(maxprint) then maxprint = 8
       mp = (nterms < maxprint)-1
       nformat='("    ",20(" ",a11))'
       vformat='(i3,":",20(" ",g11.5))'
       sformat='("err:",20(" ",g11.5))'
       if not keyword_set(silent) then print,'Chisq',fullnames[0:mp],format=nformat

       for iter = 1, itmax do begin   ; Iteration loop
          if keyword_set(NODERIVATIVE) then begin
;            Evaluate function and estimate partial derivatives
             yfit = (call_function( Function_name, x, param=params))(*)
             if logf then yfit = alog(yfit)
             xfer_parameters,params,p_names,a,/struct_to_array
             for term=0, nterms-1 do begin
                p = a       ; Copy current parameters
                ; Increment size for forward difference derivative
                inc = eps * abs(p[term])    
                if (inc eq 0.) then inc = eps
                p[term] = p[term] + inc
                tparams = params
                xfer_parameters,tparams,p_names,p,/array_to_struct
                yfit1 = (call_function( Function_name, x, param=tparams))(*)
                if logf then yfit1 = alog(yfit1)
                pder[*,term] = (yfit1-yfit)/inc
             endfor
          endif else begin
             ; The user's procedure will return partial derivatives
             yfit = (call_function(Function_name, x, param=params,  $
                  p_na=fullnames,pder = pder))(*)
             if logf then begin
                  pder = pder / (yfit # replicate(1.,nterms) )
                  yfit = alog(yfit)
             endif     
             xfer_parameters,params,p_names,a,/struct_to_array
          endelse

;         Evaluate alpha and beta matricies.
          ds = ((y-yfit)*w)[*]
          if nterms gt 1 then beta = ds # pder $
          else beta = [total(ds * pder)]
          alpha = transpose(pder) # (w[*] # replicate(1.,nterms) * pder)
          chisq1 = total(w*(y-yfit)^2)/nfree ; Present chi squared.

          if not keyword_set(silent) then print,iter,chisq1,a[0:mp],format=vformat

				; If a good fit, no need to iterate
	  all_done = chisq1 lt total(abs(y))/1e7/nfree
;
;         Invert modified curvature matrix to find new parameters.
flambda=1e-10
          tparams = params
          repeat begin
             c = sqrt(alpha[diag] # alpha[diag])
             array = alpha/c
             array[diag] = array[diag]*(1.+flambda)              
             if nterms gt 1 then array = invert(array) $
             else array = 1/array
             b = a+ array/c # transpose(beta) ; New params
             xfer_parameters,tparams,p_names,b,/array_to_struct
             yfit = (call_function( Function_name, x, param=tparams))(*)
             if logf then yfit = alog(yfit)
             chisqr = total(w*(y-yfit)^2)/nfree         ; New chisqr
if finite(chisqr) eq 0 then begin
    print,'Invalid Data or Parameters in function ',function_name,' Aborting'
    print,iter,chisq1,a[0:mp],format=vformat 
    return,0
endif
;	     if all_done then goto, done
             flambda = flambda*10.                      ; Assume fit got worse
          endrep until chisqr le chisq1
;
          flambda = flambda/10.  ; Decrease flambda by factor of 10
          a=b                     ; Save new parameter estimate.
          params = tparams
          if ((chisq1-chisqr)/chisq1) le tol then goto,done  ; Finished?
       endfor                        ;iteration loop
;
       message, 'Failed to converge', /INFORMATIONAL
;
done:  sigmaa = sqrt(array[diag]/alpha[diag]) ; Return sigma's
;       psigmaa=params
       chi2 = chisqr                          ; Return chi-squared
       if not keyword_set(silent) then begin
          print,iter+1,chi2,a[0:mp],format=vformat
          print,chi2,sigmaa[0:mp],format=sformat
          print,'Chi2 =',chi2,'  flambda =',flambda
       endif
       if logf then yfit = exp(yfit)
       return,yfit              ;return result
END

