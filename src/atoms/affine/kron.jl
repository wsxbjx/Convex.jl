import Base.kron
export kron
export sign, monotonicity, curvature, evaluate, conic_form!

type KronAtom <: AbstractExpr
  head::Symbol
  id_hash::UInt64
  children::Tuple{AbstractExpr, AbstractExpr}
  size::Tuple{Int, Int}

  function KronAtom(x::AbstractExpr, y::AbstractExpr)
    if vexity(x) != ConstVexity() && vexity(y) != ConstVexity()
      error("Kron of two non-constant expressions is not DCP compliant")
    else
      sz = (size(x)[1]*size(y)[1], size(x)[2]*size(y)[2])
      children = (x, y)
      return new(:kron, hash(children), children, sz)
    end
  end
end

function sign(x::KronAtom)
    return sign(x.children[1]) * sign(x.children[2])
end

function monotonicity(x::KronAtom)
  return (sign(x.children[2]) * Nondecreasing(), sign(x.children[1]) * Nondecreasing())
end


function curvature(x::KronAtom)
    return ConstVexity()
end

function evaluate(x::KronAtom)
  return kron(evaluate(x.children[1]),evaluate(x.children[2]))
end

function conic_form!(x::KronAtom, unique_conic_forms::UniqueConicForms)
  if !has_conic_form(unique_conic_forms, x)
    objective = conic_form!(x.children[2], unique_conic_forms)
    a = evaluate(x.children[1])
    for key in objective.keys
      xx = kron(a,objective[key][1])
      yy = kron(a,objective[key][2])
      objective[key] = (xx,yy)
    end
    cache_conic_form!(unique_conic_forms, x, objective)
  end
  return get_conic_form(unique_conic_forms, x)
end

kron(x::Value, y::AbstractExpr) = KronAtom(Constant(x), y)