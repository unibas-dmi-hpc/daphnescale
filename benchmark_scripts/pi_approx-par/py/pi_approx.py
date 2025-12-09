import sys
import time
import math # for better floating point sum accuracy
from multiprocessing.pool import ThreadPool

def compute_chunksize(n, num_workers):
    chunksize, extra = divmod(n, num_workers)
    if extra:
        chunksize += 1
    return chunksize

def worker_sum(tt):
    start, chunk, n, w = tt
    end = min(start + chunk, n)
    local_sum = 0.0
    for i in range(start, end):
        local = (i + 0.5) * w
        local_sum += 4.0 / (1.0 + local * local)
    return local_sum

def approx_pi(num_intervals, num_threads):
    chunk = compute_chunksize(num_intervals, num_threads)
    w = 1.0 / num_intervals                             # step width

    # Build only the chunk starting indices
    starts = range(0, num_intervals, chunk)

    with ThreadPool(processes=num_threads) as pool:
        results = pool.map(worker_sum, [(start, chunk, num_intervals, w) for start in starts])     # returns a list of results from each process, map blocks until all are done

    pi = math.fsum(results)   
    return pi * w

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python pi_approx.py NUM_INTERVALS NUM_THREADS")
        sys.exit(1)

    start_data = time.time()
    num_intervals = int(sys.argv[1])
    num_threads = int(sys.argv[2])

    start_compute= time.time()
    pi = approx_pi(num_intervals, num_threads)
    end = time.time()

    duration_ete = end - start_data
    duration_sort = end - start_compute
    print(f'{duration_ete},{duration_sort},{pi:.16f}')