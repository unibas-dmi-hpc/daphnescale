import sys
import time
from scipy.io import mmread
from scipy.sparse import csr_matrix, csr_array
import numpy as np

def cc(filename, maxi=100):
    start_reading = time.time()
    G = csr_matrix(mmread(filename))
    start_compute = time.time()
    n = G.shape[1]
    c = np.array([list(map(lambda i: float(i), range(1, n + 1, 1)))]).transpose()

    for iter in range(maxi):
        x = G.multiply(c.transpose()).max(axis=1)
        c = np.maximum(c, x.todense())
    fin = time.time()
    duration_reading = fin - start_reading
    duration_compute = fin - start_compute
    print(f"{duration_reading},{duration_compute},{c.sum()}")

if __name__ == "__main__":
    args = sys.argv
    assert len(args) == 2
    filename = args[1]
    cc(filename)
