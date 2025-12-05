#!/bin/bash

#SBATCH --partition=cpu
#SBATCH --mem=128G
#SBATCH --hint=nomultithread
#SBATCH --time=0-00:15:00

set -ex

NUM_THREADS=$1
SCRIPT=$2
MATRIX_PATH=$3
MATRIX_SIZE=$4 # unsued but kept to have the same api as for the other sbatch scripts
RESULT=$5

mkdir -p "$(dirname "${SLURM_SUBMIT_DIR}/${RESULT}")"

export OMP_NUM_THREADS=${NUM_THREADS}
export OPENBLAS_NUM_THREADS=${NUM_THREADS}
export MKL_NUM_THREADS=${NUM_THREADS}
export VECLIB_MAXIMUM_THREADS=${NUM_THREADS}
export NUMEXPR_NUM_THREADS=${NUM_THREADS}

export UCX_TLS=self,sm
export OMPI_MCA_PML="ucx"
export PMIX_MCA_gds="hash"

srun --mpi=pmix --cpus-per-task=${NUM_THREADS} singularity exec -B /cvmfs:/cvmfs ${SLURM_SUBMIT_DIR}/py314t.sif python3 ${SLURM_SUBMIT_DIR}/${SCRIPT} ${SLURM_SUBMIT_DIR}/${MATRIX_PATH} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
