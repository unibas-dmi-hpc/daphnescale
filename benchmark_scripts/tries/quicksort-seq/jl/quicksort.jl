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

# Sort function to call from main
function sort!(arr, threshold)
    tmp = copy(arr)
    merge_sort!(arr, 1, length(arr)+1, tmp, threshold)
end

# Main
function main()
    if length(ARGS) != 2
        println("Usage: julia mergesort.jl SIZE THRESHOLD")
        exit(1)
    end

    N = parse(Int, ARGS[1])
    threshold = parse(Int, ARGS[2])

    # Generate reverse sorted array
    start_gen = time_ns()
    arr = [N - i for i in 0:N-1]

    start_sort = time_ns()
    sort!(arr, threshold)
    stop_time =time_ns()

    # Correctness check: H = Sum^{N-1}_{i=0} (i * arr[i}) <=> H = N(N-1)(N+1)/3
    H = 0
    for i in 1:length(arr)
        H += (i-1) * arr[i]     
    end
    c = H / (N * N * N)

    duration_ete = (stop_time - start_gen) * 1e-9
    duration_sort = (stop_time - start_sort) * 1e-9

    println("$(duration_ete),$(duration_sort),$(c)")
end

main()
