import math
import sys
import time
import threading 
import os
import numpy as np

# Insertion sort for small arrays (right exclusive) --> the leaves of merge sort
def insertion_sort(arr, left, right):
    for i in range(left + 1, right):
        key = arr[i]
        j = i - 1
        while j >= left and arr[j] > key:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key

# Median-of-three pivot selection, returns the index of the pivot element
def median_of_three(arr, a, b, c):
    A, B, C = arr[a], arr[b], arr[c]
    if A < B:
        if B < C:
            return b
        return c if A < C else a
    else:
        if A < C:
            return a
        return c if B < C else b
    
# Partition array using Lomuto partitioning with a chosen pivot
def partition(arr, left, right):
    # right is exclusive, so pivot index must be < right
    mid = left + (right - left) // 2
    pivot_index = median_of_three(arr, left, mid, right - 1)

    # Move pivot to end
    arr[pivot_index], arr[right - 1] = arr[right - 1], arr[pivot_index]
    pivot = arr[right - 1]

    i = left
    for j in range(left, right - 1):
        if arr[j] <= pivot:
            arr[i], arr[j] = arr[j], arr[i]
            i += 1

    # Move pivot to correct position
    arr[i], arr[right - 1] = arr[right - 1], arr[i]
    return i

# Recursive merge sort implementation
def quicksort(arr, left, right, threshold):
    size = right - left
    if size <= 1:
        return

    if size <= threshold:
        insertion_sort(arr, left, right)
        return

    pivot_pos = partition(arr, left, right)

    quicksort(arr, left, pivot_pos, threshold)
    quicksort(arr, pivot_pos + 1, right, threshold)

# Parallel quick implementation spawning threads in recursion --> binary tree of threads
# only the leaves do perform work (recursive quicksort, insertion sort at the bottom)
def quicksort_parallel(arr, left, right, threshold, max_depth, depth):
    size = right - left
    if size <= 1:
        return

    if size <= threshold:
        insertion_sort(arr, left, right)
        return

    pivot_pos = partition(arr, left, right)

    if depth < max_depth:
        left_thread = threading.Thread(target=quicksort_parallel, args=(arr, left, pivot_pos, threshold, max_depth, depth + 1))
        right_thread = threading.Thread(target=quicksort_parallel, args=(arr, pivot_pos + 1, right, threshold, max_depth, depth + 1))

        left_thread.start()
        right_thread.start()
        # wait for them to join
        left_thread.join()
        right_thread.join()
    else:
        quicksort(arr, left, pivot_pos, threshold)
        quicksort(arr, pivot_pos + 1, right, threshold)

# Sort function to call from main
def sort(arr, threshold, workers):
    max_depth = math.floor(math.log2(workers))  # the max depth to spawn threads
    depth = 0
    quicksort_parallel(arr, 0, len(arr), threshold, max_depth, depth)

# Main
if __name__ == "__main__":

    if len(sys.argv) != 4:
        print("Usage: python mergesort.py INPUT_ARRAY THRESHOLD N_WORKERS")
        sys.exit(1)

    input_file = sys.argv[1]
    threshold = int(sys.argv[2])
    workers = int(sys.argv[3])

    # Generate reverse sorted array
    start_gen = time.time()
    with open(input_file) as f:
        lines = f.read().strip().split("\n")

    N = int(lines[0])
    arr = list(map(int, lines[1:]))
    #arr = [i for i in range(len(arr), 0, -1)]

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
