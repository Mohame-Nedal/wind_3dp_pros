;+
;*****************************************************************************************
;
;  PROCEDURE:   plot_esa_sst_combined_spec3d.pro
;  PURPOSE  :   This routine plots a combined 3D spectra of from the low energy ESA and
;                 the higher energy SST instruments.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               dat_themis_esa_str_names.pro
;               extract_tags.pro
;               test_plot_axis_range.pro
;               str_element.pro
;               is_a_number.pro
;               is_a_3_vector.pro
;               wind_3dp_units.pro
;               format_esa_bins_keyword.pro
;               conv_units.pro
;               transform_vframe_3d.pro
;               lbw_spec3d.pro
;               dat_3dp_energy_bins.pro
;               get_power_of_ten_ticks.pro
;               trange_str.pro
;               file_name_times.pro
;               popen.pro
;               pclose.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS 8.0 or SPEDAS 1.0 (or greater) IDL libraries
;               2)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT_ESA    :  Scalar [structure] associated with a known THEMIS ESA
;                               data structure [see get_th?_pe*b.pro, ? = a-f]
;                               or a Wind/3DP data structure
;                               [see get_?.pro, ? = el, elb, pl, ph, eh, etc.]
;               DAT_SST    :  Scalar [structure] associated with a known THEMIS SST
;                               data structure [see get_th?_ps*b.pro, ? = a-f]
;                               or a Wind/3DP data structure
;                               [see get_?.pro, ? = sf, sfb, so, sob]
;
;  EXAMPLES:    
;               [calling sequence]
;               plot_esa_sst_combined_spec3d,dat_esa,dat_sst [,LIM_ESA=lim_esa]          $
;                                           [,LIM_SST=lim_sst] [,ESA_ERAN=esa_eran]      $
;                                           [,SST_ERAN=sst_eran] [,/SC_FRAME]            $
;                                           [,CUT_RAN=cut_ran] [,/P_ANGLE]               $
;                                           [,/SUNDIR] [,VECTOR=vec] [,UNITS=units]      $
;                                           [,ESA_BINS=esa_bins] [,SST_BINS=sst_bins]    $
;                                           [,EX_SUFFX=ex_suffx] [,ONE_C=one_c]          $
;                                           [,RM_PHOTO_E=rm_photo_e] [,EX_LINE=ex_line]
;
;  KEYWORDS:    
;               **********************************
;               ***       DIRECT  INPUTS       ***
;               **********************************
;               LIM_ESA     :  Scalar [structure] used for plotting the ESA distribution
;                                that may contain any combination of the following
;                                structure tags or keywords accepted by PLOT.PRO:
;                                  XLOG,   YLOG,   ZLOG,
;                                  XRANGE, YRANGE, ZRANGE,
;                                  XTITLE, YTITLE,
;                                  TITLE, POSITION, REGION, etc.
;                                  (see IDL documentation for a description)
;                                The structure is passed to lbw_spec3d.pro through the
;                                LIMITS keyword.
;               LIM_SST     :  Scalar [structure] used for plotting the SST distribution
;                                that may contain any combination of the following
;                                structure tags or keywords accepted by PLOT.PRO:
;                                  XLOG,   YLOG,   ZLOG,
;                                  XRANGE, YRANGE, ZRANGE,
;                                  XTITLE, YTITLE,
;                                  TITLE, POSITION, REGION, etc.
;                                  (see IDL documentation for a description)
;                                The structure is passed to lbw_spec3d.pro through the
;                                LIMITS keyword.
;               ESA_ERAN    :  [2]-Element [float/double] array defining the range of
;                                energies [eV] over which the ESA data will be plotted
;                                [Default  :  [10,25000]]
;               SST_ERAN    :  [2]-Element [float/double] array defining the range of
;                                energies [keV] over which the ESA data will be plotted
;                                [Default  :  [30,500]]
;               SC_FRAME    :  If set, routine will fit the data in the spacecraft frame
;                                of reference rather than the eVDF's bulk flow frame
;                                [Default  :  FALSE]
;               CUT_RAN     :  Scalar [numeric] defining the range of angles [deg] about a
;                                center angle to use when averaging to define the spectra
;                                along a given direction
;                                [Default  :  22.5]
;               P_ANGLE     :  If set, routine will use the MAGF tag within DAT_ESA and
;                                DAT_SST to define the angular distributions for plotting
;                                (i.e., here it would be a pitch-angle distribution)
;                                [Default  :  TRUE]
;               SUNDIR      :  If set, routine will use the unit vector [-1,0,0] as the
;                                direction about which to define the angular distributions
;                                for plotting
;                                [Default  :  FALSE]
;               VECTOR      :  [3]-Element [float/double] array defining the vector
;                                direction about which to define the angular distributions
;                                for plotting
;                                [Default  :  determined by P_ANGLE and SUNDIR settings]
;               UNITS       :  Scalar [string] defining the units to use for the
;                                vertical axis of the plot and the outputs YDAT and DYDAT
;                                [Default = 'flux' or number flux]
;               ESA_BINS    :  [N]-Element [byte] array defining which ESA solid angle bins
;                                 should be plotted [i.e., BINS[good] = 1b] and which
;                                 bins should not be plotted [i.e., BINS[bad] = 0b].
;                                 One can also define bins as an array of indices that
;                                 define which solid angle bins to plot.  If this is the
;                                 case, then on output, BINS will be redefined to an
;                                 array of byte values specifying which bins are TRUE or
;                                 FALSE.
;                                 [Default:  BINS[*] = 1b]
;               SST_BINS    :  [N]-Element [byte] array defining which SST solid angle bins
;                                 should be plotted [i.e., BINS[good] = 1b] and which
;                                 bins should not be plotted [i.e., BINS[bad] = 0b].
;                                 One can also define bins as an array of indices that
;                                 define which solid angle bins to plot.  If this is the
;                                 case, then on output, BINS will be redefined to an
;                                 array of byte values specifying which bins are TRUE or
;                                 FALSE.
;                                 [Default:  BINS[*] = 1b]
;               EX_SUFFX    :  Scalar [string] defining an extra suffix to attach to the
;                                 PS output file name
;                                 Note:  routine will automatically add '_' before adding
;                                        EX_SUFFX to default file name
;                                 [Default:  '']
;               LEG_SFFX    :  Scalar [string] defining an extra suffix to attach to the
;                                 legend labels for the three cut directions
;                                 Note:  routine will automatically add ' ' before adding
;                                        LEG_SFFX to default legend labels
;                                 [Default:  '']
;               ONE_C       :  If set, routine computes one-count levels as well and
;                                outputs an average on the plot (but returns the full
;                                array of points on output from lbw_spec3d.pro)
;                                [Default = FALSE]
;               RM_PHOTO_E  :  If set, routine will remove data below the spacecraft
;                                potential defined by the structure tag SC_POT and
;                                shift the corresponding energy bins by
;                                CHARGE*SC_POT
;                                [Default = FALSE]
;               EX_LINE     :  Scalar [structure] defining the value and label of an
;                                extra vertical line to output on the final plots.  The
;                                structure must have the following tags:
;                                  NSTR  :  Scalar [string] defining the label
;                                  NVAL  :  Scalar [numeric] defining the value or
;                                             location [eV]
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [02/03/2016   v1.0.0]
;             2)  Continued to write routine
;                                                                   [02/05/2016   v1.0.0]
;             3)  Continued to write routine
;                                                                   [02/18/2016   v1.0.0]
;             4)  Continued to write routine
;                                                                   [02/19/2016   v1.0.0]
;             5)  Finished writing routine and renamed to
;                   plot_esa_sst_combined_spec3d.pro from
;                   temp_plot_esa_sst_combined_spec3d.pro
;                                                                   [02/19/2016   v1.0.0]
;             6)  Added the keyword RM_PHOTO_E so that the routine can now remove
;                   the spacecraft potential when plotting spectra in the spacecraft
;                   frame of reference
;                                                                   [01/02/2017   v1.1.0]
;             7)  Added error handling to deal with events with no data in a given
;                   angle range
;                                                                   [08/09/2017   v1.1.1]
;             8)  Added the keyword EX_LINE and now calls struct_value.pro
;                                                                   [08/09/2017   v1.1.2]
;
;   NOTES:      
;               1)  This routine is meant to be a wrapper for lbw_spec3d.pro so as to
;                     combine plots for ESA and SST data into one plot
;               2)  Try to keep the string LEG_SFFX short and simple
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
;               9)  Ni, B., Y. Shprits, M. Hartinger, V. Angelopoulos, X. Gu, and
;                      D. Larson "Analysis of radiation belt energetic electron phase
;                      space density using THEMIS SST measurements: Cross‐satellite
;                      calibration and a case study," J. Geophys. Res. 116, A03208,
;                      doi:10.1029/2010JA016104, 2011.
;              10)  Turner, D.L., V. Angelopoulos, Y. Shprits, A. Kellerman, P. Cruce,
;                      and D. Larson "Radial distributions of equatorial phase space
;                      density for outer radiation belt electrons," Geophys. Res. Lett.
;                      39, L09101, doi:10.1029/2012GL051722, 2012.
;
;   CREATED:  02/02/2016
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/09/2017   v1.1.2
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO plot_esa_sst_combined_spec3d,dat_esa,dat_sst,LIM_ESA=lim_esa,LIM_SST=lim_sst,   $
                                 ESA_ERAN=esa_eran,SST_ERAN=sst_eran,               $
                                 SC_FRAME=sc_frame,CUT_RAN=cut_ran,P_ANGLE=p_angle, $
                                 SUNDIR=sundir,VECTOR=vec,UNITS=units,              $
                                 ESA_BINS=esa_bins,SST_BINS=sst_bins,               $
                                 EX_SUFFX=ex_suffx,LEG_SFFX=leg_sffx,ONE_C=one_c,   $
                                 RM_PHOTO_E=rm_photo_e,EX_LINE=ex_line

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
lim0           = {XSTYLE:1,YSTYLE:1,XMINOR:9,YMINOR:9,XMARGIN:[10,10],YMARGIN:[5,5],XLOG:1,YLOG:1}
def_esa_eran   = [10d0,25d3]            ;;  Default ESA energy range [eV]
def_sst_eran   = [30d0,50d1]*1d3        ;;  Default SST energy range [eV]
def_cut_aran   = 22.5d0                 ;;  Default angular range [deg] of acceptance for averaging
frac_cnts      = 0b                     ;;  logic to use to determine whether to allow fractional counts in unit conversion (THEMIS ESA only)
cut_mids       = [22.5d0,9d1,157.5d0]   ;;  Default mid angles [deg] about which to define a range over which to average
vec_cols       = [250,150, 50]
dumb_exline    = {NSTR:'',NVAL:0d0}
;;  Dummy error messages
noinpt_msg     = 'User must supply two velocity distribution functions as IDL structures...'
notstr_msg     = 'DAT_ESA and DAT_SST must be IDL structures...'
notvdf_msg     = 'DAT_ESA and DAT_SST must be velocity distribution functions as an IDL structures...'
diffsc_msg     = 'DAT_ESA and DAT_SST must come from the same spacecraft...'
badvdf_msg     = 'Input must be an IDL structure with similar format to Wind/3DP or THEMIS/ESA...'
not3dp_msg     = 'Input must be a velocity distribution IDL structure from Wind/3DP...'
notthm_msg     = 'Input must be a velocity distribution IDL structure from THEMIS/ESA...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
IF (N_PARAMS() LT 2) THEN BEGIN
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
test           = (SIZE(dat_esa,/TYPE) NE 8L OR N_ELEMENTS(dat_esa) LT 1) OR $
                 (SIZE(dat_sst,/TYPE) NE 8L OR N_ELEMENTS(dat_sst) LT 1)
IF (test[0]) THEN BEGIN
  MESSAGE,notstr_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;  Check to make sure distributions have the correct format
test_esa0      = test_wind_vs_themis_esa_struct(dat_esa[0],/NOM)
test_sst0      = test_wind_vs_themis_esa_struct(dat_sst[0],/NOM)
test           = ((test_esa0.(0) + test_esa0.(1)) NE 1) OR $
                 ((test_sst0.(0) + test_sst0.(1)) NE 1)
IF (test[0]) THEN BEGIN
  MESSAGE,notvdf_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;  Make sure the distributions come from the same spacecraft (i.e., no mixing!)
test           = (test_esa0.(0) EQ test_sst0.(0)) AND (test_esa0.(1) EQ test_sst0.(1))
IF (test[0] EQ 0) THEN BEGIN
  MESSAGE,diffsc_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;  Determine instrument (i.e., ESA or 3DP) and define electric charge
dat0           = dat_esa[0]
dat1           = dat_sst[0]
IF (test_esa0.(0)) THEN BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Wind
  ;;--------------------------------------------------------------------------------------
  mission      = 'Wind'
  strn0        = dat_3dp_str_names(dat0[0])
  strn1        = dat_3dp_str_names(dat1[0])
  IF (SIZE(strn0,/TYPE) NE 8 OR SIZE(strn1,/TYPE) NE 8) THEN BEGIN
    ;;  Neither Wind/3DP nor THEMIS/ESA VDF
    MESSAGE,not3dp_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN
  ENDIF
  instnmmode_esa = strn0.LC[0]         ;;  e.g., 'Eesa Low Burst'
  instnmmode_sst = strn1.LC[0]         ;;  e.g., 'SST Foil Burst'
ENDIF ELSE BEGIN
  IF (test_esa0.(1)) THEN BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  THEMIS
    ;;------------------------------------------------------------------------------------
    mission      = 'THEMIS'
    strn0        = dat_themis_esa_str_names(dat0[0])
    strn1        = dat_themis_esa_str_names(dat1[0])
    IF (SIZE(strn0,/TYPE) NE 8 OR SIZE(strn1,/TYPE) NE 8) THEN BEGIN
      ;;  Neither Wind/3DP nor THEMIS/ESA VDF
      MESSAGE,notthm_msg[0],/INFORMATIONAL,/CONTINUE
      RETURN
    ENDIF
    probe          = STRUPCASE(dat0[0].SPACECRAFT[0])  ;;  e.g., 'C'
    mission        = mission[0]+'-'+probe[0]
    temp           = strn0.LC[0]                  ;;  e.g., 'IESA 3D Burst Distribution'
    tposi          = STRPOS(temp[0],'Distribution') - 1L
    instnmmode_esa = STRMID(temp[0],0L,tposi[0])  ;;  e.g., 'IESA 3D Burst'
    temp           = strn1.LC[0]                  ;;  e.g., 'SST Ion Burst Distribution'
    tposi          = STRPOS(temp[0],'Distribution') - 1L
    instnmmode_sst = STRMID(temp[0],0L,tposi[0])  ;;  e.g., 'SST Ion Burst'
    frac_cnts      = 1b
  ENDIF ELSE BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Other mission?
    ;;------------------------------------------------------------------------------------
    ;;  Not handling any other missions yet  [Need to know the format of their distributions]
    MESSAGE,badvdf_msg[0],/INFORMATIONAL,/CONTINUE
    RETURN
  ENDELSE
ENDELSE
data_str_esa   = strn0.SN[0]     ;;  e.g., 'el' for Wind EESA Low or 'peeb' for THEMIS EESA
data_str_sst   = strn1.SN[0]     ;;  e.g., 'sf' for Wind SST Foil or 'pseb' for THEMIS SST Foil
;;  Define plot title prefixes
test           = (N_ELEMENTS(mission) NE 0)
ttl_prefs      = [instnmmode_esa[0],instnmmode_sst[0]]
IF (test[0]) THEN ttl_prefs = mission[0]+' '+ttl_prefs
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check LIM_ESA and LIM_SST
test           = (SIZE(lim_esa,/TYPE) EQ 8L)
IF (test[0]) THEN extract_tags,lime_str,lim_esa
extract_tags,lime_str,lim0       ;;  Add defaults to ESA structure
test           = (SIZE(lim_sst,/TYPE) EQ 8L)
IF (test[0]) THEN extract_tags,lims_str,lim_sst
extract_tags,lims_str,lim0       ;;  Add defaults to ESA structure
;;  Check ESA_ERAN and SST_ERAN
test           = (test_plot_axis_range(esa_eran,/NOMSSG) EQ 0L)
IF (test[0]) THEN eran_esa = def_esa_eran ELSE eran_esa = esa_eran
test           = (test_plot_axis_range(sst_eran,/NOMSSG) EQ 0L)
IF (test[0]) THEN eran_sst = def_sst_eran ELSE eran_sst = sst_eran
;;  Add XRANGE for each structure
str_element,lime_str,'XRANGE',eran_esa,/ADD_REPLACE
str_element,lims_str,'XRANGE',eran_sst,/ADD_REPLACE
;;  Check SC_FRAME
IF KEYWORD_SET(sc_frame) THEN scframe = 1b ELSE scframe = 0b
;;  Check CUT_RAN
test           = (is_a_number(cut_ran,/NOMSSG) EQ 0)
IF (test[0]) THEN cutran = def_cut_aran[0] ELSE cutran = cut_ran[0]
;;  Check P_ANGLE
IF KEYWORD_SET(p_angle) THEN pang = 1b ELSE pang = 0b
;;  Check SUNDIR
IF KEYWORD_SET(sundir) THEN sun_d = 1b ELSE sun_d = 0b
;;  Check VECTOR
test           = is_a_3_vector(vec,V_OUT=v_out,/NOMSSG)
IF (test[0]) THEN BEGIN
  vecdir = v_out
  fsuffx = '_vecdir'
ENDIF ELSE BEGIN
  ;;  VECTOR not set --> check if P_ANGLE or SUNDIR was set
  test   = pang[0] OR sun_d[0]
  IF (test[0]) THEN BEGIN
    ;;  Either P_ANGLE and/or SUNDIR was set --> define direction to use (i.e., force the other to FALSE)
    IF (pang[0]) THEN sun_d = 0b ELSE pang = 0b
    IF (pang[0]) THEN fsuffx = '_PAD' ELSE fsuffx = '_sundir'
    vecdir = 0b
  ENDIF ELSE BEGIN
    ;;  None of the directions were set --> default to P_ANGLE
    fsuffx = '_PAD'
    pang   = 1b
    sun_d  = 0b
    vecdir = 0b
  ENDELSE
ENDELSE
;;  Check UNITS
test           = (N_ELEMENTS(units) EQ 0) OR (SIZE(units,/TYPE) NE 7)
IF (test[0]) THEN gunits = 'flux' ELSE gunits = units[0]
;;  Make sure input was an allowed units name
new_units      = wind_3dp_units(gunits[0])
gunits         = new_units.G_UNIT_NAME      ;;  e.g., 'flux'
punits         = new_units.G_UNIT_P_NAME    ;;  e.g., ' (# cm!U-2!Ns!U-1!Nsr!U-1!NeV!U-1!N)'
;;  Check ESA_BINS and SST_BINS
bstr           = format_esa_bins_keyword(dat0,BINS=esa_bins)
test           = (SIZE(bstr,/TYPE) NE 8)
IF (test[0]) THEN esa_bins = REPLICATE(1b,dat0[0].NBINS)
bstr           = format_esa_bins_keyword(dat1,BINS=sst_bins)
test           = (SIZE(bstr,/TYPE) NE 8)
IF (test[0]) THEN sst_bins = REPLICATE(1b,dat1[0].NBINS)
;;  Check EX_SUFFX
test           = (N_ELEMENTS(ex_suffx) EQ 0) OR (SIZE(ex_suffx,/TYPE) NE 7)
IF (test[0]) THEN exsuffx = '' ELSE exsuffx = ex_suffx[0]
;;  Check LEG_SFFX
test           = (N_ELEMENTS(leg_sffx) EQ 0) OR (SIZE(leg_sffx,/TYPE) NE 7)
IF (test[0]) THEN legsuffx = '' ELSE legsuffx = leg_sffx[0]
;;  Check ONE_C keyword
;test           = KEYWORD_SET(one_c) OR (N_ELEMENTS(one_c) GT 1)
test           = KEYWORD_SET(one_c)
IF (test[0]) THEN log_1c = 1b ELSE log_1c = 0b
;;  Check RM_PHOTO_E keyword
test           = KEYWORD_SET(rm_photo_e)
IF (test[0]) THEN rmscpot = 1b ELSE rmscpot = 0b
;;  Check EX_LINE
test           = (N_ELEMENTS(ex_line) EQ 0) OR (SIZE(ex_line,/TYPE) NE 8)
IF (test[0]) THEN BEGIN
  extra_line = dumb_exline
ENDIF ELSE BEGIN
  nlab           = struct_value(ex_line,'NSTR',DEFAULT='',INDEX=indnstr)
  nval           = struct_value(ex_line,'NVAL',DEFAULT=0d0,INDEX=indnval)
  test           = (SIZE(nlab,/TYPE) NE 7) OR (is_a_number(nval,/NOMSSG) EQ 0)
  IF (test[0]) THEN extra_line = dumb_exline ELSE extra_line = {NSTR:nlab[0],NVAL:nval[0]}
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Transform (if desired)
;;----------------------------------------------------------------------------------------
tdate_sw       = conv_units(dat0[0],'df',FRACTIONAL_COUNTS=frac_cnts[0])
tdats_sw       = conv_units(dat1[0],'df')
IF (scframe[0]) THEN BEGIN
  ;;  leave alone
  ttle_ext = 'SCF'      ;;  string to add to plot title indicating reference frame shown
ENDIF ELSE BEGIN
  ;;  transform into bulk flow frame
  ttle_ext = 'SWF'
  transform_vframe_3d,tdate_sw,/EASY_TRAN
  transform_vframe_3d,tdats_sw,/EASY_TRAN
  ;;  Shut off RM_PHOTO_E keyword in case set (Trans. routine already removes this)
  IF (rmscpot[0]) THEN rmscpot = 0b
ENDELSE
;;  Define file and title suffix associated with removal of photo electrons
IF (rmscpot[0] OR scframe[0] EQ 0) THEN BEGIN
  rmsc_suffx  = 'RM-SCPot'       ;;  Removed photo electrons
ENDIF ELSE BEGIN
  rmsc_suffx  = 'KP-SCPot'       ;;  Kept photo electrons
ENDELSE
;;  Convert into desired units
tdate_sw       = conv_units(tdate_sw[0],gunits[0],FRACTIONAL_COUNTS=frac_cnts[0])
tdats_sw       = conv_units(tdats_sw[0],gunits[0])
;;----------------------------------------------------------------------------------------
;;  Open windows for plotting
;;----------------------------------------------------------------------------------------
DEVICE,WINDOW_STATE=w_state
wttles         = mission[0]+' '+['ESA','SST','ESA+SST']
w_struc        = {RETAIN:2,XSIZE:800,YSIZE:800}
FOR ww=0L, 2L DO BEGIN
  wnum   = ww[0] + 1L
  IF (w_state[wnum[0]]) THEN CONTINUE   ;;  assume already open and in use by this routine (from previous call)
  wstruc = w_struc
  str_element,wstruc,'TITLE',wttles[ww],/ADD_REPLACE
  WINDOW,wnum[0],_EXTRA=wstruc
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Plot initial spectra
;;----------------------------------------------------------------------------------------
IF (log_1c[0]) THEN BEGIN
  ydat1c_esa = 1b
  ydat1c_sst = 1b
ENDIF ELSE BEGIN
  ydat1c_esa = 0b
  ydat1c_sst = 0b
ENDELSE

WSET,1
WSHOW,1
pang_eesa      = pang
lbw_spec3d,tdate_sw,LIMITS=lime_str,SUNDIR=sun_d,VECTOR=vecdir,PITCHANGLE=pang_eesa,   $
                    /LABEL,BINS=esa_bins,XDAT=xdat_eesa,YDAT=ydat_eesa,UNITS=gunits[0],$
                    ONE_C=ydat1c_esa,RM_PHOTO_E=rmscpot[0]

WSET,2
WSHOW,2
pang_sste      = pang
lbw_spec3d,tdats_sw,LIMITS=lims_str,SUNDIR=sun_d,VECTOR=vecdir,PITCHANGLE=pang_sste,   $
                    /LABEL,BINS=sst_bins,XDAT=xdat_sste,YDAT=ydat_sste,UNITS=gunits[0],$
                    ONE_C=ydat1c_sst,RM_PHOTO_E=rmscpot[0]
;;----------------------------------------------------------------------------------------
;;  Check to see if plot was successful
;;----------------------------------------------------------------------------------------
test           = (is_a_number(xdat_eesa,/NOMSSG) EQ 0) OR (is_a_number(ydat_eesa,/NOMSSG) EQ 0) OR $
                 (is_a_number(xdat_sste,/NOMSSG) EQ 0) OR (is_a_number(ydat_sste,/NOMSSG) EQ 0)
IF (test[0]) THEN RETURN     ;;  Nothing plotted --> leave
;;----------------------------------------------------------------------------------------
;;  Define range of pitch-angles to use for averaging
;;----------------------------------------------------------------------------------------
cut_lows       = cut_mids - cutran[0]
cut_high       = cut_mids + cutran[0]
;;  Make sure values are not < 0 or > 180
cut_lows       = cut_lows > 0d0
cut_high       = cut_high < 18d1
;;  Define elements satisfying pitch-angle ranges
test_para_esa  = (pang_eesa LE cut_high[0]) AND (pang_eesa GE cut_lows[0])
test_perp_esa  = (pang_eesa LE cut_high[1]) AND (pang_eesa GE cut_lows[1])
test_anti_esa  = (pang_eesa LE cut_high[2]) AND (pang_eesa GE cut_lows[2])
test_para_sst  = (pang_sste LE cut_high[0]) AND (pang_sste GE cut_lows[0])
test_perp_sst  = (pang_sste LE cut_high[1]) AND (pang_sste GE cut_lows[1])
test_anti_sst  = (pang_sste LE cut_high[2]) AND (pang_sste GE cut_lows[2])

good_para_esa  = WHERE(test_para_esa,gd_para_esa)
good_perp_esa  = WHERE(test_perp_esa,gd_perp_esa)
good_anti_esa  = WHERE(test_anti_esa,gd_anti_esa)
good_para_sst  = WHERE(test_para_sst,gd_para_sst)
good_perp_sst  = WHERE(test_perp_sst,gd_perp_sst)
good_anti_sst  = WHERE(test_anti_sst,gd_anti_sst)
;;----------------------------------------------------------------------------------------
;;  Define range of energies to use for averaging
;;----------------------------------------------------------------------------------------
eners_str      = dat_3dp_energy_bins(tdate_sw)
eners_esa      = eners_str.ALL_ENERGIES
;;  Check for un-used SST energy bins (problem in THEMIS, not Wind)
bad_ener       = WHERE(tdats_sw[0].DENERGY LE 0,bd_ener,COMPLEMENT=good_ener,NCOMPLEMENT=gd_ener)
IF (bd_ener GT 0) THEN tdats_sw[0].ENERGY[bad_ener] = f
eners_str      = dat_3dp_energy_bins(tdats_sw)
eners_sst      = eners_str.ALL_ENERGIES

test_ener_esa  = ((eners_esa LE eran_esa[0]) OR (eners_esa GE eran_esa[1])) OR (FINITE(eners_esa) EQ 0)
test_ener_sst  = ((eners_sst LE eran_sst[0]) OR (eners_sst GE eran_sst[1])) OR (FINITE(eners_sst) EQ 0)
bad_ener_esa   = WHERE(test_ener_esa,bd_ener_esa,COMPLEMENT=good_ener_esa,NCOMPLEMENT=gd_ener_esa)
bad_ener_sst   = WHERE(test_ener_sst,bd_ener_sst,COMPLEMENT=good_ener_sst,NCOMPLEMENT=gd_ener_sst)
;;----------------------------------------------------------------------------------------
;;  Define data over which to average
;;----------------------------------------------------------------------------------------
n_ee           = N_ELEMENTS(ydat_eesa[*,0])
n_ae           = N_ELEMENTS(ydat_eesa[0,*])
n_es           = N_ELEMENTS(ydat_sste[*,0])
n_as           = N_ELEMENTS(ydat_sste[0,*])

dumb1dpe       = DINDGEN(n_ae[0])
dumb1dee       = FINDGEN(n_ee[0])
dumb2dde       = FINDGEN(n_ee[0],n_ae[0])
dumb1dps       = DINDGEN(n_as[0])
dumb1des       = FINDGEN(n_es[0])
dumb2dds       = FINDGEN(n_es[0],n_as[0])
;;----------------------------------------
;;  Keep only "good" angular ranges
;;----------------------------------------
;;  ESA
IF (gd_para_esa[0] GT 0) THEN data_para_esa = REFORM(ydat_eesa[*,good_para_esa],n_ee[0],gd_para_esa[0]) ELSE data_para_esa = dumb2dde
IF (gd_perp_esa[0] GT 0) THEN data_perp_esa = REFORM(ydat_eesa[*,good_perp_esa],n_ee[0],gd_perp_esa[0]) ELSE data_perp_esa = dumb2dde
IF (gd_anti_esa[0] GT 0) THEN data_anti_esa = REFORM(ydat_eesa[*,good_anti_esa],n_ee[0],gd_anti_esa[0]) ELSE data_anti_esa = dumb2dde
IF (gd_para_esa[0] GT 0) THEN ener_para_esa = REFORM(xdat_eesa[*,good_para_esa],n_ee[0],gd_para_esa[0]) ELSE ener_para_esa = dumb2dde
IF (gd_perp_esa[0] GT 0) THEN ener_perp_esa = REFORM(xdat_eesa[*,good_perp_esa],n_ee[0],gd_perp_esa[0]) ELSE ener_perp_esa = dumb2dde
IF (gd_anti_esa[0] GT 0) THEN ener_anti_esa = REFORM(xdat_eesa[*,good_anti_esa],n_ee[0],gd_anti_esa[0]) ELSE ener_anti_esa = dumb2dde
IF (gd_para_esa[0] GT 0) THEN pang_para_esa =   pang_eesa[good_para_esa] ELSE pang_para_esa = dumb1dpe
IF (gd_perp_esa[0] GT 0) THEN pang_perp_esa =   pang_eesa[good_perp_esa] ELSE pang_perp_esa = dumb1dpe
IF (gd_anti_esa[0] GT 0) THEN pang_anti_esa =   pang_eesa[good_anti_esa] ELSE pang_anti_esa = dumb1dpe
;;  SST
IF (gd_para_sst[0] GT 0) THEN data_para_sst = REFORM(ydat_sste[*,good_para_sst],n_es[0],gd_para_sst[0]) ELSE data_para_sst = dumb2dds
IF (gd_perp_sst[0] GT 0) THEN data_perp_sst = REFORM(ydat_sste[*,good_perp_sst],n_es[0],gd_perp_sst[0]) ELSE data_perp_sst = dumb2dds
IF (gd_anti_sst[0] GT 0) THEN data_anti_sst = REFORM(ydat_sste[*,good_anti_sst],n_es[0],gd_anti_sst[0]) ELSE data_anti_sst = dumb2dds
IF (gd_para_sst[0] GT 0) THEN ener_para_sst = REFORM(xdat_sste[*,good_para_sst],n_es[0],gd_para_sst[0]) ELSE ener_para_sst = dumb2dds
IF (gd_perp_sst[0] GT 0) THEN ener_perp_sst = REFORM(xdat_sste[*,good_perp_sst],n_es[0],gd_perp_sst[0]) ELSE ener_perp_sst = dumb2dds
IF (gd_anti_sst[0] GT 0) THEN ener_anti_sst = REFORM(xdat_sste[*,good_anti_sst],n_es[0],gd_anti_sst[0]) ELSE ener_anti_sst = dumb2dds
IF (gd_para_sst[0] GT 0) THEN pang_para_sst =   pang_sste[good_para_sst] ELSE pang_para_sst = dumb1dps
IF (gd_perp_sst[0] GT 0) THEN pang_perp_sst =   pang_sste[good_perp_sst] ELSE pang_perp_sst = dumb1dps
IF (gd_anti_sst[0] GT 0) THEN pang_anti_sst =   pang_sste[good_anti_sst] ELSE pang_anti_sst = dumb1dps
;;----------------------------------------
;;  Keep only "good" energy ranges
;;----------------------------------------
;;  ESA
IF (gd_ener_esa[0] GT 0 AND gd_para_esa[0] GT 0) THEN data_para_esa = REFORM(data_para_esa[good_ener_esa,*],gd_ener_esa[0],gd_para_esa[0]) ELSE data_para_esa *= d
IF (gd_ener_esa[0] GT 0 AND gd_perp_esa[0] GT 0) THEN data_perp_esa = REFORM(data_perp_esa[good_ener_esa,*],gd_ener_esa[0],gd_perp_esa[0]) ELSE data_perp_esa *= d
IF (gd_ener_esa[0] GT 0 AND gd_anti_esa[0] GT 0) THEN data_anti_esa = REFORM(data_anti_esa[good_ener_esa,*],gd_ener_esa[0],gd_anti_esa[0]) ELSE data_anti_esa *= d
IF (gd_ener_esa[0] GT 0 AND gd_para_esa[0] GT 0) THEN ener_para_esa = REFORM(ener_para_esa[good_ener_esa,*],gd_ener_esa[0],gd_para_esa[0]) ELSE ener_para_esa *= d
IF (gd_ener_esa[0] GT 0 AND gd_perp_esa[0] GT 0) THEN ener_perp_esa = REFORM(ener_perp_esa[good_ener_esa,*],gd_ener_esa[0],gd_perp_esa[0]) ELSE ener_perp_esa *= d
IF (gd_ener_esa[0] GT 0 AND gd_anti_esa[0] GT 0) THEN ener_anti_esa = REFORM(ener_anti_esa[good_ener_esa,*],gd_ener_esa[0],gd_anti_esa[0]) ELSE ener_anti_esa *= d
;;  SST
IF (gd_ener_sst[0] GT 0 AND gd_para_sst[0] GT 0) THEN data_para_sst = REFORM(data_para_sst[good_ener_sst,*],gd_ener_sst[0],gd_para_sst[0]) ELSE data_para_sst *= d
IF (gd_ener_sst[0] GT 0 AND gd_perp_sst[0] GT 0) THEN data_perp_sst = REFORM(data_perp_sst[good_ener_sst,*],gd_ener_sst[0],gd_perp_sst[0]) ELSE data_perp_sst *= d
IF (gd_ener_sst[0] GT 0 AND gd_anti_sst[0] GT 0) THEN data_anti_sst = REFORM(data_anti_sst[good_ener_sst,*],gd_ener_sst[0],gd_anti_sst[0]) ELSE data_anti_sst *= d
IF (gd_ener_sst[0] GT 0 AND gd_para_sst[0] GT 0) THEN ener_para_sst = REFORM(ener_para_sst[good_ener_sst,*],gd_ener_sst[0],gd_para_sst[0]) ELSE ener_para_sst *= d
IF (gd_ener_sst[0] GT 0 AND gd_perp_sst[0] GT 0) THEN ener_perp_sst = REFORM(ener_perp_sst[good_ener_sst,*],gd_ener_sst[0],gd_perp_sst[0]) ELSE ener_perp_sst *= d
IF (gd_ener_sst[0] GT 0 AND gd_anti_sst[0] GT 0) THEN ener_anti_sst = REFORM(ener_anti_sst[good_ener_sst,*],gd_ener_sst[0],gd_anti_sst[0]) ELSE ener_anti_sst *= d
;;----------------------------------------------------------------------------------------
;;  Average data over angular ranges
;;----------------------------------------------------------------------------------------
;;  Unfortunately, FINITE.PRO reforms the array size so we need to reform again just in case
szde_para      = SIZE(data_para_esa,/DIMENSIONS)
szde_perp      = SIZE(data_perp_esa,/DIMENSIONS)
szde_anti      = SIZE(data_anti_esa,/DIMENSIONS)
;;  ESA
Avgf_para_esa  = TOTAL(data_para_esa,2L,/NAN)/TOTAL(REFORM(FINITE(data_para_esa),szde_para[0],szde_para[1]),2L,/NAN)
AvgE_para_esa  = TOTAL(ener_para_esa,2L,/NAN)/TOTAL(REFORM(FINITE(ener_para_esa),szde_para[0],szde_para[1]),2L,/NAN)
Avgf_perp_esa  = TOTAL(data_perp_esa,2L,/NAN)/TOTAL(REFORM(FINITE(data_perp_esa),szde_perp[0],szde_perp[1]),2L,/NAN)
AvgE_perp_esa  = TOTAL(ener_perp_esa,2L,/NAN)/TOTAL(REFORM(FINITE(ener_perp_esa),szde_perp[0],szde_perp[1]),2L,/NAN)
Avgf_anti_esa  = TOTAL(data_anti_esa,2L,/NAN)/TOTAL(REFORM(FINITE(data_anti_esa),szde_anti[0],szde_anti[1]),2L,/NAN)
AvgE_anti_esa  = TOTAL(ener_anti_esa,2L,/NAN)/TOTAL(REFORM(FINITE(ener_anti_esa),szde_anti[0],szde_anti[1]),2L,/NAN)
;;  SST
szds_para      = SIZE(data_para_sst,/DIMENSIONS)
szds_perp      = SIZE(data_perp_sst,/DIMENSIONS)
szds_anti      = SIZE(data_anti_sst,/DIMENSIONS)
Avgf_para_sst  = TOTAL(data_para_sst,2L,/NAN)/TOTAL(REFORM(FINITE(data_para_sst),szds_para[0],szds_para[1]),2L,/NAN)
AvgE_para_sst  = TOTAL(ener_para_sst,2L,/NAN)/TOTAL(REFORM(FINITE(ener_para_sst),szds_para[0],szds_para[1]),2L,/NAN)
Avgf_perp_sst  = TOTAL(data_perp_sst,2L,/NAN)/TOTAL(REFORM(FINITE(data_perp_sst),szds_perp[0],szds_perp[1]),2L,/NAN)
AvgE_perp_sst  = TOTAL(ener_perp_sst,2L,/NAN)/TOTAL(REFORM(FINITE(ener_perp_sst),szds_perp[0],szds_perp[1]),2L,/NAN)
Avgf_anti_sst  = TOTAL(data_anti_sst,2L,/NAN)/TOTAL(REFORM(FINITE(data_anti_sst),szds_anti[0],szds_anti[1]),2L,/NAN)
AvgE_anti_sst  = TOTAL(ener_anti_sst,2L,/NAN)/TOTAL(REFORM(FINITE(ener_anti_sst),szds_anti[0],szds_anti[1]),2L,/NAN)
;;  Define energy range limits
all_ener_esa   = [AvgE_para_esa,AvgE_perp_esa,AvgE_anti_esa]
all_ener_sst   = [AvgE_para_sst,AvgE_perp_sst,AvgE_anti_sst]
all_eran_esa   = [MIN(ABS(all_ener_esa),/NAN),MAX(ABS(all_ener_esa),/NAN)]
all_eran_sst   = [MIN(ABS(all_ener_sst),/NAN),MAX(ABS(all_ener_sst),/NAN)]
;;  Check ONE_C
IF (log_1c[0]) THEN BEGIN
  ;;----------------------------------------
  ;;  Keep only "good" angular ranges
  ;;----------------------------------------
  ;;  ESA
  IF (gd_para_esa[0] GT 0) THEN dt1c_para_esa = REFORM(ydat1c_esa[*,good_para_esa],n_ee[0],gd_para_esa[0]) ELSE dt1c_para_esa = dumb2dde
  IF (gd_perp_esa[0] GT 0) THEN dt1c_perp_esa = REFORM(ydat1c_esa[*,good_perp_esa],n_ee[0],gd_perp_esa[0]) ELSE dt1c_perp_esa = dumb2dde
  IF (gd_anti_esa[0] GT 0) THEN dt1c_anti_esa = REFORM(ydat1c_esa[*,good_anti_esa],n_ee[0],gd_anti_esa[0]) ELSE dt1c_anti_esa = dumb2dde
  ;;  SST
  IF (gd_para_sst[0] GT 0) THEN dt1c_para_sst = REFORM(ydat1c_sst[*,good_para_sst],n_es[0],gd_para_sst[0]) ELSE dt1c_para_sst = dumb2dds
  IF (gd_perp_sst[0] GT 0) THEN dt1c_perp_sst = REFORM(ydat1c_sst[*,good_perp_sst],n_es[0],gd_perp_sst[0]) ELSE dt1c_perp_sst = dumb2dds
  IF (gd_anti_sst[0] GT 0) THEN dt1c_anti_sst = REFORM(ydat1c_sst[*,good_anti_sst],n_es[0],gd_anti_sst[0]) ELSE dt1c_anti_sst = dumb2dds
  ;;----------------------------------------
  ;;  Keep only "good" energy ranges
  ;;----------------------------------------
  ;;  ESA
  IF (gd_ener_esa[0] GT 0 AND gd_para_esa[0] GT 0) THEN dt1c_para_esa = REFORM(dt1c_para_esa[good_ener_esa,*],gd_ener_esa[0],gd_para_esa[0]) ELSE dt1c_para_esa *= d
  IF (gd_ener_esa[0] GT 0 AND gd_perp_esa[0] GT 0) THEN dt1c_perp_esa = REFORM(dt1c_perp_esa[good_ener_esa,*],gd_ener_esa[0],gd_perp_esa[0]) ELSE dt1c_perp_esa *= d
  IF (gd_ener_esa[0] GT 0 AND gd_anti_esa[0] GT 0) THEN dt1c_anti_esa = REFORM(dt1c_anti_esa[good_ener_esa,*],gd_ener_esa[0],gd_anti_esa[0]) ELSE dt1c_anti_esa *= d
  ;;  SST
  IF (gd_ener_sst[0] GT 0 AND gd_para_sst[0] GT 0) THEN dt1c_para_sst = REFORM(dt1c_para_sst[good_ener_sst,*],gd_ener_sst[0],gd_para_sst[0]) ELSE dt1c_para_sst *= d
  IF (gd_ener_sst[0] GT 0 AND gd_perp_sst[0] GT 0) THEN dt1c_perp_sst = REFORM(dt1c_perp_sst[good_ener_sst,*],gd_ener_sst[0],gd_perp_sst[0]) ELSE dt1c_perp_sst *= d
  IF (gd_ener_sst[0] GT 0 AND gd_anti_sst[0] GT 0) THEN dt1c_anti_sst = REFORM(dt1c_anti_sst[good_ener_sst,*],gd_ener_sst[0],gd_anti_sst[0]) ELSE dt1c_anti_sst *= d
  ;;----------------------------------------
  ;;  Average data over angular ranges
  ;;----------------------------------------
  ;;  ESA
  ;;  Unfortunately, FINITE.PRO reforms the array size so we need to reform again just in case
  szde_para      = SIZE(dt1c_para_esa,/DIMENSIONS)
  szde_perp      = SIZE(dt1c_perp_esa,/DIMENSIONS)
  szde_anti      = SIZE(dt1c_anti_esa,/DIMENSIONS)
  Av1c_para_esa  = TOTAL(dt1c_para_esa,2L,/NAN)/TOTAL(REFORM(FINITE(dt1c_para_esa),szde_para[0],szde_para[1]),2L,/NAN)
  Av1c_perp_esa  = TOTAL(dt1c_perp_esa,2L,/NAN)/TOTAL(REFORM(FINITE(dt1c_perp_esa),szde_perp[0],szde_perp[1]),2L,/NAN)
  Av1c_anti_esa  = TOTAL(dt1c_anti_esa,2L,/NAN)/TOTAL(REFORM(FINITE(dt1c_anti_esa),szde_anti[0],szde_anti[1]),2L,/NAN)
  ;;  SST
  szds_para      = SIZE(dt1c_para_sst,/DIMENSIONS)
  szds_perp      = SIZE(dt1c_perp_sst,/DIMENSIONS)
  szds_anti      = SIZE(dt1c_anti_sst,/DIMENSIONS)
  Av1c_para_sst  = TOTAL(dt1c_para_sst,2L,/NAN)/TOTAL(REFORM(FINITE(dt1c_para_sst),szds_para[0],szds_para[1]),2L,/NAN)
  Av1c_perp_sst  = TOTAL(dt1c_perp_sst,2L,/NAN)/TOTAL(REFORM(FINITE(dt1c_perp_sst),szds_perp[0],szds_perp[1]),2L,/NAN)
  Av1c_anti_sst  = TOTAL(dt1c_anti_sst,2L,/NAN)/TOTAL(REFORM(FINITE(dt1c_anti_sst),szds_anti[0],szds_anti[1]),2L,/NAN)
ENDIF
;;----------------------------------------------------------------------------------------
;;  Set up plot stuff...
;;----------------------------------------------------------------------------------------
pstr           = lim0
;;  Add XRANGE
xran_out       = eran_esa
xran_out[0]    = xran_out[0] < eran_sst[0]
xran_out[1]    = xran_out[1] > eran_sst[1]
str_element,pstr,'XRANGE',xran_out,/ADD_REPLACE
;;  Get XRANGE and YRANGE, if present
str_element,lime_str,'YRANGE',yran_esa
str_element,lims_str,'YRANGE',yran_sst
test           = (test_plot_axis_range(yran_esa,/NOMSSG) EQ 0L) OR $
                 (test_plot_axis_range(yran_sst,/NOMSSG) EQ 0L)
IF (test[0]) THEN BEGIN
  ;;  One or both are bad --> define new
  data0       = [Avgf_para_esa,Avgf_perp_esa,Avgf_anti_esa]
  data1       = [Avgf_para_sst,Avgf_perp_sst,Avgf_anti_sst]
  data0       = REFORM(data0,N_ELEMENTS(data0))
  data1       = REFORM(data1,N_ELEMENTS(data1))
  data0       = data0[SORT(data0)]
  data1       = data1[SORT(data1)]
  yran0       = calc_log_scale_yrange(data0)
  yran1       = calc_log_scale_yrange(data1)
  yran_out    = yran0
  yran_out[0] = yran_out[0] < yran1[0]
  yran_out[1] = yran_out[1] > yran1[1]
ENDIF ELSE BEGIN
  ;;  Both are set --> use
  yran_out    = yran_esa
  yran_out[0] = yran_out[0] < yran_sst[0]
  yran_out[1] = yran_out[1] > yran_sst[1]
ENDELSE
;;  Add YRANGE to plot limits structure
str_element,pstr,'YRANGE',yran_out,/ADD_REPLACE
;;  Get tick marks
xtick          = get_power_of_ten_ticks(xran_out)
ytick          = get_power_of_ten_ticks(yran_out)
;;  Add [X,Y]TICKNAME, [X,Y]TICKV, and [X,Y]TICKS to plot limits structure
str_element,pstr,'YTICKNAME',ytick.YTICKNAME,/ADD_REPLACE
str_element,pstr,   'YTICKV',   ytick.YTICKV,/ADD_REPLACE
str_element,pstr,   'YTICKS',   ytick.YTICKS,/ADD_REPLACE
str_element,pstr,'XTICKNAME',xtick.XTICKNAME,/ADD_REPLACE
str_element,pstr,   'XTICKV',   xtick.XTICKV,/ADD_REPLACE
str_element,pstr,   'XTICKS',   xtick.XTICKS,/ADD_REPLACE
;;  Define titles and add to structure
title_esa      = ttl_prefs[0]+': '+trange_str(tdate_sw[0].TIME,tdate_sw[0].END_TIME,/MSEC)
title_sst      = ttl_prefs[1]+': '+trange_str(tdats_sw[0].TIME,tdats_sw[0].END_TIME,/MSEC)
p_title        = title_esa[0]+'!C'+title_sst[0]
;ytitle         = gunits[0]+' ['+ttle_ext[0]+']'+punits[0]
ytitle         = gunits[0]+' ['+ttle_ext[0]+', '+rmsc_suffx[0]+']'+punits[0]
xtitle         = 'Energy [eV]'
str_element,pstr,'XTITLE', xtitle[0],/ADD_REPLACE
str_element,pstr,'YTITLE', ytitle[0],/ADD_REPLACE
str_element,pstr, 'TITLE',p_title[0],/ADD_REPLACE
;;  Define popen structure
popen_str      = {PORT:1,UNITS:'inches',XSIZE:8.5,YSIZE:8.5,ASPECT:1}
;;  Define file save name
;fpref          = mission[0]+'_'+gunits[0]+'_'+data_str_esa[0]+'-'
fpref          = mission[0]+'_'+gunits[0]+'_'+data_str_esa[0]+'-'+ttle_ext[0]+'_'+rmsc_suffx[0]+'_'
fend           = 'para-red_perp-green_anti-blue_wrt'+fsuffx[0]    ;;  e.g., 'para-red_perp-green_anti-blue_wrt_PAD'
fnm_esa        = file_name_times(tdate_sw[0].TIME,PREC=3)
fnm_sst        = file_name_times(tdats_sw[0].TIME,PREC=3)
ft_esa         = fnm_esa[0].F_TIME[0]             ;;  e.g., '1998-08-09_0801x09.494'
ft_sst         = STRMID(fnm_sst[0].F_TIME[0],11)  ;;  e.g., '0801x09.494'
fname          = fpref[0]+ft_esa[0]+'_'+data_str_sst[0]+'-'+ft_sst[0]+'_'+fend[0]+'_'+exsuffx[0]
;;----------------------------------------------------------------------------------------
;;  Define power-law lines
;;----------------------------------------------------------------------------------------
fo_facs        = [1d0,1d1,1d1]
IF (gunits[0] EQ 'df') THEN fo_facs = [1d-2,1d-1,1d0]
f_at_xo        = yran_out[1]
a_o_2          = f_at_xo[0]*(xran_out[0])^2*fo_facs[0]
a_o_3          = f_at_xo[0]*(xran_out[0])^3*fo_facs[1]
a_o_4          = f_at_xo[0]*(xran_out[0])^4*fo_facs[2]

fplaw_2        = a_o_2[0]*xran_out^(-2d0)        ;;  f(E) ~ E^(-2)
fplaw_3        = a_o_3[0]*xran_out^(-3d0)        ;;  f(E) ~ E^(-3)
fplaw_4        = a_o_4[0]*xran_out^(-4d0)        ;;  f(E) ~ E^(-4)
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Plot combined spectra
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
legends        = ['Para.','Perp.','Anti.']+' Avg.: '+STRMID(fsuffx[0],1)+' '+legsuffx[0]
leg_fpl        = ['Dashed:  f(E) ~ E^(-2)','Dash-Dot:  f(E) ~ E^(-3)','Dash-Dot-Dot:  f(E) ~ E^(-4)']
plw_cols       = [ 30, 125, 200]
xyfacs         = [55d-2,105d-2,35d-2]
xposi          = [0.12,0.15]
yposi          = [0.34,0.31,0.28,0.24,0.21,0.18]
thck           = 2.0
psym           = -6                     ;;  square symbol and connect points with solid lines
symz           = 2.0
lsty           = [1L,2L,3L,4L]          ;;  LINESTYLE values
ecol           = [200L,100L, 30L]       ;;  COLOR values
;;  Define some parameters for XYOUTS
xxloc          = [xyfacs[0]*all_eran_esa[1],xyfacs[1]*all_eran_sst[0],xyfacs[1]*extra_line.NVAL[0]]
yyloc          = [xyfacs[2]*yran_out[1],xyfacs[2]*yran_out[1],xyfacs[2]*yran_out[1]]
vllab          = ['ESA','SST',extra_line.NSTR[0]]
align          = 0
WSET,3
WSHOW,3
;;----------------------------------------------------------------------------------------
;;  Initialize Plot
;;----------------------------------------------------------------------------------------
PLOT,AvgE_para_esa,Avgf_para_esa,/NODATA,_EXTRA=pstr
  ;;--------------------------------------------------------------------------------------
  ;;  Plot EESA data
  ;;--------------------------------------------------------------------------------------
  OPLOT,AvgE_para_esa,Avgf_para_esa,COLOR=vec_cols[0],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
  OPLOT,AvgE_perp_esa,Avgf_perp_esa,COLOR=vec_cols[1],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
  OPLOT,AvgE_anti_esa,Avgf_anti_esa,COLOR=vec_cols[2],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
  ;;--------------------------------------------------------------------------------------
  ;;  Plot SSTe data
  ;;--------------------------------------------------------------------------------------
  OPLOT,AvgE_para_sst,Avgf_para_sst,COLOR=vec_cols[0],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
  OPLOT,AvgE_perp_sst,Avgf_perp_sst,COLOR=vec_cols[1],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
  OPLOT,AvgE_anti_sst,Avgf_anti_sst,COLOR=vec_cols[2],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
  ;;--------------------------------------------------------------------------------------
  ;;  Plot energy range limits
  ;;--------------------------------------------------------------------------------------
  OPLOT,[all_eran_esa[0],all_eran_esa[0]],yran_out,COLOR=ecol[0],LINESTYLE=lsty[1]
  OPLOT,[all_eran_esa[1],all_eran_esa[1]],yran_out,COLOR=ecol[0],LINESTYLE=lsty[1]
  OPLOT,[all_eran_sst[0],all_eran_sst[0]],yran_out,COLOR=ecol[1],LINESTYLE=lsty[2]
  OPLOT,[all_eran_sst[1],all_eran_sst[1]],yran_out,COLOR=ecol[1],LINESTYLE=lsty[2]
  ;;--------------------------------------------------------------------------------------
  ;;  Output power-laws
  ;;--------------------------------------------------------------------------------------
  OPLOT,xran_out,fplaw_2,LINESTYLE=lsty[1],THICK=thck[0],COLOR=plw_cols[0]
  OPLOT,xran_out,fplaw_3,LINESTYLE=lsty[2],THICK=thck[0],COLOR=plw_cols[1]
  OPLOT,xran_out,fplaw_4,LINESTYLE=lsty[3],THICK=thck[0],COLOR=plw_cols[2]
  ;;--------------------------------------------------------------------------------------
  ;;  Output EX_LINE
  ;;--------------------------------------------------------------------------------------
  OPLOT,[extra_line.NVAL[0],extra_line.NVAL[0]],yran_out,COLOR=ecol[2],LINESTYLE=lsty[1],THICK=thck[0]
  ;;--------------------------------------------------------------------------------------
  ;;  Output one-count levels (if desired by user)
  ;;--------------------------------------------------------------------------------------
  IF (log_1c[0]) THEN BEGIN
    ;;  ESA
    OPLOT,AvgE_para_esa,Av1c_para_esa,COLOR=vec_cols[0],LINESTYLE=lsty[0]
    OPLOT,AvgE_para_esa,Av1c_perp_esa,COLOR=vec_cols[1],LINESTYLE=lsty[0]
    OPLOT,AvgE_para_esa,Av1c_anti_esa,COLOR=vec_cols[2],LINESTYLE=lsty[0]
    ;;  SST
    OPLOT,AvgE_para_sst,Av1c_para_sst,COLOR=vec_cols[0],LINESTYLE=lsty[0]
    OPLOT,AvgE_perp_sst,Av1c_perp_sst,COLOR=vec_cols[1],LINESTYLE=lsty[0]
    OPLOT,AvgE_anti_sst,Av1c_anti_sst,COLOR=vec_cols[2],LINESTYLE=lsty[0]
  ENDIF
  ;;--------------------------------------------------------------------------------------
  ;;  Output legend
  ;;--------------------------------------------------------------------------------------
  XYOUTS,xxloc[0],yyloc[0],vllab[0],COLOR=ecol[0],/DATA,ALIGNMENT=align[0]             ;;  ESA energy range labels
  XYOUTS,xxloc[1],yyloc[1],vllab[1],COLOR=ecol[1],/DATA,ALIGNMENT=align[0]             ;;  SST energy range labels
  XYOUTS,xxloc[2],yyloc[2],vllab[2],COLOR=ecol[2],/DATA,ALIGNMENT=align[0]             ;;  EX_LINE label
  XYOUTS,xposi[0],yposi[0],legends[0],COLOR=vec_cols[0],/NORMAL,ALIGNMENT=align[0]     ;;  Para label
  XYOUTS,xposi[0],yposi[1],legends[1],COLOR=vec_cols[1],/NORMAL,ALIGNMENT=align[0]     ;;  Perp label
  XYOUTS,xposi[0],yposi[2],legends[2],COLOR=vec_cols[2],/NORMAL,ALIGNMENT=align[0]     ;;  Anti label
  XYOUTS,xposi[0],yposi[3],leg_fpl[0],COLOR=plw_cols[0],/NORMAL,ALIGNMENT=align[0]     ;;  f(E) ~ E^(-2) label
  XYOUTS,xposi[0],yposi[4],leg_fpl[1],COLOR=plw_cols[1],/NORMAL,ALIGNMENT=align[0]     ;;  f(E) ~ E^(-3) label
  XYOUTS,xposi[0],yposi[5],leg_fpl[2],COLOR=plw_cols[2],/NORMAL,ALIGNMENT=align[0]     ;;  f(E) ~ E^(-4) label

;;----------------------------------------------------------------------------------------
;;  Save plot of combined spectra
;;----------------------------------------------------------------------------------------
thck           = 3.0
symz           = 1.0
popen,fname[0],_EXTRA=popen_str
  ;;--------------------------------------------------------------------------------------
  ;;  Initialize Plot
  ;;--------------------------------------------------------------------------------------
  PLOT,AvgE_para_esa,Avgf_para_esa,/NODATA,_EXTRA=pstr
    ;;------------------------------------------------------------------------------------
    ;;  Plot EESA data
    ;;------------------------------------------------------------------------------------
    OPLOT,AvgE_para_esa,Avgf_para_esa,COLOR=vec_cols[0],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
    OPLOT,AvgE_perp_esa,Avgf_perp_esa,COLOR=vec_cols[1],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
    OPLOT,AvgE_anti_esa,Avgf_anti_esa,COLOR=vec_cols[2],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
    ;;------------------------------------------------------------------------------------
    ;;  Plot SSTe data
    ;;------------------------------------------------------------------------------------
    OPLOT,AvgE_para_sst,Avgf_para_sst,COLOR=vec_cols[0],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
    OPLOT,AvgE_perp_sst,Avgf_perp_sst,COLOR=vec_cols[1],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
    OPLOT,AvgE_anti_sst,Avgf_anti_sst,COLOR=vec_cols[2],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
    ;;------------------------------------------------------------------------------------
    ;;  Plot energy range limits
    ;;------------------------------------------------------------------------------------
    OPLOT,[all_eran_esa[0],all_eran_esa[0]],yran_out,COLOR=ecol[0],LINESTYLE=lsty[1]
    OPLOT,[all_eran_esa[1],all_eran_esa[1]],yran_out,COLOR=ecol[0],LINESTYLE=lsty[1]
    OPLOT,[all_eran_sst[0],all_eran_sst[0]],yran_out,COLOR=ecol[1],LINESTYLE=lsty[2]
    OPLOT,[all_eran_sst[1],all_eran_sst[1]],yran_out,COLOR=ecol[1],LINESTYLE=lsty[2]
    ;;------------------------------------------------------------------------------------
    ;;  Output power-laws
    ;;------------------------------------------------------------------------------------
    OPLOT,xran_out,fplaw_2,LINESTYLE=lsty[1],THICK=thck[0],COLOR=plw_cols[0]
    OPLOT,xran_out,fplaw_3,LINESTYLE=lsty[2],THICK=thck[0],COLOR=plw_cols[1]
    OPLOT,xran_out,fplaw_4,LINESTYLE=lsty[3],THICK=thck[0],COLOR=plw_cols[2]
    ;;------------------------------------------------------------------------------------
    ;;  Output EX_LINE
    ;;------------------------------------------------------------------------------------
    OPLOT,[extra_line.NVAL[0],extra_line.NVAL[0]],yran_out,COLOR=ecol[2],LINESTYLE=lsty[1],THICK=thck[0]
    ;;------------------------------------------------------------------------------------
    ;;  Output one-count levels (if desired by user)
    ;;------------------------------------------------------------------------------------
    IF (log_1c[0]) THEN BEGIN
      ;;  ESA
      OPLOT,AvgE_para_esa,Av1c_para_esa,COLOR=vec_cols[0],LINESTYLE=lsty[0]
      OPLOT,AvgE_para_esa,Av1c_perp_esa,COLOR=vec_cols[1],LINESTYLE=lsty[0]
      OPLOT,AvgE_para_esa,Av1c_anti_esa,COLOR=vec_cols[2],LINESTYLE=lsty[0]
      ;;  SST
      OPLOT,AvgE_para_sst,Av1c_para_sst,COLOR=vec_cols[0],LINESTYLE=lsty[0]
      OPLOT,AvgE_perp_sst,Av1c_perp_sst,COLOR=vec_cols[1],LINESTYLE=lsty[0]
      OPLOT,AvgE_anti_sst,Av1c_anti_sst,COLOR=vec_cols[2],LINESTYLE=lsty[0]
    ENDIF
    ;;------------------------------------------------------------------------------------
    ;;  Output legend
    ;;------------------------------------------------------------------------------------
    XYOUTS,xxloc[0],yyloc[0],vllab[0],COLOR=ecol[0],/DATA,ALIGNMENT=align[0]             ;;  ESA energy range labels
    XYOUTS,xxloc[1],yyloc[1],vllab[1],COLOR=ecol[1],/DATA,ALIGNMENT=align[0]             ;;  SST energy range labels
    XYOUTS,xxloc[2],yyloc[2],vllab[2],COLOR=ecol[2],/DATA,ALIGNMENT=align[0]             ;;  EX_LINE label
    XYOUTS,xposi[0],yposi[0],legends[0],COLOR=vec_cols[0],/NORMAL,ALIGNMENT=align[0]     ;;  Para label
    XYOUTS,xposi[0],yposi[1],legends[1],COLOR=vec_cols[1],/NORMAL,ALIGNMENT=align[0]     ;;  Perp label
    XYOUTS,xposi[0],yposi[2],legends[2],COLOR=vec_cols[2],/NORMAL,ALIGNMENT=align[0]     ;;  Anti label
    XYOUTS,xposi[0],yposi[3],leg_fpl[0],COLOR=plw_cols[0],/NORMAL,ALIGNMENT=align[0]     ;;  f(E) ~ E^(-2) label
    XYOUTS,xposi[0],yposi[4],leg_fpl[1],COLOR=plw_cols[1],/NORMAL,ALIGNMENT=align[0]     ;;  f(E) ~ E^(-3) label
    XYOUTS,xposi[0],yposi[5],leg_fpl[2],COLOR=plw_cols[2],/NORMAL,ALIGNMENT=align[0]     ;;  f(E) ~ E^(-4) label
;  PLOT,AvgE_para_esa,Avgf_para_esa,/NODATA,_EXTRA=pstr
;    ;;  Plot EESA data
;    OPLOT,AvgE_para_esa,Avgf_para_esa,COLOR=vec_cols[0],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
;    OPLOT,AvgE_perp_esa,Avgf_perp_esa,COLOR=vec_cols[1],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
;    OPLOT,AvgE_anti_esa,Avgf_anti_esa,COLOR=vec_cols[2],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
;    ;;  Plot SSTe data
;    OPLOT,AvgE_para_sst,Avgf_para_sst,COLOR=vec_cols[0],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
;    OPLOT,AvgE_perp_sst,Avgf_perp_sst,COLOR=vec_cols[1],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
;    OPLOT,AvgE_anti_sst,Avgf_anti_sst,COLOR=vec_cols[2],PSYM=psym[0],SYMSIZE=symz[0],THICK=thck[0]
;    ;;  Plot energy range limits
;    OPLOT,[all_eran_esa[0],all_eran_esa[0]],yran_out,COLOR=200,LINESTYLE=2
;    OPLOT,[all_eran_esa[1],all_eran_esa[1]],yran_out,COLOR=200,LINESTYLE=2
;    OPLOT,[all_eran_sst[0],all_eran_sst[0]],yran_out,COLOR=100,LINESTYLE=3
;    OPLOT,[all_eran_sst[1],all_eran_sst[1]],yran_out,COLOR=100,LINESTYLE=3
;    ;;  Output power-laws
;    OPLOT,xran_out,fplaw_2,LINESTYLE=2,THICK=thck[0],COLOR=plw_cols[0]
;    OPLOT,xran_out,fplaw_3,LINESTYLE=3,THICK=thck[0],COLOR=plw_cols[1]
;    OPLOT,xran_out,fplaw_4,LINESTYLE=4,THICK=thck[0],COLOR=plw_cols[2]
;    ;;  Output EX_LINE
;    OPLOT,[extra_line.NVAL[0],extra_line.NVAL[0]],yran_out,COLOR= 30,LINESTYLE=2,THICK=thck[0]
;    ;;  Output one-count levels (if desired by user)
;    IF (log_1c[0]) THEN BEGIN
;      ;;  ESA
;      OPLOT,AvgE_para_esa,Av1c_para_esa,COLOR=vec_cols[0],LINESTYLE=1
;      OPLOT,AvgE_para_esa,Av1c_perp_esa,COLOR=vec_cols[1],LINESTYLE=1
;      OPLOT,AvgE_para_esa,Av1c_anti_esa,COLOR=vec_cols[2],LINESTYLE=1
;      ;;  SST
;      OPLOT,AvgE_para_sst,Av1c_para_sst,COLOR=vec_cols[0],LINESTYLE=1
;      OPLOT,AvgE_perp_sst,Av1c_perp_sst,COLOR=vec_cols[1],LINESTYLE=1
;      OPLOT,AvgE_anti_sst,Av1c_anti_sst,COLOR=vec_cols[2],LINESTYLE=1
;    ENDIF
;    ;;  Output legend
;    XYOUTS,xyfacs[0]*all_eran_esa[1],xyfacs[2]*yran_out[1],'ESA',COLOR=200,/DATA,ALIGNMENT=0
;    XYOUTS,xyfacs[1]*all_eran_sst[0],xyfacs[2]*yran_out[1],'SST',COLOR=100,/DATA,ALIGNMENT=0
;    XYOUTS,xyfacs[1]*extra_line.NVAL[0],xyfacs[2]*yran_out[1],extra_line.NSTR[0],COLOR= 30,/DATA,ALIGNMENT=0
;    XYOUTS,xposi[1],yposi[0],legends[0],COLOR=vec_cols[0],/NORMAL,ALIGNMENT=0
;    XYOUTS,xposi[1],yposi[1],legends[1],COLOR=vec_cols[1],/NORMAL,ALIGNMENT=0
;    XYOUTS,xposi[1],yposi[2],legends[2],COLOR=vec_cols[2],/NORMAL,ALIGNMENT=0
;    XYOUTS,xposi[1],yposi[3],leg_fpl[0],COLOR=plw_cols[0],/NORMAL,ALIGNMENT=0
;    XYOUTS,xposi[1],yposi[4],leg_fpl[1],COLOR=plw_cols[1],/NORMAL,ALIGNMENT=0
;    XYOUTS,xposi[1],yposi[5],leg_fpl[2],COLOR=plw_cols[2],/NORMAL,ALIGNMENT=0
pclose
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END
