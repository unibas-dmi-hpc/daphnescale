using Random
using Base.Threads

function compute_pi_atomic(N)
    approx = Threads.Atomic{Float64}(0.0)
    start = time_ns()
    @threads for i in 1:N
        x = rand()
        y = rand()
        if x*x + y*y < 1.0
            Threads.atomic_add!(approx,1.0)
        end
    end
    res = 4.0 * approx[] / N
    fin = time_ns()
    println("PI: $(res) computed in $((fin - start) * 1e-9) seconds [atomic adds]")
end

function compute_pi(N)
    n_threads = Threads.maxthreadid()
    approx = zeros(n_threads)
    start = time_ns()
    @threads for i in 1:N
        x = rand()
        y = rand()
        if x*x + y*y < 1.0
            approx[Threads.threadid()] += 1.0
        end
    end
    res = 4.0 * sum(approx) / N
    fin = time_ns()
    println("PI: $(res) computed in $((fin - start) * 1e-9) seconds")
end

N = 100_000_000
compute_pi_atomic(N)
compute_pi(N)
