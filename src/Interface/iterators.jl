
"""
    AxisIterator(axis, window_size[, first_pad=nothing, last_pad=nothing, stride=nothing, dilation=nothing])

Creates an iterator for indexing ranges of elements within `axis`.

## Examples

```jldoctest axis_iterator_examples
julia> using AxisIndices

julia> axis = Axis(range(2.0, step=3.0, length=20))
Axis(2.0:3.0:59.0 => Base.OneTo(20))

julia> AxisIterator(axis, 3)
AxisIterator((1:3):3:(16:18))
```
The final print out indicates that the first window is `1:3` and all subsequent iterations move by `3` until reaching `16:18`.


The size of the window may be determined by providing an explicit size or the size in terms of the keys of an axis.
```jldoctest axis_iterator_examples
julia> collect(AxisIterator(axis, 3))
6-element Array{Any,1}:
 1:3
 4:6
 7:9
 10:12
 13:15
 16:18

julia> collect(AxisIterator(axis, 9.0))
6-element Array{Any,1}:
 1:3
 4:6
 7:9
 10:12
 13:15
 16:18

```

The iterator may start with padding from the beginning..
```jldoctest axis_iterator_examples
julia> collect(AxisIterator(axis, 3, first_pad=1))
6-element Array{Any,1}:
 2:4
 5:7
 8:10
 11:13
 14:16
 17:19

julia> collect(AxisIterator(axis, 9.0, first_pad=3.0))
6-element Array{Any,1}:
 2:4
 5:7
 8:10
 11:13
 14:16
 17:19

```
...and the end.
```jldoctest axis_iterator_examples
julia> collect(AxisIterator(axis, 3, first_pad=1, last_pad=2))
5-element Array{Any,1}:
 2:4
 5:7
 8:10
 11:13
 14:16

julia> collect(AxisIterator(axis, 9.0, first_pad=3.0, last_pad=6.0))
5-element Array{Any,1}:
 2:4
 5:7
 8:10
 11:13
 14:16

```

The window can be dilated so that a regular but non-continuous range of elements
are indexed.
```jldoctest axis_iterator_examples
julia> collect(AxisIterator(axis, 3, first_pad=1, last_pad=2, dilation=2))
5-element Array{Any,1}:
 2:2:4
 5:2:7
 8:2:10
 11:2:13
 14:2:16

julia> collect(AxisIterator(axis, 9.0, first_pad=3.0, last_pad=6.0, dilation=6.0))
5-element Array{Any,1}:
 2:2:4
 5:2:7
 8:2:10
 11:2:13
 14:2:16

```

Regular strides can be placed between each iteration.
```jldoctest axis_iterator_examples
julia> collect(AxisIterator(axis, 3, first_pad=1, last_pad=2, stride=2))
3-element Array{Any,1}:
 2:4
 7:9
 12:14

julia> collect(AxisIterator(axis, 9.0, first_pad=3.0, last_pad=6.0, stride=6.0))
3-element Array{Any,1}:
 2:4
 7:9
 12:14

```
"""
struct AxisIterator{B<:AbstractRange{<:Integer},W<:AbstractRange{<:Integer}}
    bounds::B
    window::W

    AxisIterator{B,W}(bounds::B, window::W) where {B,W} = new{B,W}(bounds, window)

    function AxisIterator(axis, sz; first_pad=nothing, last_pad=nothing, stride=nothing, dilation=nothing)
        return _axis_iterator(axis, _to_size(axis, sz), first_pad, last_pad, stride, dilation)
    end
end

@inline function _to_size(axis, x)
    if is_key(x)
        return Int(div(x, step(keys(axis))))
    else
        return Int(div(x, step(axis)))
    end
end

function _axis_iterator(axis, sz::Integer, first_pad, last_pad, stride, dilation)
    if dilation === nothing
        window = OneTo(sz)
    else
        fi = firstindex(axis)
        window = fi:_to_size(axis, dilation):(fi + sz - 1)
    end


    start = firstindex(axis) - 1
    if first_pad !== nothing
        start = start + _to_size(axis, first_pad)
    end

    stop = lastindex(axis) - sz
    if last_pad !== nothing
        stop = stop - _to_size(axis, last_pad)
    end

    if stride === nothing
        bounds = range(start, step=sz, stop=stop)
    else
        bounds = range(start, step=_to_size(axis, stride) + sz, stop = stop)
    end

    return AxisIterator{typeof(bounds),typeof(window)}(bounds, window)
end

Base.length(w::AxisIterator) = length(getfield(w, :bounds))

@inline function Base.iterate(w::AxisIterator)
    itr = iterate(getfield(w, :bounds))
    if itr === nothing
        return nothing
    else
        return _iterate(first(itr), getfield(w, :window)), last(itr)
    end
end

@inline function Base.iterate(w::AxisIterator, state)
    itr = iterate(getfield(w, :bounds), state)
    if itr === nothing
        return nothing
    else
        return _iterate(first(itr), getfield(w, :window)), last(itr)
    end
end

_iterate(itr, w::AbstractUnitRange) = (first(w) + itr):(last(w) + itr)
_iterate(itr, w::OrdinalRange) = (first(w) + itr):step(w):(last(w) + itr)

@inline function Base.first(itr::AxisIterator)
    return _iterate(first(getfield(itr, :bounds)), getfield(itr, :window))
end

@inline function Base.last(itr::AxisIterator)
    return _iterate(last(getfield(itr, :bounds)), getfield(itr, :window))
end

Base.show(io::IO, ::MIME"text/plain", itr::AxisIterator) = print_axis_iterator(io, itr)

function print_axis_iterator(io, itr::AxisIterator)
    print(io, "AxisIterator(")
    print(io, "($(first(itr))):" * "$(step(getfield(itr, :bounds)))" *":($(last(itr)))")
    print(io, ")")
end

"""
    AxesIterator

N-dimensional iterator of `AxisIterator`s.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxesIterator(CartesianAxes((20, 20, 20)), (3,3,3))
AxesIterator:
 • AxisIterator((1:3):3:(16:18))
 • AxisIterator((1:3):3:(16:18))
 • AxisIterator((1:3):3:(16:18))

```
"""
struct AxesIterator{I<:Tuple{Vararg{<:AxisIterator}}}
    iterators::I

    function AxesIterator(
        axs::NTuple{N,Any},
        sz::NTuple{N,Any};
        first_pad=ntuple(_ -> nothing, Val(N)),
        last_pad=ntuple(_ -> nothing, Val(N)),
        stride=ntuple(_ -> nothing, Val(N)),
        dilation=ntuple(_ -> nothing, Val(N))
    ) where {N}

        itrs = map(_axis_iterator, axs, map(_to_size, axs, sz), first_pad, last_pad, stride, dilation)
        return new{typeof(itrs)}(itrs)
    end

    AxesIterator(A::AbstractArray, sz; kwargs...) = AxesIterator(axes(A), sz; kwargs...)
end

Base.length(itr::AxesIterator) = prod(map(length, getfield(itr, :iterators)))

inc(::Tuple{}, ::Tuple{}, ::Tuple{}) = ()
@inline function inc(itr::Tuple{Any}, olditr::Tuple{Any}, state::Tuple{Any})
    newitr = iterate(first(itr), first(state))
    if newitr === nothing
        return nothing
    else
        return (first(newitr),), (last(newitr),)
    end
end

@inline function inc(itr::Tuple{Any,Vararg{Any}}, olditr::Tuple{Any,Vararg{Any}}, state::Tuple{Any,Vararg{Any}})
    subitr = first(itr)
    substate = first(state)
    nextsubitr = iterate(subitr, substate)
    if nextsubitr === nothing
        subitr, substate = iterate(subitr)
        nextitr = inc(tail(itr), tail(olditr), tail(state))
        if nextitr === nothing
            return nothing
        else
            return (subitr, first(nextitr)...), (substate, last(nextitr)...)
        end
    else
        return (first(nextsubitr), tail(olditr)...), (last(nextsubitr), tail(state)...)
    end
end

@inline firstinc(itr::Tuple{Any}) = iterate(first(itr))

@inline function firstinc(itr::Tuple{Any,Any})
    itr_i = iterate(first(itr))
    if itr_i === nothing
        return nothing
    else
        nextitr = firstinc(tail(itr))
        if nextitr === nothing
            return nothing
        else
            return (first(itr_i), first(nextitr)), (last(itr_i), last(nextitr))
        end
    end
end

@inline function firstinc(itr::Tuple{Any,Vararg{Any}})
    itr_i = iterate(first(itr))
    if itr_i === nothing
        return nothing
    else
        nextitr = firstinc(tail(itr))
        if nextitr === nothing
            return nothing
        else
            return (first(itr_i), first(nextitr)...), (last(itr_i), last(nextitr)...)
        end
    end
end

function Base.iterate(itr::AxesIterator)
    newitr = firstinc(itr.iterators)
    if newitr === nothing
        return nothing
    else
        return Iterators.ProductIterator(first(newitr)), newitr
    end
end

function Base.iterate(itr::AxesIterator, state)
    if state === nothing
        return nothing
    else
        newitrs = inc(itr.iterators, first(state), last(state))
        if newitrs === nothing
            return nothing
        else
            return (Iterators.ProductIterator(first(newitrs)), newitrs)
        end
    end
end

_first(itr) = map(first, getfield(itr, :iterators))
_last(itr) = map(last, getfield(itr, :iterators))

Base.first(itr::AxesIterator) = Iterators.ProductIterator(_first(itr))
Base.last(itr::AxesIterator) = Iterators.ProductIterator(_last(itr))

function Base.show(io::IO, ::MIME"text/plain", itr::AxesIterator)
    print(io, "AxesIterator:\n")
    itrs = getfield(itr, :iterators)
    N = length(itrs)
    for i in 1:N
        print(io, " • ")
        print_axis_iterator(io, itrs[i])
        if i != N
            print(io, "\n")
        end
    end
end


