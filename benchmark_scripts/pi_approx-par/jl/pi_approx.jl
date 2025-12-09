using Base.Threads

function compute_chunksize(n, num_workers)
    chunk = fld(n, num_workers)           
    extra = n % num_workers               
    if extra != 0
        chunk += 1
    end
    return chunk
end

function approx_pi(num_intervals, num_threads)
    chunk = compute_chunksize(num_intervals, num_threads)
    w = 1 / num_intervals
    partial = zeros(Float64, num_threads)

    @threads for tid in 1:num_threads
        start = (tid - 1) * chunk
        finish = min(tid * chunk, num_intervals)
        local_pi = 0.0
        for i in start:(finish - 1) # Julia ranges are inclusive
            llocal = (i + 0.5) * w
            local_pi += 4 / (1 + llocal * llocal)
        end
        partial[tid] = local_pi
    end

    return sum(partial) * w
end

# Main
function main()
    if length(ARGS) != 2
        println("Usage: julia pi_approx.jl NUM_INTERVALS NUM_THREADS")
        exit(1)
    end

    start_data = time_ns()
    num_intervals = parse(Int, ARGS[1])
    num_threads = parse(Int, ARGS[2])

    start_compute = time_ns()
    pi = approx_pi(num_intervals, num_threads)
    stop_time =time_ns()

    duration_ete = (stop_time - start_data) * 1e-9
    duration_compute = (stop_time - start_compute) * 1e-9

    println("$(duration_ete),$(duration_compute),$(pi)")
end

main()