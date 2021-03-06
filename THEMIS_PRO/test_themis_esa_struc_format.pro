;+
;*****************************************************************************************
;
;  FUNCTION :   test_themis_esa_struc_format.pro
;  PURPOSE  :   This program tests the format of an input IDL structure, returning
;                 TRUE[FALSE] if input structure format is[is not] consistent with the
;                 THEMIS/ESA data structures.
;
;  CALLED BY:   
;               test_wind_vs_themis_esa_struct.pro
;
;  CALLS:
;               dat_themis_esa_str_names.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT  :  Scalar [structure] associated with a known THEMIS ESA data
;                         structure
;
;  EXAMPLES:    
;               test = test_themis_esa_struc_format(dat)
;
;  KEYWORDS:    
;               NOM     :  If set, routine will not print out messages
;               PAD     :  If set, routine will test if routine was returned by pad.pro
;
;   CHANGED:  1)  Fixed a typo in default message
;                                                                   [03/13/2012   v1.0.1]
;             2)  Added keyword:  NOM
;                                                                   [03/29/2012   v1.1.0]
;             3)  Now routine should work with structures returned by pad.pro and
;                   added keyword:  PAD
;                                                                   [10/02/2014   v1.2.0]
;             4)  Now should work with SST data structures
;                                                                   [11/15/2015   v1.3.0]
;
;   NOTES:      
;               1)  see also:  test_3dp_struc_format.pro
;               2)  This routine is specific to the THEMIS mission
;               3)  Routine should now be able to handle structures returned by pad.pro
;
;  REFERENCES:  
;               NA
;
;   CREATED:  03/08/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/15/2015   v1.3.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION test_themis_esa_struc_format,dat,NOM=nom,PAD=test_pad

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
notstr_mssg    = 'Must be an IDL structure...'
badstr_mssg    = 'Not an appropriate THEMIS ESA structure...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF N_PARAMS() EQ 0 THEN RETURN,0b
str            = dat[0]   ;;  in case it is an array of structures of the same format
IF (SIZE(str,/TYPE) NE 8L) THEN BEGIN
  IF ~KEYWORD_SET(nom) THEN MESSAGE,notstr_mssg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF

strns          = dat_themis_esa_str_names(str[0],NOM=nom)
IF (SIZE(strns,/TYPE) NE 8L) THEN BEGIN
  IF ~KEYWORD_SET(nom) THEN MESSAGE,badstr_mssg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Expected format:  
;;      {LC:[scalar string], UC:[scalar string], SN:[scalar string]}
IF (N_TAGS(strns) NE 3L) THEN BEGIN
  IF ~KEYWORD_SET(nom) THEN MESSAGE,badstr_mssg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
sname          = strns[0].SN           ;;  e.g., 'pseb'
snpre          = STRMID(sname[0],0,2)  ;;  
;;----------------------------------------------------------------------------------------
;;  Examine input
;;----------------------------------------------------------------------------------------
tags           = STRLOWCASE(TAG_NAMES(str))
ntags          = N_TAGS(str)
test0a         = TOTAL(tags EQ 'project_name') EQ 1
test0b         = TOTAL(tags EQ 'data_name') EQ 1
test1a         = TOTAL(tags EQ 'time') EQ 1
test1b         = TOTAL(tags EQ 'end_time') EQ 1
test1c         = TOTAL(tags EQ 'nbins') EQ 1
test1d         = TOTAL(tags EQ 'nenergy') EQ 1
test2a         = TOTAL(tags EQ 'data') EQ 1
test2c         = TOTAL(tags EQ 'gf') EQ 1
test2d         = TOTAL(tags EQ 'energy') EQ 1
test2e         = TOTAL(tags EQ 'denergy') EQ 1
test3a         = TOTAL(tags EQ 'phi') EQ 1
test3b         = TOTAL(tags EQ 'dphi') EQ 1
test3c         = TOTAL(tags EQ 'theta') EQ 1
test3d         = TOTAL(tags EQ 'dtheta') EQ 1
test4a         = TOTAL(tags EQ 'angles') EQ 1           ;;  TRUE for PADs
IF (snpre[0] EQ 'ps') THEN BEGIN
  ;;  SST structure
  test2b         = TOTAL(tags EQ 'att') EQ 1
  test2f         = TOTAL(tags EQ 'eff') EQ 1
ENDIF ELSE BEGIN
  ;;  ESA structure
  test2b         = TOTAL(tags EQ 'dt_arr') EQ 1
  test2f         = TOTAL(tags EQ 'dead') EQ 1
ENDELSE

IF KEYWORD_SET(test_pad) THEN BEGIN
  ;;  PAD structure
  tests          = [test0a,test0b,test1a,test1b,test1c,test1d,test2a,test2b,test2c,test2d,$
                    test2e,test2f,test4a]
ENDIF ELSE BEGIN
  ;;  SST or ESA structure
  tests          = [test0a,test0b,test1a,test1b,test1c,test1d,test2a,test2b,test2c,test2d,$
                    test2e,test2f,test3a,test3b,test3c,test3d]
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------
good   = TOTAL(tests) EQ N_ELEMENTS(tests)
IF (good) THEN BEGIN
  RETURN,good
ENDIF ELSE BEGIN
  IF ~KEYWORD_SET(nom) THEN MESSAGE,badstr_mssg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDELSE

END
