using Base.Threads

function merge(L, R)
    n1 = length(L)
    n2 = length(R)
    n = n1 + n2
    tmp = zeros(n)
    i = 1
    j = 1
    k = 1
    while i <= n1 && j <= n2
        if L[i] < R[j]
            tmp[k] = L[i]
            i += 1
        else
            tmp[k] = R[j]
            j += 1
        end
        k += 1
    end

    while i <= n1
        tmp[k] = L[i]
        k += 1
        i += 1
    end

    while j <= n2
        tmp[k] = R[j]
        k += 1
        j += 1
    end

    return tmp
end

function mergesort(array)
    n = length(array)
    if n <= 1024
        return sort(array)
    else
        mid = div(n, 2)
        taskL = @spawn mergesort(array[1:mid])
        taskR = @spawn mergesort(array[(mid+1):n])
        return merge(fetch(taskL), fetch(taskR))
    end
end


function main()
    p = 25
    n = 2^p
    x = rand(n)
    t1 = time_ns()
    R = mergesort(x)
    t2 = time_ns()
    println("sorted $(n) elements in $((t2-t1)*1e-9) seconds")
end

main()
