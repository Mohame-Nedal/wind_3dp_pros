;+
;*****************************************************************************************
;
;  FUNCTION :   moments_3du.pro
;  PURPOSE  :   Returns all useful moments of a distribution function as a structure,
;                 which includes:
;        ** {Scalar} = rank-0 tensor                        -> [1]-element array **
;        ** {Vector} = rank-1 tensor                        -> [3]-element array **
;        ** {Matrix} = rank-2 tensor                        -> [3,3]-element array **
;        ** {DiagEl} = diagonal elements of a rank-2 tensor -> [3]-element array **
;        ** {QTense} = quasi-tensor                         -> just symmetric elements **
;
;        ** Symmetry Direction  :  See Section II.B (Software) of Curtis et al., [1988]
;
;                   SC_CURRENT  :  {Scalar} Current density [# cm^(-2) s^(-1)]
;                   DENSITY     :  {Scalar} Number density [cm^(-3)]
;                   AVGTEMP     :  {Scalar} Average particle temperature [eV]
;                   VTHERMAL    :  {Scalar} Average thermal speed [km s^(-1)]
;                   VELOCITY    :  {Vector} Bulk flow velocity [km s^(-1)]
;                   FLUX        :  {Vector} Number flux [cm^(-2) s^(-1)]
;                     ** Velocity flux [cm^(-1) s^(-2)] **
;                   MFTENS      :  {QTense} Momentum flux [eV cm^(-3)]
;                   EFLUX       :  {Vector} Energy flux [eV cm^(-2) s^(-1)]
;                   PTENS       :  {QTense} Pressure tensor [eV cm^(-3)]
;                   T3          :  {DiagEl} Eigenvalues of "temperature tensor" in
;                                             the input coordinate system [xx,yy,zz]
;                   MAGT3       :  {DiagEl} Eigenvalues of "temperature tensor" in
;                                             field-aligned coordinates [perp1,perp2, para]
;                   SYMM        :  {Vector} Symmetry direction of distribution
;                   SYMM_THETA  :  {Scalar} Poloidal angle of symmetry direction [deg]
;                   SYMM_PHI    :  {Scalar} Azimuthal angle of symmetry direction [deg]
;                   SYMM_ANG    :  {Scalar} Angle between symmetry direction and Bo [deg]
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               test_wind_vs_themis_esa_struct.pro
;               dat_3dp_str_names.pro
;               convert_ph_units.pro
;               conv_units.pro
;               moments_3d_omega_weights.pro
;               moments_3du.pro
;               str_element.pro
;               sc_pot.pro
;               struct_value.pro
;               rot_mat.pro
;               xyz_to_polar.pro
;
;  REQUIRES:    
;               1)  THEMIS TDAS IDL libraries or UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DATA            :  Scalar particle distribution from either Wind/3DP
;                                    or THEMIS ESA
;                                    [See:  get_??.pro for Wind]
;                                    [See:  thm_part_dist_array.pro for THEMIS]
;
;  EXAMPLES:    
;               test = moments_3du()
;
;  KEYWORDS:    
;               SC_POT          :  Scalar defining the spacecraft potential (eV)
;               MAGDIR          :  3-Element vector defining the magnetic field (nT)
;                                    associated with the data structure
;               TRUE_DENS       :  Scalar defining the true density (cc)
;                                    [Used to constrain SC potential estimates]
;               COMP_SC_POT     :  If set, routine attempts to estimate the SC potential
;               PARDENS         :  Set to a named variable to return the partial
;                                    densities for each energy/angle bin
;               DENS_ONLY       :  If set, program only returns the density estimate (cc)
;               MOM_ONLY        :  If set, program only returns through flux (1/cm/s^2)
;               ADD_MOMENT      :  Set to a structure of identical format to the return
;                                    format of this program to be added to the structure
;                                    being manipulated
;               ADD_DMOMENT     :  The same format as ADD_MOMENT but for an uncertainty
;                                    structure
;               ERANGE          :  Set to a 2-Element array specifying the first and last
;                                    elements of the energy bins desired to be used for
;                                    calculating the moments
;               FORMAT          :  Set to a dummy variable which will be returned the
;                                    as the structure format associated with the output
;                                    structure of this program
;               BINS            :  Old keyword apparently
;               VALID           :  Set to a dummy variable which will return a 1 for a
;                                    structure with useful data or 0 for a bad structure
;               DMOM            :  Set to a named variable to return the uncertainties in
;                                    the distribution moment calculations
;               DOMEGA_WEIGHTS  :  If set, routine uses solid angle estimates determined
;                                    by DOMEGA values existing in IDL structures instead
;                                    of using estimates from moments_3d_omega_weights.pro
;               PH_0_360        :  Determines the range of azimuthal angles of symmetry
;                                    direction
;                                      > 0  :     0 < phi < +360
;                                      = 0  :  -180 < phi < +180
;                                      < 0  :     routine determines best range
;
;   CHANGED:  1)  Davin Larson created                            [??/??/????   v1.0.0]
;             2)  Updated man page                                [01/05/2009   v1.0.1]
;             3)  Fixed comments regarding tensors                [01/28/2009   v1.0.2]
;             4)  Changed an assignment variable                  [03/01/2009   v1.0.3]
;             5)  Changed SC Potential calc to avoid redefining the original variable
;                                                                 [03/04/2009   v1.0.4]
;             6)  Updated man page                                [03/20/2009   v1.0.5]
;             7)  Changed SC Potential keyword to avoid conflicts with
;                   sc_pot.pro calling                            [04/17/2009   v1.0.6]
;             8)  Updated man page                                [06/17/2009   v1.1.0]
;             9)  Added comments and units to calcs               [08/20/2009   v1.1.1]
;            10)  Added error handling and the programs:
;                   convert_ph_units.pro and dat_3dp_str_names.pro
;                                                                 [08/25/2009   v1.2.0]
;            11)  Fixed a typo that ONLY affected Pesa High data structures
;                                                                 [04/09/2010   v1.2.1]
;            12)  Added keyword:  DMOM and DOMEGA_WEIGHTS
;                   now calls moments_3d_omega_weights.pro
;                                                                 [06/14/2011   v1.3.0]
;            13)  Fixed a typo in SC potential use                [06/20/2011   v1.3.1]
;            14)  Fixed typo in man page                          [08/16/2011   v1.3.2]
;            15)  Updated to be in accordance with newest version of moments_3d.pro
;                   in TDAS IDL libraries
;                   A)  Cleaned up and added some comments
;                   B)  Added units to calculations
;                   C)  Added keyword:  PH_0_360
;                   D)  no longer calls moments_3d.pro
;                   E)  now calls test_wind_vs_themis_esa_struct.pro, moments_3du.pro,
;                                 and struct_value.pro
;                                                                 [04/12/2012   v1.4.0]
;            16)  Fixed typo in man page description of DOMEGA_WEIGHTS usage
;                                                                 [08/21/2012   v1.4.1]
;
;   NOTES:      
;               1)  Adaptations from routines written by Jim McTiernan are used
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
;
;   ADAPTED FROM:  moments_3du.pro  [LAST MODIFIED:  04/21/2011 by jimm]
;   CREATED:  ??/??/????
;   CREATED BY:  Davin Larson
;    LAST MODIFIED:  08/21/2012   v1.4.1
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION moments_3du,data,                            $
                     SC_POT         = scpot,          $
                     MAGDIR         = magdir,         $
                     TRUE_DENS      = tdens,          $
                     COMP_SC_POT    = comp_sc_pot,    $
                     PARDENS        = pardens,        $
                     DENS_ONLY      = dens_only,      $
                     MOM_ONLY       = mom_only,       $
                     ADD_MOMENT     = add_moment,     $
                     ADD_DMOMENT    = add_dmoment,    $
                     ERANGE         = er,             $
                     FORMAT         = momformat,      $
                     BINS           = bins,           $
                     VALID          = valid,          $
                     DMOM           = dmom,           $
                     DOMEGA_WEIGHTS = domega_weights, $
                     PH_0_360       = ph_0_360

;-----------------------------------------------------------------------------------------
; => Define dummy variables and structures
;-----------------------------------------------------------------------------------------
f   = !VALUES.F_NAN
f3  = [f,f,f]
f6  = [f,f,f,f,f,f]
f33 = [[f3],[f3],[f3]]
d   = !VALUES.D_NAN

IF (SIZE(momformat,/TYPE) EQ 8) THEN mom = momformat ELSE $
  mom = {TIME:d, SC_POT:f, SC_CURRENT:f, MAGF:f3, DENSITY:f, AVGTEMP:f, VTHERMAL:f, $
         VELOCITY:f3, FLUX:f3, PTENS:f6, MFTENS:f6, EFLUX:f3,                       $
         T3:f3, SYMM:f3, SYMM_THETA:f, SYMM_PHI:f, SYMM_ANG:f,                      $
         MAGT3:f3, ERANGE:[f,f], MASS:f,VALID:0}

mom.VALID = 0
IF (N_PARAMS() EQ 0) THEN GOTO,SKIPSUMS
; => Make sure nothing reassigns values to original data
dd     = data[0]
IF (SIZE(dd,/TYPE) NE 8) THEN RETURN,mom
valid  = 0
;-----------------------------------------------------------------------------------------
; => Check DAT structure format
;-----------------------------------------------------------------------------------------
;  LBW III  04/12/2012   v1.4.0
test0      = test_wind_vs_themis_esa_struct(dd,/NOM)
test       = (test0.(0) + test0.(1)) NE 1
IF (test) THEN BEGIN
  RETURN,mom
ENDIF
; => Check which spacecraft is being used
;  LBW III  04/12/2012   v1.4.0
IF (test0.(0)) THEN BEGIN
  ;-------------------------------------------
  ; Wind
  ;-------------------------------------------
  ; => Check which instrument is being used
  strns   = dat_3dp_str_names(dd[0])
  IF (SIZE(strns,/TYPE) NE 8) THEN RETURN,mom
  shnme   = STRLOWCASE(STRMID(strns.SN[0],0L,2L))
  CASE shnme[0] OF
    'ph' : BEGIN
      ; => First deal with uncertainty estimates
      data3d1      = dd
      convert_ph_units,data3d1,'counts'
      data3d1.DATA = 1.0
      ; => Now convert actual data to energy flux [eV cm^(-2) s^(-1) sr^(-1) eV^(-1)]
      convert_ph_units,dd,'eflux'
      data3d       = dd
      charge       = 1d0
    END
    ELSE : BEGIN
      ; => First deal with uncertainty estimates
      data3d1      = conv_units(dd,'counts')
      data3d1.DATA = 1.0
      ; => Now convert actual data to energy flux [eV cm^(-2) s^(-1) sr^(-1) eV^(-1)]
      data3d       = conv_units(dd,'eflux')
      IF (STRMID(shnme[0],0L,1L) EQ 's') THEN BEGIN
        charge       = ([-1d0,1d0])[STRMID(shnme[0],1L,1L) EQ 'o']
      ENDIF ELSE BEGIN
        charge       = ([-1d0,1d0])[STRMID(shnme[0],0L,1L) EQ 'p']
      ENDELSE
    END
  ENDCASE
ENDIF ELSE BEGIN
  ;-------------------------------------------
  ; THEMIS
  ;-------------------------------------------
  ; => First deal with uncertainty estimates
  data3d1      = conv_units(dd,'counts')
  data3d1.DATA = 1.0
  ; => Now convert actual data to energy flux [eV cm^(-2) s^(-1) sr^(-1) eV^(-1)]
  data3d       = conv_units(dd,'eflux')
  charge       = DOUBLE(data3d[0].CHARGE[0])
ENDELSE

mom.TIME = data3d.TIME
mom.MAGF = data3d.MAGF
IF (data3d[0].VALID EQ 0) THEN RETURN,mom
;-----------------------------------------------------------------------------------------
; => Define a data structure with one count per angular and energy bin, for uncertainties
;      [Jim M. 12-apr-2011]
;-----------------------------------------------------------------------------------------
dd1    = data3d1
dmom   = mom

;-----------------------------------------------------------------------------------------
; => Determine Solid Angle [sr]
;-----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(domega_weights) THEN $
  domega_weight = moments_3d_omega_weights(data3d.THETA,data3d.PHI,data3d.DTHETA,data3d.DPHI)
  ;;  domega_weight = [13,N,M,K]-element array
  ;;                     N  =  # of energy bins
  ;;                     M  =  # of angle bins
  ;;                     K  =  # of data structures

e      = data3d.ENERGY       ; => Energy bin energies [eV]
nn     = data3d.NENERGY      ; => # of energy bins used
;-----------------------------------------------------------------------------------------
; => Determine energy range
;-----------------------------------------------------------------------------------------
IF KEYWORD_SET(er) THEN BEGIN
   err                = 0 >  er < (nn-1)
   s                  = e
   s[*]               = 0.
   s[err[0]:err[1],*] = 1.
   data3d.DATA        = data3d.DATA * s
ENDIF ELSE  BEGIN
   err = [0,nn-1]
ENDELSE
mom.ERANGE = data3d.ENERGY[err,0]
;-----------------------------------------------------------------------------------------
;if keyword_set(bins) then begin 
;   if ndimen(bins) eq 2 then w = where(bins eq 0,c)   $
;   else  w = where((replicate(1b,nn) # bins) eq 0,c)
;   if c ne 0 then data3d.data[w]=0
;endif
;-----------------------------------------------------------------------------------------
IF KEYWORD_SET(bins) THEN MESSAGE,/INFO,'bins keyword ignored'
;  TDAS Update
bins = data3d.BINS
IF (SIZE(/N_DIMENSIONS,bins) EQ 1) THEN bins = REPLICATE(1,nn) # bins

w = WHERE(data3d.BINS EQ 0,c)
IF (c NE 0) THEN data3d.DATA[w] = 0
;-----------------------------------------------------------------------------------------
; => Determine or set spacecraft (SC) potential
;-----------------------------------------------------------------------------------------
;IF (KEYWORD_SET(scpot))   THEN pot = scpot[0] ELSE pot = 0.
IF (KEYWORD_SET(scpot))   THEN pot = scpot[0]
IF (N_ELEMENTS(pot) EQ 0) THEN str_element,data3d,'SC_POT',pot
IF (N_ELEMENTS(pot) EQ 0) THEN pot = 0.
IF (NOT FINITE(pot))      THEN pot = 6.

IF KEYWORD_SET(tdens) THEN BEGIN
   pota = [3.,12.]
   m0   = moments_3du(data3d,SC_POT=pota[0],/DENS_ONLY)
   m1   = moments_3du(data3d,SC_POT=pota[1],/DENS_ONLY)
   dens = [m0.DENSITY,m1.DENSITY]
   FOR i = 0L, 4L DO BEGIN 
      yp   = (dens[0] - dens[1])/(pota[0] - pota[1])
      pot  = pota[0] - (dens[0] - tdens) / yp
      m0   = moments_3du(data3d,SC_POT=pot,/DENS_ONLY)
      dens = [m0.DENSITY,dens]
      pota = [pot,pota]
   ENDFOR
ENDIF
;-----------------------------------------------------------------------------------------
; => Determine the spacecraft potential
;-----------------------------------------------------------------------------------------
IF KEYWORD_SET(comp_sc_pot) THEN BEGIN
;   par = {v0:-1.9036d,n0:533.7d }
   FOR i = 0L, 3L DO BEGIN 
     m   = moments_3du(data3d,SC_POT=pot,/DENS_ONLY)
     pot = sc_pot(m.DENSITY)
   ENDFOR
ENDIF
mom.SC_POT   = pot[0]                                    ; => [eV]
mom.MASS     = data3d.MASS                               ; => [eV/c^2, with c in km/s]
mass         = mom.MASS
;-----------------------------------------------------------------------------------------
; => Determine differential energy then calculate DF differential
;-----------------------------------------------------------------------------------------
;str_element,data3d,'DENERGY',denergy
denergy      = struct_value(data3d,'denergy')
IF NOT KEYWORD_SET(denergy) THEN BEGIN
  de_e         = ABS(SHIFT(e,1) - SHIFT(e,-1))/(2.0*e)   ; => [unitless]
  de_e[0,*]    = de_e[1,*]
  de_e[nn-1,*] = de_e[nn-2,*]
  de           = de_e * e                                ; => [eV]
ENDIF ELSE BEGIN
  de_e         = denergy/data3d.ENERGY                   ; => [unitless]
  de           = denergy
ENDELSE
;-----------------------------------------------------------------------------------------
; => Define weighting factors
;-----------------------------------------------------------------------------------------
;weight   = 0. > ((e + pot)/de + .5) < 1.                 ; => [unitless weight factor]
;e_inf    = (e + pot) > 0.                                ; => Energy at infinity [eV]
weight   = 0. > ((e + pot[0]*charge[0])/de + .5) < 1.    ; => [unitless weight factor]
e_inf    = (e + pot[0]*charge[0]) > 0.                   ; => Energy at infinity [eV]
; => Define a differential volume
dvolume  = de_e * weight * domega_weight[0,*,*,*]        ; => [sr]
data_dv  = data3d.DATA * dvolume                         ; => DF differential  [cm^(-2) s^(-1)]
data_dv1 = data3d1.DATA * dvolume                        ; => uncertainty, jmm, 12-apr-2011
;-----------------------------------------------------------------------------------------
; => Current calculation:
;-----------------------------------------------------------------------------------------
mom.SC_CURRENT  = TOTAL(data_dv,/NAN)
dmom.SC_CURRENT = SQRT(TOTAL(data_dv*data_dv1,/NAN))     ; => uncertainty, jmm, 12-apr-2011
;-----------------------------------------------------------------------------------------
; => Density calculation:  cm^(-3)
;-----------------------------------------------------------------------------------------
dweight      = SQRT(e_inf)/e                             ; => [eV^(-1/2)]
par_factor   = SQRT(mass/2.) * 1e-5                      ; => [eV^(1/2) / (cm/s)]
; => Note:  The factor of 1e-5 is to change [km] to [cm]
pardens      = par_factor * data_dv  * dweight           ; => [cm^(-3)]
pardens1     = par_factor * data_dv1 * dweight           ; => [cm^(-3)]
mom.DENSITY  = TOTAL(pardens,/NAN)                       ; => [cm^(-3)]
dmom.DENSITY = SQRT(TOTAL(pardens*pardens1,/NAN))        ; => uncertainty, jmm, 12-apr-2011

IF KEYWORD_SET(dens_only) THEN RETURN,mom
;-----------------------------------------------------------------------------------------
; => FLUX calculation:  [cm^(-2) s^(-1)]
;-----------------------------------------------------------------------------------------
f_fac       = de_e * weight * e_inf / e                    ; => [Unitless]
temp        = data3d.DATA  * f_fac                         ; => [cm^(-2) s^(-1) sr^(-1)]
temp1       = data3d1.DATA * f_fac

fx          = TOTAL(temp*domega_weight[1,*,*,*],/NAN)      ; => [cm^(-2) s^(-1)]
fy          = TOTAL(temp*domega_weight[2,*,*,*],/NAN)
fz          = TOTAL(temp*domega_weight[3,*,*,*],/NAN)
; => uncertainty [cm^(-2) s^(-1)], jmm, 12-apr-2011
dfx         = SQRT(TOTAL(temp*temp1*domega_weight[1,*,*,*]^2,/NAN))
dfy         = SQRT(TOTAL(temp*temp1*domega_weight[2,*,*,*]^2,/NAN))
dfz         = SQRT(TOTAL(temp*temp1*domega_weight[3,*,*,*]^2,/NAN))

mom.FLUX    = [fx,fy,fz]     ; Units: [cm^(-2) s^(-1)]
dmom.FLUX   = [dfx,dfy,dfz]
;-----------------------------------------------------------------------------------------
; => VELOCITY FLUX:  [eV^(1/2) cm^(-2) s^(-1)]
;-----------------------------------------------------------------------------------------
v_fac       = de_e * weight * e_inf^(3./2.) / e            ; => [eV^(1/2)]
; => Note:  The factor of 1e-5 is to change [km] to [cm]
m_fac       = (SQRT(2/mass)*1e5)                           ; => [eV^(-1/2) cm^(+1) s^(-1)]
temp        = data3d.DATA  * v_fac                         ; => [eV^(+1/2) cm^(-2) s^(-1) sr^(-1)]
temp1       = data3d1.DATA * v_fac
vfxx        = TOTAL(temp*domega_weight[4,*,*,*],/NAN)      ; => [eV^(+1/2) cm^(-2) s^(-1)]
vfyy        = TOTAL(temp*domega_weight[5,*,*,*],/NAN)
vfzz        = TOTAL(temp*domega_weight[6,*,*,*],/NAN)
vfxy        = TOTAL(temp*domega_weight[7,*,*,*],/NAN)
vfxz        = TOTAL(temp*domega_weight[8,*,*,*],/NAN)
vfyz        = TOTAL(temp*domega_weight[9,*,*,*],/NAN)

vftens      = [vfxx,vfyy,vfzz,vfxy,vfxz,vfyz]*m_fac        ; => [cm^(-1) s^(-2)]
; => Note:  The factor of 1e10 is to change [km^(-2)] in mass to [cm^(-2)]
mftens      = vftens*mass/1e10                             ; => [eV cm^(-3)]
mom.MFTENS  = mftens
; => uncertainty [eV^(1/2) cm^(-2) s^(-1)], jmm, 12-apr-2011
dvfxx       = SQRT(TOTAL(temp*temp1*domega_weight[4,*,*,*]^2,/NAN))
dvfyy       = SQRT(TOTAL(temp*temp1*domega_weight[5,*,*,*]^2,/NAN))
dvfzz       = SQRT(TOTAL(temp*temp1*domega_weight[6,*,*,*]^2,/NAN))
dvfxy       = SQRT(TOTAL(temp*temp1*domega_weight[7,*,*,*]^2,/NAN))
dvfxz       = SQRT(TOTAL(temp*temp1*domega_weight[8,*,*,*]^2,/NAN))
dvfyz       = SQRT(TOTAL(temp*temp1*domega_weight[9,*,*,*]^2,/NAN))

dvftens     = [dvfxx,dvfyy,dvfzz,dvfxy,dvfxz,dvfyz]*m_fac  ; => [cm^(-1) s^(-2)]
; => Note:  The factor of 1e10 is to change [km^(-2)] in mass to [cm^(-2)]
dmftens     = dvftens*mass/1e10                            ; => [eV cm^(-3)]
dmom.MFTENS = dmftens
;-----------------------------------------------------------------------------------------
; => ENERGY FLUX:  [eV cm^(-2) s^(-1) sr^(-1) eV^(-1)]
;-----------------------------------------------------------------------------------------
e_fac       = de_e * weight * e_inf^(2.) / e               ; => [eV]
temp        = data3d.DATA  * e_fac                         ; => [eV cm^(-2) s^(-1) sr^(-1)]
temp1       = data3d1.DATA * e_fac
v2f_x       = TOTAL(temp*domega_weight[1,*,*,*],/NAN)      ; => [eV cm^(-2) s^(-1)]
v2f_y       = TOTAL(temp*domega_weight[2,*,*,*],/NAN)
v2f_z       = TOTAL(temp*domega_weight[3,*,*,*],/NAN)
mom.eflux   = [v2f_x,v2f_y,v2f_z]                          ; => [eV cm^(-2) s^(-1)]
; => uncertainty [eV cm^(-2) s^(-1)], jmm, 12-apr-2011
dv2f_x      = SQRT(TOTAL(temp*temp1*domega_weight[1,*,*,*]^2,/NAN))
dv2f_y      = SQRT(TOTAL(temp*temp1*domega_weight[2,*,*,*]^2,/NAN))
dv2f_z      = SQRT(TOTAL(temp*temp1*domega_weight[3,*,*,*]^2,/NAN))
dmom.eflux  = [dv2f_x,dv2f_y,dv2f_z]                       ; => [eV cm^(-2) s^(-1)]
;=========================================================================================
SKIPSUMS:        ; enter here to calculate remainder of items.
;=========================================================================================
IF (SIZE(dmom,/TYPE) NE 8) THEN dmom = mom    ;;  needed when :  test = moments_3du()
;; => Add moment of desired
IF (SIZE(add_moment,/TYPE) EQ 8) THEN BEGIN
   mom.DENSITY  = mom.DENSITY + add_moment.DENSITY
   mom.FLUX     = mom.FLUX    + add_moment.FLUX
   mom.MFTENS   = mom.MFTENS  + add_moment.MFTENS
ENDIF
IF (SIZE(add_dmoment,/TYPE) EQ 8) THEN BEGIN
   dmom.DENSITY = SQRT(dmom.DENSITY^2 + add_dmoment.DENSITY^2)
   dmom.FLUX    = SQRT(dmom.FLUX^2    + add_dmoment.FLUX^2)
   dmom.MFTENS  = SQRT(dmom.MFTENS^2  + add_dmoment.MFTENS^2)
ENDIF
IF KEYWORD_SET(mom_only) THEN RETURN,mom

mass   = mom.MASS
map3x3 = [[0,3,4],[3,1,5],[4,5,2]]
mapt   = [0,4,8,1,2,5]
;-----------------------------------------------------------------------------------------
; => mf3x3  = ptens[map3x3]   [eV cm^(-3)]
;-----------------------------------------------------------------------------------------
mom.VELOCITY  = mom.FLUX/mom.DENSITY/1e5   ; => [km/s]
term0         = (dmom.FLUX/mom.DENSITY)^2 + (mom.FLUX*dmom.DENSITY/mom.DENSITY^2)^2
; => uncertainty [km/s], jmm, 12-apr-2011
dmom.VELOCITY = SQRT(term0)/1e5            ; => [km/s]
;-----------------------------------------------------------------------------------------
; => Map the velocity flux to a 3x3 tensor
;-----------------------------------------------------------------------------------------
mf3x3         = mom.MFTENS[map3x3]
dmf3x3        = dmom.MFTENS[map3x3]
; => Define pressure tensor
pt3x3         = mf3x3 - (mom.VELOCITY # mom.FLUX)*mass/1e5
mom.PTENS     = pt3x3[mapt]                       ; => [eV cm^(-3)]
; => Define "temperature tensor"
t3x3          = pt3x3/mom.DENSITY                 ; => [eV]
mom.AVGTEMP   = (t3x3[0] + t3x3[4] + t3x3[8])/3.  ; => Trace/3 = scalar temperature [eV]
mom.VTHERMAL  = SQRT(2.*mom.AVGTEMP/mass)         ; => Thermal speed [km/s]
tempt         = t3x3[mapt]                        ; => Symmetric elements of tensor

; => uncertainty [eV cm^(-3)], jmm, 12-apr-2011
term0         = ((mom.VELOCITY # dmom.FLUX)^2 + (dmom.VELOCITY # mom.FLUX)^2)*mass^2/1e10
dpt3x3        = SQRT(dmf3x3^2 + term0)
dmom.PTENS    = dpt3x3[mapt]                      ; => [eV cm^(-3)]
term0         = (dpt3x3/mom.DENSITY)^2 + (pt3x3*dmom.DENSITY/mom.DENSITY^2)^2
dt3x3         = SQRT(term0)                       ; => [eV]
term0         = dt3x3[0]^2 + dt3x3[4]^2 + dt3x3[8]^2
dmom.AVGTEMP  = SQRT(term0)/3.                    ; => Scalar temperature [eV]
; => units are WRONG in the following for some reason...
term0         = dmom.AVGTEMP/(2.*mass*mom.AVGTEMP)
dmom.VTHERMAL = SQRT(term0)
dtempt        = dt3x3[mapt]

gtemp        = WHERE(FINITE(t3x3),gt33,COMPLEMENT=btemp,NCOMPLEMENT=bt33)
IF (bt33 GT 0) THEN BEGIN   ; => Non-Finite points break TRIQL.PRO
  bind = ARRAY_INDICES(t3x3,btemp)
  t3x3[bind[0,*],bind[1,*]] = 0e0
ENDIF
IF (bt33 EQ 9) THEN mom.DENSITY = f
good         = FINITE(mom.DENSITY)
IF (NOT good OR mom.DENSITY LE 0) THEN RETURN,mom
t3evec       = t3x3
;-----------------------------------------------------------------------------------------
; -> If t3evec = [NxN]-Element real symmetric matrix then:
; -> t3    = N-Element vector of the diagonal elements of t3evec
; -> dummy = N-Element vector of the off-diagonal " " 
;-----------------------------------------------------------------------------------------
TRIRED,t3evec,t3,dummy
;-----------------------------------------------------------------------------------------
; -> t3     => Now goes to the eigenvalues of the input matrix, t3
; -> dummy  => gets destroyed by TRIQL.PRO
; -> t3evec => Now becomes the N-Eigenvectors of t3
;-----------------------------------------------------------------------------------------
TRIQL,t3,dummy,t3evec

;; => Define magnetic field direction
IF (N_ELEMENTS(magdir) NE 3L) THEN magdir = [-1.,1.,0.]
magfn = magdir/(SQRT(TOTAL(magdir^2,/NAN)))  ;; normalize

;; sort the temperature tensor eigenvalue elements
s      = SORT(t3)
IF (t3[s[1]] LT .5*(t3[s[0]] + t3[s[2]])) THEN num = s[2] ELSE num = s[0]

shft   = ([-1,1,0])[num]
t3     = SHIFT(t3,shft)
t3evec = SHIFT(t3evec,0,shft)
dot    = TOTAL(magfn*t3evec[*,2],/NAN)  ;; B . T_zz
bmag   = SQRT(TOTAL(mom.MAGF^2,/NAN))
IF (FINITE(bmag)) THEN BEGIN
  ;; => use defined B-field to define parallel/perpendicular temperatures
  magfn        = mom.MAGF/bmag
  b_dot_s      = TOTAL((magfn # [1,1,1])*t3evec,1,/NAN)
  dummy        = MAX(ABS(b_dot_s),num,/NAN)
  mrot         = rot_mat(mom.MAGF,mom.VELOCITY)
  magt3x3      = INVERT(mrot) # (t3x3 # mrot)
  mom.MAGT3    = magt3x3[[0,4,8]]  ;; => Diagonal elements
  ;---------------------------------------------------------------------------------------
  ; =>mom.PTENS = [perp1,perp2,para,xy,xz,yz],  mom.MAGT3 = [perp1,perp2,para]
  ;
  ; => (INVERT(mrot) # (t3x3 # mrot))[0,4,8,1,2,5] = same as
  ;                       mom.PTENS/mom.DENSITY in mom3d.pro
  ;---------------------------------------------------------------------------------------
  dot          = TOTAL(magfn*t3evec[*,2],/NAN)  ;; B . T_zz
  mom.SYMM_ANG = ACOS(ABS(dot))*!RADEG          ;; angle of B-field from symmetry axis
ENDIF

IF (dot LT 0) THEN t3evec = -t3evec
mom.SYMM       = t3evec[*,2]         ;; symmetry direction
magdir         = mom.SYMM

;  TDAS Update
;xyz_to_polar,mom.SYMM,THETA=symm_theta,PHI=symm_phi,/PH_0_360
xyz_to_polar,mom.SYMM,THETA=symm_theta,PHI=symm_phi,PH_0_360=ph_0_360
mom.SYMM_THETA = symm_theta
mom.SYMM_PHI   = symm_phi
mom.T3         = t3
valid          = 1
mom.VALID      = 1
;-----------------------------------------------------------------------------------------
; => Return
;-----------------------------------------------------------------------------------------

RETURN,mom
END
