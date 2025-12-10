#!/bin/bash

#SBATCH --partition=cpu
#SBATCH --mem=128G
#SBATCH --hint=nomultithread
#SBATCH --time=0-00:15:00

set -ex

# Required fixed arguments
NUM_THREADS=$1
SOURCEFILE=$2
RESULT=$3
# All remaining arguments are benchmark-specific
shift 3
ARGS="$@"

mkdir -p "$(dirname "${SLURM_SUBMIT_DIR}/${RESULT}")"

EXECUTABLE=$(dirname ${SOURCEFILE})/$(basename ${SOURCEFILE} .cpp)_${NUM_THREADS}_$RANDOM

CFLAGS=$(PKG_CONFIG_PATH=/share/pkgconfig singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/jupycpp.sif pkg-config --cflags eigen3)

OPTIONS=""

if [ "${NUM_THREADS}" -gt "1" ]
then
  OPTIONS="${CFLAGS} -O3 -fopenmp"
else
  OPTIONS="${CFLAGS} -O3 -DEIGEN_DONT_PARALLELIZE"
fi

export UCX_TLS=self,sm
export OMPI_MCA_PML="ucx"
export PMIX_MCA_gds="hash"

singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/jupycpp.sif mpic++ ${SLURM_SUBMIT_DIR}/${SOURCEFILE} -o ${SLURM_SUBMIT_DIR}/${EXECUTABLE} ${OPTIONS}

OMP_NUM_THREADS=${NUM_THREADS} srun --mpi=pmix --cpus-per-task=${NUM_THREADS} singularity exec ${SLURM_SUBMIT_DIR}/jupycpp.sif ${SLURM_SUBMIT_DIR}/${EXECUTABLE} ${ARGS} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
