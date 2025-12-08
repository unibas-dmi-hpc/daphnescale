import numpy as np

# Balanced-disorder generator for Quicksort benchmarking
# - Ensures pivot ALWAYS lands at the midpoint of the array segment
# - Ensures value ranges perfectly match array segment sizes
# - Ensures disorder in left/right halves to force partition work
# - Uses UPPER MEDIAN pivot for even-sized ranges 


def make_balanced_disorder(n, max_depth):
    arr = [0] * n

    def fill(left, right, lo, hi, depth):
        """
        Fill arr[left:right] using values lo..hi inclusive.
        left/right: index range
        lo/hi:      value range
        """
        length = right - left
        if length <= 0:
            return

        # Base case: scatter values in alternating high/low pattern
        if depth == max_depth or length == 1:
            vals = list(range(lo, hi + 1))
            i, j = 0, len(vals) - 1
            idx = left
            while i <= j:
                arr[idx] = vals[j]
                idx += 1
                if i != j:
                    arr[idx] = vals[i]
                    idx += 1
                i += 1
                j -= 1
            return

        # Place pivot at midpoint of array segment
        mid = (left + right) // 2

        # Use UPPER MEDIAN for even number of values
        # This ensures left_count = left_size and right_count = right_size
        pivot = lo + (hi - lo + 1) // 2

        arr[mid] = pivot

        # Compute sizes
        left_size  = mid - left
        right_size = right - (mid + 1)

        # Compute value counts
        left_count  = pivot - lo         # values lo..pivot-1
        right_count = hi - pivot         # values pivot+1..hi

        # Safety checks for debugging
        if left_size != left_count:
            raise ValueError(
                f'Left mismatch: segment size {left_size} but value count {left_count} '
                f'(lo={lo}, hi={hi}, pivot={pivot}, left={left}, mid={mid})'
            )
        if right_size != right_count:
            raise ValueError(
                f'Right mismatch: segment size {right_size} but value count {right_count} '
                f'(lo={lo}, hi={hi}, pivot={pivot}, mid={mid}, right={right})'
            )

        # Recursively fill left and right halves
        fill(left, mid, lo, pivot - 1, depth + 1)
        fill(mid + 1, right, pivot + 1, hi, depth + 1)

    # Call the recursive generator
    fill(0, n, 1, n, 0)

    return arr


# SCRIPT ENTRY POINT (Snakemake injects "snakemake" object)
N = int(snakemake.params.N)
depth = int(snakemake.params.depth)
outfile = snakemake.output[0]

print(f'[BalancedQS] Generating array: N={N}, depth={depth}, outfile={outfile}')

arr = make_balanced_disorder(N, depth)

with open(outfile, 'w') as f:
    f.write(f'{len(arr)}\n')
    for x in arr:
        f.write(f'{x}\n')

# Verify correctness of input by sorting once in Python
arr_test = sorted(arr)
H = sum(i * v for i, v in enumerate(arr_test))
c = H / (N * N * N)

if abs(c - 1/3) > 1e-12:
    raise RuntimeError(
        f'Correctness check failed: c={c}, expected ~0.333333333333'
    )

print(f'[BalancedQS] Correctness OK: c={c:.16f}')