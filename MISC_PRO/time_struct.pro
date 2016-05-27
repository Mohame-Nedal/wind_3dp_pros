;+
;*****************************************************************************************
;
;  FUNCTION :   time_struct.pro
;  PURPOSE  :   This program returns a data structure for the input time array/structure.
;
;  CALLED BY:   
;               time_ticks.pro
;               time_string.pro
;               time_double.pro
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               time_struct.pro
;               time_double.pro
;               time_string.pro
;               isdaylightsavingtime.pro
;               day_to_year_doy.pro
;               doy_to_month_date.pro
;
;  REQUIRES:    
;               1)  THEMIS SPEDAS/TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               TIME           :  Scalar or [N]-Element array with the following formats:
;                                   Input time which can have the form of a double
;                                   (Unix times), a string (YYYY-MM-DD/hh:mm:ss), or
;                                   a structure of the same format as the return
;                                   structure format.
;
;  EXAMPLES:    
;               test = time_struct(time)
;               HELP, test
;** Structure TIME_STRUCT, 11 tags, length=40:
;   YEAR            INT           1970            ; year    (0-14699)
;   MONTH           INT              1            ; month   (1-12)
;   DATE            INT              1            ; date    (1-31)
;   HOUR            INT              0            ; hours   (0-23)
;   MIN             INT              0            ; minutes (0-59)
;   SEC             INT              0            ; seconds (0-59)
;   FSEC            DOUBLE           0.0000000    ; fractional seconds (0-.999999)
;   DAYNUM          LONG            719162        ; days since 0 AD  (subject to change)
;   DOY             INT              0            ; day of year (1-366)
;   DOW             INT              3            ; day of week  (subject to change)
;   SOD             DOUBLE           0.0000000    ; seconds of day
;
;  KEYWORDS:    
;               EPOCH          :  If set, routine assumes input is double precision
;                                   EPOCH time
;               NO_CLEAN       :  Set if first attempt at structure is desired
;               MMDDYYYY       :  If set, changes order of date output
;               TIMEZONE       :  Keyword used by isdaylightsavingtime.pro
;               LOCAL_TIME     :  If set, then local time is displayed
;               INFORMAT       :  ** not implemented yet **
;               IS_LOCAL_TIME  :  ** not working correctly yet **
;
;   CHANGED:  1)  Davin Larson changed something...                [11/01/2002   v1.0.15]
;             2)  Re-wrote and cleaned up                          [04/20/2009   v1.1.0]
;             3)  Updated man page                                 [06/17/2009   v1.1.1]
;             4)  THEMIS software update includes:
;                 a)  Multiple syntax changes
;                 b)  Now calls:  dprint.pro and isdaylightsavingtime.pro
;                 c)  Added keywords:  MMDDYYYY, TIMEZONE, LOCAL_TIME, and IS_LOCAL_TIME
;                 d)  Changed return structure format
;                                                                  [09/08/2009   v1.2.0]
;             5)  Minor superficial changes                        [03/16/2010   v1.3.0]
;             6)  Updated to be in accordance with newest version of time_struct.pro
;                   in TDAS IDL libraries
;                   A)  Cleaned up and added some comments
;                   B)  new keyword:  INFORMAT
;                                                                  [04/04/2012   v1.4.0]
;             6)  Updated to be in accordance with newest version of time_struct.pro
;                   in TDAS IDL libraries [thmsw_r10908_2012-09-10]
;                   A)  Removed usage of dprint.pro
;                                                                  [09/12/2012   v1.5.0]
;             7)  If the input value was a scalar integer, the routine would get caught
;                   in an infinite loop, now this shouldn't happen
;                                                                  [10/26/2012   v1.5.1]
;             8)  Updated Man. page and removed limit on time resolution for numeric
;                   input
;                                                                  [09/23/2015   v1.5.2]
;
;   NOTES:      
;               1)  This routine works on vectors and is designed to be fast.
;               2)  Output will have the same dimensions as the input
;               3)  See also:  time_string.pro, time_double.pro, time_epoch.pro
;
;  REFERENCES:  
;               NA
;
;   CREATED:  Oct, 1996
;   CREATED BY:  Davin Larson
;    LAST MODIFIED:  09/23/2015   v1.5.2
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION time_struct,time,EPOCH=epoch,NO_CLEAN=no_clean,MMDDYYYY=mmddyyyy, $
                          TIMEZONE=timezone,LOCAL_TIME=local_time,         $
                          INFORMAT=informat,                               $
                          IS_LOCAL_TIME=is_local_time

;;----------------------------------------------------------------------------------------
;;  
;;----------------------------------------------------------------------------------------
;  TDAS Update
;dprint,DLEVEL=9,time[0]
dt             = SIZE(time,/TYPE)
IF KEYWORD_SET(timezone) THEN BEGIN
   local_time = 1
   tzone      = timezone
ENDIF
;;  There is no need to call time_double.pro and then re-call time_struct.pro in the
;;    the string input case below, so here we check to see if any of the keywords
;;    that would require these steps are set.  If not --> force NO_CLEAN = TRUE
;;
;;    *** Without this setting, the "cleaning" process causes rounding errors ***
test_clean     = (N_ELEMENTS(timezone) LT 1) AND (N_ELEMENTS(local_time) LT 1) AND $
                 (N_ELEMENTS(is_local_time) LT 1); AND 
IF (test_clean[0]) THEN no_clean = 1b
;;----------------------------------------------------------------------------------------
;;  Define some dummy logic variables
;;----------------------------------------------------------------------------------------
stris = 0   ;;  Logical number for string
dobll = 0   ;;  Logical number for double, float, or long
struc = 0   ;;  Logical number for structure
undef = 0   ;;  Logical number for undefined
d     = !VALUES.D_NAN
tst_t = ['YEAR','MONTH','DATE','HOUR','MIN','SEC','FSEC','DAYNUM','DOY','DOW','SOD',$
         'DST','TZONE','TDIFF']
tst0  = CREATE_STRUCT(tst_t,1970,1,1,0,0,0,d,0L,0,0,d,0,0,0,NAME='TIME_STRUCTR')
;;----------------------------------------------------------------------------------------
;;  Determine size and type of variable time
;;----------------------------------------------------------------------------------------
dim  = SIZE(time,/DIMENSIONS)
ndim = SIZE(time,/N_DIMENSIONS)

IF (ndim[0] EQ 0) THEN tsts = tst0 ELSE tsts = MAKE_ARRAY(VALUE=tst0,DIM=dim)

CASE dt[0] OF
  7L   : BEGIN  ;;  Input is a string
    stris = 1
  END
  5L   : BEGIN  ;;  Input is a double
    dobll = 1
  END
  4L   : BEGIN  ;;  Input is a float => turns into double
    dobll = 1
  END
  3L   : BEGIN  ;;  Input is a long => turns into double
    dobll = 1
  END
  14L  : BEGIN  ;;  Input is a 64 bit long => turns into double
    dobll = 1
  END
  8L   : BEGIN  ;;  Input is a structure
    struc = 1
    RETURN, time_struct(time_double(time),TIMEZONE=timezone)
  END
  0L   : BEGIN  ;;  Input is undefined
    undef = 1
    MESSAGE,'Improper input format!',/CONTINUE,/INFORMATIONAL
    RETURN,time_struct(time_string(time,PREC=6))
  END
  ELSE : BEGIN  ;;  Input is in an unusable format
    MESSAGE,'Invalid input format!',/CONTINUE,/INFORMATIONAL
    IF (dt[0] LT 3) THEN BEGIN
      RETURN,tsts
    ENDIF ELSE BEGIN
      RETURN,time_struct(time_string(time,PREC=6))
    ENDELSE
  END
ENDCASE

IF KEYWORD_SET(epoch) THEN BEGIN
  RETURN,time_struct(time_double(time,EPOCH=epoch),TIMEZONE=timezone)
ENDIF

check = [stris,dobll,struc,undef]
gchck = WHERE(check GT 0,gch)
IF (gch GT 0) THEN BEGIN
  CASE gchck[0] OF
    0L   : BEGIN
      ;;----------------------------------------------------------------------------------
      ;;  Input is a string
      ;;----------------------------------------------------------------------------------
      bt                = BINDGEN(256)
      ;;  Create new ascii set where common separators are replaced with spaces
      bt[BYTE(':_-/,')] = 32
      year = 0L & month = 0 & date = 0 & hour = 0 & min = 0 & fsec = 0d0
      FOR i=0L, N_ELEMENTS(time) - 1L DO BEGIN
        tst = tst0
        str = STRING(bt[BYTE(time[i])])+' 0 0 0 0 0 0'    ;;  Remove separators
        ;;  get Year, Month, Day, Hour, Minute, and Seconds out of STR
        IF KEYWORD_SET(mmddyyyy) THEN BEGIN
          READS,str,month,date,year,hour,min,fsec
        ENDIF ELSE BEGIN
          READS,str,year,month,date,hour,min,fsec
        ENDELSE
        ;;  check for unphysically large year number
        IF (year GT 10000000L) THEN BEGIN
          hour  = month
          date  = year MOD 100
          year  = year/100
          month = year MOD 100
          year  = year/100
          min   = hour MOD 100
          hour  = hour/100
        ENDIF
        IF (year LT 70L ) THEN year = year + 2000L
        IF (year LT 200L) THEN year = year + 1900L
        ;;  make sure month and date are at least 1
        month     = month > 1
        date      = date  > 1
        ;;  define structure tag values
        tst.YEAR  = year
        tst.MONTH = month
        tst.DATE  = date
        tst.HOUR  = hour
        tst.MIN   = min
        ;;  Separate seconds and fractional seconds
        tst.SEC   = FIX(fsec)
        tst.FSEC  = (DOUBLE(fsec) MOD 1d0)
;        tst.FSEC  = fsec
;        IF (tst.FSEC[0] LT 0) THEN STOP   ;;  figure out where things go wrong...
        ;;  define new element in structure array
        tsts[i]   = tst
      ENDFOR 
      IF KEYWORD_SET(no_clean) THEN BEGIN
        ;;  Return to user
        RETURN,tsts
      ENDIF ELSE BEGIN
        t = time_double(tsts)  ;;  get Unix time
        IF KEYWORD_SET(is_local_time) THEN BEGIN
;  TDAS Update
;          dprint,DLEVEL=9,'is_local_time'
          ;;  ??  input was local time, not UTC  ??
          dst = isdaylightsavingtime(t,tzone)
          t  -= (dst + tzone)*3600
        ENDIF
        ;;  Return to user
        RETURN, time_struct(t,TIMEZONE=timezone,LOCAL_TIME=local_time)
      ENDELSE
    END
    1L   : BEGIN
      ;;----------------------------------------------------------------------------------
      ;;  Input is a double, float, or long
      ;;----------------------------------------------------------------------------------
      good = WHERE(FINITE(time),gd)
      IF (gd GT 0L) THEN BEGIN
        ltime  = time[good]
        IF KEYWORD_SET(local_time) THEN BEGIN
          dst              = isdaylightsavingtime(time[good],tzone)
          ltime           += (tzone + dst)*3600L
          tsts[good].DST   = dst
          tsts[good].TZONE = tzone
          tsts[good].TDIFF = tzone + dst
        ENDIF
        dn1970 = 719162L                       ;;  Julian day number for 1970-01-01
        dn     = FLOOR(time[good]/36d2/24d0)   ;;  day number
        sod    = ltime - dn*36d2*24d0          ;;  seconds of day
        daynum = dn + dn1970[0]                ;;  ??  Julian day number ??
        hour   = FLOOR(sod/36d2)               ;;  hour
        fsec   = sod - hour*36d2               ;;  fractional seconds of day
        min    = FLOOR(fsec/6d1)               ;;  minutes of hour
        fsec   = fsec - min*6d1                ;;  fractional seconds of minute
        sec    = FLOOR(fsec)                   ;;  rounded seconds of minute
        fsec   = fsec - sec                    ;;  fractional seconds
        ;;  convert Julian day number -> year and (day of year)
        day_to_year_doy,daynum,year,doy
        ;;  convert year and (day of year) -> month and date
        doy_to_month_date,year,doy,month,date
        ;;  replace structure elements
        tsts[good].MONTH  = month
        tsts[good].DATE   = date
        tsts[good].YEAR   = year
        tsts[good].DOY    = doy
        tsts[good].HOUR   = hour
        tsts[good].MIN    = min
        tsts[good].SEC    = sec
        tsts[good].FSEC   = LONG64(fsec*1d15)/1d15  ;;  round to petasecond level
;        tsts[good].FSEC   = LONG64(fsec*1d18)/1d18  ;;  round to exasecond level [too big]
;        tsts[good].FSEC   = LONG64(fsec*1d24)/1d24  ;;  round to yoctosecond level [way too big]
;        tsts[good].FSEC   = ROUND(fsec*1d6)/1d6  ;  round to microsecond level
        tsts[good].SOD    = sod
        tsts[good].DAYNUM = daynum
        tsts[good].DOW    = daynum MOD 7         ;;  day of week
;        IF (tsts[good].FSEC[0] LT 0) THEN STOP   ;;  figure out where things go wrong...
      ENDIF
      ;;  Return to user
      RETURN,tsts
    END
    2L   : BEGIN
      ;;  Input is a structure  [** should not get here **]
      RETURN, time_struct(time_double(time),TIMEZONE=timezone)
    END
    ELSE : BEGIN
      ;;  Input is in an unusable format  [** should not get here **]
      MESSAGE,'I have no clue how you managed this...',/CONTINUE,/INFORMATIONAL
      RETURN,time_struct(time_string(time,PREC=6))
    END
  ENDCASE
ENDIF ELSE BEGIN
  MESSAGE,'I have no clue how you managed this...',/CONTINUE,/INFORMATIONAL
  RETURN,time_struct(time_string(time,PREC=6))
ENDELSE

;;  Should not reach this point
MESSAGE,'Improper time input',/INFORMATIONAL
END