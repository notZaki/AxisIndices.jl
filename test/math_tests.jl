
@testset "+" begin
    a = AxisArray(ones(3), (2:4,))

    @testset "standard case" begin
        @test +(a) == ones(3)
        @test keys(axes(+(a), 1)) == 2:4

        @test +(a, a) == 2ones(3)
        @test keys(axes(+(a, a), 1)) == 2:4

        @test +(a, a, a) == 3ones(3)
        @test keys(axes(+(a, a, a), 1)) == 2:4
    end

    #= TODO decide what to do with axes that don't match
    @testset "Dimension disagreement" begin
        @test_throws DimensionMismatch +(
            NamedDimsArray{(:a, :b, :c, :d)}(zeros(3, 3, 3, 3)),
            NamedDimsArray{(:w, :x, :y, :z)}(ones(3, 3, 3, 3))
        )

        @test_throws DimensionMismatch +(
            NamedDimsArray{(:time,)}(zeros(3,)),
            NamedDimsArray{(:time, :value)}(ones(3, 3))
        )
    end
    =#

    @testset "Mixed array types" begin
        axs = (2:4, 3:5, 4:6, 5:7)
        lhs_sum = +(AxisArray(zeros(3, 3, 3, 3), axs), ones(3, 3, 3, 3));
        @test lhs_sum == ones(3, 3, 3, 3)
        @test keys.(axes(lhs_sum)) == axs

        rhs_sum = +(zeros(3, 3, 3, 3), AxisArray(ones(3, 3, 3, 3), axs))
        @test rhs_sum == ones(3, 3, 3, 3)
        @test keys.(axes(rhs_sum)) == axs

        #= TODO
        casts = (AxisArray{(:foo, :bar)}, identity)
        for (T1, T2, T3, T4) in Iterators.product(casts, casts, casts, casts)
            all(isequal(identity), (T1, T2, T3, T4)) && continue
            total = T1(ones(3, 6)) + T2(2ones(3, 6)) + T3(3ones(3, 6)) + T4(4ones(3, 6))
            @test total == 10ones(3, 6)
            @test dimnames(total) == (:foo, :bar)
        end
        =#
    end
end


@testset "-" begin
    # This is actually covered by the tests for + above, since that uses the same code
    # just one extra as a sensability check
    a = AxisArray(ones(3, 100), (2:4, 3:102))
    @test a - a == zeros(3, 100)
    @test keys.(axes(a - a)) == (2:4, 3:102)
end


@testset "scalar product" begin
    ax = (Axis(1:10), Axis(2:21), Axis(3:32), Axis(4:43), Axis(5:54))
    a = AxisArray(ones(10, 20, 30, 40, 50), ax);
    @test 10a == 10ones(10, 20, 30, 40, 50)
    @test keys.(axes(10a)) == keys.(ax)
end



#= TODO figure allocations
@testset "allocations: matmul names" begin
    @test 0 == @allocated (() -> matrix_prod_names((:foo, :bar), (:bar,)))()
    @test 0 == @allocated (() -> symmetric_names((:foo, :bar), 1))()
end
=#


@testset "Mutmul with special types" begin
    a = AxisArray(ones(5,5), (2:6, 3:7))
    @testset "$T" for T in (Diagonal, Symmetric, Tridiagonal, SymTridiagonal, BitArray,)
        x = T(ones(5,5))
        @test keys.(axes(x * a)) == (1:5, 3:7)
        @test keys.(axes(a * x)) == (2:6, 1:5)
    end
end


@testset "inv" begin
    a = AxisArray([1.0 2; 3 4], (2:3, 4:5));
    @test keys.(axes(inv(a))) == (4:5, 2:3)
    @test a * inv(a) ≈ [1.0 0; 0 1]
    @test keys.(axes(a * inv(a))) == (2:3, 2:3)

    @test inv(a) * a ≈ [1.0 0; 0 1]
    @test keys.(axes(inv(a) * a)) == (4:5, 4:5)
end

@testset "cov/cor" begin
    @testset "$f" for f in (cov, cor)
        @testset "matrix input, matrix result" begin
            A = rand(3, 5)
            a = AxisArray(A, (2:4, 2:6))
            @test f(a; dims=1) == f(A, dims=1)
            @test keys.(axes(f(a; dims=1))) == (2:6, 2:6)
            @test keys.(axes(f(a, dims=2))) == (2:4, 2:4)
            @test keys.(axes(f(a, dims=3))) == (2:4, 2:4)
            @test keys.(axes(f(a[:,1:3], dims=3))) == (2:4, 2:4)
        end
        @testset "vector input, scalar result" begin
            v = rand(4)
            av = AxisArray(v, (2:5,))
            @test f(av) isa Number
            @test f(av) == f(v)
        end
    end
    @testset "cov corrected=$bool" for bool in (true, false)
        # test that kwargs get passed on correctly
        A = rand(2, 4)
        a = AxisArray(A)
        @test cov(a; corrected=bool) == cov(A; corrected=bool)
        @test cov(a; corrected=bool, dims=2)  == cov(A; corrected=bool, dims=2)
    end
end

