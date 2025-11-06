#!/bin/bash

#SBATCH --job-name=daphnesched2
#SBATCH --nodes=1
#SBATCH --partition=cpu
#SBATCH --ntasks-per-node=1
#SBATCH --hint=nomultithread
#SBATCH --cpus-per-task=128
#              d-hh:mm:ss
#SBATCH --time=0-02:00:00
#SBATCH --wait
#SBATCH --mem=8G

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

srun --cpus-per-task=${NUM_THREADS} singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/jupycpp.sif julia --project=$(dirname ${SLURM_SUBMIT_DIR}/${SCRIPT}) -e "using Pkg; Pkg.instantiate()"

srun --cpus-per-task=${NUM_THREADS} singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/jupycpp.sif julia --threads ${NUM_THREADS} --project=$(dirname ${SLURM_SUBMIT_DIR}/${SCRIPT}) ${SLURM_SUBMIT_DIR}/${SCRIPT} ${SLURM_SUBMIT_DIR}/${MATRIX_PATH} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
