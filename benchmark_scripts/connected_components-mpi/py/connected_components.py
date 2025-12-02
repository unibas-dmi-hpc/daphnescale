import sys
import time
import numpy as np
from scipy.io import mmread
from scipy.sparse import csr_matrix, csr_array

from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

def read_and_send_sparse_matrix(filename):
    rank = comm.Get_rank()
    nb_sub = comm.Get_size()
    shape = 0
    n = 0
    Gs = None
    if rank == 0:
        G = csr_matrix(mmread(filename))
        n = G.shape[0]
        fh_indices = []
        fh_indptr  = []
        fh_data    = []
        fh_ptr     = [0 for _ in range(nb_sub)]
        shapes     = [n // nb_sub for _ in range(nb_sub)]
        shapes[-1] = n - sum(shapes[:-1])
        for k in range(nb_sub):
            fh_indices.append([])
            fh_indptr.append([0])
            fh_data.append([])

        remainer = n % nb_sub

        row_id = 0
        while row_id < len(G.indptr) - 1:
            next_ptr = G.indptr[row_id + 1]
            current_ptr = G.indptr[row_id]
            k = row_id // (n // nb_sub)
            if k >= nb_sub:
                k = nb_sub -1
            #print(f"{row_id} -> {k}")
            nb_elements = next_ptr - current_ptr
            indices = G.indices[current_ptr:next_ptr]
            half_indices = [ind for ind in indices]
            fh_indices[k] += half_indices
            fh_ptr[k] += len(indices)
            fh_data[k] += [1.0 for _ in range(len(indices))]
            fh_indptr[k].append(fh_ptr[k])
            row_id += 1

        for k in range(1, nb_sub):
            G_h = csr_matrix((fh_data[k], fh_indices[k], fh_indptr[k]), shape=(shapes[k], n))
            info = {"n_data": len(fh_data[k]), "n_indices": len(fh_indices[k]), "n_indptr": len(fh_indptr[k]), "shape": shapes[k], "n": n}
            #print(f"{k} -> {info['n_indptr']} -> {np.array(fh_indptr[k])}")
            comm.send(info, dest=k, tag=10)
            #comm.Send(len(fh_data[k]),    dest=k, tag=10)
            #comm.Send(len(fh_indices[k]), dest=k, tag=11)
            #comm.Send(len(fh_indptr[k]),  dest=k, tag=12)
            #comm.Send(fh_shapes[k],       dest=k, tag=13)

            #plop = np.array(fh_indptr[k])
            #print(plop.dtype)
            comm.Send(np.array(fh_indptr[k]),    dest=k, tag=121)
            comm.Send(np.array(fh_data[k]),    dest=k, tag=101)
            comm.Send(np.array(fh_indices[k]), dest=k, tag=111)

        # TODO 0
        data = fh_data[0]
        indices = fh_indices[0]
        indptr = fh_indptr[0]
        shape = shapes[0]
        Gs = csr_matrix((data, indices, indptr), shape=(shape, n))
    else:
        info = comm.recv(source=0, tag=10)
        #print(info)
        n_data = info["n_data"]
        n_indices = info["n_indices"]
        n_indptr = info["n_indptr"]
        shape = info["shape"]
        n = info["n"]

        data = np.empty(n_data, dtype=np.float64)
        indptr = np.zeros(n_indptr, dtype=np.int64)
        indices = np.empty(n_indices, dtype=np.int32)

        comm.Recv(indptr,  source=0, tag=121)
        comm.Recv(data,    source=0, tag=101)
        comm.Recv(indices, source=0, tag=111)

        Gs = csr_matrix((data, indices, indptr), shape=(shape, n))
    #print(f"{rank}:\n{Gs.A}\n\n\n")
    return Gs

def reduce_max(xmem, ymem, dt):
    x = np.frombuffer(xmem, dtype=np.float64)
    y = np.frombuffer(ymem, dtype=np.float64)
    z = np.maximum(x, y)
    y[:] = z

def cc(filename, maxi=100):
    start_reading = time.time()
    G = read_and_send_sparse_matrix(filename)
    op = MPI.Op.Create(reduce_max, commute=True)
    start_compute = time.time()
    world = comm.Get_size()
    n = G.shape[1]
    sizes = [n // world for _ in range(world)]
    sizes[-1] = n - sum(sizes[:-1])
    offsets = np.zeros(world, dtype=np.int32)
    offsets[1:]=np.cumsum(sizes)[:-1]

    c = np.array([list(map(lambda i: float(i), range(1, n + 1, 1)))])

    for iter in range(maxi):
        # 1. Multiply G element-wise with broadcasted c
        G_weighted = G.multiply(c[0])  # each G[i,j] * c[j]

        # 2. Compute max of each row (only the rows owned by this rank)
        x_partial = G_weighted.max(axis=1)  # shape: (local_rows, 1)
        x_partial = np.asarray(x_partial.todense()).ravel()  # shape: (sizes[rank],)

        # 3. Gather all x_partial into full x vector
        x_full = np.empty(n, dtype=np.float64)
        comm.Allgatherv(
            x_partial,
            [x_full, sizes, offsets, MPI.DOUBLE]
        )

        # 4. Element-wise max update of c
        c = np.maximum(c, x_full.reshape(1, n))

    end = time.time()
    if rank == 0:
        fin = time.time()
        duration_reading = fin - start_reading
        duration_compute = fin - start_compute
        print(f"{duration_reading},{duration_compute},{c.sum()}")

if __name__ == "__main__":
    args = sys.argv
    assert len(args) == 2
    filename = args[1]
    cc(filename)
