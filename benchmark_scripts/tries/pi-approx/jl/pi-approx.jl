using Random
N = 1000000
M = rand(N, 2)
start = time_ns()
res = 4.0 * sum(sum(M .* M, dims=2) .< 1) / N
fin = time_ns()
println("PI: $(res) computed in $((fin - start) * 1e-9) seconds")
