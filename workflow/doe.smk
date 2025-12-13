DAPHNE_GIT_URL    = "https://github.com/daphne-eu/daphne"
# DAPHNE_GIT_COMMIT = "218e4688c132615195e329b2734962b05cd74500" # 0.3
DAPHNE_GIT_COMMIT = "aa1fb14badc0083c2d927210b782745544260f38"
# DAPHNE_DOCKER_TAG = "0.3_X86-64_BASE_ubuntu20.04"
DAPHNE_DOCKER_TAG = "2025-03-12_X86-64_BASE_ubuntu24.04"
JUPYCPP_DOCKER_TAG = "july25"

LANGUAGES = [
  "py",
  "jl",
  "cpp",
  "daph"
]

MATRICES = [
  #"amazon0601",
  #"wikipedia-20070206",
  "ljournal-2008"
]

MATRICES_CONFIG = [
  # "amazon0601",
  # "wikipedia-20070206",
  "ljournal-2008"
]
# benchmarks with matrix input where there is a seq/mpi implementation
SCRIPTS_WITH_MATRICES = [
  "connected_components",
]
# benchmarks with matrix input where the seq implementation is used as par, e.g. for cc, there is only one
SEQ_AS_PAR_SCRIPTS_WITH_MATRICES = [
  "connected_components"
]
# benchmarks with matrix input where there is a separate par implementation too
PAR_SCRIPTS_WITH_MATRICES = [
]

# benchmarks without matrix input where there is a seq/mpi implementation
SCRIPTS = [
  "pi_approx",
  "mergesort",
  "nbody",   
]
# benchmarks without matrix input where the seq implementation is used as par, always true for daphne
SEQ_AS_PAR_SCRIPTS = [
]
# benchmarks without matrix input where there is a separate par implementation too
PAR_SCRIPTS = [
  "pi_approx",
  "mergesort",
  "nbody",
]

TOTAL_ITERS = 5
# TOTAL_ITERS = 1
ITERATIONS = range(1, TOTAL_ITERS + 1)

# Threading experiments
NUM_THREADS_PAR = [1,2,4,8,16,32]
NUM_THREADS_SEQ = [2,4,8,16,32]

# MPI scaling over nodes
MPI_SCALE_NB_NODES = [1,2,4,8,16]
# MPI_SCALE_NB_NODES = [4]

MPI_LOCAL = {
  # total-mpi-procs, task-per-node, cpu-per-task
  # based on 1  node
  "1":  (1,  1), 
  "2":  (2,  1),
  "4": (4,  1),
  "8": (8,  1),
  "16": (16, 1),
  "32": (32, 1),
  # 64 and 128 could not be run for daphne as memory problems
  # --mem=128 worked for 32 processes, not for 64
  # --mem=256 is the limit of Vega node, and takes ages to start on Vega
  # "64": (64, 1),
  # "128": (128, 1),  
}

# MPI distributed with many processes on multiple nodes
MPI_NB_NODES=4
# MPI_DISTRIBUTION = {
#   # total-mpi-procs, task-per-node, cpu-per-task
#   # based on MPI_CONFIG_NB_NODES=4 (4 nodes)
#   "4":  (1,  128),
#   "8":  (2,  64),
#   "16": (4,  32),
#   "32": (8,  16),
#   "64": (16, 8),
#   "128": (32, 4),
#   "256": (64, 2),
#   "512": (128, 1)
# }

SCHEMES = [
  "STATIC",
  "GSS",
  "AUTO",
  "VISS",
  # "SS",
  "TSS",
  "FAC2",
  "TFSS",
  "FISS",
  "PLS",
  "MSTATIC",
  "MFSC",
  "PSS",
]

QUEUE_LAYOUTS = [
  "CENTRALIZED",
  "PERGROUP",
  "PERCPU"
]

VICTIMS = [
  "SEQ",
  "SEQPRI"
]

# Sort arguments
ARRAY_SIZE = 10_000
THRESHOLD = 32

# QS arguments
import math
MAX_THREADS = max(NUM_THREADS_PAR)
MAX_DEPTH = math.floor(math.log2(MAX_THREADS))
QS_INPUT = f"arrays/quicksort_input_N{ARRAY_SIZE}_d{MAX_DEPTH}.dat"

# Pi Approx Arguments
NUM_INTERVALS = 500_000_000

INPUT_DATA = {
    "quicksort": QS_INPUT,
}

ARGUMENTS = {
    "mergesort": {
        "seq": {
            "args": ["array_size", "threshold"],
            "array_size": [ARRAY_SIZE],
            "threshold": [THRESHOLD],
        },
        "par": {
            "args": ["array_size", "threshold", "num_threads"],
            "array_size": [ARRAY_SIZE],
            "threshold": [THRESHOLD],
        },
        "mpi_local": {
            "args": ["array_size", "threshold"],
            "array_size": [ARRAY_SIZE],
            "threshold": [THRESHOLD],
        },
        "mpi_scale": {
            "args": ["array_size", "threshold"],
            "array_size": [ARRAY_SIZE],
            "threshold": [THRESHOLD],
        }                   
    }, 
    "pi_approx": {
        "seq": {
            "args": ["num_intervals"],
            "num_intervals": [NUM_INTERVALS],
        },
        "par": {
            "args": ["num_intervals", "num_threads"],
            "num_intervals": [NUM_INTERVALS],
        },
        "mpi_local": {
            "args": ["num_intervals"], # no num_workers for mpi as comm.Get_size() is used
            "num_intervals": [NUM_INTERVALS],
        },  
        "mpi_scale": {
            "args": ["num_intervals"], # no num_workers for mpi as comm.Get_size() is used
            "num_intervals": [NUM_INTERVALS],
        },                
    },
    "nbody": {
        "seq": {
            "args": ["num_intervals"],
            "num_intervals": [NUM_INTERVALS],
        },
        "par": {
            "args": ["num_intervals", "num_threads"],
            "num_intervals": [NUM_INTERVALS],
        },
        "mpi_local": {
            "args": ["num_intervals"], # no num_workers for mpi as comm.Get_size() is used
            "num_intervals": [NUM_INTERVALS],
        },  
        "mpi_scale": {
            "args": ["num_intervals"], # no num_workers for mpi as comm.Get_size() is used
            "num_intervals": [NUM_INTERVALS],
        },     
}