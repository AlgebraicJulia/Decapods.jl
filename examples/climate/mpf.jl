# Import Dependencies 

## AlgebraicJulia Dependencies
using ACSets
using CombinatorialSpaces
using DiagrammaticEquations
using Decapodes

## External Dependencies
using ComponentArrays
using CairoMakie
using Distributions
using GeometryBasics: Point3
using JLD2
using LinearAlgebra
using MLStyle
using OrdinaryDiffEq
using Random
Point3D = Point3{Float64}

Random.seed!(0)

# Define Models

## Define vorticity streamflow formulation

Eq11InviscidPoisson = @decapode begin
  d𝐮::DualForm2
  𝐮::DualForm1
  ψ::Form0
  μ::Constant

  ψ == Δ₀⁻¹(⋆(d𝐮))
  𝐮 == ⋆(d(ψ))

  ∂ₜ(d𝐮) == μ * ∘(⋆, d, ⋆, d)(d𝐮) - ∘(♭♯, ⋆₁, d̃₁)(∧ᵈᵖ₁₀(𝐮, ⋆(d𝐮)))
end

to_graphviz(Eq11InviscidPoisson)
(to_graphviz ∘ resolve_overloads! ∘ infer_types! ∘ expand_operators)(Eq11InviscidPoisson)

## Apply boundary conditions with a collage

VorticityBoundaries = @decapode begin
  U::DualForm1
  DU::DualForm2
end
VorticityMorphism = @relation () begin
  bound_dual1form(Flow, FlowBoundaryValues)
  bound_dual2form(Vorticity, VorticityBoundaryValues)
end
VorticitySymbols = Dict(
  :Flow => :𝐮,
  :FlowBoundaryValues => :U,
  :Vorticity => :d𝐮,
  :VorticityBoundaryValues => :DU)
VorticityBounded = collate(
  Eq11InviscidPoisson,
  VorticityBoundaries,
  VorticityMorphism,
  VorticitySymbols)

to_graphviz(VorticityBounded)

## Define phase segmentation process

CahnHilliard = @decapode begin
  C::Form0
  𝐯::DualForm1
  (D,γ)::Constant
  ∂ₜ(C) == D * ∘(⋆,d,⋆)(
    d(C^3 - C - γ * Δ(C)) +
    C ∧ ♭♯(𝐯))
end

to_graphviz(CahnHilliard)

## Compose bounded Navier-Stokes with phase field

NSPhaseFieldDiagram = @relation () begin
  navierstokes(𝐮)

  phasefield(𝐮)
end

draw_composition(NSPhaseFieldDiagram)

vort_ch = apex(oapply(NSPhaseFieldDiagram,
  [Open(VorticityBounded, [:𝐮]),
   Open(CahnHilliard, [:𝐯])]))

to_graphviz(vort_ch)

vort_ch = (resolve_overloads! ∘ infer_types! ∘ expand_operators)(vort_ch)

to_graphviz(vort_ch)

# Define the mesh

s = triangulated_grid(1.0, 1.0, 0.0125, 0.0125, Point3D)
sd = EmbeddedDeltaDualComplex2D{Bool, Float64, Point3D}(s)
subdivide_duals!(sd, Circumcenter())

f = Figure()
ax = CairoMakie.Axis(f[1,1])
wireframe!(ax, s, linewidth=2)
wireframe!(ax, sd)
f

# Define constants, parameters, and initial conditions

## This is a dual 2-form, with values at the dual cells around primal vertices.
★ = dec_hodge_star(0,sd)
#d𝐮₀ = ★ * ones(nv(sd))
distribution = MvNormal([0.5, 0.5, 0.0], Diagonal([1/8, 1/8, 1e-9]))
d𝐮₀ = normalize(★ * map(x -> pdf(distribution, x), point(sd)), 1)
DU₀ = zeros(nv(sd))

## This is a dual 1-form, with values orthogonal to primal edges.
U₀ = zeros(ne(sd))

## This is a primal 0-form, with values at primal vertices.
C₀ = (rand(nv(sd)) .- 0.5) * 2

## Store these values to be passed to the solver.
u₀ = ComponentArray(
  navierstokes_d𝐮 = d𝐮₀,
  navierstokes_U = U₀,
  navierstokes_DU = DU₀,
  phasefield_C = C₀)

constants_and_parameters = (
  navierstokes_μ = 1e-3,
  phasefield_D = 5e-3,
  phasefield_γ = (1e-2)^2)

# Define how symbols map to Julia functions

boundary_edges = boundary_inds(Val{1}, sd)
boundary_vertices = boundary_inds(Val{0}, sd)

function simple_dual1form_bounds(form, bvals)
  form[boundary_edges] = bvals[boundary_edges]
  form
end
function simple_dual2form_bounds(form, bvals)
  form[boundary_vertices] = bvals[boundary_vertices]
  form
end

function generate(sd, my_symbol; hodge=GeometricHodge())
  op = @match my_symbol begin
    :bound_dual1form => simple_dual1form_bounds
    :bound_dual2form => simple_dual2form_bounds
    x => error("$x not matched")
  end
  return (args...) -> op(args...)
end

# Generate simulation 

## Write the simulation code to a file.
open("collage_mpf.jl", "w") do f
  write(f, string(gensim(vort_ch)))
end
#sim = include("collage_mpf.jl") # in VSCode: sim = include("../../collage_mpf.jl")
sim = include("../../collage_mpf.jl")

## Generate the simulation
fₘ = sim(sd, generate)

## Run simulation 

tₑ = 1e0

# Julia will pre-compile the generated simulation the first time it is run.
@info("Precompiling Solver")
prob = ODEProblem(fₘ, u₀, (0, 1e-8), constants_and_parameters)
soln = solve(prob, Tsit5())
soln.retcode != :Unstable || error("Solver was not stable")

# This next run should be fast.
@info("Solving")
prob = ODEProblem(fₘ, u₀, (0, tₑ), constants_and_parameters)
soln = solve(prob, Tsit5())
@show soln.retcode
@info("Done")

@save "collage_mpf.jld2" soln

# Visualize 
★ = dec_inv_hodge_star(0,sd)
f = Figure()
ax = CairoMakie.Axis(f[1,1])
sctr = scatter!(ax, point(sd), color= ★ * soln(tₑ).navierstokes_d𝐮)
Colorbar(f[1,2], sctr)
ax2 = CairoMakie.Axis(f[2,1])
sctr2 = scatter!(ax2, point(sd), color= ★ * soln(0).navierstokes_d𝐮)
Colorbar(f[2,2], sctr2)
ax3 = CairoMakie.Axis(f[3,1])
sctr3 = scatter!(ax3, point(sd), color= ★ * (soln(tₑ).navierstokes_d𝐮 - soln(0).navierstokes_d𝐮))
Colorbar(f[3,2], sctr3)
f

f = Figure()
ax = CairoMakie.Axis(f[1,1])
msh = mesh!(ax, s, color=soln(tₑ).phasefield_C)
Colorbar(f[1,2], msh)
f
