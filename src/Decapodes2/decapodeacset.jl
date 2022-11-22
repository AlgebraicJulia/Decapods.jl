#using AlgebraicRewriting
#using AlgebraicRewriting: Var as ARVar

@present SchDecapode(FreeSchema) begin
    (Var, TVar, Op1, Op2)::Ob
    (Type, Operator)::AttrType
    src::Hom(Op1, Var)
    tgt::Hom(Op1, Var)
    proj1::Hom(Op2, Var)
    proj2::Hom(Op2, Var)
    res::Hom(Op2, Var)
    incl::Hom(TVar, Var)
    
    op1::Attr(Op1, Operator)
    op2::Attr(Op2, Operator)
    type::Attr(Var, Type)
end

@present SchNamedDecapode <: SchDecapode begin
    Name::AttrType
    name::Attr(Var, Name)
end

@abstract_acset_type AbstractDecapode
@abstract_acset_type AbstractNamedDecapode <: AbstractDecapode

@acset_type Decapode(SchDecapode,
  index=[:src, :tgt, :res, :incl, :op1, :op2, :type]) <: AbstractDecapode

@acset_type NamedDecapode(SchNamedDecapode,
  index=[:src, :tgt, :res, :incl, :op1, :op2, :type, :name]) <: AbstractNamedDecapode

"""    fill_names!

add new variable names to all the variables that don't have names.
"""
function fill_names!(d::AbstractNamedDecapode)
    bulletcount = 1
    for i in parts(d, :Var)
        if !isassigned(d[:,:name],i)
            d[i,:name] = Symbol("•$bulletcount")
            bulletcount += 1
        end
    end
    for e in incident(d, :∂ₜ, :op1)
        s = d[e,:src]
        t = d[e, :tgt]
        d[t, :name] = append_dot(d[s,:name])
    end
    return d
end

function make_sum_unique!(d::AbstractNamedDecapode)
  num = 1
  for (i, name) in enumerate(d[:name])
    if(name == :sum)
      d[i, :name] = Symbol(join([String(name), string(num)] , "_"))
      num += 1
    end
  end
end

function expand_operators(d::AbstractNamedDecapode)
  e = SummationDecapode{Symbol, Symbol, Symbol}()
  copy_parts!(e, d, (:Var, :TVar, :Op2))
  expand_operators!(e, d)
  return e
end


function expand_operators!(e::AbstractNamedDecapode, d::AbstractNamedDecapode)
  newvar = 0
  for op in parts(d, :Op1)
    if !isa(d[op,:op1], AbstractArray)
      add_part!(e, :Op1, op1=d[op,:op1], src=d[op, :src], tgt=d[op,:tgt])
    else
      for (i, step) in enumerate(d[op, :op1])
        if i == 1
          newvar = add_part!(e, :Var, type=:infer, name=Symbol("•_$(op)_$(i)"))
          add_part!(e, :Op1, op1=step, src=d[op, :src], tgt=newvar)
        elseif i == length(d[op, :op1])
          add_part!(e, :Op1, op1=step, src=newvar, tgt=d[op,:tgt])
        else
          newvar′ = add_part!(e, :Var, type=:infer, name=Symbol("•_$(op)_$(i)"))
          add_part!(e, :Op1, op1=step, src=newvar, tgt=newvar′)
          newvar = newvar′
        end
      end
    end
  end
  return newvar
end
@present SchSummationDecapode <: SchNamedDecapode begin
  # Σ are the white nodes in the Decapode drawing
  # Summands are the edges that connect white nodes to variables (the projection maps)
  # because addition is commutative, we don't need to distinguish the order
  (Σ, Summand)::Ob
  summand::Hom(Summand, Var)
  summation::Hom(Summand, Σ)
  sum::Hom(Σ, Var)
end

@acset_type SummationDecapode(SchSummationDecapode,
  index=[:src, :tgt, :res, :incl, :op1, :op2, :type]) <: AbstractNamedDecapode


function expand_operators(d::SummationDecapode)
  e = SummationDecapode{Symbol, Symbol, Symbol}()
  copy_parts!(e, d, (:Var, :TVar, :Op2, :Σ, :Summand))
  expand_operators!(e, d)
  return e
end

function add_constant!(d::AbstractNamedDecapode, k::Symbol)
    return add_part!(d, :Var, type=:Constant, name=k)
end

function add_parameter(d::AbstractNamedDecapode, k::Symbol)
    return add_part!(d, :Var, type=:Parameter, name=k)
end


#"""
#These are the default rewrite rules used to do type inference.
#"""
#default_op1_type_inference_rules = [
#  # The tgt of ∂ₜ is of the same type as its src.
#  begin
#    L = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; TVar = 1; Op1 = 1
#
#      type = [ARVar(:src_form), :infer]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      incl = [2]
#      src = [1]
#      tgt = [2]
#      op1 = [:∂ₜ]
#    end
#    I = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 1
#      type = [ARVar(:src_form)]
#      name = [ARVar(:src_name)]
#    end
#    R = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; TVar = 1; Op1 = 1
#
#      type = [ARVar(:src_form), ARVar(:src_form)]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      incl = [2]
#      src = [1]
#      tgt = [2]
#      op1 = [:∂ₜ]
#    end
#    hil = AlgebraicRewriting.homomorphism(I, L)
#    hir = AlgebraicRewriting.homomorphism(I, R)
#    Rule(hil, hir)
#  end,
#  # The src of ∂ₜ is of the same type as its tgt.
#  begin
#    L = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; TVar = 1; Op1 = 1
#
#      type = [:infer, ARVar(:tgt_form)]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      incl = [2]
#      src = [1]
#      tgt = [2]
#      op1 = [:∂ₜ]
#    end
#    I = @acset SummationDecapode{Any, Any, Any} begin
#      #Var = 1
#      #type = [ARVar(:tgt_form)]
#      #name = [ARVar(:tgt_name)]
#      Var = 1; TVar = 1
#      type = [ARVar(:tgt_form)]
#      name = [ARVar(:tgt_name)]
#      incl = [1]
#    end
#    R = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; TVar = 1; Op1 = 1
#
#      type = [ARVar(:tgt_form), ARVar(:tgt_form)]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      incl = [2]
#      src = [1]
#      tgt = [2]
#      op1 = [:∂ₜ]
#    end
#    hil = AlgebraicRewriting.homomorphism(I, L)
#    hir = AlgebraicRewriting.homomorphism(I, R)
#    Rule(hil, hir)
#  end,
#  # The tgt of d of a Form0 is of the type Form1.
#  begin
#    L = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; Op1 = 1
#
#      type = [:Form0, :infer]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      src = [1]
#      tgt = [2]
#      op1 = [:d]
#    end
#    I = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 1
#      type = [:Form0]
#      name = [ARVar(:src_name)]
#    end
#    R = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; Op1 = 1
#
#      type = [:Form0, :Form1]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      src = [1]
#      tgt = [2]
#      op1 = [:d]
#    end
#    hil = AlgebraicRewriting.homomorphism(I, L)
#    hir = AlgebraicRewriting.homomorphism(I, R)
#    Rule(hil, hir)
#  end,
#  # The tgt of d of a Form1 is of the type Form2.
#  begin
#    L = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; Op1 = 1
#
#      type = [:Form1, :infer]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      src = [1]
#      tgt = [2]
#      op1 = [:d]
#    end
#    I = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 1
#      type = [:Form1]
#      name = [ARVar(:src_name)]
#    end
#    R = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; Op1 = 1
#
#      type = [:Form1, :Form2]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      src = [1]
#      tgt = [2]
#      op1 = [:d]
#    end
#    hil = AlgebraicRewriting.homomorphism(I, L)
#    hir = AlgebraicRewriting.homomorphism(I, R)
#    Rule(hil, hir)
#  end,
#  # The src of d of a Form1 is of the type Form0.
#  begin
#    L = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; Op1 = 1
#
#      type = [:infer, :Form1]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      src = [1]
#      tgt = [2]
#      op1 = [:d]
#    end
#    I = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 1
#      type = [:Form1]
#      name = [ARVar(:tgt_name)]
#    end
#    R = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; Op1 = 1
#
#      type = [:Form0, :Form1]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      src = [1]
#      tgt = [2]
#      op1 = [:d]
#    end
#    hil = AlgebraicRewriting.homomorphism(I, L)
#    hir = AlgebraicRewriting.homomorphism(I, R)
#    Rule(hil, hir)
#  end,
#  # The src of d of a Form2 is of the type Form1.
#  begin
#    L = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; Op1 = 1
#
#      type = [:infer, :Form2]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      src = [1]
#      tgt = [2]
#      op1 = [:d]
#    end
#    I = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 1
#      type = [:Form2]
#      name = [ARVar(:tgt_name)]
#    end
#    R = @acset SummationDecapode{Any, Any, Any} begin
#      Var = 2; Op1 = 1
#
#      type = [:Form1, :Form2]
#      name = [ARVar(:src_name), ARVar(:tgt_name)]
#      src = [1]
#      tgt = [2]
#      op1 = [:d]
#    end
#    hil = AlgebraicRewriting.homomorphism(I, L)
#    hir = AlgebraicRewriting.homomorphism(I, R)
#    Rule(hil, hir)
#  end]
#
#function infer_types(d::SummationDecapode, rules::Vector{Rule{:DPO}}; kw...)
#  # Step 1: Convert to {Any,Any,Any} so we can use AlgebraicRewriting's Var.
#  #d′ = migrate(SummationDecapode{Any, Any, Any}, d,
#  #  Dict(:Var => :Var, :TVar => :TVar, :Op1 => :Op1, :Op2 => :Op2, :Σ => :Σ, :Summand => :Summand, :Type => :Type, :Operator => :Operator, :Name => :Name),
#  #  Dict(:src => :src, :tgt => :tgt, :proj1 => :proj1, :proj2 => :proj2, :res => :res, :incl => :incl, :op1 => :op1, :op2 => :op2, :type => :type, :name => :name, :summand => :summand, :summation => :summation, :sum => :sum))
#  d′ = migrate(SummationDecapode{Any, Any, Any}, d,
#    merge(
#      Dict(SchSummationDecapode.generators.Ob .=> SchSummationDecapode.generators.Ob),
#      Dict(SchSummationDecapode.generators.AttrType .=> SchSummationDecapode.generators.AttrType)),
#    merge(
#      Dict(SchSummationDecapode.generators.Hom .=> SchSummationDecapode.generators.Hom),
#      Dict(SchSummationDecapode.generators.Attr .=> SchSummationDecapode.generators.Attr)))
#
#  # Step 2: Apply rules
#  seq = Schedule[]
#  append!(seq, RuleSchedule.(rules))
#  #seq = Vector{Schedule}([RuleSchedule.(rules)])
#  ar_step = ListSchedule(seq)
#  end_condition(prev, curr) = :infer ∉ curr[:type]
#  overall = WhileSchedule(ar_step, :main, end_condition)
#  trajectory = apply_schedule(overall; G=d′, kw...)
#  res = last(trajectory).G
#  # Step 3: Convert back to {Any,Any,Symbol}.
#  #migrate(SummationDecapode{Any, Any, Symbol}, res
#  #  Dict(:Var => :Var, :TVar => :TVar, :Op1 => :Op1, :Op2 => :Op2, :Σ => :Σ, :Summand => :Summand, :Type => :Type, :Operator => :Operator, :Name => :Name),
#  #  Dict(:src => :src, :tgt => :tgt, :proj1 => :proj1, :proj2 => :proj2, :res => :res, :incl => :incl, :op1 => :op1, :op2 => :op2, :type => :type, :name => :name, :summand => :summand, :summation => :summation, :sum => :sum))
#  migrate(SummationDecapode{Any, Any, Symbol}, res,
#    merge(
#      Dict(SchSummationDecapode.generators.Ob .=> SchSummationDecapode.generators.Ob),
#      Dict(SchSummationDecapode.generators.AttrType .=> SchSummationDecapode.generators.AttrType)),
#    merge(
#      Dict(SchSummationDecapode.generators.Hom .=> SchSummationDecapode.generators.Hom),
#      Dict(SchSummationDecapode.generators.Attr .=> SchSummationDecapode.generators.Attr)))
#end
#
#infer_types(d::SummationDecapode; kw...) =
#  infer_types(d, default_op1_type_inference_rules; kw...)


function expand_compositions!(d::SummationDecapode)
  max_anon = 1
  for op1_idx in parts(d, :Op1)
    op1 = string(d[:op1])
    op1[1] != '•' && continue
    num = parse(Integer, op1[4:end])
    if max_anon < num
      max_anon = num
    end
  end
  curr_anon = max_anon
  for op1_idx in parts(d, :Op1)
    op1 = d[:op1][op1_idx]
    typeof(op1) == Vector{Symbol} || continue
    prev_var_added_idx = d[:src][op1_idx]
    for op in op1[1:end-1]
      # Add a new intermediate var.
      curr_var_added_idx = add_part!(d, :Var)
      d[:type][curr_var_added_idx] = :infer
      d[:name][curr_var_added_idx] = Symbol('•', curr_anon)
      curr_anon += 1
      # Add a new intermediate op.
      curr_op1_added_idx = add_part!(d, :Op1)
      d[:op1][curr_op1_added_idx] = op
      d[:src][curr_op1_added_idx] = prev_var_added_idx
      d[:tgt][curr_op1_added_idx] = curr_var_added_idx
      prev_var_added_idx = curr_var_added_idx
    end
    d[:op1][op1_idx] = last(d[:op1][op1_idx])
    d[:src][op1_idx] = prev_var_added_idx
  end
  d
end

# TODO: You could write a method which auto-generates these rules given degree N.
"""
These are the default rules used to do type inference in the 2D exterior calculus.
"""
default_op1_type_inference_rules_2D = [
  # TODO: There are rules for op2s that must be written still.
  # Rules for ∂ₜ where tgt is unknown.
  (src_type = :Form0, tgt_type = :infer, replacement_type = :Form0, op = :∂ₜ),
  (src_type = :Form1, tgt_type = :infer, replacement_type = :Form1, op = :∂ₜ),
  (src_type = :Form2, tgt_type = :infer, replacement_type = :Form2, op = :∂ₜ),
  # Rules for ∂ₜ where src is unknown.
  (src_type = :infer, tgt_type = :Form0, replacement_type = :Form0, op = :∂ₜ),
  (src_type = :infer, tgt_type = :Form1, replacement_type = :Form1, op = :∂ₜ),
  (src_type = :infer, tgt_type = :Form2, replacement_type = :Form2, op = :∂ₜ),
  # Rules for d where tgt is unknown.
  (src_type = :Form0, tgt_type = :infer, replacement_type = :Form1, op = :d),
  (src_type = :Form1, tgt_type = :infer, replacement_type = :Form2, op = :d),
  (src_type = :DualForm0, tgt_type = :infer, replacement_type = :DualForm1, op = :d),
  (src_type = :DualForm1, tgt_type = :infer, replacement_type = :DualForm2, op = :d),
  # Rules for d where src is unknown.
  (src_type = :infer, tgt_type = :Form2, replacement_type = :Form1, op = :d),
  (src_type = :infer, tgt_type = :Form1, replacement_type = :Form0, op = :d),
  (src_type = :infer, tgt_type = :DualForm0, replacement_type = :DualForm1, op = :d),
  (src_type = :infer, tgt_type = :DualForm1, replacement_type = :DualForm2, op = :d),
  # Rules for ⋆ where tgt is unknown.
  (src_type = :Form0, tgt_type = :infer, replacement_type = :DualForm2, op = :⋆),
  (src_type = :Form1, tgt_type = :infer, replacement_type = :DualForm1, op = :⋆),
  (src_type = :Form2, tgt_type = :infer, replacement_type = :DualForm0, op = :⋆),
  (src_type = :DualForm2, tgt_type = :infer, replacement_type = :Form0, op = :⋆),
  (src_type = :DualForm1, tgt_type = :infer, replacement_type = :Form1, op = :⋆),
  (src_type = :DualForm0, tgt_type = :infer, replacement_type = :Form2, op = :⋆),
  # Rules for ⋆ where src is unknown.
  (src_type = :infer, tgt_type = :DualForm2, replacement_type = :Form0, op = :⋆),
  (src_type = :infer, tgt_type = :DualForm1, replacement_type = :Form1, op = :⋆),
  (src_type = :infer, tgt_type = :DualForm0, replacement_type = :Form2, op = :⋆),
  (src_type = :infer, tgt_type = :Form0, replacement_type = :DualForm2, op = :⋆),
  (src_type = :infer, tgt_type = :Form1, replacement_type = :DualForm1, op = :⋆),
  (src_type = :infer, tgt_type = :Form2, replacement_type = :DualForm0, op = :⋆)]

"""
These are the default rules used to do type inference in the 1D exterior calculus.
"""
default_op1_type_inference_rules_1D = [
  # TODO: There are rules for op2s that must be written still.
  # Rules for ∂ₜ where tgt is unknown.
  (src_type = :Form0, tgt_type = :infer, replacement_type = :Form0, op = :∂ₜ),
  (src_type = :Form1, tgt_type = :infer, replacement_type = :Form1, op = :∂ₜ),
  # Rules for ∂ₜ where src is unknown.
  (src_type = :infer, tgt_type = :Form0, replacement_type = :Form0, op = :∂ₜ),
  (src_type = :infer, tgt_type = :Form1, replacement_type = :Form1, op = :∂ₜ),
  # Rule for d where tgt is unknown.
  (src_type = :Form0, tgt_type = :infer, replacement_type = :Form1, op = :d),
  (src_type = :DualForm1, tgt_type = :infer, replacement_type = :DualForm0, op = :d),
  # Rules for d where src is unknown.
  (src_type = :infer, tgt_type = :Form1, replacement_type = :Form0, op = :d),
  (src_type = :infer, tgt_type = :DualForm1, replacement_type = :DualForm0, op = :d),
  # Rules for ⋆ where tgt is unknown.
  (src_type = :Form0, tgt_type = :infer, replacement_type = :DualForm1, op = :⋆),
  (src_type = :Form1, tgt_type = :infer, replacement_type = :DualForm0, op = :⋆),
  (src_type = :DualForm1, tgt_type = :infer, replacement_type = :Form0, op = :⋆),
  (src_type = :DualForm0, tgt_type = :infer, replacement_type = :Form1, op = :⋆),
  # Rules for ⋆ where src is unknown.
  (src_type = :infer, tgt_type = :DualForm1, replacement_type = :Form0, op = :⋆),
  (src_type = :infer, tgt_type = :DualForm0, replacement_type = :Form1, op = :⋆),
  (src_type = :infer, tgt_type = :Form0, replacement_type = :DualForm1, op = :⋆),
  (src_type = :infer, tgt_type = :Form1, replacement_type = :DualForm0, op = :⋆)]

"""
  function infer_summands_and_summations!(d::SummationDecapode)

"""
function infer_summands_and_summations!(d::SummationDecapode)
  # Note that we are not doing any type checking here!
  # i.e. We are not checking for this: [Form0, Form1, Form0].
  applied = false
  for Σ_idx in parts(d, :Σ)
    summands = d[:summand][incident(d, Σ_idx, :summation)]
    sum = d[:sum][Σ_idx]
    idxs = [summands; sum]
    types = d[:type][idxs]
    all(t != :infer for t in types) && continue # We need not infer
    all(t == :infer for t in types) && continue # We can  not infer
    inferred_type = types[findfirst(!=(:infer), types)]
    to_infer_idxs = filter(i -> d[:type][i] == :infer, idxs)
    d[:type][to_infer_idxs] .= inferred_type
    applied = true
  end
  return applied
end

"""
  function apply_op1_type_rules!(d::SummationDecapode, types_known::Vector{Bool}, src_type::Symbol, tgt_type::Symbol, replacement_type::Symbol, op::Symbol)

"""
function apply_op1_type_rules!(d::SummationDecapode, types_known::Vector{Bool}, src_type::Symbol, tgt_type::Symbol, replacement_type::Symbol, op::Symbol)
  applied = false
  if !xor(src_type == :infer, tgt_type == :infer)
    error("Exactly one provided type must be :infer.")
  end
  for op1_idx in parts(d, :Op1)
    types_known[op1_idx] && continue
    src = d[:src][op1_idx]; tgt = d[:tgt][op1_idx]; op1 = d[:op1][op1_idx]

    if op1 == op && d[:type][src] == src_type && d[:type][tgt] == tgt_type
      if src_type == :infer
        d[:type][src] = replacement_type
      else #if tgt_type == :infer
        d[:type][tgt] = replacement_type
      end
      types_known[op1_idx] = true
      applied = true
      break
    end
  end
  return applied
end

# TODO: Although the big-O complexity is the same, it might be more efficent on
# average to iterate over edges then rules, instead of rules then edges. This
# might result in more un-maintainable code. If you implement this, you might
# also want to make the rules keys in a Dict.
# It also might be more efficient on average to instead iterate over variables.
"""
  function infer_types!(d::SummationDecapode, op1_rules::Vector{NamedTuple{(:src_type, :tgt_type, :replacement_type, :op), NTuple{4, Symbol}}})

Infer types of Vars given rules wherein one type is known and the other not.
"""
function infer_types!(d::SummationDecapode, op1_rules::Vector{NamedTuple{(:src_type, :tgt_type, :replacement_type, :op), NTuple{4, Symbol}}})
  # This is an optimization so we do not "visit" a row which has no infer types.
  # It could be deleted if found to be not worth maintainability tradeoff.
  #types_known = ones(Bool, nparts(d, :Op1))
  #types_known[incident(d, :infer, [:src, :type])] .= false
  #types_known[incident(d, :infer, [:tgt, :type])] .= false
  types_known = zeros(Bool, nparts(d, :Op1))
  types_known[incident(d, :infer, [:src, :type])] .= false
  types_known[incident(d, :infer, [:tgt, :type])] .= false
  while true
    applied = false
    for rule in op1_rules
      this_applied = apply_op1_type_rules!(d, types_known, rule...)
      applied = applied || this_applied
    end
    # TODO: Infer Op2 types.
    applied = applied || infer_summands_and_summations!(d)
    applied || break # Break if no rules were applied.
  end
  d
end

# TODO: When SummationDecapodes are annotated with the degree of their space,
# use dispatch to choose the correct set of rules.
infer_types!(d::SummationDecapode) =
  infer_types!(d, default_op1_type_inference_rules_2D)

# TODO: You could write a method which auto-generates these rules given degree N.
"""
These are the default rules used to do function resolution in the 2D exterior calculus.
"""
default_overloading_resolution_rules_2D = [
  # TODO: There are rules for op2s that must be written still.
  # Rules for d.
  (src_type = :Form0, tgt_type = :Form1, resolved_name = :d₀, op = :d),
  (src_type = :Form1, tgt_type = :Form2, resolved_name = :d₁, op = :d),
  (src_type = :DualForm0, tgt_type = :DualForm1, resolved_name = :dual_d₀, op = :d),
  (src_type = :DualForm1, tgt_type = :DualForm2, resolved_name = :dual_d₁, op = :d),
  # Rules for ⋆.
  (src_type = :Form0, tgt_type = :DualForm2, resolved_name = :⋆₀, op = :⋆),
  (src_type = :Form1, tgt_type = :DualForm1, resolved_name = :⋆₁, op = :⋆),
  (src_type = :Form2, tgt_type = :DualForm0, resolved_name = :⋆₂, op = :⋆),
  (src_type = :DualForm2, tgt_type = :Form0, resolved_name = :⋆₀⁻¹, op = :⋆),
  (src_type = :DualForm1, tgt_type = :Form1, resolved_name = :⋆₁⁻¹, op = :⋆),
  (src_type = :DualForm0, tgt_type = :Form2, resolved_name = :⋆₂⁻¹, op = :⋆),
  # Rules for δ.
  (src_type = :Form2, tgt_type = :Form1, resolved_name = :δ₂, op = :δ),
  (src_type = :Form1, tgt_type = :Form0, resolved_name = :δ₁, op = :δ),
  # Rules for ∇².
  (src_type = :Form0, tgt_type = :Form0, resolved_name = :∇²₀, op = :∇²),
  (src_type = :Form1, tgt_type = :Form1, resolved_name = :∇²₁, op = :∇²),
  (src_type = :Form2, tgt_type = :Form2, resolved_name = :∇²₂, op = :∇²),
  # Rules for Δ².
  (src_type = :Form0, tgt_type = :Form0, resolved_name = :Δ₀, op = :Δ),
  (src_type = :Form1, tgt_type = :Form1, resolved_name = :Δ₁, op = :Δ),
  (src_type = :Form1, tgt_type = :Form1, resolved_name = :Δ₂, op = :Δ)]

"""
These are the default rules used to do function resolution in the 1D exterior calculus.
"""
default_overloading_resolution_rules_1D = [
  # TODO: There are rules for op2s that must be written still.
  # Rules for d.
  (src_type = :Form0, tgt_type = :Form1, resolved_name = :d₀, op = :d),
  (src_type = :DualForm0, tgt_type = :DualForm1, resolved_name = :dual_d₀, op = :d),
  # Rules for ⋆.
  (src_type = :Form0, tgt_type = :DualForm1, resolved_name = :⋆₀, op = :⋆),
  (src_type = :Form1, tgt_type = :DualForm0, resolved_name = :⋆₁, op = :⋆),
  (src_type = :DualForm1, tgt_type = :Form0, resolved_name = :⋆₀⁻¹, op = :⋆),
  (src_type = :DualForm0, tgt_type = :Form1, resolved_name = :⋆₁⁻¹, op = :⋆),
  # Rules for δ.
  (src_type = :Form1, tgt_type = :Form0, resolved_name = :δ₁, op = :δ)]

"""
  function resolve_overloads!(d::SummationDecapode, op1_rules::Vector{NamedTuple{(:src_type, :tgt_type, :resolved_name, :op), NTuple{4, Symbol}}})

Resolve function overloads based on types of src and tgt.
"""
function resolve_overloads!(d::SummationDecapode, op1_rules::Vector{NamedTuple{(:src_type, :tgt_type, :resolved_name, :op), NTuple{4, Symbol}}})
  for op1_idx in parts(d, :Op1)
    src = d[:src][op1_idx]; tgt = d[:tgt][op1_idx]; op1 = d[:op1][op1_idx]
    src_type = d[:type][src]; tgt_type = d[:type][tgt]
    for rule in op1_rules
      if op1 == rule[:op] && src_type == rule[:src_type] && tgt_type == rule[:tgt_type]
        d[:op1][op1_idx] = rule[:resolved_name]
        break
      end
    end
  end
  d
end

# TODO: When SummationDecapodes are annotated with the degree of their space,
# use dispatch to choose the correct set of rules.
resolve_overloads!(d::SummationDecapode) =
  resolve_overloads!(d, default_overloading_resolution_rules_2D)

