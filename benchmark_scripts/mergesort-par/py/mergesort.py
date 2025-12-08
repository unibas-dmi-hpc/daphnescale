import math
import sys
import time
import threading 
import os

# Insertion sort for small arrays (right exclusive) --> the leaves of merge sort
def insertion_sort(arr, left, right):
    for i in range(left + 1, right):
        key = arr[i]
        j = i - 1
        while j >= left and arr[j] > key:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key

# Merge step a[left:mid] and a[mid:right] using tmp buffer
def merge(arr, left, mid, right, tmp):
    i, j, k = left, mid, left

    while i < mid and j < right:
        if arr[i] <= arr[j]:
            tmp[k] = arr[i]
            i += 1
        else:
            tmp[k] = arr[j]
            j += 1
        k += 1

    while i < mid:
        tmp[k] = arr[i]
        i += 1
        k += 1

    while j < right:
        tmp[k] = arr[j]
        j += 1
        k += 1

    # copy back
    for idx in range(left, right):
        arr[idx] = tmp[idx]

# Recursive merge sort implementation
def merge_sort(arr, left, right, tmp, threshold):
    size = right - left
    if size <= 1:
        return

    if size <= threshold:
        insertion_sort(arr, left, right)
        return

    mid = left + size // 2

    merge_sort(arr, left, mid, tmp, threshold)
    merge_sort(arr, mid, right, tmp, threshold)
    merge(arr, left, mid, right, tmp)

# Parallel merge sort implementation spawning threads in recursion --> binary tree of threads
# only the leaves do perform work (recursive merge sort, insertion sort at the bottom)
def merge_sort_parallel(arr, left, right, tmp, threshold, max_depth, depth):
    size = right - left
    if size <= 1:
        return

    if size <= threshold:
        insertion_sort(arr, left, right)
        return

    mid = left + size // 2

    if depth < max_depth:
        left_thread = threading.Thread(target=merge_sort_parallel, args=(arr, left, mid, tmp, threshold, max_depth, depth + 1))
        right_thread = threading.Thread(target=merge_sort_parallel, args=(arr, mid, right, tmp, threshold, max_depth, depth + 1))

        left_thread.start()
        right_thread.start()
        # wait for them to join
        left_thread.join()
        right_thread.join()
    else:
        merge_sort(arr, left, mid, tmp, threshold)
        merge_sort(arr, mid, right, tmp, threshold)

    merge(arr, left, mid, right, tmp)

# Sort function to call from main
def sort(arr, threshold, workers):
    tmp = arr.copy()
    max_depth = math.floor(math.log2(workers))  # the max depth to spawn threads
    depth = 0
    merge_sort_parallel(arr, 0, len(arr), tmp, threshold, max_depth, depth)

# Main
if __name__ == "__main__":

    if len(sys.argv) != 4:
        print("Usage: python mergesort.py SIZE THRESHOLD N_WORKERS")
        sys.exit(1)

    N = int(sys.argv[1])
    threshold = int(sys.argv[2])
    workers = int(sys.argv[3])

    # Generate reverse sorted array
    start_gen = time.time()
    arr = [N - i for i in range(N)]

    cpu_before = os.times().user
    start_sort = time.time()
    sort(arr, threshold, workers)
    end = time.time()
    cpu_after = os.times().user

    # Correctness check: H = Sum^{N-1}_{i=0} (i * arr[i}) <=> H = N(N-1)(N+1)/3
    H = 0
    for i, val in enumerate(arr):
        H += i * val
    c = H / (N * N * N)   # scaled correctness check

    duration_ete = end - start_gen
    duration_sort = end - start_sort

    print(f'{duration_ete},{duration_sort},{c:.16f}')
    #print(f'Version {sys.version},GIL enabled: {sys._is_gil_enabled()}')

    cpu_used = cpu_after - cpu_before
    wall_used = end - start_sort
    ratio = cpu_used / wall_used if wall_used > 0 else float('nan')

    print(f"CPU time used: {cpu_used:.4f} sec")
    print(f"Wall time:     {wall_used:.4f} sec")
    print(f"CPU/Wall ratio: {ratio:.2f}  (parallelism indicator)")
