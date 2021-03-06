
function sup_fit4, x,detector,  parameters=p ,type=type

if not keyword_set(p) then begin
    est = [.67,1.,1.33,1.67,2., 2.33, 2.67, 3.0, 3.4,  4.33, 4.67, 5.0, 5.33, 5.67]
    energy =  keyword_set(x) ? float(x) : 10.^est
    flux = keyword_set(detector) ? detector : 1e10/energy^3
;    eh = {eff:.5d, bkg:500.}
;    el = {bkg:1d4}
    maxw = {n:5d,t:10d}
    kappa= {n: .10d,vh:4000.0d,k:6.0d}
    pow  = {h:.05d,p:-2.d}
    if keyword_set(type) then   p = {func:'sup_fit4', $
         eff:.5d,  bkg:650.d , elbkg:1d4, $
         core:maxw, $
         halo:kappa, $
         suph:pow, $
         type:1, $
         units:'flux'}  $
     else  begin
         p = {func:'sup_fit4', $
         eff:.5d,  bkg:650.d , elbkg:1d4, $
         spl:splfunc(energy,flux,/xlog,/ylog), $
         type:0, $
         units:'flux'}
     endelse
    return,p
endif

if  data_type(x) eq 8 then begin
   energy = x.e
   detector = x.det
   effs = [1d,p.eff,1d]
   bkgs = [p.elbkg,p.bkg,0d]
   eff = effs[detector]
   bkg = bkgs[detector] / energy 
endif else begin
   energy = x
   eff = 1d
   bkg = 0d
endelse


if p.type then  begin
  mass = 5.6856593e-06
  k = (mass/2/!dpi)^1.5 
  a = 2./mass^2*1e5

  c = 2.9979d5      ;      Davin_units_to_eV = 8.9875e10
  E0 = double(mass*c^2)
  gam =  ( double(energy) + E0 ) / E0
  vel = sqrt(1.0d - 1.0d/(gam*gam) ) * c ;   Velocity in km/s
  v2 = vel^2

  pm = p.core
  exp1 = pm.t ^ (-1.5) * exp(- energy/pm.t)
  fcore =  k * pm.n * exp1
  
  pk = p.halo
  c1 = (!dpi)^(-1.5) * pk.vh^(-3) *  gamma(pk.k+1)/gamma(pk.k-.5)/pk.k^1.5
  fhalo = pk.n*c1*(1+(v2/pk.k/pk.vh^2 )  ) ^(-pk.k-1)
  
  pp = p.suph
  fshalo =  pp.h * (energy/30000.)^ pp.p /energy/a
  
  flux = (fcore+fhalo+fshalo)*energy*a
  
endif else flux =  splfunc(energy,param=p.spl)  

flux = flux * eff + bkg

case strlowcase(p.units) of
'df'   :  conv = 1/ (energy * a)
'flux' :  conv = 1
'eflux':  conv = energy
else   : message,"Units not recognized!"
endcase

f = conv * flux

return,f
end


