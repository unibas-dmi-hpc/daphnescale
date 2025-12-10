using MPI
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

function compute_chunksize(n, num_workers)
    chunk = fld(n, num_workers)           
    extra = n % num_workers               
    if extra != 0
        chunk += 1
    end
    return chunk
end

function approx_pi(num_intervals)
    chunk = compute_chunksize(num_intervals, size)
    w = 1.0 / num_intervals
    start = rank * chunk
    finish = min(start + chunk, num_intervals)

    local_pi = 0.0
    for i in start:(finish - 1)
        llocal = (i + 0.5) * w
        local_pi += 4.0 / (1.0 + llocal * llocal)
    end

    pi = MPI.Reduce(local_pi, MPI.SUM, 0, comm)

    if rank == 0
        return pi * w
    else
        return nothing
    end
end

# Main
function main()
    if length(ARGS) != 1
        println("Usage: julia pi_approx.jl NUM_INTERVALS")
        MPI.Finalize()
        exit(1)
    end

    start_data = time_ns()
    num_intervals = parse(Int, ARGS[1])

    start_compute = time_ns()
    pi = approx_pi(num_intervals)
    stop_time =time_ns()

    # Only rank 0 prints the result
    if pi !== nothing
        duration_ete = (stop_time - start_data) * 1e-9
        duration_compute = (stop_time - start_compute) * 1e-9
        println("$(duration_ete),$(duration_compute),$(pi)")
    end
end

main()
MPI.Finalize()