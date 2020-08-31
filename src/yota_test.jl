using Yota
using LinearAlgebra

using Zygote

# lets write a super basic idea of what we might want
sx = [0.0 + 0.0im 1.0 + 0.0im
      1.0 + 0.0im 0.0 + 0.0im]

U0 = [1.0 + 0.0im 0.0 + 0.0im
0.0 + 0.0im 1.0 + 0.0im]

# function series_exp(A)
#     # u02 = Array{ComplexF64,2}(I(2))
    
#     #out = U0 + (A + (A * A) / 2) # + ((A^3) / 6 + (A^4) / 24))
# end

function evolve(x)
    # x = complex.(real.(x))
    N = length(x)
    out = copy(U0)
    for i = 1:N
        ham = ((-1.0im) * sx) * x[i] 
        out = exp(ham) * out
        # U0 = exp(-1.0im * 0.1 * sx * x[i]) * U0
    end
    out
end

# define some states
ρ = [1.0 + 0.0im, 0.0 + 0.0im]
ρt = [0.0 + 0.0im, 1.0 + 0.0im]

function functional(x)
    U = evolve(x)
    1 - abs(ρt' * (U * ρ))^2
end

x_input = rand(10)
functional(x_input)

val, tape = Yota.trace(functional, x_input)


Yota.back!(tape)
o = Yota.GradResult(tape)[1]

Yota.compile!(tape)

function test(G, x)
    val, tape = Yota.itrace(functional, x)
    Yota.back!(tape)
    G .= Yota.GradResult(tape)[1]
end

using Optim

gtest = similar(x_input)
test(gtest, x_input)

Yota.simplegrad(functional, x_input)

res = Optim.optimize(functional, test, x_input, Optim.LBFGS(), Optim.Options(show_trace = true))

grad(functional, x_input)


Yota.simplegrad(functional, x_input)


Yota.back!(tape)
import Base./

# first diffrule needed
@diffrule abs(x::Number) x x / sqrt(real(x)^2 + imag(x)^2)
@diffrule abs2(x::Number) x abs(x)^2
@diffrule (/)(u::Array{ComplexF64,2}, v::Number) u dy / v
# expand list of rules for (*) to match complex numbers and arrays
@diffrule *(u::Number, v::Number)            u     v * dy
@diffrule *(u::Number, v::AbstractArray)    u     sum(v .* dy)
@diffrule *(u::AbstractArray, v::Number)            u     v .* dy
@diffrule *(u::AbstractArray, v::AbstractArray)    u     dy * transpose(v)

@diffrule *(u::Number, v::Number)            v     u * dy
@diffrule *(u::Number, v::AbstractArray)    v     u .* dy
@diffrule *(u::AbstractArray, v::Number)            v     sum(u .* dy)
@diffrule *(u::AbstractArray, v::AbstractArray)    v     transpose(u) * dy


using Zygote
grad_zygote = Zygote.gradient(functional, x_input)[1]

Zygote.refresh()

using FiniteDiff
FiniteDiff.finite_difference_gradient(functional, x_input)