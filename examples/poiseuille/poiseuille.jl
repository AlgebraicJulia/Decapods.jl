using CombinatorialSpaces
using CombinatorialSpaces.ExteriorCalculus
import Catlab.Theories: otimes, oplus, compose, ⊗, ⊕, ⋅, associate, associate_unit, Ob, Hom, dom, codom
using Catlab.Theories
using Catlab.Present
using Catlab.Graphics
using Catlab.Syntax
using Catlab.CategoricalAlgebra
using LinearAlgebra

using Decapodes.Simulations
using Decapodes.Examples
using Decapodes.Diagrams
using Decapodes.Schedules

# Julia community libraries
using MeshIO
using CairoMakie
using Decapodes.Debug
using DifferentialEquations
using Logging: global_logger
using TerminalLoggers: TerminalLogger
global_logger(TerminalLogger())




""" Decapodes2D
A schema which includes any homomorphisms that may be added by the @decapode
macro.

TODO: This should be chipped away at as more of this tooling takes advantage
of the Catlab GAT system
"""


@present Decapodes1D(FreeExtCalc1D) begin
  X::Space
  proj₁_⁰⁰₀::Hom(Form0(X)⊗Form0(X),Form0(X))
  proj₂_⁰⁰₀::Hom(Form0(X)⊗Form0(X),Form0(X))
  proj₁_⁰⁰₀⁺::Hom(Form0(X)⊕Form0(X),Form0(X))
  proj₂_⁰⁰₀⁺::Hom(Form0(X)⊕Form0(X),Form0(X))
  proj₁_⁰¹₀::Hom(Form0(X)⊗Form1(X),Form0(X))
  proj₂_⁰¹₁::Hom(Form0(X)⊗Form1(X),Form1(X))
  proj₁_⁰¹₀⁺::Hom(Form0(X)⊕Form1(X),Form0(X))
  proj₂_⁰¹₁⁺::Hom(Form0(X)⊕Form1(X),Form1(X))
  proj₁_⁰⁰̃₀::Hom(Form0(X)⊗DualForm0(X),Form0(X))
  proj₂_⁰⁰̃₀̃::Hom(Form0(X)⊗DualForm0(X),DualForm0(X))
  proj₁_⁰⁰̃₀⁺::Hom(Form0(X)⊕DualForm0(X),Form0(X))
  proj₂_⁰⁰̃₀̃⁺::Hom(Form0(X)⊕DualForm0(X),DualForm0(X))
  proj₁_⁰¹̃₀::Hom(Form0(X)⊗DualForm1(X),Form0(X))
  proj₂_⁰¹̃₁̃::Hom(Form0(X)⊗DualForm1(X),DualForm1(X))
  proj₁_⁰¹̃₀⁺::Hom(Form0(X)⊕DualForm1(X),Form0(X))
  proj₂_⁰¹̃₁̃⁺::Hom(Form0(X)⊕DualForm1(X),DualForm1(X))
  proj₁_¹⁰₁::Hom(Form1(X)⊗Form0(X),Form1(X))
  proj₂_¹⁰₀::Hom(Form1(X)⊗Form0(X),Form0(X))
  proj₁_¹⁰₁⁺::Hom(Form1(X)⊕Form0(X),Form1(X))
  proj₂_¹⁰₀⁺::Hom(Form1(X)⊕Form0(X),Form0(X))
  proj₁_¹¹₁::Hom(Form1(X)⊗Form1(X),Form1(X))
  proj₂_¹¹₁::Hom(Form1(X)⊗Form1(X),Form1(X))
  proj₁_¹¹₁⁺::Hom(Form1(X)⊕Form1(X),Form1(X))
  proj₂_¹¹₁⁺::Hom(Form1(X)⊕Form1(X),Form1(X))
  proj₁_¹⁰̃₁::Hom(Form1(X)⊗DualForm0(X),Form1(X))
  proj₂_¹⁰̃₀̃::Hom(Form1(X)⊗DualForm0(X),DualForm0(X))
  proj₁_¹⁰̃₁⁺::Hom(Form1(X)⊕DualForm0(X),Form1(X))
  proj₂_¹⁰̃₀̃⁺::Hom(Form1(X)⊕DualForm0(X),DualForm0(X))
  proj₁_¹¹̃₁::Hom(Form1(X)⊗DualForm1(X),Form1(X))
  proj₂_¹¹̃₁̃::Hom(Form1(X)⊗DualForm1(X),DualForm1(X))
  proj₁_¹¹̃₁⁺::Hom(Form1(X)⊕DualForm1(X),Form1(X))
  proj₂_¹¹̃₁̃⁺::Hom(Form1(X)⊕DualForm1(X),DualForm1(X))
  proj₁_⁰̃⁰₀̃::Hom(DualForm0(X)⊗Form0(X),DualForm0(X))
  proj₂_⁰̃⁰₀::Hom(DualForm0(X)⊗Form0(X),Form0(X))
  proj₁_⁰̃⁰₀̃⁺::Hom(DualForm0(X)⊕Form0(X),DualForm0(X))
  proj₂_⁰̃⁰₀⁺::Hom(DualForm0(X)⊕Form0(X),Form0(X))
  proj₁_⁰̃¹₀̃::Hom(DualForm0(X)⊗Form1(X),DualForm0(X))
  proj₂_⁰̃¹₁::Hom(DualForm0(X)⊗Form1(X),Form1(X))
  proj₁_⁰̃¹₀̃⁺::Hom(DualForm0(X)⊕Form1(X),DualForm0(X))
  proj₂_⁰̃¹₁⁺::Hom(DualForm0(X)⊕Form1(X),Form1(X))
  proj₁_⁰̃⁰̃₀̃::Hom(DualForm0(X)⊗DualForm0(X),DualForm0(X))
  proj₂_⁰̃⁰̃₀̃::Hom(DualForm0(X)⊗DualForm0(X),DualForm0(X))
  proj₁_⁰̃⁰̃₀̃⁺::Hom(DualForm0(X)⊕DualForm0(X),DualForm0(X))
  proj₂_⁰̃⁰̃₀̃⁺::Hom(DualForm0(X)⊕DualForm0(X),DualForm0(X))
  proj₁_⁰̃¹̃₀̃::Hom(DualForm0(X)⊗DualForm1(X),DualForm0(X))
  proj₂_⁰̃¹̃₁̃::Hom(DualForm0(X)⊗DualForm1(X),DualForm1(X))
  proj₁_⁰̃¹̃₀̃⁺::Hom(DualForm0(X)⊕DualForm1(X),DualForm0(X))
  proj₂_⁰̃¹̃₁̃⁺::Hom(DualForm0(X)⊕DualForm1(X),DualForm1(X))
  proj₁_¹̃⁰₁̃::Hom(DualForm1(X)⊗Form0(X),DualForm1(X))
  proj₂_¹̃⁰₀::Hom(DualForm1(X)⊗Form0(X),Form0(X))
  proj₁_¹̃⁰₁̃⁺::Hom(DualForm1(X)⊕Form0(X),DualForm1(X))
  proj₂_¹̃⁰₀⁺::Hom(DualForm1(X)⊕Form0(X),Form0(X))
  proj₁_¹̃¹₁̃::Hom(DualForm1(X)⊗Form1(X),DualForm1(X))
  proj₂_¹̃¹₁::Hom(DualForm1(X)⊗Form1(X),Form1(X))
  proj₁_¹̃¹₁̃⁺::Hom(DualForm1(X)⊕Form1(X),DualForm1(X))
  proj₂_¹̃¹₁⁺::Hom(DualForm1(X)⊕Form1(X),Form1(X))
  proj₁_¹̃⁰̃₁̃::Hom(DualForm1(X)⊗DualForm0(X),DualForm1(X))
  proj₂_¹̃⁰̃₀̃::Hom(DualForm1(X)⊗DualForm0(X),DualForm0(X))
  proj₁_¹̃⁰̃₁̃⁺::Hom(DualForm1(X)⊕DualForm0(X),DualForm1(X))
  proj₂_¹̃⁰̃₀̃⁺::Hom(DualForm1(X)⊕DualForm0(X),DualForm0(X))
  proj₁_¹̃¹̃₁̃::Hom(DualForm1(X)⊗DualForm1(X),DualForm1(X))
  proj₂_¹̃¹̃₁̃::Hom(DualForm1(X)⊗DualForm1(X),DualForm1(X))
  proj₁_¹̃¹̃₁̃⁺::Hom(DualForm1(X)⊕DualForm1(X),DualForm1(X))
  proj₂_¹̃¹̃₁̃⁺::Hom(DualForm1(X)⊕DualForm1(X),DualForm1(X))
  sum₀::Hom(Form0(X)⊗Form0(X),Form0(X))
  sum₁::Hom(Form1(X)⊗Form1(X),Form1(X))
  sum₀̃::Hom(DualForm0(X)⊗DualForm0(X),DualForm0(X))
  sum₁̃::Hom(DualForm1(X)⊗DualForm1(X),DualForm1(X))
end

@present Poiseuille <: Decapodes1D begin
  (R, μ̃)::Hom(Form1(X), Form1(X))
  # μ̃ = negative viscosity per unit area
  # R = drag of pipe boundary
end;

Poise = @decapode Poiseuille begin
  (∇P)::Form1{X}
  (q, q̇, Δq)::DualForm1{X}
  P::Form0{X}

  Δq == d₀{X}(⋆₀⁻¹{X}(dual_d₀{X}(⋆₁{X}(q))))
  q̇ == sum₁(sum₁(μ̃(Δq), ∇P),R(q))
  ∂ₜ{Form1{X}}(q) == q̇
  ∇P == d₀{X}(P)
end;

##
function create_funcs(ds)
  Dict{Symbol, Dict}()
  subdivide_duals!(ds, Circumcenter())
  funcs[:⋆₁] = Dict(:operator => ⋆(Val{1}, ds, hodge=DiagonalHodge()),
                    :type => MatrixFunc());
  funcs[:⋆₀] = Dict(:operator => ⋆(Val{0}, ds, hodge=DiagonalHodge()),
                    :type => MatrixFunc());
  funcs[:⋆₀⁻¹] = Dict(:operator => inv(⋆(Val{0}, ds, hodge=DiagonalHodge())), #I(nv(ds)), #
                    :type => MatrixFunc());
  funcs[:⋆₁⁻¹] = Dict(:operator => inv(⋆(Val{1}, ds, hodge=DiagonalHodge())),
                    :type => MatrixFunc());
  funcs[:d₀] = Dict(:operator => d(Val{0}, ds), :type => MatrixFunc());
  funcs[:dual_d₀] = Dict(:operator => dual_derivative(Val{0}, ds), :type => MatrixFunc());
  funcs[:μ̃] = Dict(:operator => 0.5 * diagm(vcat([0,ones(Int,ne(ds)-2)...,0])), :type => MatrixFunc())
  funcs[:sum₁] = Dict(:operator => (x′, x, y)->(x′ .= x .+ y), :type => InPlaceFunc())
  funcs[:R] = Dict(:operator => -0.1 * I(ne(ds)), :type => MatrixFunc())
  return funcs
end

form2dim = Dict(:Scalar => x->1,
                :Form0 => nv,
                :Form1 => ne,
                :DualForm1 => nv,
                :DualForm0 => ne)

##
Point3D = Point3{Float64}
s = EmbeddedDeltaSet1D{Bool,Point3D}()
add_vertices!(s, 2, point=[Point3D(-1, 0, 0), Point3D(+1, 0, 0)])
add_edge!(s, 1, 2, edge_orientation=true)

ds = EmbeddedDeltaDualComplex1D{Bool,Float64,Point3D}(s)
funcs = create_funcs(ds)
func, code = gen_sim(diag2dwd(Poise), funcs, ds; autodiff=false, form2dim=form2dim, params=[:P]);
prob = ODEProblem(func, [2.], (0.0, 10000.0), [1.,11.])
sol = solve(prob, Tsit5(); progress=true);
sol.u

#####
function linear_pipe(n::Int)
  s = EmbeddedDeltaSet1D{Bool,Point3D}()
  add_vertices!(s, n, point=[Point3D(i, 0, 0) for i in 1:n])
  add_edges!(s, 1:n-1, 2:n, edge_orientation=true)
  orient!(s)
  ds = EmbeddedDeltaDualComplex1D{Bool,Float64,Point3D}(s)
  funcs = create_funcs(ds)
  func, code = gen_sim(diag2dwd(Poise), funcs, ds; autodiff=false, form2dim=form2dim, params=[:P])
  return func
end

func = linear_pipe(10)
prob = ODEProblem(func, [5,3,4,2,5,2,8,4,3], (0.0, 10000.0), [10. *i for i in 1:10])
sol = solve(prob, Tsit5(); progress=true);
sol.u



end