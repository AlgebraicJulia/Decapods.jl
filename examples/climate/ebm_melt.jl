# Import Dependencies 

# AlgebraicJulia Dependencies
using Catlab
using CombinatorialSpaces
using DiagrammaticEquations
using DiagrammaticEquations.Deca
using Decapodes
using Decapodes: SchSummationDecapode

# External Dependencies
using ComponentArrays
using CoordRefSystems
using GLMakie
using JLD2
using LinearAlgebra
using MLStyle
using NetCDF
using OrdinaryDiffEq
using ProgressBars
Point3D = Point3{Float64}

## Load a mesh
s_plots = loadmesh(Icosphere(7));
s = EmbeddedDeltaDualComplex2D{Bool, Float64, Point3D}(s_plots);
subdivide_duals!(s, Barycenter());
wireframe(s_plots)

## Load Data
# Effective sea ice thickness data can be downloaded here:
# https://pscfiles.apl.uw.edu/axel/piomas20c/v1.0/monthly/piomas20c.heff.1901.2010.v1.0.nc
ice_thickness_file = "examples/climate/piomas20c.heff.1901.2010.v1.0.nc"

# Use ncinfo(ice_thickness_file) to get information on variables.
# Sea ice thickness ("sit") has dimensions of [y, x, time].
# y,x index into "Latitude" and "Longitude" variables.
# Time is in units of days since 1901-01-01.
lat = ncread(ice_thickness_file, "Latitude")
lon = ncread(ice_thickness_file, "Longitude")
sit = ncread(ice_thickness_file, "sit")

# Convert latitude from [90, -90] to [0, 180] for convenience.
lat .= -lat .+ 90

p_sph = map(point(s)) do p
  p = convert(Spherical, Cartesian(p...))
  [rad2deg(p.θ).val, rad2deg(p.ϕ).val]
end

# TODO: Do algebraic parameterization, rather than nearest-neighbor interpolation.
# TODO: You can set a value to 0.0 if the distance to the nearest-neighbor is greater than some threshold.
sit_sph_idxs = map(ProgressBar(p_sph)) do p
  argmin(map(i -> sqrt((lat[i] - p[1])^2 + (lon[i] - p[2])^2), eachindex(lat)))
end

sit_sph = map(sit_sph_idxs, p_sph) do i, p
  ((p[1] > maximum(lat)) || isnan(sit[i])) ? 0.0f0 : sit[i]
end

f = Figure()
ax = LScene(f[1,1], scenekw=(lights=[],))
msh = mesh!(ax, s_plots, color=sit_sph)
Colorbar(f[1,2], msh)

## Define the model

halfar_eq2 = @decapode begin
  (h, melt)::Form0
  Γ::Form1
  n::Constant

  ∂ₜ(h)  == ∘(⋆, d, ⋆)(Γ * d(h) * avg₀₁(mag(♯(d(h)))^(n-1)) * avg₀₁(h^(n+2))) - melt
end

glens_law = @decapode begin
  (A,Γ)::Form1
  (ρ,g,n)::Constant
  
  Γ == (2/(n+2))*A*(ρ*g)^n
end

ice_dynamics_composition_diagram = @relation () begin
  dynamics(Γ,n)
  stress(Γ,n)
end

ice_dynamics = apex(oapply(ice_dynamics_composition_diagram,
  [Open(halfar_eq2, [:Γ,:n]),
   Open(glens_law, [:Γ,:n])]))

energy_balance = @decapode begin
  (Tₛ, ASR, OLR, HT)::Form0
  C::Constant

  ∂ₜ(Tₛ) == (ASR - OLR + HT) ./ C
end

absorbed_shortwave_radiation = @decapode begin
  (Q, ASR)::Form0
  α::Constant

  ASR == (1 .- α) .* Q
end

outgoing_longwave_radiation = @decapode begin
  (Tₛ, OLR)::Form0
  (A,B)::Constant

  OLR == A .+ (B .* Tₛ)
end

heat_transfer = @decapode begin
  (HT, Tₛ)::Form0
  (D,cosϕᵖ,cosϕᵈ)::Constant

  HT == (D ./ cosϕᵖ) .* ⋆(d(cosϕᵈ .* ⋆(d(Tₛ))))
end

insolation = @decapode begin
  Q::Form0
  cosϕᵖ::Constant

  Q == 450 * cosϕᵖ
end

budyko_sellers_composition_diagram = @relation () begin
  energy(Tₛ, ASR, OLR, HT)
  absorbed_radiation(Q, ASR)
  outgoing_radiation(Tₛ, OLR)
  diffusion(Tₛ, HT, cosϕᵖ)
  insolation(Q, cosϕᵖ)
end

budyko_sellers = apex(oapply(budyko_sellers_composition_diagram,
  [Open(energy_balance, [:Tₛ, :ASR, :OLR, :HT]),
   Open(absorbed_shortwave_radiation, [:Q, :ASR]),
   Open(outgoing_longwave_radiation, [:Tₛ, :OLR]),
   Open(heat_transfer, [:Tₛ, :HT, :cosϕᵖ]),
   Open(insolation, [:Q, :cosϕᵖ])]))

warming = @decapode begin
  Tₛ::Form0
  A::Form1

  #A == avg₀₁(5.8282*10^(-0.236 * Tₛ)*1.65e7)
  #A == avg₀₁(5.8282*10^(-0.236 * Tₛ)*1.01e-13)
  A == avg₀₁(5.8282*10^(-0.236 * Tₛ)*1.01e-19)
end

melting = @decapode begin
  (Tₛ, h, melt, water)::Form0
  Dₕ₂ₒ::Constant

  melt == (Tₛ - 15)*1e-16*h
  ∂ₜ(water) == melt + Dₕ₂ₒ*Δ(water)
end

budyko_sellers_halfar_water_composition_diagram = @relation () begin
  budyko_sellers(Tₛ)

  warming(A, Tₛ)

  melting(Tₛ, h, melt)

  halfar(A, h, melt)
end

budyko_sellers_halfar_water = apex(oapply(budyko_sellers_halfar_water_composition_diagram,
  [Open(budyko_sellers, [:Tₛ]),
   Open(warming, [:A, :Tₛ]),
   Open(melting, [:Tₛ, :h, :melt]),
   Open(ice_dynamics, [:stress_A, :dynamics_h, :dynamics_melt])]))

## Define constants, parameters, and initial conditions

# This is a primal 0-form, with values at vertices.
cosϕᵖ = map(x -> cos(x[1]), point(s))
# This is a dual 0-form, with values at edge centers.
cosϕᵈ = map(edges(s)) do e
  (cos(point(s, src(s, e))[1]) + cos(point(s, tgt(s, e))[1])) / 2
end

α₀ = 0.354
α₂ = 0.25
α = map(point(s)) do ϕ
  α₀ + α₂*((1/2)*(3*ϕ[1]^2 - 1))
end
A = 210
B = 2
f = 0.70
ρ = 1025
cw = 4186
H = 70
C = map(point(s)) do ϕ
  f * ρ * cw * H
end
D = 0.6

# Isothermal initial conditions:
Tₛ₀ = map(point(s)) do ϕ
  15.0
end

water = map(point(s)) do _
  0.0
end

Dₕ₂ₒ = 1e-16

n = 3
halfar_ρ = 910
g = 9.8

h₀ = sit_sph
# Store these values to be passed to the solver.
u₀ = ComponentArray(
  Tₛ = Tₛ₀,
  h = h₀,
  melting_water = water)

constants_and_parameters = (
  budyko_sellers_absorbed_radiation_α = α,
  budyko_sellers_outgoing_radiation_A = A,
  budyko_sellers_outgoing_radiation_B = B,
  budyko_sellers_energy_C = C,
  budyko_sellers_diffusion_D = D,
  budyko_sellers_cosϕᵖ = cosϕᵖ,
  budyko_sellers_diffusion_cosϕᵈ = cosϕᵈ,
  halfar_n = n,
  halfar_stress_ρ = halfar_ρ,
  halfar_stress_g = g,
  melting_Dₕ₂ₒ = Dₕ₂ₒ)

# Define how symbols map to Julia functions

function generate(sd, my_symbol; hodge=GeometricHodge())
  op = @match my_symbol begin
    :♯ => begin
      sharp_mat = ♯_mat(sd, AltPPSharp())
      x -> sharp_mat * x
    end
    :mag => x -> begin
      norm.(x)
    end
    :^ => (x,y) -> x .^ y
    :* => (x,y) -> x .* y
    x => error("Unmatched operator $my_symbol")
  end
  return (args...) -> op(args...)
end

## Generate simulation 

sim = eval(gensim(budyko_sellers_halfar_water))
fₘ = sim(s, generate)

## Run simulation 

tₑ = 100.0

# Julia will precompile the generated simulation the first time it is run.
@info("Precompiling Solver")
prob = ODEProblem(fₘ, u₀, (0, 1e-4), constants_and_parameters)
soln = solve(prob, Tsit5())
soln.retcode != :Unstable || error("Solver was not stable")

@info("Solving")
prob = ODEProblem(fₘ, u₀, (0, tₑ), constants_and_parameters)
soln = solve(prob, Tsit5())
@show soln.retcode
@info("Done")

extrema(soln(0.0).halfar_h)
extrema(soln(tₑ).halfar_h)

@save "budyko_sellers_halfar_water.jld2" soln

# Visualize 

g = Figure()
ax = LScene(g[1,1], scenekw=(lights=[],))
msh = mesh!(ax, s_plots, color=soln.u[end].h)
Colorbar(g[1,2], msh)

