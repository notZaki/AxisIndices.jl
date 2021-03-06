# AxisIndices.jl

[![Build Status](https://travis-ci.com/Tokazama/AxisIndices.jl.svg?branch=master)](https://travis-ci.com/Tokazama/AxisIndices.jl)
[![stable-docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/AxisIndices.jl/stable)
[![dev-docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/AxisIndices.jl/dev)

Here are some reasons you should try AxisIndices
* **Flexible design** for **customizing multidimensional indexing** behavior
* **It's fast**. [StaticRanges](https://github.com/Tokazama/StaticRanges.jl) are used to speed up indexing ranges. If something is slow, please create a detailed issue.
* **Works with Julia's standard library** (in progress). The end goal of AxisIndices is to fully integrate with the standard library wherever possible. If you can find a relevant method that isn't supported in `Base`or  `Statistics` then it's likely an oversight, so make an issue. `LinearAlgebra`, `MappedArrays`, `OffsetArrays`, and `NamedDims` also have some form of support.

The linked documentation provides a very brief ["Quick Start"](https://tokazama.github.io/AxisIndices.jl/dev/quick_start/) section along with detailed documentation of internal methods and types.

## Construction By Axes

Axes can indicate what kind of array you want (static/fixed size) and/or can map key values to indices.

```julia
julia> using AxisIndices

julia> x = AxisArray{Int}(undef, OneToSRange(2), OneToSRange(2));

julia> x[1:4] .= 1;

julia> parent(x)
2×2 StaticArrays.MArray{Tuple{2,2},Int64,2,4} with indices SOneTo(2)×SOneTo(2):
 1  1
 1  1

julia> A = AxisArray(reshape(1:4, 2, 2), [:a, :b], ["one", "two"])
2×2 AxisArray{Int64,2}
 • dim_1 - [:a, :b]
 • dim_2 - ["one", "two"]
      one   two
  a     1     3
  b     2     4

julia> A[:a, "one"]
1
```

## Indexing Cheat Sheet

The following can be replicated by using Unitful seconds (i.e., `using Unitful: s`)

| Code                                                |    | Result                             |
|----------------------------------------------------:|----|------------------------------------|
| `Axis((1:10)s, 2:11)[1s]`                           | -> | `2`                                |
| `Axis((1:10)s, 2:11)[2]`                            | -> | `2`                                |
| `Axis((1:10)s, 2:11)[1s..3s]`                       | -> | `Axis((1:3)s, 2:4)`                |
| `Axis((1:10)s, 2:11)[2:4]`                          | -> | `Axis((1:3)s, 2:4)`                |
| `Axis((1:10)s, 2:11)[>(5s)]`                        | -> | `Axis((6:10)s, 7:11)`              |
| `Axis((1:10)s, 2:11)[<(5s)]`                        | -> | `Axis((1:4)s, 2:5)`                |
| `Axis((1:10)s, 2:11)[==(5s)]`                       | -> | `6`                                |
| `Axis((1:10)s, 2:11)[!=(5s)]`                       | -> | `[1, 2, 3, 4, 5, 7, 8, 9, 10, 11]` |
| `Axis((1:10)s, 2:11)[in((1:2)s)]`                   | -> | `Axis((1:2)s, 2:3)`                |
| `Axis((2:11), 1:10)[Keys(5)]`                       | -> | `5`                                |
| `Axis((2:11), 1:10)[Indices(<(5))]`                 | -> | `Axis(2:5 => 1:4)`                 |
| `Axis([pi + 0, pi + 1])[isapprox(3.14, atol=1e-2)]` | -> | `1`                                |
| `SimpleAxis(1:10)[<(5)]`                            | -> | `SimpleAxis(1:4)`                  |

