;+
;*****************************************************************************************
;
;  FUNCTION :   beam_fit___get_common.pro
;  PURPOSE  :   This routine returns the value of a common block variable defined by
;                 the input string, LOGIC.
;
;  CALLED BY:   
;               beam_fit_change_parameter.pro
;               beam_fit_contour_plot.pro
;               beam_fit_fit_wrapper.pro
;               beam_fit_options.pro
;               beam_fit_prompts.pro
;               beam_fit_1df_plot_fit.pro
;               wrapper_beam_fit_array.pro
;
;  CALLS:
;               beam_fit_struc_common.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               LOGIC    :  Scalar [string] that matches the name of a common block
;                             variable
;
;  EXAMPLES:    
;               ;;  To get the variable VSW, enter the following,
;               ;;    where DEFINED will tell you if VSW was already defined [= 1]
;               ;;    or if undefined [= 0]
;               vsw = beam_fit___get_common('vsw',DEFINED=defined)
;
;  KEYWORDS:    
;               DEFINED  :  Set to a named variable to return a scalar defining
;                             whether the associated common block variable is defined
;                               TRUE  = 1
;                               FALSE = 0
;
;   CHANGED:  1)  Continued to write routine                       [09/07/2012   v1.0.0]
;
;   NOTES:      
;               1)  LOGIC must match EXACTLY to the string name associated with the
;                     desired common block variable
;               2)  See also:  beam_fit_keyword_com.pro, beam_fit_params_com.pro,
;                              beam_fit_unset_common.pro, beam_fit___set_common.pro,
;                              beam_fit_struc_common.pro
;
;   CREATED:  08/30/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  09/07/2012   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION beam_fit___get_common,logic,DEFINED=defined

;;----------------------------------------------------------------------------------------
;; => Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
defined        = 0b

key_com_str    = ['vlim','ngrid','nsmooth','sm_cuts','sm_cont','dfra','dfmin','dfmax',$
                  'plane','angle','fill','perc_pk','save_dir','file_pref','file_midf']
key_par_str    = ['vsw','vcmax','v_bx','v_by','vb_reg','vbmax','def_fill','def_perc', $
                  'def_dfmin','def_dfmax','def_ngrid','def_nsmth','def_plane',        $
                  'def_sdir','def_pref','def_midf','def_vlim']
;key_par_str    = ['vsw','vcmax','v_bx','v_by','vb_reg','def_fill','def_perc','def_dfmin',$
;                  'def_dfmax','def_ngrid','def_nsmth','def_plane','def_sdir','def_pref', $
;                  'def_midf','def_vlim']
key_all_str    = [key_com_str,key_par_str]
nkey           = N_ELEMENTS(key_all_str)
;;  Define a dummy array with null strings
key_def_str    = REPLICATE('',nkey)
;;  Define default type codes for each common block variable
;;    => Result of SIZE([variable],/TYPE)
def_types      = [5L,3L,3L,2L,2L,5L,5L,5L,7L,5L,5L,5L,7L,7L,7L,4L,5L,5L,5L,5L,5L,5L,5L,$
                  5L,5L,3L,3L,7L,7L,7L,7L,5L]
;;  Define default # of elements for each common block variable
def_elmnt      = [1L,1L,1L,1L,1L,2L,1L,1L,1L,1L,1L,1L,1L,10L,1L,3L,1L,1L,1L,4L,1L,1L,1L,$
                  1L,1L,1L,1L,1L,1L,10L,1L,1L]
;;;  Define default type codes for each common block variable
;;;    => Result of SIZE([variable],/TYPE)
;def_types      = [5L,3L,3L,2L,2L,5L,5L,5L,7L,5L,5L,5L,7L,7L,7L,4L,5L,5L,5L,5L,5L,5L,$
;                  5L,5L,3L,3L,7L,7L,7L,7L,5L]
;;;  Define default # of elements for each common block variable
;def_elmnt      = [1L,1L,1L,1L,1L,2L,1L,1L,1L,1L,1L,1L,1L,10L,1L,3L,1L,1L,1L,4L,1L,1L,$
;                  1L,1L,1L,1L,1L,1L,10L,1L,1L]
;;----------------------------------------------------------------------------------------
;; => Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 1)
IF (test) THEN RETURN,-1
;;----------------------------------------------------------------------------------------
;; => Determine if common block variables are defined
;;----------------------------------------------------------------------------------------
dumb           = beam_fit_struc_common(DEFINED=define_arr)
test           = (TOTAL(define_arr) LT 1) OR (SIZE(dumb,/TYPE) NE 8)
IF (test) THEN RETURN,-1
;;  Find all the common block variables that are defined
good_all       = WHERE(define_arr,gdall,COMPLEMENT=bad_all,NCOMPLEMENT=bdall)
IF (gdall GT 0) THEN BEGIN
  key_def_str[good_all]  =  key_all_str[good_all]
ENDIF
;;----------------------------------------------------------------------------------------
;; => Determine what variable the user wants
;;----------------------------------------------------------------------------------------
log            = STRLOWCASE(logic[0])
test           = (key_def_str EQ log[0]) AND (key_def_str NE '')
good           = WHERE(test,gd)
IF (gd EQ 0) THEN RETURN,-1  ;; either not defined or no match
;; => Define variable [success]
defvar         = dumb.(good[0])
defined        = 1b
;;----------------------------------------------------------------------------------------
;; => Return to user
;;----------------------------------------------------------------------------------------

RETURN,defvar
END
