using Random

function compute_pi(N)
    approx = 0.0
    start = time_ns()
    for i in 1:N
        x = rand()
        y = rand()
        if x*x + y*y < 1.0
            approx += 1
        end
    end
    res = 4.0 * approx / N
    fin = time_ns()
    println("PI: $(res) computed in $((fin - start) * 1e-9) seconds")
end

N = 100_000_000
compute_pi(N)
