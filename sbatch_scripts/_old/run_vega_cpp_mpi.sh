#!/bin/bash

#SBATCH --job-name=daphnesched2
#SBATCH --partition=cpu
#SBATCH --hint=nomultithread
#              d-hh:mm:ss
#SBATCH --time=0-02:00:00
#SBATCH --wait
#SBATCH --mem=128G
#SBATCH --nodelist=cn[0580-0599]

set -ex

NUM_THREADS=$1
SOURCEFILE=$2
MATRIX_PATH=$3
MATRIX_SIZE=$4
RESULT=$5

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

OMP_NUM_THREADS=${NUM_THREADS} srun --mpi=pmix_v3 --cpus-per-task=${NUM_THREADS} singularity exec ${SLURM_SUBMIT_DIR}/jupycpp.sif ${SLURM_SUBMIT_DIR}/${EXECUTABLE} ${SLURM_SUBMIT_DIR}/${MATRIX_PATH} ${MATRIX_SIZE} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
