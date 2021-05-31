# This file is a part of ShapedVariates.jl, licensed under the MIT License (MIT).


function _transformed_ntd_accessors(d::NamedTupleDist{names}) where names
    shapes = map(_transformed_ntd_elshape, values(d))
    vs = NamedTupleShape(NamedTuple{names}(shapes))
    values(vs)
end

function VariateTrafoRules.apply_dist_trafo(trg_d::StdMvDist, src_d::ValueShapes.UnshapedNTD, src_v::AbstractVector{<:Real}, prev_ladj::OptionalLADJ)
    src_vs = varshape(src_d.shaped)
    @argcheck length(src_d) == length(eachindex(src_v))
    trg_accessors = _transformed_ntd_accessors(src_d.shaped)
    init_ladj = ismissing(prev_ladj) ? missing : zero(Float32)
    rs = map((acc, sd) -> _ntdistelem_to_stdmv(trg_d, sd, src_v, acc, init_ladj), trg_accessors, values(src_d.shaped))
    trg_v = vcat(map(r -> r.v, rs)...)
    trafo_ladj = !ismissing(prev_ladj) ? sum(map(r -> r.ladj, rs)) : missing
    var_trafo_result(trg_v, src_v, trafo_ladj, prev_ladj)
end

function VariateTrafoRules.apply_dist_trafo(trg_d::StdMvDist, src_d::NamedTupleDist, src_v::Union{NamedTuple,ShapedAsNT}, prev_ladj::OptionalLADJ)
    src_v_unshaped = unshaped(src_v, varshape(src_d))
    VariateTrafoRules.apply_dist_trafo(trg_d, unshaped(src_d), src_v_unshaped, prev_ladj)
end


function _stdmv_to_ntdistelem(td::ConstValueDist, src_d::StdMvDist, src_v::AbstractVector{<:Real}, src_acc::ValueAccessor, init_ladj::OptionalLADJ)
    (v = Bool[], ladj = init_ladj)
end

function VariateTrafoRules.apply_dist_trafo(trg_d::ValueShapes.UnshapedNTD, src_d::StdMvDist, src_v::AbstractVector{<:Real}, prev_ladj::OptionalLADJ)
    trg_vs = varshape(trg_d.shaped)
    @argcheck length(src_d) == length(eachindex(src_v))
    src_accessors = _transformed_ntd_accessors(trg_d.shaped)
    init_ladj = ismissing(prev_ladj) ? missing : zero(Float32)
    rs = map((acc, td) -> _stdmv_to_ntdistelem(td, src_d, src_v, acc, init_ladj), src_accessors, values(trg_d.shaped))
    trg_v_unshaped = vcat(map(r -> unshaped(r.v), rs)...)
    trafo_ladj = !ismissing(prev_ladj) ? sum(map(r -> r.ladj, rs)) : missing
    var_trafo_result(trg_v_unshaped, src_v, trafo_ladj, prev_ladj)
end

function VariateTrafoRules.apply_dist_trafo(trg_d::NamedTupleDist, src_d::StdMvDist, src_v::AbstractVector{<:Real}, prev_ladj::OptionalLADJ)
    unshaped_result = VariateTrafoRules.apply_dist_trafo(unshaped(trg_d), src_d, src_v, prev_ladj)
    (v = varshape(trg_d)(unshaped_result.v), ladj = unshaped_result.ladj)
end


function VariateTrafoRules.apply_dist_trafo(trg_d::Distribution{Multivariate}, src_d::ReshapedDist, src_v::Any, prev_ladj::OptionalLADJ)
    src_vs = varshape(src_d)
    @argcheck length(trg_d) == totalndof(src_vs)
    VariateTrafoRules.apply_dist_trafo(trg_d, unshaped(src_d), unshaped(src_v, src_vs), prev_ladj)
end

function VariateTrafoRules.apply_dist_trafo(trg_d::ReshapedDist, src_d::Distribution{Multivariate}, src_v::AbstractVector{<:Real}, prev_ladj::OptionalLADJ)
    trg_vs = varshape(trg_d)
    @argcheck totalndof(trg_vs) == length(src_d)
    r = VariateTrafoRules.apply_dist_trafo(unshaped(trg_d), src_d, src_v, prev_ladj)
    (v = trg_vs(r.v), ladj = r.ladj)
end

function VariateTrafoRules.apply_dist_trafo(trg_d::ReshapedDist, src_d::ReshapedDist, src_v::AbstractVector{<:Real}, prev_ladj::OptionalLADJ)
    trg_vs = varshape(trg_d)
    src_vs = varshape(src_d)
    @argcheck totalndof(trg_vs) == totalndof(src_vs)
    r = VariateTrafoRules.apply_dist_trafo(unshaped(trg_d), unshaped(src_d), unshaped(src_v, src_vs), prev_ladj)
    (v = trg_vs(r.v), ladj = r.ladj)
end
