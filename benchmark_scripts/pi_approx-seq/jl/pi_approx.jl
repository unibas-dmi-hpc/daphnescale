function approx_pi(num_intervals)
    pi = 0.0
    w = 1.0 / num_intervals
    for i in 0:num_intervals-1
        llocal = (i + 0.5) * w  # local is a keyword in Julia
        pi += 4.0 / (1.0 + llocal * llocal)
    end
    return pi * w
end

# Main
function main()
    if length(ARGS) != 1
        println("Usage: julia pi_approx.jl NUM_INTERVALS")
        exit(1)
    end

    start_data = time_ns()
    num_intervals = parse(Int, ARGS[1])

    start_compute = time_ns()
    sort!(arr, threshold, workers)
    stop_time =time_ns()

    duration_ete = (stop_time - start_data) * 1e-9
    duration_compute = (stop_time - start_compute) * 1e-9

    println("$(duration_ete),$(duration_compute),$(c)")
end

main()