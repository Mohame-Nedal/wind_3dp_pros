;+
;PROCEDURE:	load_wi_3dp_ehsp
;PURPOSE:	
;   loads WIND 3D Plasma Experiment key parameter data for "tplot".
;
;INPUTS:
;  none, but will call "timespan" if time_range is not already set.
;KEYWORDS:
;  DATA:        Raw data can be returned through this named variable.
;  NVDATA:	Raw non-varying data can be returned through this variable.
;  TIME_RANGE:  2 element vector specifying the time range.
;  MASTERFILE:	(string) full filename of master file.
;  PREFIX:	Prefix for tplot variables. Default is 'ehsp'
;  RESOLUTION:	Resolution to be returned in seconds.
;SEE ALSO: 
;  "make_cdf_index","loadcdf","loadcdfstr","loadallcdf"
;
;CREATED BY:	Davin Larson
;FILE:  
;LAST MODIFICATION: %W% %E%
;-
pro load_wi_3dp_ehsp $
   ,trange=trange $
   ,format=format $
   ,bartel = bartel $
   ,prefix = prefix $
   ,median = med $
  ,resolution = res

if keyword_set(bartel) then format='wi_3dp_ehsp_B_files'
if not keyword_set(format) then format = 'wi_3dp_ehsp_files'

cdfnames = ['ehsp_44']
cdf2tplot,format=format,/verbose,trange=trange

ylim,'ehsp_44',1e-6,1e5,1


if data_type(prefix) eq 7 then px=prefix else px = 'wi_3dp_'

;evals = roundsig(d(0).energy/1000.)
;elab = strtrim(string(evals,format='(g0)')+' keV',2)
;elabpos=reverse([100000., 42000., 15000., 5400., 790., 110., 5.3, 0.59, $
;  0.21 ,0.046, 0.013, 0.0042, 0.0017, 0.0008, 0.00029 ])

;store_data,px,data={x:d.time,y:dimen_shift(d.flux,1),v:dimen_shift(d.energy,1)}$
;  ,min=-1e30,dlim={ylog:1,labels:elab,labpos:elabpos}



end
