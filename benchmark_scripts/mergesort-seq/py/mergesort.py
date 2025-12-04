import sys
import time

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

# Sort function to call from main
def sort(arr, threshold):
    tmp = arr.copy()
    merge_sort(arr, 0, len(arr), tmp, threshold)

# Main
if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("Usage: python mergesort.py SIZE THRESHOLD")
        sys.exit(1)

    N = int(sys.argv[1])
    threshold = int(sys.argv[2])

    # Generate reverse sorted array
    start_gen = time.time()
    arr = [N - i for i in range(N)]

    start_sort = time.time()
    sort(arr, threshold)
    end = time.time()

    # Correctness check: H = Sum^{N-1}_{i=0} (i * arr[i}) <=> H = N(N-1)(N+1)/3
    H = 0
    for i, val in enumerate(arr):
        H += i * val
    c = H / (N * N * N)   # scaled correctness check

    duration_ete = end - start_gen
    duration_sort = end - start_sort

    print(f'{duration_ete},{duration_sort},{c:.16f}')