
module Metadata

export
    has_metadata,
    has_metaproperty,
    axis_meta,
    axis_metaproperty,
    axis_metaproperty!,
    metadata,
    metaproperty,
    metaproperty!,
    metadata_type,
    combine_metadata


import MetadataArrays: MetadataArray

function _construct_meta(meta::AbstractDict{Symbol}; kwargs...)
    for (k, v) in kwargs
        meta[k] = v
    end
    return meta
end

_construct_meta(meta::Nothing; kwargs...) = _construct_meta(Dict{Symbol,Any}(); kwargs...)

function _construct_meta(meta::T; kwargs...) where {T}
    isempty(kwargs) || error("Cannot assign key word arguments to metadata of type $T")
    return meta
end

"""
    metadata(x)

Returns metadata for `x`.
"""
metadata(x) = nothing
metadata(x::SubArray) = metadata(parent(x))
metadata(x::Base.ReshapedArray) = metadata(parent(x))
# define our own metadata method
Metadata.metadata(x::MetadataArray) = getfield(x, :metadata)

"""
    metaproperty(x, meta_key)

Return the metadata of `x` paired to `meta_key`.
"""
metaproperty(x, meta_key::Symbol) = getindex(metadata(x), meta_key)

"""
    metadata!(x, meta_key, val)

Set the metadata of `x` paired to `meta_key`.
"""
metaproperty!(x, meta_key::Symbol, val) = setindex!(metadata(x), val, meta_key)


"""
    has_metaproperty(x, meta_key)
"""
has_metaproperty(x, meta_key::Symbol) = haskey(metadata(x), meta_key)

"""
    axis_meta(x)

Returns metadata (i.e. not keys or indices) associated with each axis of the array `x`.
"""
axis_meta(x::AbstractArray) = map(metadata, axes(x))

"""
    axis_meta(x, i)

Returns metadata (i.e. not keys or indices) associated with the ith axis of the array `x`.
"""
axis_meta(x::AbstractArray, i) = metadata(axes(x, i))

"""
    axis_metaproperty(x, i, meta_key)

Return the metadata of `x` paired to `meta_key`.
"""
axis_metaproperty(x, i, meta_key::Symbol) = getindex(axis_meta(x, i), meta_key)

"""
    has_axis_metaproperty(x, meta_key)
"""
has_axis_metaproperty(x, i, meta_key::Symbol) = haskey(axis_meta(x, i), meta_key)


"""
    meta_axis!(x, meta_key, val)

Set the metadata of `x` paired to `meta_key`.
"""
axis_metaproperty!(x, i, meta_key::Symbol) = setindex!(axis_meta(x, i), meta_key)

"""
    has_metadata(x) -> Bool

Returns true if `x` contains additional fields besides those for `keys` or `indices`
"""
has_metadata(::T) where {T} = has_metadata(T)
has_metadata(::Type{T}) where {T} = false

"""
    metadata_type(x)

Returns the type of the metadata of `x`.
"""
metadata_type(::T) where {T} = metadata_type(T)
metadata_type(::Type{T}) where {T} = nothing

# TODO document combine_metadata
function combine_metadata(x::AbstractUnitRange, y::AbstractUnitRange)
    return combine_metadata(metadata(x), metadata(y))
end
combine_metadata(::Nothing, ::Nothing) = nothing
combine_metadata(::Nothing, y) = y
combine_metadata(x, ::Nothing) = x
combine_metadata(x, y) = merge(x, y)

end
