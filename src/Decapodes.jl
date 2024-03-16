module Decapodes

using Catlab
using Catlab.Theories
using Catlab.Programs
using Catlab.CategoricalAlgebra
using Catlab.WiringDiagrams
using Catlab.WiringDiagrams.DirectedWiringDiagrams
using Catlab.ACSetInterface
using MLStyle
using Base.Iterators
using SparseArrays
using PreallocationTools

using DiagrammaticEquations
using DiagrammaticEquations.Deca

export
flat_op,
gensim, evalsim, closest_point, compile, compile_env, default_dec_matrix_generate, default_dec_generate, default_dec_generate,
CartesianPoint, SpherePoint, r, theta, phi, TangentBasis, θhat, ϕhat  

append_dot(s::Symbol) = Symbol(string(s)*'\U0307')

include("coordinates.jl")
include("operators.jl")
include("simulation.jl")

# documentation
include("canon/Canon.jl")

end
