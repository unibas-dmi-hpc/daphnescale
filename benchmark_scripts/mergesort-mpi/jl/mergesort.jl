using MPI
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

# Insertion sort for small arrays (right exclusive) --> the leaves of merge sort
function insertion_sort!(arr, left, right)
    for i in left+1:right-1
        key = arr[i]
        j = i - 1
        while j ≥ left && arr[j] > key
            arr[j+1] = arr[j]
            j -= 1
        end
        arr[j+1] = key
    end
end

# Merge step a[left:mid] and a[mid:right] using tmp buffer
function merge!(arr, left, mid, right, tmp)
    i = left
    j = mid
    k = left

    while i < mid && j < right
        if arr[i] <= arr[j]
            tmp[k] = arr[i]
            i += 1
        else
            tmp[k] = arr[j]
            j += 1
        end
        k += 1
    end

    while i < mid
        tmp[k] = arr[i]
        i += 1
        k += 1
    end

    while j < right
        tmp[k] = arr[j]
        j += 1
        k += 1
    end

    # Copy back
    @inbounds for idx in left:right-1
        arr[idx] = tmp[idx]
    end
end

# Recursive merge sort implementation
function merge_sort!(arr, left, right, tmp, threshold)
    size = right - left
    if size <= 1
        return
    end

    if size <= threshold
        insertion_sort!(arr, left, right)
        return
    end

    mid = left + size ÷ 2

    merge_sort!(arr, left, mid, tmp, threshold)
    merge_sort!(arr, mid, right, tmp, threshold)
    merge!(arr, left, mid, right, tmp)
end

# Compute child rank in binary tree of ranks
function compute_child(rank, depth, max_depth)
    if depth >= max_depth
        return nothing
    end
    bit_pos = max_depth - depth - 1
    child = rank | (1 << bit_pos)

    if child >= size
        return nothing
    end
    if child == rank
        return nothing
    end
    return child
end

# Parallel merge sort implementation sending to ranks in recursion --> binary tree of ranks
# only the leaves do perform work (recursive merge sort, insertion sort at the bottom)
function merge_sort_parallel(arr, threshold, max_depth, depth)
    n = length(arr)

    child = compute_child(rank, depth, max_depth)
    if child === nothing || n <= threshold
        tmp = copy(arr)
        merge_sort!(arr, 1, n+1, tmp, threshold)
        return arr
    end

    mid = div(n, 2)
    left_part  = arr[1:mid]
    right_part = arr[mid+1:end]

    # send right part to child
    MPI.send(right_part, comm; dest=child, tag=depth)

    # recurse on left
    sorted_left = merge_sort_parallel(left_part, threshold, max_depth, depth + 1)

    # receive right sorted part from child (source/tag known)
    sorted_right = MPI.recv(comm; source=child, tag=depth)

    # merge
    merged = vcat(sorted_left, sorted_right)
    tmp = copy(merged)
    merge!(merged, 1, length(sorted_left)+1, length(merged)+1, tmp)

    return merged
end

# Main
function main()
    if length(ARGS) != 2
        println("Usage: julia mergesort.jl SIZE THRESHOLD")
        MPI.Finalize()
        exit()
    end

    N = parse(Int, ARGS[1])
    threshold = parse(Int, ARGS[2])
    max_depth = floor(Int, log2(size))    

    if rank == 0
        # Generate reverse sorted array
        start_gen = time_ns()
        arr = [N - i for i in 0:N-1]

        start_sort = time_ns()
        sorted_arr = merge_sort_parallel(arr, threshold, max_depth, 0)
        stop_time =time_ns()

        # Correctness check: H = Sum^{N-1}_{i=0} (i * arr[i}) <=> H = N(N-1)(N+1)/3
        H = 0
        for i in 1:length(arr)
            H += (i-1) * sorted_arr[i]     
        end
        c = H / (N * N * N)

        duration_ete = (stop_time - start_gen) * 1e-9
        duration_sort = (stop_time - start_sort) * 1e-9

        println("$(duration_ete),$(duration_sort),$(c)")

        # terminate workers
        for r in 1:size-1
            MPI.send(Int[], comm; dest=r, tag=999)
        end

    else
        while true
            # receive message from any parent, with status to get tag/source
            msg, status = MPI.recv(comm, MPI.Status;
                                   source=MPI.ANY_SOURCE, tag=MPI.ANY_TAG)
            parent = MPI.Get_source(status)
            tag    = MPI.Get_tag(status)

            if tag == 999
                break
            end

            depth = tag
            data = msg::Vector{Int}
            sorted_data = merge_sort_parallel(data, threshold, max_depth, depth + 1)
            MPI.send(sorted_data, comm; dest=parent, tag=depth)
        end
    end
end

main()
MPI.Finalize()