;+
;*****************************************************************************************
;
;  PROCEDURE:   vbulk_change_vdf_plot_wrapper.pro
;  PURPOSE  :   This is a wrapping routine for the plotting and parameter changing
;                 routines within the Vbulk Change IDL Libraries.
;
;  CALLED BY:   
;               wrapper_vbulk_change_thm_wi.pro
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               get_os_slash.pro
;               num2int_str.pro
;               vbulk_change_test_vdf_str_form.pro
;               vbulk_change_test_cont_str_form.pro
;               is_a_number.pro
;               vbulk_change_test_vdfinfo_str_form.pro
;               extract_tags.pro
;               vbulk_change_change_parameter.pro
;               str_element.pro
;               vbulk_change_get_fname_ptitle.pro
;               struct_value.pro
;               popen.pro
;               general_vdf_contour_plot.pro
;               pclose.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;               2)  Vbulk Change IDL Libraries
;
;  INPUT:
;               DATA        :  [M]-Element [structure] array containing particle velocity
;                                distribution functions (VDFs) each containing the
;                                following structure tags:
;                                  VDF     :  [N]-Element [float/double] array defining
;                                               the VDF in units of phase space density
;                                               [i.e., # s^(+3) km^(-3) cm^(-3)]
;                                  VELXYZ  :  [N,3]-Element [float/double] array defining
;                                               the particle velocity 3-vectors for each
;                                               element of VDF
;                                               [km/s]
;
;  EXAMPLES:    
;               [calling sequence]
;               vbulk_change_vdf_plot_wrapper, data [,INDEX=index] [,VDF_INFO=vdf_info]    $
;                                              [,CONT_STR=cont_str] [,WINDN=windn]         $
;                                              [,PLOT_STR=plot_str] [,EX_VECN=ex_vecn]     $
;                                              [,VCIRC=vcirc] [,ALL_FPREFS=all_fprefs]     $
;                                              [,ONEC_ARR=onec_arr]                        $
;                                              [,ALL_PTTLS=all_pttls] [,READ_OUT=read_out] $
;                                              [,DATA_OUT=data_out] [,PS_FNAME=ps_fname]
;
;  KEYWORDS:    
;               ***  INPUT --> Param  ***
;               INDEX       :  Scalar [long] defining the index of DATA to use when
;                                changing/defining keywords (i.e., which VDF of the M-
;                                element array of DATA)
;                                [Default = 0]
;               VDF_INFO    :  [M]-Element [structure] array containing information
;                                relevant to each VDF with the following format
;                                [*** units and format matter here ***]:
;                                  SE_T   :  [2]-Element [double] array defining to the
;                                              start and end times [Unix] of the VDF
;                                  SCFTN  :  Scalar [string] defining the spacecraft name
;                                              [e.g., 'Wind' or 'THEMIS-B']
;                                  INSTN  :  Scalar [string] defining the instrument name
;                                              [e.g., '3DP' or 'ESA' or 'EESA' or 'SST']
;                                  SCPOT  :  Scalar [float] defining the spacecraft
;                                              electrostatic potential [eV] at the time of
;                                              the VDF
;                                  VSW    :  [3]-Element [float] array defining to the
;                                              bulk flow velocity [km/s] 3-vector at the
;                                              time of the VDF
;                                  MAGF   :  [3]-Element [float] array defining to the
;                                              quasi-static magnetic field [nT] 3-vector at
;                                              the time of the VDF
;               ***  INPUT --> Contour Plot  ***
;               CONT_STR    :  Scalar [structure] containing tags defining all of the
;                                current plot settings associated with all of the above
;                                "INPUT --> Command to Change" keywords
;               ***  INPUT --> System  ***
;               WINDN       :  Scalar [long] defining the index of the window to use when
;                                selecting the region of interest
;                                [Default = !D.WINDOW]
;               PLOT_STR    :  Scalar [structure] that defines the scaling factors for the
;                                contour plot shown in window WINDN to be used by
;                                general_cursor_select.pro
;               ***  INPUT --> Circles for Contour Plot  ***
;               VCIRC       :  [C]-Element [structure] array containing the center
;                              locations and radii of circles the user wishes to
;                              project onto the contour and cut plots, each with
;                              the following format:
;                                VRAD  :  Scalar defining the velocity radius of the
;                                           circle to project centered at {VOX,VOY}
;                                VOX   :  Scalar defining the velocity offset along
;                                           X-Axis [Default = 0.0]
;                                VOY   :  Scalar defining the velocity offset along
;                                           Y-Axis [Default = 0.0]
;               ***  INPUT --> Extras for Contour Plot  ***
;               EX_VECN     :  [V]-Element [structure] array containing extra vectors the
;                                user wishes to project onto the contour, each with
;                                the following format:
;                                  VEC   :  [3]-Element [numeric] array of 3-vectors in the
;                                             same coordinate system as VELXYZ to be
;                                             projected onto the contour plot
;                                             [e.g. VEC[0] = along X-Axis]
;                                  NAME  :  Scalar [string] used as a name for each VEC
;                                             to output onto the contour plot
;                                             [Default = 'Vec_j', j = index of EX_VECS]
;               ***  INPUT --> File and Plot Info  ***
;               ALL_FPREFS  :  [M]-Element [string] array defining all the file prefixes
;                                for the M VDFs in DATA
;               ALL_PTTLS   :  [M]-Element [string] array defining all the plot titles
;                                for the M VDFs in DATA
;               ***  INPUT --> Contour Plot  ***
;               ONEC_ARR    :  [M]-Element [structure] array containing particle VDFs
;                                of the same format as DATA but for the one-count levels
;                                [Default = FALSE]
;               ***  OUTPUT  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               ***  [all the following changed on output]  ***
;               !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;               READ_OUT    :  Set to a named variable to return a string containing the
;                                last command line input.  This is used by the overhead
;                                routine to determine whether user left the program by
;                                quitting or if the program finished
;               DATA_OUT    :  Set to a named variable to return the relevant plot and
;                                file settings for the ith VDF defined by INDEX
;               PS_FNAME    :  Set to a named variable to return a string containing the
;                                list of PS file names saved during this run through the
;                                routine.  If READ_OUT = 'q', then the overhead routine
;                                will delete these files prior to moving on to the next
;                                particle distribution.
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [07/27/2017   v1.0.0]
;             2)  Continued to write routine
;                                                                   [07/28/2017   v1.0.0]
;             3)  Continued to write routine
;                                                                   [07/31/2017   v1.0.0]
;             4)  Fixed an issue with passing an updated version of the CONT_STR back
;                   to the calling routine
;                                                                   [08/01/2017   v1.0.1]
;             5)  Added keyword ONEC_ARR and
;                   now sends one-count level information to plotting routines
;                                                                   [08/24/2017   v1.1.0]
;
;   NOTES:      
;               0)  User should not directly call this routine
;               1)  See routines called by this wrapping program for more information
;                     about their usage
;
;  REFERENCES:  
;               1)  Carlson et al., "An instrument for rapidly measuring plasma
;                      distribution functions with high resolution," Adv. Space Res. 2,
;                      pp. 67-70, 1983.
;               2)  Curtis et al., "On-board data analysis techniques for space plasma
;                      particle instruments," Rev. Sci. Inst. 60, pp. 372, 1989.
;               3)  Lin et al., "A three-dimensional plasma and energetic particle
;                      investigation for the Wind spacecraft," Space Sci. Rev. 71,
;                      pp. 125, 1995.
;               4)  Paschmann, G. and P.W. Daly "Analysis Methods for Multi-Spacecraft
;                      Data," ISSI Scientific Report, Noordwijk, The Netherlands.,
;                      Int. Space Sci. Inst., 1998.
;               5)  McFadden, J.P., C.W. Carlson, D. Larson, M. Ludlam, R. Abiad,
;                      B. Elliot, P. Turin, M. Marckwordt, and V. Angelopoulos
;                      "The THEMIS ESA Plasma Instrument and In-flight Calibration,"
;                      Space Sci. Rev. 141, pp. 277-302, 2008.
;               6)  McFadden, J.P., C.W. Carlson, D. Larson, J.W. Bonnell,
;                      F.S. Mozer, V. Angelopoulos, K.-H. Glassmeier, U. Auster
;                      "THEMIS ESA First Science Results and Performance Issues,"
;                      Space Sci. Rev. 141, pp. 477-508, 2008.
;               7)  Auster, H.U., K.-H. Glassmeier, W. Magnes, O. Aydogar, W. Baumjohann,
;                      D. Constantinescu, D. Fischer, K.H. Fornacon, E. Georgescu,
;                      P. Harvey, O. Hillenmaier, R. Kroth, M. Ludlam, Y. Narita,
;                      R. Nakamura, K. Okrafka, F. Plaschke, I. Richter, H. Schwarzl,
;                      B. Stoll, A. Valavanoglou, and M. Wiedemann "The THEMIS Fluxgate
;                      Magnetometer," Space Sci. Rev. 141, pp. 235-264, 2008.
;               8)  Angelopoulos, V. "The THEMIS Mission," Space Sci. Rev. 141,
;                      pp. 5-34, (2008).
;               9)  Wilson III, L.B., et al., "Quantified energy dissipation rates in the
;                      terrestrial bow shock: 1. Analysis techniques and methodology,"
;                      J. Geophys. Res. 119, pp. 6455--6474, doi:10.1002/2014JA019929,
;                      2014a.
;              10)  Wilson III, L.B., et al., "Quantified energy dissipation rates in the
;                      terrestrial bow shock: 2. Waves and dissipation,"
;                      J. Geophys. Res. 119, pp. 6475--6495, doi:10.1002/2014JA019930,
;                      2014b.
;              11)  Pollock, C., et al., "Fast Plasma Investigation for Magnetospheric
;                      Multiscale," Space Sci. Rev. 199, pp. 331--406,
;                      doi:10.1007/s11214-016-0245-4, 2016.
;              12)  Gershman, D.J., et al., "The calculation of moment uncertainties
;                      from velocity distribution functions with random errors,"
;                      J. Geophys. Res. 120, pp. 6633--6645, doi:10.1002/2014JA020775,
;                      2015.
;              13)  Bordini, F. "Channel electron multiplier efficiency for 10-1000 eV
;                      electrons," Nucl. Inst. & Meth. 97, pp. 405--408,
;                      doi:10.1016/0029-554X(71)90300-4, 1971.
;              14)  Meeks, C. and P.B. Siegel "Dead time correction via the time series,"
;                      Amer. J. Phys. 76, pp. 589--590, doi:10.1119/1.2870432, 2008.
;              15)  Furuya, K. and Y. Hatano "Pulse-height distribution of output signals
;                      in positive ion detection by a microchannel plate,"
;                      Int. J. Mass Spectrom. 218, pp. 237--243,
;                      doi:10.1016/S1387-3806(02)00725-X, 2002.
;              16)  Funsten, H.O., et al., "Absolute detection efficiency of space-based
;                      ion mass spectrometers and neutral atom imagers,"
;                      Rev. Sci. Inst. 76, pp. 053301, doi:10.1063/1.1889465, 2005.
;              17)  Oberheide, J., et al., "New results on the absolute ion detection
;                      efficiencies of a microchannel plate," Meas. Sci. Technol. 8,
;                      pp. 351--354, doi:10.1088/0957-0233/8/4/001, 1997.
;
;   ADAPTED FROM:  beam_fit_1df_plot_fit.pro [UMN 3DP library, beam fitting routines]
;   CREATED:  07/26/2017
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/24/2017   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO vbulk_change_vdf_plot_wrapper,data,                                               $
                                       INDEX=index,VDF_INFO=vdf_info0,                $  ;;  ***  INPUT --> Param  ***
                                       CONT_STR=cont_str0,                            $  ;;  ***  INPUT --> Contour Plot  ***
                                       WINDN=windn,PLOT_STR=plot_str0,                $  ;;  ***  INPUT --> System  ***
                                       EX_VECN=ex_vecn,                               $  ;;  ***  INPUT --> Extras for Contour Plot  ***
                                       VCIRC=vcirc,                                   $  ;;  ***  INPUT --> Circles for Contour Plot  ***
                                       ALL_FPREFS=all_fprefs,ALL_PTTLS=all_pttls,     $  ;;  ***  INPUT --> File and Plot Info  ***
                                       ONEC_ARR=onec_arr,                             $  ;;  ***  INPUT --> Extras for Cut Plot  ***
                                       READ_OUT=read_out,DATA_OUT=data_out,           $  ;;  ***  OUTPUT  ***
                                       PS_FNAME=ps_fname                                 ;;  ***  OUTPUT  ***

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Define parts of file names
xyzvecf        = ['V1','V1xV2xV1','V1xV2']
xy_suff        = xyzvecf[1]+'_vs_'+xyzvecf[0]+'_'
xz_suff        = xyzvecf[0]+'_vs_'+xyzvecf[2]+'_'
yz_suff        = xyzvecf[2]+'_vs_'+xyzvecf[1]+'_'
;;  Default window numbers
def_winn       = [4L,5L,6L]
;;  Initialize outputs
read_out       = ''
data_out       = 0b
ps_fname       = ''
;;  Define the current working directory character
;;    e.g., './' [for unix and linux] otherwise guess './' or '.\'
slash          = get_os_slash()                    ;;  '/' for Unix-like, '\' for Windows
vers           = !VERSION.OS_FAMILY                ;;  e.g., 'unix'
vern           = !VERSION.RELEASE                  ;;  e.g., '7.1.1'
test           = (vern[0] GE '6.0')
IF (test[0]) THEN cwd_char = FILE_DIRNAME('',/MARK_DIRECTORY) ELSE cwd_char = '.'+slash[0]
;;  Define PS file formatting structure
popen_str      = {PORT:1,LANDSCAPE:0,UNITS:'inches',YSIZE:11,XSIZE:8.5}
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_ELEMENTS(data) EQ 0) OR (N_PARAMS() LT 1) OR (SIZE(data,/TYPE) NE 8)
IF (test[0]) THEN RETURN     ;; nothing supplied, so leave
;;  Define dummy copy of DATA to avoid changing input
dat            = data
ndat           = N_ELEMENTS(dat)
;;  Define parameters used in case statement
inds           = LINDGEN(ndat)
ind_ra         = [MIN(inds),MAX(inds)]
sind_ra        = num2int_str(ind_ra,NUM_CHAR=4,/ZERO_PAD)
;;  Check DATA
test           = vbulk_change_test_vdf_str_form(dat[0])
IF (test[0] EQ 0) THEN RETURN
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check CONT_STR
test           = vbulk_change_test_cont_str_form(cont_str0,DAT_OUT=cont_str)
IF (test[0] EQ 0 OR SIZE(cont_str,/TYPE) NE 8) THEN cont_str = def_contstr
;;  Check WINDN
test           = vbulk_change_test_windn(windn,DAT_OUT=win)
IF (test[0] EQ 0) THEN RETURN ELSE windn = win[0]
;;  Check PLOT_STR
;;    TRUE   -->  Allow use of general_cursor_select.pro routine
;;    FALSE  -->  Command-line input only
test_plt       = vbulk_change_test_plot_str_form(plot_str0,DAT_OUT=plot_str)
;;  Check INDEX
test           = (is_a_number(index,/NOMSSG) EQ 0) OR (N_ELEMENTS(index) LT 1)
IF (test[0]) THEN ind0 = 0L ELSE ind0 = LONG(index[0])
;;  Check VDF_INFO
temp           = vbulk_change_test_vdfinfo_str_form(vdf_info0,DAT_OUT=vdf_info)
n_vdfi         = N_ELEMENTS(vdf_info)
test           = (temp[0] EQ 0) OR (n_vdfi[0] NE ndat[0])
IF (test[0]) THEN STOP  ;;  Not properly set --> Output structure is null --> debug
;;  Define EX_INFO
extract_tags,dumb,vdf_info[0],TAGS=['SCPOT','VSW','MAGF']
ex_infoa       = REPLICATE(dumb[0],ndat[0])
ex_infoa.SCPOT = vdf_info.SCPOT
ex_infoa.VSW   = vdf_info.VSW
ex_infoa.MAGF  = vdf_info.MAGF
;;  Check ONEC_ARR
test           = (N_ELEMENTS(onec_arr) EQ ndat[0]) AND (SIZE(onec_arr,/TYPE) EQ 8)
IF (test[0]) THEN vdf_1c = onec_arr ELSE vdf_1c = 0b
;;  Check ONEC_ARR structure format
test           = vbulk_change_test_vdf_str_form(vdf_1c[0])
IF (test[0]) THEN onec_on = 1b ELSE onec_on = 0b
;;----------------------------------------------------------------------------------------
;;  Define index-specific parameters
;;----------------------------------------------------------------------------------------
;;  Define EX_INFO for plotting
ex_info        = ex_infoa[ind0[0]]
;;  Define VDF params for plotting
dat_i          = dat[ind0[0]]
IF (onec_on[0]) THEN one_c = vdf_1c[ind0[0]].VDF ELSE one_c = 0b
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Plot initial VDF
;;----------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------
;;  Define plot title(s) and file name(s)
cont_str_xy    = cont_str
cont_str_xz    = cont_str
cont_str_yz    = cont_str
str_element,cont_str_xy,'PLANE','xy',/ADD_REPLACE
str_element,cont_str_xz,'PLANE','xz',/ADD_REPLACE
str_element,cont_str_yz,'PLANE','yz',/ADD_REPLACE
struc_xy       = vbulk_change_get_fname_ptitle(dat,all_fprefs,all_pttls,INDEX=ind0,CONT_STR=cont_str_xy)
struc_xz       = vbulk_change_get_fname_ptitle(dat,all_fprefs,all_pttls,INDEX=ind0,CONT_STR=cont_str_xz)
struc_yz       = vbulk_change_get_fname_ptitle(dat,all_fprefs,all_pttls,INDEX=ind0,CONT_STR=cont_str_yz)
test           = (SIZE(struc_xy,/TYPE) NE 8) OR (SIZE(struc_xz,/TYPE) NE 8) OR (SIZE(struc_yz,/TYPE) NE 8)
IF (test[0]) THEN STOP       ;;  Something failed --> Debug
;;  Plot all three planes to initialize
pttles         = [struc_xy.PLOT_TITLE[0],struc_xz.PLOT_TITLE[0],struc_yz.PLOT_TITLE[0]]
contstrs       = {XY:cont_str_xy,XZ:cont_str_xz,YZ:cont_str_yz}
vdf            = dat_i[0].VDF
velxyz         = dat_i[0].VELXYZ
FOR k=0L, 2L DO BEGIN
  plot_title     = pttles[k]
  copy_str       = contstrs.(k)
  WSET,def_winn[k]
  WSHOW,def_winn[k]
  general_vdf_contour_plot,vdf,velxyz,_EXTRA=copy_str,CIRCS=vcirc,EX_VECS=ex_vecn, $
                       EX_INFO=ex_info,/SLICE2D,P_TITLE=plot_title[0],ONE_C=one_c
ENDFOR
;;========================================================================================
JUMP_STEP_1:
;;========================================================================================
;;  Prompt user for desired changes
vbulk_change_change_parameter,dat,                                               $
                                  INDEX=ind0,VDF_INFO=vdf_info,                  $  ;;  ***  INPUT --> Param  ***
                                  CONT_STR=cont_str,                             $  ;;  ***  INPUT --> Contour Plot  ***
                                  WINDN=windn,PLOT_STR=plot_str,                 $  ;;  ***  INPUT --> System  ***
                                  VCIRC=vcirc,                                   $  ;;  ***  INPUT --> Circles for Contour Plot  ***
                                  EX_VECN=ex_vecn,                               $  ;;  ***  INPUT --> Extras for Contour Plot  ***
                                  ALL_FPREFS=all_fprefs,ALL_PTTLS=all_pttls,     $  ;;  ***  INPUT --> File and Plot Info  ***
                                  ONEC_ARR=onec_arr,                             $  ;;  ***  INPUT --> Extras for Cut Plot  ***
                                  READ_OUT=name_out,DAT_PLOT=dat_i                  ;;  ***  OUTPUT  ***
;;  Check if user wishes to quit
IF (name_out[0] EQ 'q') THEN BEGIN
  read_out  = 'q'
  ;;  Update CONT_STR
  cont_str0 = cont_str[0]
  RETURN
ENDIF
;;  Make sure the change was not a switch of index
test           = (name_out[0] EQ 'next') OR (name_out[0] EQ 'prev') OR (name_out[0] EQ 'index')
IF (test[0]) THEN BEGIN
  ;;  Change index input and leave
  index          = ind0[0]
  read_out       = name_out[0]
  ;;  Update CONT_STR
  cont_str0      = cont_str[0]
  ;;  Return
  RETURN
ENDIF
;;  Redefine structure [in case user changed something]
dat_i          = dat[ind0[0]]
IF (onec_on[0]) THEN one_c = vdf_1c[ind0[0]].VDF ELSE one_c = 0b
;dat_i          = dat_i[0]
;;----------------------------------------------------------------------------------------
;;  Define plot title(s) and file name(s)
;;----------------------------------------------------------------------------------------
cont_str_xy    = cont_str
cont_str_xz    = cont_str
cont_str_yz    = cont_str
str_element,cont_str_xy,'PLANE','xy',/ADD_REPLACE
str_element,cont_str_xz,'PLANE','xz',/ADD_REPLACE
str_element,cont_str_yz,'PLANE','yz',/ADD_REPLACE
struc_xy       = vbulk_change_get_fname_ptitle(dat,all_fprefs,all_pttls,INDEX=ind0,CONT_STR=cont_str_xy)
struc_xz       = vbulk_change_get_fname_ptitle(dat,all_fprefs,all_pttls,INDEX=ind0,CONT_STR=cont_str_xz)
struc_yz       = vbulk_change_get_fname_ptitle(dat,all_fprefs,all_pttls,INDEX=ind0,CONT_STR=cont_str_yz)
test           = (SIZE(struc_xy,/TYPE) NE 8) OR (SIZE(struc_xz,/TYPE) NE 8) OR (SIZE(struc_yz,/TYPE) NE 8)
IF (test[0]) THEN STOP       ;;  Something failed --> Debug
;;  Define file name
fname_xy       = struc_xy.FILE_NAME[0]
fname_xz       = struc_xz.FILE_NAME[0]
fname_yz       = struc_yz.FILE_NAME[0]
;;  Define plot title 
pttle_xy       = struc_xy.PLOT_TITLE[0]
pttle_xz       = struc_xz.PLOT_TITLE[0]
pttle_yz       = struc_yz.PLOT_TITLE[0]
;;----------------------------------------------------------------------------------------
;;  Check if user wants to save
;;----------------------------------------------------------------------------------------
test           = (name_out[0] EQ 'save1') OR (name_out[0] EQ 'save3')
IF (test[0]) THEN BEGIN
  ;;  Define VDF params for plotting
  vdf            = dat_i[0].VDF
  velxyz         = dat_i[0].VELXYZ
  test           = (name_out[0] EQ 'save1')
  IF (test[0]) THEN BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Plot just 1 plane
    ;;------------------------------------------------------------------------------------
    ;;  Define plot title and file name
    struc          = vbulk_change_get_fname_ptitle(dat,all_fprefs,all_pttls,INDEX=ind0,CONT_STR=cont_str)
    savdir         = struct_value(cont_str,'SAVE_DIR',INDEX=dind)
    IF (dind[0] GE 0) THEN sdir = savdir[0] ELSE sdir = cwd_char[0]
    file_name      = sdir[0]+struc.FILE_NAME[0]
    plot_title     = struc.PLOT_TITLE[0]
    popen,file_name[0],_EXTRA=popen_str
      general_vdf_contour_plot,vdf,velxyz,_EXTRA=cont_str,CIRCS=vcirc,EX_VECS=ex_vecn,   $
                           EX_INFO=ex_info,/SLICE2D,P_TITLE=plot_title[0],ONE_C=one_c
    pclose
  ENDIF ELSE BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  Plot all 3 planes
    ;;------------------------------------------------------------------------------------
    savdir         = struct_value(cont_str,'SAVE_DIR',INDEX=dind)
    IF (dind[0] GE 0) THEN sdir = savdir[0] ELSE sdir = cwd_char[0]
    fnames         = sdir[0]+[fname_xy[0],fname_xz[0],fname_yz[0]]
    pttles         = [pttle_xy[0],pttle_xz[0],pttle_yz[0]]
    contstrs       = {XY:cont_str_xy,XZ:cont_str_xz,YZ:cont_str_yz}
    FOR k=0L, 2L DO BEGIN
      file_name      = fnames[k]
      plot_title     = pttles[k]
      copy_str       = contstrs.(k)
      popen,file_name[0],_EXTRA=popen_str
        general_vdf_contour_plot,vdf,velxyz,_EXTRA=copy_str,CIRCS=vcirc,EX_VECS=ex_vecn, $
                             EX_INFO=ex_info,/SLICE2D,P_TITLE=plot_title[0],ONE_C=one_c
      pclose
    ENDFOR
  ENDELSE
ENDIF
;;  Update CONT_STR and READ_OUT
cont_str0      = cont_str[0]
read_out       = name_out[0]
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END