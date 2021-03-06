
@testset "keys" begin
    axis = Axis(2:3 => 1:2)

    @test keytype(typeof(Axis(1.0:10.0))) <: Float64
    @test keys_type(axis) == UnitRange{Int}
    @test haskey(axis, 3)
    @test !haskey(axis, 4)
    @test axes_keys(axis) == (2:3,)

    A = AxisArray(ones(3,2), [:one, :two, :three])

    KS = keys_type(A, 1)
    #@test is_fixed(KS)
    @test eltype(KS) <: Symbol


    @testset "reverse" begin
        x = [1, 2, 3]
        y = AxisArray(x)
        z = AxisArray(x, Axis([:one, :two, :three]))

        revx = reverse(x)
        revy = @inferred(reverse(y))
        revz = @inferred(reverse(z))

        @testset "reverse vectors values properly" begin
            @test revx == revz == revy
        end

        @testset "reverse vectors keys" begin
            @test axes_keys(revy, 1) == [3, 2, 1]
            @test axes_keys(revz, 1) == [:three, :two, :one]
        end

        @testset "reverse arrays" begin
            b = [1 2; 3 4]
            x = AxisArray(b, [:one, :two], ["a", "b"])

            xrev1 = reverse(x, dims=1)
            xrev2 = reverse(x, dims=2)
            @test axes_keys(xrev1) == ([:two, :one], ["a", "b"])
            @test axes_keys(xrev2) == ([:one, :two], ["b", "a"])
        end
    end
end
