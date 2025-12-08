import sys
import time

def approx_pi(num_intervals):
    pi = 0.0
    w = 1.0 / num_intervals                 # step width
    for i in range(num_intervals):          # for each subinterval
        local = (i + 0.5) * w               # local midpoint
        pi += 4.0 / (1.0 + local * local)   # f(local)
    
    return pi * w

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python pi_approx.py NUM_INTERVALS")
        sys.exit(1)

    start_data = time.time()
    num_intervals = int(sys.argv[1])

    start_compute= time.time()
    pi = approx_pi(num_intervals)
    end = time.time()

    duration_ete = end - start_data
    duration_sort = end - start_compute
    print(f'{duration_ete},{duration_sort},{pi:.16f}')
