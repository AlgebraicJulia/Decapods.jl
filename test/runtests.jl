using Test

@testset "Code Quality (Aqua.jl)" begin
  include("aqua.jl")
end

@testset "Coordinates" begin
  include("coordinates.jl")
end

@testset "ComponentArrays.jl Integration" begin
  include("componentarrays.jl")
end

@testset "Simulation" begin
  include("simulation.jl")
end


