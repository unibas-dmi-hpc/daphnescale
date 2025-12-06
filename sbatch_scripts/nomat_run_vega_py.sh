#!/bin/bash

#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=128G
#SBATCH --hint=nomultithread
#SBATCH --time=0-00:15:00

set -ex

# Required fixed arguments
NUM_THREADS=$1
SCRIPT=$2
RESULT=$3
# All remaining arguments are benchmark-specific
shift 3
ARGS="$@"

mkdir -p "$(dirname "${SLURM_SUBMIT_DIR}/${RESULT}")"

export OMP_NUM_THREADS=${NUM_THREADS}
export OPENBLAS_NUM_THREADS=${NUM_THREADS}
export MKL_NUM_THREADS=${NUM_THREADS}
export VECLIB_MAXIMUM_THREADS=${NUM_THREADS}
export NUMEXPR_NUM_THREADS=${NUM_THREADS}

srun --mpi=none --cpus-per-task=${NUM_THREADS} singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/py314t.sif python3 ${SLURM_SUBMIT_DIR}/${SCRIPT} ${ARGS} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
