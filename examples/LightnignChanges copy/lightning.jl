# TODO: Make parameters to be adjusted obvious/ top-level.

##############
# References #
##############

# Kotovsky, D. A. (2016), Response of the nighttime upper mesosphere to electric
#   field changes produced by lightning discharges, Ph.D. dissertation,
#   University of Florida, Gainesville, Florida. 

# V. P. Pasko, U. S. Inan, T. F. Bell, and Y. N. Taranenko, “Sprites produced by
#   quasi-electrostatic heating and ionization in the lower ionosphere,”
#   Journal of Geophysical Research: Space Physics, vol. 102, no. A3,
#   pp. 4529–4561, 1997, doi: 10.1029/96JA03528.

# G. Veronis, V. P. Pasko, and U. S. Inan, “Characteristics of mesospheric
#   optical emissions produced by lightning discharges,” Journal of Geophysical
#   Research: Space Physics, vol. 104, no. A6, pp. 12645–12656, 1999,
#   doi: 10.1029/1999JA900129.

################
# Dependencies #
################
using Pkg
Pkg.resolve()
begin # Dependencies
# AlgebraicJulia
using Catlab
using Catlab.CategoricalAlgebra
using Catlab.Graphics
using Catlab.Programs
using CombinatorialSpaces
using CombinatorialSpaces.ExteriorCalculus
using Decapodes

# External Dependencies
using Base.MathConstants: e, π
using Distributions
using GLMakie
using Interpolations
using LinearAlgebra
using Logging
using MAT
using MLStyle
using MultiScaleArrays
using OrdinaryDiffEq
using Roots
using SparseArrays

using GeometryBasics: Point2, Point3
Point2D = Point2{Float64}
Point3D = Point3{Float64}
end # Dependencies

#################
# Load the Mesh #
#################
begin # Load the Mesh
# We assume cylindrical symmetry.
MAX_r = 400.0e3 # [m]
MAX_Z = 100.0e3 # [m]

include("../../grid_meshes.jl")
s = triangulated_grid(400.0e3, 100.0e3, 100e2, 100e2, Point3D)
sd = EmbeddedDeltaDualComplex2D{Bool,Float64,Point3D}(s)
subdivide_duals!(sd, Circumcenter())
#wireframe(s)
#wireframe(sd)
nv(s), ne(s), ntriangles(s)

#s = loadmesh(Rectangle_30x10())
#s[:point] = map(x -> Diagonal([MAX_r / 30, MAX_Z / 10, 1]) * x, s[:point])
# TODO: Check whether these should be 32 or 64 bit floats.
####s = EmbeddedDeltaSet2D("LightningMesh.obj")
#s = EmbeddedDeltaSet2D{Bool, Point3D}()
#add_vertex!(s, point=Point3D([0.0, 0.0, 0.0]))
#add_vertex!(s, point=Point3D([0.0, 1.0, 0.0]))
#add_vertex!(s, point=Point3D([0.0, 2.0, 0.0]))
#add_vertex!(s, point=Point3D([1.0, 0.0, 0.0]))
#add_vertex!(s, point=Point3D([1.0, 1.0, 0.0]))
#add_vertex!(s, point=Point3D([1.0, 2.0, 0.0]))
#add_vertex!(s, point=Point3D([2.0, 0.0, 0.0]))
#add_vertex!(s, point=Point3D([2.0, 1.0, 0.0]))
#add_vertex!(s, point=Point3D([2.0, 2.0, 0.0]))
#glue_sorted_triangle!(s, 1,2,4)
#glue_sorted_triangle!(s, 2,4,5)
#glue_sorted_triangle!(s, 2,5,3)
#glue_sorted_triangle!(s, 3,5,6)
#glue_sorted_triangle!(s, 4,7,5)
#glue_sorted_triangle!(s, 5,7,8)
#glue_sorted_triangle!(s, 5,6,8)
#glue_sorted_triangle!(s, 6,8,9)
#GLMakie.wireframe(s)
####sd = EmbeddedDeltaDualComplex2D{Bool,Float64,Point2D}(s)
####subdivide_duals!(sd, Circumcenter())
#α_of_ν = EForm(collect(1.0:16.0))
#i₁′(α_of_ν, α_of_ν, sd, GeometricHodge())
#α_of_ν .* α_of_ν
#colors = inv_hodge_star(0, sd, GeometricHodge()) * (∧₁₁′(α_of_ν, ⋆(1,sd,α_of_ν,GeometricHodge()), sd),sd,GeometricHodge())[1]
#mesh(s, color=colors)
#wedge_mat(Val{(1,1)}, sd)
#
#inv_hodge_star(0, sd) * dual_derivative(1, sd) * hodge_star(1, sd) * α_of_ν
#mesh(s, color=inv_hodge_star(0, sd) * dual_derivative(1, sd) * hodge_star(1, sd) * ones(ne(s)))

####minimum_x = minimum(p -> p[1], s[:point])
####minimum_y = minimum(p -> p[2], s[:point])
####minimum_z = minimum(p -> p[3], s[:point])
####s[:point] = map(x -> Point3D([x[1] - minimum_x, x[2], x[3] - minimum_z]), s[:point])
####scaling_mat_to_unit_square = Diagonal([
####  1/maximum(p -> p[1], s[:point]),
####  1.0,
####  1/maximum(p -> p[3], s[:point])])
####scaling_mat_to_final_dimensions = Diagonal([
####  MAX_r,
####  1.0,
####  MAX_Z])
####scaling_mats = scaling_mat_to_final_dimensions * scaling_mat_to_unit_square
####s[:point] = map(x -> scaling_mats * x, s[:point])
####s[:point] = map(p -> Point3D([p[1], p[3], p[2]]), s[:point])
####s[:edge_orientation] = false
####orient!(s)
##### Visualize the mesh.
#####GLMakie.wireframe(s)
##### Note that these points are stored as Float64.
####sd = EmbeddedDeltaDualComplex2D{Bool,Float64,Point2D}(s)
####subdivide_duals!(sd, Circumcenter())
##### Notice that we are storing Z in the second position here.
##### Note the converstion to Float64.
#####sd[:point] = map(x -> Point3{Float64}([x[1], x[3], x[2]]), sd[:point])
#####sd[:dual_point] = map(x -> Point3{Float64}([x[1], x[3], x[2]]), sd[:dual_point])
#####sd[:point] = map(x -> Point3{Float64}([x[1], x[2], x[3]]), sd[:point])
#####sd[:dual_point] = map(x -> Point3{Float64}([x[1], x[2], x[3]]), sd[:dual_point])
####sd
end # Load the Mesh

#############
# Operators #
#############
begin # Operators

include("operators.jl")

function generate(sd, my_symbol; hodge=GeometricHodge())
  op = @match my_symbol begin
    :⋆ => x -> begin
      error("Uninferred hodge star")
    end
    :d => x -> begin
       error("Uninferred exterior derivative")
    end
    :⋆₀ => x -> begin
      # We create a local mat variable as a hint for Julia to cache it.
      mat = ⋆(0,sd,hodge=hodge)
      mat*x
    end
    :⋆₁ => x -> begin
      mat = ⋆(1, sd, hodge=hodge)
      mat*x
    end
    :⋆₂ => x -> begin
      mat = ⋆(2, sd, hodge=hodge)
      mat*x
    end
    :⋆₀⁻¹ => x -> begin 
      mat = inv_hodge_star(0, sd, hodge=hodge)
      mat*x
    end
    :⋆₁⁻¹ => x -> begin
      mat = inv_hodge_star(1, sd, hodge=hodge)
      mat*x
    end
    :d₁ => x -> begin
      mat = d(1,sd)
      mat*x
    end
    :d̃₀ => x -> begin
      mat = dual_derivative(0,sd)
      mat*x
    end
    :avg₀₁ => x -> begin
      avg_mat = avg₀₁(sd)
      avg_mat*x
    end
    :exp => x -> begin
      exp.(x)
    end
    :sqrt => x -> begin
      sqrt.(x)
    end
    :∧ᵖᵈ => (x,y) -> begin
      pd_wedge(Val{(1,1)}, sd, x, y)
    end
    :log10 => x -> begin
      log10.(x)
    end
    :exp10 => x -> begin
      exp10.(x)
    end
    :maskalt => x -> begin
      below_60_mask = map(x -> x[2] < 60*1000, sd[:point])
      x[below_60_mask] .= 0.0
      x
    end
    :♯ => x -> ♯(sd, x, DiscreteExteriorCalculus.PPSharp())
    :mag => x -> norm.(x)
    :.* => (x,y) -> x .* y
    :./ => (x,y) -> x ./ y
    :.+ => (x,y) -> x .+ y
    :.- => (x,y) -> x .- y
    :.^ => (x,y) -> x .^ y
    :^ => (x,y) -> x ^ y
    # TODO: Will this shorthand cause problems when we are trying to subtract?
    :- => x -> -1 * x
    #:- => (x,y) -> x .- y
    :.> => (x,y) -> 1 * (x .> y)
    :.< => (x,y) -> 1 * (x .< y)
    :.≤ => (x,y) -> 1 * (x .≤ y)
    :.≥ => (x,y) -> 1 * (x .≥ y)
    :invert_mask => x -> (!).(x)
    :id => x -> x

    #_ => error("Unmatched operator $my_symbol")
    _ => default_dec_generate(sd, my_symbol, hodge)
  end
  return (args...) -> op(args...)
end
end # Operators

######################
# Heidler Parameters #
######################
begin # Heidler Parameters

T1 = 50.0         # [us] See Kotovsky Table 5-1 column 1
T2 = 1000.0       # [us]
τ₁ = T1 .*1e-6    # [s]
τ₂ = T2 .*1e-6    # [s]
n = 10.0          # Heidler normalizing constant

# TODO: Should this distribution should reach its max at 50 microseconds?
HeidlerForη = t -> (t / τ₁)^n / (1 + ((t /τ₁)^n)) * exp(-1.0 * t / τ₁)
ddtHeidlerForη = t -> (exp(-t / τ₁) * (t/τ₁)^n * ((t*(-(t/τ₁)^n - 1)) + n*τ₂)) /
  (t * τ₂ * ((t/τ₁)^n + 1)^2)
time_for_k = find_zero(ddtHeidlerForη, (1.0e-6, 100.0e-6)) # 8.0878657...e-5
#plot(0.0:1.0e-8:100.0e-6, HeidlerForη)
#log_Heidler = map(0.0:1.0e-5:1.5e-3) do x
#  log(HeidlerForη(x)*1e6)
#end
#log_Heidler[1] = log_Heidler[2] # Set this manually to something not -Inf
#plot(0.0:1.0e-5:1.5e-3, log_Heidler)
#plot(0.0:1.0e-8:100.0e-6, ddtHeidlerForη)
η = HeidlerForη(time_for_k) # Normalizing constant 0.196775...

end # Heidler Parameters

#############
# Constants #
#############
begin # Constants
#temp = (return_time ./ rise_time) .^ 10 # Relative time difference.
I₀ = 250.0e3      # [kA] See Kotovsky pp. 107
ε₀ = 8.854e-12    # [F m⁻¹] Permittivity of free space
μ₀ = 4*π*1e-7     # [H m⁻¹] Permeability of free space
Z₀ = sqrt(μ₀/ε₀)  # [Ω] Impedance of free space
c = sqrt(1/ε₀/μ₀) # [m s⁻¹] Speed of light
v = 2/3 * c       # [m s⁻¹] Approximate speed of propagation of lightning strike through medium
qₑ = 1.602e-19    # [coul] Charge of electron
mₑ = 9.109e-31    # [kg] Mass of electron
kB = 8.617e-5     # [eV K⁻¹] Boltzmann constant
# Note that these ρ₀ and z₀ are chosen for numerical stability.
# For a rectangular grid discretization, good values are 3Δρ, 3Δz.
z₀ = 3.0e3        # [km] Heidler normalizing constant
ρ₀ = 3.0e3        # [km] Heidler normalizing constant
a = 10.0 * 1e3    # [m] Starting altitude of vertical decay for Heidler
# TODO: If the axes are swapped, then these accessors must be as well.
Z = EForm(avg₀₁(sd) * VForm(map(p -> p[2], sd[:point]))) # [m] Altitude
ρ = EForm(avg₀₁(sd) * VForm(map(p -> p[1], sd[:point]))) # [m] Distance from centre of strike

constants_and_parameters = (
  #mₑ = mₑ,
  #μ₀ = μ₀,
  #Z₀ = Z₀,
  #e = e,
  Chemistry_kB = kB,
  Veronis_qₑ = qₑ,
  Veronis_c = c,
  Veronis_ε₀ = ε₀,
  Heidler_τ₁ = τ₁,
  Heidler_τ₂ = τ₂,
  Heidler_I₀ = I₀,
  Heidler_v = v,
  Heidler_n = n,
  Heidler_a = a,
  Heidler_η = η,
  Heidler_t = t -> t,
  Heidler_z₀ = z₀,
  Heidler_π = π,
  Heidler_ρ₀ = ρ₀)

end # Constants

#################
# Heidler Model #
#################
begin # Heidler Model

# This defines J.
# The model takes in rise time, fall time, and peak current of the lightning
# strike, (i₀).
# Note that this model does not have any tangent variables.

# See Veronis et al. § 2.

Heidler = @decapode begin
  (J, J₀, Z, ρ, tret)::Form1{X}
  #(Z, tret)::Form0{X}
  (τ₁, τ₂, I₀, v, n, a, η, z₀, π, ρ₀)::Constant{X}
  (t)::Parameter{X}

  #I == I₀ * (one / η) * (t / τ₁)^n / (1 + (t / τ₁)^n) * e ^ (negone * t / τ₂)
  tret == t .- Z ./ v
  temp == (tret./τ₁).^n
  # See Veronis et al. § 2.1
  J₀ == (1.0 / (π * ρ₀^2)) * I₀/η * temp ./ (1 .+ temp) .* exp(-1 * tret ./ τ₂) .* (tret .> 0)

  # See Kotovsky Eq. 5-11a and 5-11b.
  J == (Z .≤ a) .* J₀ .* exp(-1.0 .* ρ .^ 2 / ρ₀ .^ 2) +
       (Z .> a) .* J₀ .* exp((-1.0 * ρ .^ 2 / ρ₀^2) - ((Z .- a) .^ 2 / z₀^2))
end
to_graphviz(Heidler)

end # Heidler Model

###########
# Veronis #
###########
begin # Veronis
# TODO: Handle half-timestepping in compile by passing an optional list that has
# the symbols of the TVars that you want to compute.
# See SymplecticIntegrators: 
# https://docs.sciml.ai/DiffEqDocs/latest/solvers/dynamical_solve/

# Primal_time: J,B,Nₑ
# Dual_time: E,Nₑ,θ,σ

# This will be useful also for the DEC -> plotting toolkit.

# Tonti tried to formalize primal-vs-dual time via a 3D layout of diagrams.
# (~ fields are on primal-space-primal-time, or dual-space-dual-time)
# (~ particles are on primal-space-dual-time, or dual-space-primal-time)

# "Dual things happening on dual steps makes sense."
# Default would be to compute primals on primal time, duals on dual time.

# Always keep in mind: B_into - B_outof = E_rightwards
# i.e. Keep your subtractions consistent.

# Assumptions that allow for cylindrical "pseudo-3D":
# - Lightning can be restricted to plane.
# - The magnetic field is orthogonal to this plane.

# More assumptions:
# - Tn is the neutral temperature. We assume that this never changes due to its
#   magnitude, and the timescale of investigation being small. As a consequence,
#   it acts as something like an "infinite source."

Veronis = @decapode begin
  # TODO: Double check units on these (esp. w.r.t. σ being integrated along
  # edges.)
  B::DualForm0{X}
  E::Form1{X}
  θ::Form0{X}
  J::Form1{X}
  (ρ_e, ρ_gas, Tn)::Form0{X}
  # Note: You just need σ for updating E, no need to recalculate on the other
  # time step.
  # TODO: Maybe define this as a Form0 to avoid the odd concept of integrated
  # conductivity.
  σ::Form1{X}
  (qₑ,c,ε₀)::Constant{X}

  # See Veronis et al. Equations 1 & 2
  #Ė == -(J - σ .* E)./ε₀ + (c^2).*(⋆₁⁻¹(d̃₀(B)))
  #Ė == -(J - σ .* E)./ε₀ + (c^2).*(⋆₀⁻¹(d̃₁(B)))
  #Ė == -1 * (J - σ .* E)./ε₀ + (c^2).*(⋆₀⁻¹(d̃₁(B)))
#  Ė == -1 * (J - σ .* E)./ε₀ + (c^2).*(⋆₁⁻¹(d̃₁(B)))
  Ė == -1 * (J - σ .* E)./ε₀ + ((c^2) .* ⋆(d(B)))
  Ė == ∂ₜ(E)

  # See Veronis et al. Equation 3
#  Ḃ == ⋆₂(d₁(E))
  Ḃ == ⋆(d(E))
  Ḃ == ∂ₜ(B)

  # See Kotovsky pp. 91: theta = E/n
  # Note: Updating θ with E means we are using the nonlinear model. i.e. We
  # consider electron temperature variation and species density variation.
  # Note: θ is used as a sort of "threshold" determining whether certain
  # reactions will occur.
  #θ == (1e21/1e6) .* ⋆(∧ᵖᵈ(E, ⋆(E))) ./ ρ_gas
  #θ == (1e21/1e6) .* ⋆₀⁻¹(∧ᵖᵈ(E, ⋆₁(E))) ./ ρ_gas
#  θ == (1e21/1e6) .* ⋆₀⁻¹(∧ᵖᵈ(E, ⋆(E))) ./ ρ_gas
  θ == (1e21/1e6) .* mag(♯(E)) ./ ρ_gas

  # Note: There may be a way to perform masking more efficiently,  while still
  # using the "programming language of PDEs."
  Eq5_2a_mask == .>(θ, (0.0603 * sqrt(200 ./ Tn)))
  #Eq5_2b_mask == invert_mask(Eq5_2a_mask)
  Eq5_2b_mask == .≤(θ, (0.0603 * sqrt(200 ./ Tn)))
  # See Kotovsky pp. 92 5-2a
  Eq5_2a == qₑ * ρ_e ./ ρ_gas *
    (10 .^ ( 50.97 + (3.026 * log10( 1e-21*θ )) + (8.4733e-2 * (log10( 1e-21*θ ) .^ 2))))
  #E15_2a_exponent_term_two == (3.026 * log10( 1e-21*θ ))
  #E15_2a_exponent_term_three == (8.4733e-2 * (log10( 1e-21*θ ) .^ 2))
  #Eq5_2a == qₑ * ρ_e ./ ρ_gas * (10 .^ ( 50.97 + E15_2a_exponent_term_two + E15_2a_exponent_term_three))
  #Eq5_2a == qₑ * ρ_e ./ ρ_gas * exp10( 50.97 + 0)
  # See Kotovsky pp. 92 5-2b
  Eq5_2b == qₑ * 3.656e25 * ρ_e ./ ρ_gas .* sqrt(200.0 ./ Tn)

  σ == avg₀₁((Eq5_2a_mask .*  Eq5_2a) + (Eq5_2b_mask .*  Eq5_2b))
end
to_graphviz(Veronis)
to_graphviz(resolve_overloads!(infer_types!(Veronis)))
end # Veronis

################################################
# Initialize Densities and Neutral Temperature #
################################################
begin # Format Atmosphere

include("formatAtmosphere.jl")
species, densities, Tn, rateCoef_names, rateCoefs = formatAtmosphere("./examples/LightnignChanges copy/chi180_O_dyn.mat", sd)
#mesh(s, color=rateCoefs[:k25])
mesh(s, color=densities[:O])

end # Format Atmosphere

#############################
# Initialize E, B, σ, and θ #
#############################
begin # Initialize Electromagnetism

Ef = VForm(zeros(ne(s)))
#B = DualForm{1}(zeros(ne(s)))
B = DualForm{0}(zeros(ntriangles(s)))

# Initialize reduced electric field, θ [V m m]
θ = nothing
E₀ = nothing
# Linear model of the reduced electric field
#if option == 3
  E₀ = Ef
  #θ = 1e21/1e6 * E ./ avg₀₁(sd, densities[:gas]) # Danny Dissert p 91 theta = E/n
  θ = EForm(zeros(ne(s)))
#end

# Initialize conductivity
#σ = zeros(nv(s))
for p in vertices(s)
  # Note: This is assuming that points in s are in Cartesian coordinates.
  ionosphere_altitude = 60.0e3
  #if s[p, :point][3] < ionosphere_altitude
  if s[p, :point][2] < ionosphere_altitude
    #σ[p] = 0.0
  else
    # See Kotovsky pp.92 eq 5-2b
    # See also Pasko et al.
    #σ[p] = qₑ * 3.656e25 * densities[:e][p] / densities[:gas][p] * sqrt(200.0 / Tn[p])
  end
end
#mesh(s, color=σ)

end # Initialize Electromagnetism

#####################
# Model Composition #
#####################
begin # Model Composition

# TODO: Rename this file to chemistry.jl
include("rateCoefficients_dynam.jl")
#to_graphviz(Chemistry)

compose_lightning = @relation () begin
  Heidler(J)
  Veronis(θ, J, ρ_e, ρ_gas, Tn)
  Chemistry(Tn, θ, ρ_e, ρ_gas)
end
#to_graphviz(compose_lightning, junction_labels=:variable, box_labels=:name, prog="circo")

lighting_cospan = oapply(compose_lightning,
  [Open(Heidler, [:J]),
  Open(Veronis, [:θ, :J, :ρ_e, :ρ_gas, :Tn]),
  Open(Chemistry, [:Tn, :θ, :ρ_e, :ρ_gas])])

lightning = apex(lighting_cospan)
#to_graphviz(lightning)

lightning = ∘(resolve_overloads!, infer_types!, expand_operators)(lightning)

end # Model Composition

#########################
# Simulation Generation #
#########################
begin # Simulation Generation

# Primal_time: J,B,Nₑ
# Dual_time: E,Nₑ,θ,σ

#To use VerletLeapfrog:
#primal_physics = recursive_delete_parent!(copy(lightning), [:E])
#dual_physics = recursive_delete_parent!(copy(lightning), [:B])
#
#primal_f = eval(gensim(primal_physics, generate))
#dual_f = eval(gensim(dual_physics, generate))

#sim = eval(gensim(expand_operators(lightning)))
#f = sim(sd, generate)

open("examples\\climate\\generated_lightning_sim.jl", "w") do file
  write(file, string(gensim(lightning)))
end
#sim = include(eval, "..\\climate\\generated_lightning_sim.jl")
sim = include("..\\climate\\generated_lightning_sim.jl")
fₘ = sim(sd, generate)

end

###########
# Solving #
###########

#v₀ = construct .. E
#u₀ = construct(PhysicsState, [B, vars["rateCoef"]["r1"], vars["rateCoef"]["r2"], ...])
#
##tₑ = 200e-6 # [s]
#tₑ = 1.334e-3 # [s] # How long it takes light to travel 400 km in a vacuum.
## TODO: Do I need to add {isinplace}?
#prob = DynamicalODEProblem(primal_f, dual_f, v₀, u₀, (0, tₑ), constants_and_parameters)
## TODO: Pick a dt.
#solve(prob, VerletLeapfrog())

u₀ = construct(PhysicsState,
  map(x -> VectorForm(x.data),
    [Z, ρ, B, Ef, Tn, values(densities)..., values(rateCoefs)...]),

  Float64[],

  [:Heidler_Z, :Heidler_ρ, :Veronis_B, :Veronis_E, :Tn,
    map(x -> Symbol(x == :e ? :ρ_e : "Chemistry_ρ_" * string(x)), species)...,
    map(x -> Symbol("Chemistry_" * string(x)), rateCoef_names)...])

du₀ = deepcopy(u₀)
fₘ(du₀, u₀, constants_and_parameters, 0)
fₘ(du₀, u₀, constants_and_parameters, 1e-10)
fₘ(du₀, u₀, constants_and_parameters, 1e-9)

findnode(u₀, :Chemistry_ρ_O)
findnode(du₀, :Chemistry_ρ_O)
findnode(du₀, :Veronis_E)
mesh(s, color=findnode(u₀, :Chemistry_ρ_O))
mesh(s, color=findnode(du₀, :Chemistry_ρ_O))
extrema(findnode(u₀, :Chemistry_ρ_O))
extrema(findnode(du₀, :Chemistry_ρ_O))

#prob = ODEProblem(f, u₀, (0, 1e-9), constants_and_parameters)
prob = ODEProblem(fₘ, u₀, (0, 1e-9), constants_and_parameters)
soln = solve(prob, Tsit5())
soln = solve(prob, ORK256(), dt=1e-9)

@save "soln_testing_aug292023.jld2" soln
loaded_soln = @load "soln_testing_aug292023.jld2"

findnode(loaded_soln(1e-8), :Chemistry_ρ_O)
x, y, t    ,  Chemistry_ρ_O, ...
-, -, 0    ,  1e-15        , ...
-, -, 1e-10,  1e-15        , ...
-, -, 2e-10,  1e-15        , ...
-, -, 3e-10,  1e-15        , ...

prob = ODEProblem(fₘ, u₀, (0, 1e-6), constants_and_parameters)
soln = solve(prob, ORK256(), dt=1e-6)

prob = ODEProblem(fₘ, u₀, (0, 200e-6), constants_and_parameters)
soln = solve(prob, ORK256(), dt=200e-6)

prob = ODEProblem(fₘ, u₀, (0, 1.334e-3), constants_and_parameters)
soln = solve(prob, ORK256(), dt=1.334e-3)

begin end

############
# Plotting #
############

# Create a gif
begin
  frames = 100
  fig, ax, ob = GLMakie.mesh(s, color=norm.(♯(sd, EForm(findnode(soln(0), :Veronis_E)))), colormap=:jet, colorrange=extrema(norm.(♯(sd, EForm(findnode(soln(1.334e-3), :Veronis_E))))))
  Colorbar(fig[1,2], ob)
  record(fig, "lightning_ORK256.gif", range(0.0, 1.334e-3; length=frames); framerate = 30) do t
    ob.color = norm.(♯(sd, EForm(findnode(soln(t), :Veronis_E))))
  end
end


du₀ = deepcopy(u₀)
fₘ(du₀, u₀, constants_and_parameters, 0)
fₘ(du₀, u₀, constants_and_parameters, 1e-10)
fₘ(du₀, u₀, constants_and_parameters, 1e-9)

findnode(u₀, :Chemistry_ρ_O)
findnode(du₀, :Chemistry_ρ_O)
findnode(du₀, :Veronis_E)
mesh(s, color=findnode(du₀, :Veronis_E))
mesh(s, color=findnode(u₀, :Chemistry_ρ_O))
mesh(s, color=findnode(du₀, :Chemistry_ρ_O))
extrema(findnode(u₀, :Chemistry_ρ_O))
extrema(findnode(du₀, :Chemistry_ρ_O))

compose_lightning_no_chem = @relation () begin
  Heidler(J)
  Veronis(J)
end
#to_graphviz(compose_lightning, junction_labels=:variable, box_labels=:name, prog="circo")

lighting_no_chem_cospan = oapply(compose_lightning_no_chem,
  [Open(Heidler, [:J]),
  Open(Veronis, [:J])])

lightning_no_chem = apex(lighting_no_chem_cospan)
#to_graphviz(lightning_no_chem)

lightning_no_chem = ∘(resolve_overloads!, infer_types!, expand_operators)(lightning_no_chem)

sim = eval(gensim(expand_operators(lightning_no_chem)))
f = sim(sd, generate)

u₀ = construct(PhysicsState,
  map(x -> VectorForm(x.data),
    [Z, ρ, B, Ef, Tn, values(densities)...]),
  Float64[],
  [:Heidler_Z, :Heidler_ρ, :Veronis_B, :Veronis_E, :Veronis_Tn,
    map(x -> Symbol("Veronis_ρ_" * string(x)), species)...,
    ])
prob = ODEProblem(f, u₀, (0, 1e-9), constants_and_parameters)
solve(prob, Tsit5())

function simulate(mesh, operators, hodge = GeometricHodge())
  #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:427 =#
  #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:428 =#
  begin
      #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:155 =#
      (M_dual_d₀, dual_d₀) = default_dec_matrix_generate(mesh, :dual_d₀, hodge)
      (var"M_⋆₁⁻¹", ⋆₁⁻¹) = default_dec_matrix_generate(mesh, :⋆₁⁻¹, hodge)
      (M_d₁, d₁) = default_dec_matrix_generate(mesh, :d₁, hodge)
      (var"M_⋆₂", ⋆₂) = default_dec_matrix_generate(mesh, :⋆₂, hodge)
      (var"M_⋆₁", ⋆₁) = default_dec_matrix_generate(mesh, :⋆₁, hodge)
      (var"M_⋆₀⁻¹", ⋆₀⁻¹) = default_dec_matrix_generate(mesh, :⋆₀⁻¹, hodge)
      exp = operators(mesh, :exp)
      sqrt = operators(mesh, :sqrt)
      log10 = operators(mesh, :log10)
      avg₀₁ = operators(mesh, :avg₀₁)
      #(.^) = operators(mesh, :.^)
      #(^) = operators(mesh, :^)
      #(.>) = operators(mesh, :.>)
      #(.≤) = operators(mesh, :.≤)
      (∧ᵖᵈ) = operators(mesh, :∧ᵖᵈ)
  end
  #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:429 =#
  begin
      #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:214 =#
      var"Veronis_•8" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Veronis_•7" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Veronis_•9" = Vector{Float64}(undef, nparts(mesh, :Tri))
      Veronis_Ḃ = Vector{Float64}(undef, nparts(mesh, :Tri))
      var"Veronis_•16" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Heidler_•2" = Vector{Float64}(undef, nparts(mesh, :E))
      Heidler_tret = Vector{Float64}(undef, nparts(mesh, :E))
      var"Heidler_•4" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Heidler_•17" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Heidler_•16" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Veronis_•5" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Veronis_•19" = Vector{Float64}(undef, nparts(mesh, :V))
      var"Veronis_•22" = Vector{Float64}(undef, nparts(mesh, :V))
      var"Veronis_•25" = Vector{Float64}(undef, nparts(mesh, :V))
      var"Veronis_•24" = Vector{Float64}(undef, nparts(mesh, :V))
      var"Veronis_•11" = Vector{Float64}(undef, nparts(mesh, :V))
      Veronis_θ = Vector{Float64}(undef, nparts(mesh, :V))
      var"Veronis_•29" = Vector{Float64}(undef, nparts(mesh, :V))
      var"Veronis_•33" = Vector{Float64}(undef, nparts(mesh, :V))
      J = Vector{Float64}(undef, nparts(mesh, :E))
      var"Veronis_•4" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Veronis_•3" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Veronis_•2" = Vector{Float64}(undef, nparts(mesh, :E))
      var"Veronis_•1" = Vector{Float64}(undef, nparts(mesh, :E))
      Veronis_Ė = Vector{Float64}(undef, nparts(mesh, :E))
  end
  #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:430 =#
  f(du, u, p, t) = begin
          #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:430 =#
          #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:431 =#
          begin
              #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:236 =#
              Heidler_Z = (findnode(u, :Heidler_Z)).values
              Heidler_ρ = (findnode(u, :Heidler_ρ)).values
              Heidler_τ₁ = p.Heidler_τ₁
              Heidler_τ₂ = p.Heidler_τ₂
              Heidler_I₀ = p.Heidler_I₀
              Heidler_v = p.Heidler_v
              Heidler_n = p.Heidler_n
              Heidler_a = p.Heidler_a
              Heidler_η = p.Heidler_η
              Heidler_z₀ = p.Heidler_z₀
              Heidler_π = p.Heidler_π
              Heidler_ρ₀ = p.Heidler_ρ₀
              Heidler_t = p.Heidler_t(t)
              Veronis_B = (findnode(u, :Veronis_B)).values
              Veronis_E = (findnode(u, :Veronis_E)).values
              Veronis_ρ_e = (findnode(u, :Veronis_ρ_e)).values
              Veronis_ρ_gas = (findnode(u, :Veronis_ρ_gas)).values
              Veronis_Tn = (findnode(u, :Veronis_Tn)).values
              Veronis_qₑ = p.Veronis_qₑ
              Veronis_c = p.Veronis_c
              Veronis_ε₀ = p.Veronis_ε₀
              var"1.0" = 1.0
              var"2" = 2.0
              var"1" = 1.0
              var"-1" = -1.0
              var"0" = 0.0
              var"-1.0" = -1.0
              var"-1" = -1.0
              var"2" = 2.0
              var"3.656e25" = 3.656e25
              var"1.0e21" = 1.0e21
              var"1.0e6" = 1.0e6
              var"200.0" = 200.0
              var"0.0603" = 0.0603
              var"200" = 200.0
              var"10" = 10.0
              var"50.97" = 50.97
              var"3.026" = 3.026
              var"1.0e-21" = 1.0e-21
              var"0.084733" = 0.084733
              @show Heidler_t
          end
          #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:432 =#
          mul!(var"Veronis_•8", M_dual_d₀, Veronis_B)
          mul!(var"Veronis_•7", var"M_⋆₁⁻¹", var"Veronis_•8")
          mul!(var"Veronis_•9", M_d₁, Veronis_E)
          mul!(Veronis_Ḃ, var"M_⋆₂", var"Veronis_•9")
          mul!(var"Veronis_•16", var"M_⋆₁", Veronis_E)
          var"Heidler_•2" .= Heidler_Z ./ Heidler_v
          Heidler_tret .= Heidler_t .- var"Heidler_•2"
          var"Heidler_•4" .= Heidler_tret ./ Heidler_τ₁
          Heidler_temp = var"Heidler_•4" .^ Heidler_n
          var"Heidler_•13" = Heidler_ρ₀ ^ var"2"
          var"Heidler_•12" = Heidler_π .* var"Heidler_•13"
          var"Heidler_•11" = var"1.0" / var"Heidler_•12"
          var"Heidler_•10" = var"Heidler_•11" .* Heidler_I₀
          var"Heidler_•9" = var"Heidler_•10" / Heidler_η
          var"Heidler_•8" = var"Heidler_•9" .* Heidler_temp
          var"Heidler_•14" = var"1" .+ Heidler_temp
          var"Heidler_•7" = var"Heidler_•8" ./ var"Heidler_•14"
          var"Heidler_•17" .= var"-1" .* Heidler_tret
          var"Heidler_•16" .= var"Heidler_•17" ./ Heidler_τ₂
          var"Heidler_•18" = Heidler_tret .> var"0"
          var"Heidler_•21" = Heidler_Z .≤ Heidler_a
          var"Heidler_•25" = Heidler_ρ .^ var"2"
          var"Heidler_•24" = var"-1.0" .* var"Heidler_•25"
          var"Heidler_•26" = Heidler_ρ₀ .^ var"2"
          var"Heidler_•23" = var"Heidler_•24" / var"Heidler_•26"
          var"Heidler_•29" = Heidler_Z .> Heidler_a
          var"Heidler_•34" = Heidler_ρ .^ var"2"
          var"Heidler_•33" = var"-1.0" .* var"Heidler_•34"
          var"Heidler_•35" = Heidler_ρ₀ ^ var"2"
          var"Heidler_•32" = var"Heidler_•33" / var"Heidler_•35"
          var"Heidler_•3" = Heidler_Z .- Heidler_a
          var"Heidler_•1" = var"Heidler_•3" .^ var"2"
          var"Heidler_•5" = Heidler_z₀ ^ var"2"
          var"Heidler_•36" = var"Heidler_•1" / var"Heidler_•5"
          var"Heidler_•31" = var"Heidler_•32" .- var"Heidler_•36"
          var"Veronis_•6" = Veronis_c ^ var"2"
          var"Veronis_•5" .= var"Veronis_•6" .* var"Veronis_•7"
          var"Veronis_•13" = var"1.0e21" / var"1.0e6"
          var"Veronis_•15" = Veronis_E ∧ᵖᵈ var"Veronis_•16"
          var"Veronis_•19" .= var"200" ./ Veronis_Tn
          var"Veronis_•22" .= var"200" ./ Veronis_Tn
          var"Veronis_•25" .= Veronis_qₑ .* Veronis_ρ_e
          var"Veronis_•24" .= var"Veronis_•25" ./ Veronis_ρ_gas
          Veronis_mult_1 = Veronis_qₑ .* var"3.656e25"
          Veronis_mult_2 = Veronis_mult_1 .* Veronis_ρ_e
          var"Veronis_•35" = Veronis_mult_2 ./ Veronis_ρ_gas
          var"Veronis_•11" .= var"200.0" ./ Veronis_Tn
          var"Heidler_•15" = exp(var"Heidler_•16")
          var"Heidler_•22" = exp(var"Heidler_•23")
          var"Heidler_•30" = exp(var"Heidler_•31")
          var"Veronis_•14" = (⋆₀⁻¹)(var"Veronis_•15")
          var"Veronis_•18" = sqrt(var"Veronis_•19")
          var"Veronis_•21" = sqrt(var"Veronis_•22")
          var"Veronis_•10" = sqrt(var"Veronis_•11")
          var"Heidler_•6" = var"Heidler_•7" .* var"Heidler_•15"
          Heidler_J₀ = var"Heidler_•6" .* var"Heidler_•18"
          var"Heidler_•20" = var"Heidler_•21" .* Heidler_J₀
          var"Heidler_•19" = var"Heidler_•20" .* var"Heidler_•22"
          var"Heidler_•28" = var"Heidler_•29" .* Heidler_J₀
          var"Heidler_•27" = var"Heidler_•28" .* var"Heidler_•30"
          var"Veronis_•12" = var"Veronis_•13" .* var"Veronis_•14"
          Veronis_θ .= var"Veronis_•12" ./ Veronis_ρ_gas
          var"Veronis_•17" = var"0.0603" .* var"Veronis_•18"
          Veronis_Eq5_2a_mask = Veronis_θ .> var"Veronis_•17"
          var"Veronis_•20" = var"0.0603" .* var"Veronis_•21"
          Veronis_Eq5_2b_mask = Veronis_θ .≤ var"Veronis_•20"
          var"Veronis_•29" .= var"1.0e-21" .* Veronis_θ
          var"Veronis_•33" .= var"1.0e-21" .* Veronis_θ
          Veronis_Eq5_2b = var"Veronis_•35" .* var"Veronis_•10"
          var"Veronis_•34" = Veronis_Eq5_2b_mask .* Veronis_Eq5_2b
          J .= (.+)(var"Heidler_•19", var"Heidler_•27")
          var"Veronis_•28" = log10(var"Veronis_•29")
          var"Veronis_•32" = log10(var"Veronis_•33")
          var"Veronis_•27" = var"3.026" .* var"Veronis_•28"
          var"Veronis_•31" = var"Veronis_•32" .^ var"2"
          var"Veronis_•30" = var"0.084733" .* var"Veronis_•31"
          Veronis_sum_2 = (.+)(var"50.97", var"Veronis_•27", var"Veronis_•30")
          var"Veronis_•26" = var"10" .^ Veronis_sum_2
          Veronis_Eq5_2a = var"Veronis_•24" .* var"Veronis_•26"
          var"Veronis_•23" = Veronis_Eq5_2a_mask .* Veronis_Eq5_2a
          Veronis_sum_1 = (.+)(var"Veronis_•23", var"Veronis_•34")
          Veronis_σ = avg₀₁(Veronis_sum_1)
          var"Veronis_•4" .= Veronis_σ .* Veronis_E
          var"Veronis_•3" .= J .- var"Veronis_•4"
          var"Veronis_•2" .= var"-1" .* var"Veronis_•3"
          var"Veronis_•1" .= var"Veronis_•2" ./ Veronis_ε₀
          Veronis_Ė .= (.+)(var"Veronis_•1", var"Veronis_•5")
          #= c:\Users\lukel\Prgming\Decapodes.jl\src\simulation.jl:433 =#
          (findnode(du, :Veronis_E)).values .= Veronis_Ė
          (findnode(du, :Veronis_B)).values .= Veronis_Ḃ
      end
end

constants_and_parameters = (
  #mₑ = mₑ,
  #μ₀ = μ₀,
  #Z₀ = Z₀,
  #e = e,
  Veronis_ρ_gas = densities[:gas],
  Veronis_Tn = Tn,
  Chemistry_kB = kB,
  Veronis_qₑ = qₑ,
  Veronis_c = c,
  Veronis_ε₀ = ε₀,
  Heidler_τ₁ = τ₁,
  Heidler_τ₂ = τ₂,
  Heidler_I₀ = I₀,
  Heidler_v = v,
  Heidler_n = n,
  Heidler_a = a,
  Heidler_η = η,
  Heidler_t = t -> t,
  Heidler_z₀ = z₀,
  Heidler_π = π,
  Heidler_ρ₀ = ρ₀)

foo = simulate(sd, generate)
du₀ = deepcopy(u₀)
foo(du₀, u₀, constants_and_parameters, 1e-1)

sum(findnode(du₀, :Veronis_B))
sum(findnode(du₀, :Veronis_E))
prob = ODEProblem(foo, u₀, (0, 1e-9), constants_and_parameters)
soln = solve(prob, Tsit5())

foo(du₀, u₀, constants_and_parameters, 9.8e-10)

sum(findnode(du₀, :Veronis_E))
