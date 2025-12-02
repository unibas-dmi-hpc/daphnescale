#!/bin/bash

#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=128G
#SBATCH --hint=nomultithread
#SBATCH --time=0-00:15:00

set -ex

NUM_THREADS=$1
SOURCEFILE=$2
MATRIX_PATH=$3
MATRIX_SIZE=$4
RESULT=$5

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


singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/jupycpp.sif g++ ${SLURM_SUBMIT_DIR}/${SOURCEFILE} -o ${SLURM_SUBMIT_DIR}/${EXECUTABLE} ${OPTIONS}

OMP_NUM_THREADS=${NUM_THREADS} srun --mpi=none --cpus-per-task=${NUM_THREADS} singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/jupycpp.sif ${SLURM_SUBMIT_DIR}/${EXECUTABLE} ${SLURM_SUBMIT_DIR}/${MATRIX_PATH} ${MATRIX_SIZE} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
