#!/bin/bash

#SBATCH --partition=cpu
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

export UCX_TLS=self,sm
export OMPI_MCA_PML="ucx"
export PMIX_MCA_gds="hash"

singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/jupycpp.sif julia --project=$(dirname ${SLURM_SUBMIT_DIR}/${SCRIPT}) -e "using Pkg; Pkg.instantiate()"
srun --mpi=pmix --cpus-per-task=${NUM_THREADS} singularity exec ${SLURM_SUBMIT_DIR}/jupycpp.sif julia --threads ${NUM_THREADS} --project=$(dirname ${SLURM_SUBMIT_DIR}/${SCRIPT}) ${SLURM_SUBMIT_DIR}/${SCRIPT} ${ARGS} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
