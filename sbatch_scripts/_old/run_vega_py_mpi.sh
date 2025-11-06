#!/bin/bash

#SBATCH --job-name=daphnesched2
#SBATCH --partition=cpu
#SBATCH --hint=nomultithread
#              d-hh:mm:ss
#SBATCH --time=0-02:00:00
#SBATCH --wait
#SBATCH --mem=128G

set -ex

NUM_THREADS=$1
SCRIPT=$2
MATRIX_PATH=$3
MATRIX_SIZE=$4 # unsued but kept to have the same api as for the other sbatch scripts
RESULT=$5

export OMP_NUM_THREADS=${NUM_THREADS}
export OPENBLAS_NUM_THREADS=${NUM_THREADS}
export MKL_NUM_THREADS=${NUM_THREADS}
export VECLIB_MAXIMUM_THREADS=${NUM_THREADS}
export NUMEXPR_NUM_THREADS=${NUM_THREADS}

export UCX_TLS=self,sm
export OMPI_MCA_PML="ucx"
export PMIX_MCA_gds="hash"

srun --mpi=pmix_v3 --cpus-per-task=${NUM_THREADS} singularity exec --env OMP_NUM_THREADS=${NUM_THREADS} --env PYTHONPATH=/nix/store/yvqis8yj3dylnl4d7b4a75g9z8pxmh4i-python3-3.12.10-env/lib/python3.12/site-packages ${SLURM_SUBMIT_DIR}/jupycpp.sif python3 ${SLURM_SUBMIT_DIR}/${SCRIPT} ${SLURM_SUBMIT_DIR}/${MATRIX_PATH} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
