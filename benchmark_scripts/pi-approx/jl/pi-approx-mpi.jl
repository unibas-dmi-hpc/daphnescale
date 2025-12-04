using Random
using Base.Threads

using MPI
MPI.Init()

comm = MPI.COMM_WORLD


function compute_pi(N)
    n_threads = Threads.maxthreadid()
    approx = zeros(n_threads)
    @threads for i in 1:N
        x = rand()
        y = rand()
        if x*x + y*y < 1.0
            approx[Threads.threadid()] += 1.0
        end
    end
    return sum(approx)
end


function main()
    N = 100_000_000
    rank = MPI.Comm_rank(comm)
    world = MPI.Comm_size(comm)
    sizes = [div(N, world) for _ in 1:world]
    if rank == 0
        start = time_ns()
    end

    local_res = compute_pi(sizes[rank + 1])
    approx = MPI.Reduce(local_res, MPI.Op(+), comm)
    if rank == 0
        res = 4.0 * approx / N
        fin = time_ns()
        println("PI: $(res) computed in $((fin - start) * 1e-9) seconds")
    end
end

main()
