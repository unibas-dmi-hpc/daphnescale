import math
import sys
import time
from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

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
    arr_size = right - left
    if arr_size <= 1:
        return

    if arr_size <= threshold:
        insertion_sort(arr, left, right)
        return

    mid = left + arr_size // 2

    merge_sort(arr, left, mid, tmp, threshold)
    merge_sort(arr, mid, right, tmp, threshold)
    merge(arr, left, mid, right, tmp)

# Compute child rank based on current depth
def compute_child(rank, depth, max_depth):
    if depth >= max_depth:
        return None
    bit_pos = max_depth - depth - 1
    child = rank | (1 << bit_pos)
    if child >= size:
        return None
    if child == rank:
        return None
    return child

# Parallel merge sort implementation sending to ranks in recursion --> binary tree of ranks
# only the leaves do perform work (recursive merge sort, insertion sort at the bottom)
def merge_sort_parallel(arr, threshold, max_depth, depth):
    n = len(arr)
    
    # compute child rank
    child = compute_child(rank, depth, max_depth)
     # no child available (=leaf) or below threshold --> local merge sort
    if child is None or n <= threshold:
        tmp = arr.copy()
        merge_sort(arr, 0, n, tmp, threshold)
        return arr
    
    # split array
    mid = n // 2
    left_part = arr[:mid]
    right_part = arr[mid:]

    # send right part to child
    comm.send(right_part, dest=child, tag=depth)

    # sort left part locally
    sorted_left = merge_sort_parallel(left_part, threshold, max_depth, depth + 1)

    # receive sorted right part from child
    sorted_right = comm.recv(source=child, tag=depth)

    # merge sorted parts
    merged = sorted_left + sorted_right
    tmp = merged.copy()
    merge(merged, 0, len(sorted_left), len(merged), tmp)

    return merged
 
# Main
if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("Usage: python mergesort.py SIZE THRESHOLD")
        MPI.Finalize()
        sys.exit(1)

    N = int(sys.argv[1])
    threshold = int(sys.argv[2])
    max_depth = math.floor(math.log2(size))  # the max depth to split to ranks

    if rank == 0:
        start_gen = time.time()  
        # Generate reverse sorted array  
        arr = [N - i for i in range(N)]

        start_sort = time.time()
        sorted_arr = merge_sort_parallel(arr, threshold, max_depth, 0)
        end = time.time()

        # Correctness check: H = Sum^{N-1}_{i=0} (i * arr[i}) <=> H = N(N-1)(N+1)/3
        H = 0
        for i, val in enumerate(sorted_arr):
            H += i * val
        c = H / (N * N * N)   # scaled correctness check

        duration_ete = end - start_gen
        duration_sort = end - start_sort

        print(f'{duration_ete},{duration_sort},{c:.16f}')

        # Tell all workers to stop
        for r in range(1, size):
            comm.send([], dest=r, tag=999)

    else:
        status = MPI.Status()
        # wait for message from parent
        while True:
            data = comm.recv(source=MPI.ANY_SOURCE, tag=MPI.ANY_TAG, status=status)
            parent = status.Get_source()
            tag = status.Get_tag()

            if tag == 999:
                break

            depth = tag
            sorted_data = merge_sort_parallel(data, threshold, max_depth, depth + 1)
            comm.send(sorted_data, dest=parent, tag=depth)

    MPI.Finalize()

