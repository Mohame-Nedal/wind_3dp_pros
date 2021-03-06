;+
;*****************************************************************************************
;
;  FUNCTION :   conv_units.pro
;  PURPOSE  :   This is a wrapping program for the unit conversion programs for Wind,
;                 THEMIS, etc., 3DP particle distribution structures.  This function
;                 is just a shell that calls whatever conversion procedure is specified
;                 in data[0].UNITS_PROCEDURE.
;
;  CALLED BY:   
;               [any routine that converts units of a particle distribution structure]
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               convert_esa_units.pro
;               convert_ph_units.pro
;               convert_sf_units.pro
;               convert_so_units.pro
;               convert_sst_units.pro
;               thm_convert_esa_units_lbwiii.pro
;               thm_sst_convert_units2.pro
;               etc.
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DATA               :  [N]-element array [structure] of particle velocity
;                                       distributions THEMIS ESA or Wind/3DP in the form
;                                       of IDL data structures
;                                       [See:  get_??.pro for Wind]
;                                       [See:  thm_part_dist_array.pro for THEMIS]
;               UNITS              :  Scalar [string] defining to which the units to
;                                       convert.  The following inputs are allowed:
;                                         'compressed'  ;  # of counts
;                                         'counts'      ;  # of counts
;                                         'rate'        ;  [s^(-1)]
;                                         'crate'       ;  [s^(-1)] scaled rate
;                                         'eflux'       ;  energy flux
;                                         'flux'        ;  number flux
;                                         'df'          ;  phase space density
;                                       [Default = 'eflux']
;
;  EXAMPLES:    
;               ;;  Convert from counts to phase space density
;               dat_df = conv_units(dat_counts,'df')
;
;  KEYWORDS:    
;               SCALE              :  Set to a named variable to return the conversion
;                                       factor array used to scale the data
;               FRACTIONAL_COUNTS  :  If set, routine will allow for fractional counts
;                                       to be used rather than rounded to nearest whole
;                                       count.  This has been defaulted to TRUE to avoid
;                                       rounding errors which results in quantization
;                                       artifacts.
;                                       [Default = TRUE]
;
;   CHANGED:  1)  Davin Larson changed something...
;                                                                   [11/07/1995   v1.0.8]
;             2)  Re-wrote and cleaned up
;                                                                   [06/22/2009   v1.1.0]
;             3)  Fixed syntax issue if data is an array of structures
;                                                                   [08/05/2009   v1.1.1]
;             4)  Added keyword:  FRACTIONAL_COUNTS and
;                   cleaned up Man. page and added some comments
;                                                                   [09/12/2014   v1.2.0]
;             5)  Updated in accordance with latest version of SPEDAS [11-16-2015 build]
;                   - Updated Man. page
;                   - Changed FRACTIONAL_COUNTS to _EXTRA
;                     - Removed separate calling sequences for CALL_PROCEDURE.PRO
;                                                                   [11/16/2015   v1.3.0]
;             6)  Fixed a bug caught by S.E. Dorfman
;                                                                   [12/04/2015   v1.3.1]
;             8)  Fixed explanation of FRACTIONAL_COUNTS keyword
;                                                                   [02/19/2016   v1.3.2]
;
;   NOTES:      
;               1)  See also:  convert_esa_units.pro, thm_convert_esa_units_lbwiii.pro,
;                              or any other unit converting routine for more details
;
;  REFERENCES:  
;               1)  Carlson et al., (1983), "An instrument for rapidly measuring
;                      plasma distribution functions with high resolution,"
;                      Adv. Space Res. Vol. 2, pp. 67-70.
;               2)  Curtis et al., (1989), "On-board data analysis techniques for
;                      space plasma particle instruments," Rev. Sci. Inst. Vol. 60,
;                      pp. 372.
;               3)  Lin et al., (1995), "A Three-Dimensional Plasma and Energetic
;                      particle investigation for the Wind spacecraft," Space Sci. Rev.
;                      Vol. 71, pp. 125.
;               4)  Paschmann, G. and P.W. Daly (1998), "Analysis Methods for Multi-
;                      Spacecraft Data," ISSI Scientific Report, Noordwijk, 
;                      The Netherlands., Int. Space Sci. Inst.
;               5)  McFadden, J.P., C.W. Carlson, D. Larson, M. Ludlam, R. Abiad,
;                      B. Elliot, P. Turin, M. Marckwordt, and V. Angelopoulos
;                      "The THEMIS ESA Plasma Instrument and In-flight Calibration,"
;                      Space Sci. Rev. 141, pp. 277-302, (2008).
;               6)  McFadden, J.P., C.W. Carlson, D. Larson, J.W. Bonnell,
;                      F.S. Mozer, V. Angelopoulos, K.-H. Glassmeier, U. Auster
;                      "THEMIS ESA First Science Results and Performance Issues,"
;                      Space Sci. Rev. 141, pp. 477-508, (2008).
;               7)  Auster, H.U., K.-H. Glassmeier, W. Magnes, O. Aydogar, W. Baumjohann,
;                      D. Constantinescu, D. Fischer, K.H. Fornacon, E. Georgescu,
;                      P. Harvey, O. Hillenmaier, R. Kroth, M. Ludlam, Y. Narita,
;                      R. Nakamura, K. Okrafka, F. Plaschke, I. Richter, H. Schwarzl,
;                      B. Stoll, A. Valavanoglou, and M. Wiedemann "The THEMIS Fluxgate
;                      Magnetometer," Space Sci. Rev. 141, pp. 235-264, (2008).
;               8)  Angelopoulos, V. "The THEMIS Mission," Space Sci. Rev. 141,
;                      pp. 5-34, (2008).
;               9)  Bordoni, F. "Channel electron multiplier efficiency for 10-1000 eV
;                      electrons," Nucl. Inst. & Meth. 97, pp. 405, (1971).
;              10)  Goruganthu, R.R. and W.G. Wilson "Relative electron detection
;                      efficiency of microchannel plates from 0-3 keV,"
;                      Rev. Sci. Inst. 55, pp. 2030-2033, (1984).
;              11)  Meeks, C. and P.B. Siegel "Dead time correction via the time series,"
;                      Amer. J. Phys. 76, pp. 589-590, (2008).
;              12)  Schecker, J.A., M.M. Schauer, K. Holzscheiter, and M.H. Holzscheiter
;                      "The performance of a microchannel plate at cryogenic temperatures
;                      and in high magnetic fields, and the detection efficiency for
;                      low energy positive hydrogen ions,"
;                      Nucl. Inst. & Meth. in Phys. Res. A 320, pp. 556-561, (1992).
;
;   CREATED:  ??/??/????
;   CREATED BY:  Davin Larson
;    LAST MODIFIED:  02/19/2016   v1.3.2
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION conv_units,data,units,SCALE=scale,_EXTRA=_extra

;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (SIZE(data,/TYPE) NE 8) THEN RETURN,0    ;; Error
new_data       = data
proc           = data[0].UNITS_PROCEDURE    ;;  Necessary to include [0] if DATA is an array of structures
test           = ((NOT KEYWORD_SET(units)) OR (SIZE(units,/TYPE) NE 7))
IF (test[0]) THEN units = 'Eflux'
;;----------------------------------------------------------------------------------------
;;  Convert units
;;----------------------------------------------------------------------------------------
CALL_PROCEDURE,proc,new_data,units,SCALE=scale,_EXTRA=_extra
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,new_data
END

