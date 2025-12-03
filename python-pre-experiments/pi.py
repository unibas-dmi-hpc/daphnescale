# Credits to César Piñeiro, examples here:https://github.com/citiususc/omp4py/blob/main/examples/pi.py
import sys, time, os
import importlib  # used to make sure function modules are reloaded every run as cached oterhrwise
import math # to evaluate the goodness of approximation

# catch omp4py not found exception for those container without it
try:
    from omp4py import omp
    HAVE_OMP4PY = True
except ImportError:
    HAVE_OMP4PY = False

DEFAULT_N = 1_000_000

def worker_sum(tt) -> float:
    """
    Worker function to compute the local sum for a given chunk of subintervals.

    Args:
        tt (Tuple(int, int, int)): Tuple containing the start index, chunk size, and total number of subintervals.

    Returns:
        float: Local sum for the chunk.
    """
    start, chunk, n = tt
    w = 1.0 / n
    end = min(start + chunk, n)
    local_sum = 0.0
    for i in range(start, end):
        local = (i + 0.5) * w
        local_sum += 4.0 / (1.0 + local * local)
    return local_sum

def compute_chunksize(n: int, num_workers: int = 1) -> int:
    """
    Computes the chunk size for workload distribution.

    Args:
        n (int): Total number of subintervals.
        num_workers (int): Number of workers (Default=1).

    Returns:
        int: Chunk size.
    """
    chunksize, extra = divmod(n, num_workers)
    if extra:
        chunksize += 1
    return chunksize

def pi_seq(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule.

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """

    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')

    pi = 0.0
    w = 1.0 / n                             # step width
    for i in range(n):                      # for each subinterval
        local = (i + 0.5) * w               # local midpoint
        pi += 4.0 / (1.0 + local * local)   # f(local)
    
    pi = pi * w
    return pi, (n_task, n_cpu, n_task * n_cpu)

def pi_mp_threads(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule with multiprocessing but with threads.
    - Results are returned in order and all at once.
    - Default worklaod distribution here: https://github.com/python/cpython/blob/main/Lib/multiprocessing/pool.py
        Subclass from multiprocessing.pool
            def _map_async(self, func, iterable, mapper, chunksize=None, ...):
                if chunksize is None:
                    chunksize, extra = divmod(len(iterable), len(self._pool) * 4)
                    if extra:
                        chunksize += 1
    - Chunks assigned to workers as they become free.    

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """
    mp = importlib.import_module("multiprocessing")
    # Explicitly import ThreadPool (not exposed at top level in newer Python)
    ThreadPool = importlib.import_module("multiprocessing.pool").ThreadPool

    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')
    chunk = compute_chunksize(n, n_cpu)
    w = 1.0 / n                             # step width

    # Build only the chunk starting indices
    starts = range(0, n, chunk)

    with ThreadPool(processes=n_cpu) as pool:
        results = pool.map(worker_sum, [(start, chunk, n) for start in starts])     # returns a list of results from each process, map blocks until all are done

    pi = math.fsum(results) * w
    return pi, (n_cpu, n_task, n_task * n_cpu)

def pi_mp_map(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule with multiprocessing.
    - Results are returned in order and all at once.
    - Default worklaod distribution here: https://github.com/python/cpython/blob/main/Lib/multiprocessing/pool.py
        def _map_async(self, func, iterable, mapper, chunksize=None, ...):
            if chunksize is None:
                chunksize, extra = divmod(len(iterable), len(self._pool) * 4)
                if extra:
                    chunksize += 1
    - Chunks assigned to workers as they become free.

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """
    mp = importlib.import_module('multiprocessing')

    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')
    chunk = compute_chunksize(n, n_cpu)
    w = 1.0 / n                             # step width

    # Build only the chunk starting indices
    starts = range(0, n, chunk)

    with mp.Pool(processes=n_cpu) as pool:
        results = pool.map(worker_sum, [(start, chunk, n) for start in starts])     # returns a list of results from each process, map blocks until all are done

    pi = math.fsum(results) * w
    return pi, (n_task, n_cpu, n_task * n_cpu)

def pi_mp_imap(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule with multiprocessing.
    - Results are in order, but can be processed as they arrive.
    - Default worklaod distribution here: https://github.com/python/cpython/blob/main/Lib/multiprocessing/pool.py
        def imap(self, func, iterable, chunksize=1)
    - Chunks assigned to workers as they become free.

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """
    mp = importlib.import_module('multiprocessing')

    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')
    chunk = compute_chunksize(n, n_cpu)
    w = 1.0 / n                             # step width

    # Build only the chunk starting indices
    starts = range(0, n, chunk)

    with mp.Pool(processes=n_cpu) as pool:
        # needs the list() to consume results
        results = list(pool.imap(worker_sum, [(start, chunk, n) for start in starts]))     # returns a list of results from each process, map blocks until all are done

    pi = math.fsum(results) * w
    return pi, (n_task, n_cpu, n_task * n_cpu)

def pi_mp_imap_unordered(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule with multiprocessing.
    - Results are returned as they complete, in any order.
    - Default worklaod distribution here: https://github.com/python/cpython/blob/main/Lib/multiprocessing/pool.py
        def imap_unordered(self, func, iterable, chunksize=1)
    - Chunks assigned to workers as they become free.

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """
    mp = importlib.import_module('multiprocessing')

    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')
    chunk = compute_chunksize(n, n_cpu)
    w = 1.0 / n                             # step width

    # Build only the chunk starting indices
    starts = range(0, n, chunk)

    with mp.Pool(processes=n_cpu) as pool:
        # returns a list of results from each process, map blocks until all are done
        # needs the list() to consume results
        results = list(pool.imap_unordered(worker_sum, [(start, chunk, n) for start in starts]))     

    pi = math.fsum(results) * w
    return pi, (n_task, n_cpu, n_task * n_cpu)

def pi_numba(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule with Numba JIT compilation.
    - Workload distribution with prange
    - The iteration space is divided into chunks that are approximately equal in size
    - It will use OMP: https://numba.pydata.org/numba-doc/dev/user/threading-layer.html

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """
    numba = importlib.import_module('numba')

    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')

    @numba.njit(parallel=True)   # needs to be parallel to use prange
    def compute_pi(n):
        pi = 0.0
        w = 1.0 / n
        for i in numba.prange(n):  # Equivalent to OpenMP static scheduling (schedule(static))
            local = (i + 0.5) * w
            pi += 4.0 / (1.0 + local * local)
        return pi * w

    pi = compute_pi(n)
    # count workers
    print(f'Threading layer chosen: {numba.threading_layer()}')
    print(f'Numba detected {numba.config.NUMBA_NUM_THREADS} threads.')
    
    return pi, (n_task, n_cpu, n_task * n_cpu)

def pi_pyomp(n: int) -> float:
    """
    Computes an approximation of pi using Numba's built-in OpenMP (v0.60+).
    - Static scheduling with k chunksize (Default: The iteration space is divided into chunks that are approximately equal in size)
    - https://www.openmp.org/wp-content/uploads/openmp-tr4.pdf
        "When no chunk_size is specified, the iteration space is divided into chunks that are approximately equal in size, 
        and at most one chunk is distributed to each team of the league. The size of the chunks is unspecified in this case."

    Args:
        n (int): Number of subintervals.
    Returns:
        float: Approximation of pi.
    """
    numba = importlib.import_module("numba")
    numba_openmp = importlib.import_module("numba.openmp")

    # detect available workers (threads only, since OpenMP controls them internally)
    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')
    chunksize = compute_chunksize(n, n_cpu)

    @numba.njit         # short for @jit(nopython=True), function is only compiled if Numba can fully translate it to machine code (no interpreter help)
    def compute_pi(n, chunksize):
        w = 1.0 / n
        pi = 0.0
        # The clause here can't be parameterizied
        with numba_openmp.openmp_context("parallel for reduction(+:pi) schedule(static)"):
            for i in range(n):
                local = (i + 0.5) * w
                pi += 4.0 / (1.0 + local * local)
        return pi * w

    pi = compute_pi(n, chunksize)
    
    return pi, (n_task, n_cpu, n_task * n_cpu)

if HAVE_OMP4PY:
    @omp(compile=True)
    def compute_pi(n, chunksize):
        """
        Computes an approximation of pi using the midpoint rule with omp4py.
        Functions decorated with @omp(compile=True) must be defined at the top level 
        of a module so that source extraction and compilation are feasible. 
        Nested functions, lambda expressions, or dynamically created functions 
        cannot be compiled.
        Scheduling based on os.env OMP_SCHEDULE variable.

        Args:
            n (int): Number of subintervals.
            chunksize (int): Chunk size for static scheduling.  
        
        Returns:
            float: Approximation of pi.
        """
        w  = 1.0 / n
        pi = 0.0

        with omp('parallel for reduction(+:pi)'):
            for i in range(n):
                local = (i + 0.5) * w
                pi += 4.0 / (1.0 + local * local)
        return pi * w
  
def pi_omp4py_static(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule with omp4py and static scheduling.
    - Static scheduling with k chunksize (Default: The iteration space is divided into chunks that are approximately equal in size)
    - https://www.openmp.org/wp-content/uploads/openmp-tr4.pdf
        "When no chunk_size is specified, the iteration space is divided into chunks that are approximately equal in size, 
        and at most one chunk is distributed to each team of the league. The size of the chunks is unspecified in this case."

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """
    # detect available workers (threads only, since OpenMP controls them internally)
    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')
    chunksize = compute_chunksize(n, n_cpu)

    size = len(os.sched_getaffinity(0))

    os.environ["OMP_SCHEDULE"] = f'static,{chunksize}'
    pi = compute_pi(n, chunksize)
    print("OMP threads:", os.environ.get("OMP_NUM_THREADS"))

    return pi, (n_task, size, n_task * size)

def pi_omp4py_guided(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule with omp4py and guided scheduling.
    - Guided scheduling with decreasing chunksize.

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """
    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')
    chunksize = compute_chunksize(n, n_cpu)

    size = len(os.sched_getaffinity(0))

    os.environ["OMP_SCHEDULE"] = 'guided'
    pi = compute_pi(n, chunksize)
    print("OMP threads:", os.environ.get("OMP_NUM_THREADS"))

    return pi, (n_task, size, n_task * size)

def pi_omp4py_dynamic(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule with omp4py dynamic scheduling.
    - Dynamic scheduling with k chunksize (Default k=1)

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """
    n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
    n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')
    chunksize = compute_chunksize(n, n_cpu)    

    size = len(os.sched_getaffinity(0))

    os.environ["OMP_SCHEDULE"] = 'dynamic'
    pi = compute_pi(n, chunksize)
    print("OMP threads:", os.environ.get("OMP_NUM_THREADS"))

    return pi, (n_task, size, n_task * size)

def pi_mpi4py(n: int) -> float:
    """
    Computes an approximation of pi using the midpoint rule with mpi4py.

    Args:
        n (int): Number of subintervals.

    Returns:
        float: Approximation of pi.
    """
    MPI = importlib.import_module("mpi4py.MPI")

    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()

    if rank == 0:
        print("mpi4py built against:", MPI.get_vendor())
        lib_version = MPI.Get_library_version().rstrip("\x00")
        print("MPI library version:", lib_version)
        print("MPI standard version:", MPI.Get_version())
        n_cpu = get_slurm_resources().get('SLURM_CPUS_PER_TASK')
        n_task = get_slurm_resources().get('SLURM_NTASKS_PER_NODE')

    # work distribution need to be handled manually.
    w = 1.0 / n
    local_n = compute_chunksize(n, size)
    start = rank * local_n
    end = start + local_n if rank != size - 1 else n

    local_pi = 0.0
    for i in range(start, end):
        local = (i + 0.5) * w
        local_pi += 4.0 / (1.0 + local * local)

    pi = comm.reduce(local_pi, op=MPI.SUM, root=0)  # reduce all local_pi to total_pi at root rank 0

    if rank == 0:
        # count workers
        workers = (n_cpu, size, size * n_cpu)
        pi = pi * w
        return pi, workers
    else:
        # return safe dummy values to prevent unpack error
        return None, (0, 0, 0)

def get_slurm_resources():
    resources = {}
    slurm_vars = [
        'SLURM_JOB_ID',
        'SLURM_JOB_NAME',
        'SLURM_JOB_PARTITION',
        'SLURM_JOB_NUM_NODES',
        'SLURM_JOB_NODELIST',
        'SLURM_NTASKS_PER_NODE',
        'SLURM_CPUS_PER_TASK',
        'SLURM_MEM_PER_NODE',
        'SLURM_TIME'  # that one is not existing by default
    ]
    
    for var in slurm_vars:
        value = os.getenv(var)
        try:
            resources[var] = int(value) if value is not None else 'NA'
        except ValueError:
            resources[var] = value if value is not None else 'NA'

    
    return resources

WAYS = {
    'seq': pi_seq,
    'mp-threads': pi_mp_threads,
    'mp-map': pi_mp_map,
    'mp-imap': pi_mp_imap,
    'mp-imap_unordered': pi_mp_imap_unordered,
    'numba': pi_numba,
    'pyomp': pi_pyomp,
    'omp4py-static': pi_omp4py_static,
    'omp4py-guided': pi_omp4py_guided,
    'omp4py-dynamic': pi_omp4py_dynamic,
    'mpi4py': pi_mpi4py,
}

def experiments(n: int, way: str):
    """
    Runs experiments to approximate pi using different methods.

    Args:
        n (int): Number of subintervals.
        way (str): Method to use ('seq' for sequential).
    """    
    # get function to execute
    func = WAYS.get(way)
    if func is None:
        raise ValueError(f'Unknown method: {way}')

    st = time.perf_counter()
    pi, workers = func(n)
    et = time.perf_counter() - st

    # unpack
    n_threads, n_procs, total_workers = workers

    # pi error
    if pi is not None:
        abs_error = abs(pi - math.pi)
        rel_error = abs_error / math.pi

        n_str = f'{n:,}'.replace(',', "'")
        print(f'Approximation of pi {way} with {n_str} intervals: {pi}')
        print(f'Absolute error: {abs_error:.10e}  |  Relative error: {rel_error:.3e}')    
        print(f'Detected {n_threads} threads and {n_procs} processes/ranks (total workers: {total_workers})')
        print(f'Time taken {way}: {et:.6f} seconds')

        GIL_str = ''
        if sys.version.__contains__('3.14'):
            GIL_str = f' (GIL enabled: {sys._is_gil_enabled()})'

        print('---------------------------')
        print(f'Experiment {way} with {sys.version}{GIL_str} finsihed.')
        print('===========================')

if __name__ == "__main__":
    # parse command line arguments
    if len(sys.argv) < 2:
        print(f'Usage: python pi_approx.py <way> [num_intervals (default={DEFAULT_N})]')
        sys.exit(1) 
    way = sys.argv[1]
    n = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_N

    # run experiments
    experiments(n, way)
