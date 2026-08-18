"""
ModelingToolkit version compatibility.

MTK v10 unified ODESystem, SDESystem, NonlinearSystem and the rest into a single
`System` type, and removed `defaults` as a constructor keyword. v10 also renamed
`structural_simplify` to `mtkcompile` and `states` to `unknowns`.

Rather than pin to one version, resolve the names once here. Defaults are set
INLINE on variable declarations throughout the components - that syntax is stable
across versions and is better practice anyway, since the default lives next to the
thing it defaults.
"""

# System type: v10 `System`, v9 `ODESystem`.
const MTKSystem = if isdefined(ModelingToolkit, :System)
    ModelingToolkit.System
else
    ModelingToolkit.ODESystem
end

"""
    mtk_simplify(sys)

Structural simplification, whatever it is called in this version.
"""
const mtk_simplify = if isdefined(ModelingToolkit, :mtkcompile)
    ModelingToolkit.mtkcompile
elseif isdefined(ModelingToolkit, :structural_simplify)
    ModelingToolkit.structural_simplify
else
    error("no structural simplification function found in ModelingToolkit")
end

"""
    mtk_unknowns(sys)

State variables. `unknowns` in v9+, `states` before.
"""
const mtk_unknowns = if isdefined(ModelingToolkit, :unknowns)
    ModelingToolkit.unknowns
else
    ModelingToolkit.states
end
