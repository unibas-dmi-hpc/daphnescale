import sys
import time
import math # for better floating point sum accuracy
from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

def compute_chunksize(n, num_workers):
    chunksize, extra = divmod(n, num_workers)
    if extra:
        chunksize += 1
    return chunksize

def approx_pi(num_intervals):
    chunk = compute_chunksize(num_intervals, size)
    w = 1.0 / num_intervals
    start = rank * chunk
    end = min(start + chunk, num_intervals)

    local_pi = 0.0
    for i in range(start, end):
        local = (i + 0.5) * w
        local_pi += 4.0 / (1.0 + local * local)

    pi = comm.reduce(local_pi, op=MPI.SUM, root=0)  # reduce all local_pi to total_pi at root rank 0

    if rank == 0:
        return pi * w
    else:
        # return safe dummy values to prevent unpack error
        return None

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python pi_approx.py NUM_INTERVALS")
        MPI.Finalize()
        sys.exit(1)

    start_data = time.time()
    num_intervals = int(sys.argv[1])

    start_compute= time.time()
    pi = approx_pi(num_intervals)
    end = time.time()

    # only rank 0 has not None Pi and prints the result
    if pi is not None:
        duration_ete = end - start_data
        duration_sort = end - start_compute
        print(f'{duration_ete},{duration_sort},{pi:.16f}')

    MPI.Finalize()