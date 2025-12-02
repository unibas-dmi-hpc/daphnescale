#!/bin/bash

#SBATCH --job-name=py314t_cc
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=64G
#SBATCH --hint=nomultithread
#SBATCH --time=0-02:00:00

set -ex

echo "SLURM CPUSET:"
grep Cpus_allowed_list /proc/self/status
echo "Cgroup cpuset:"
cat /sys/fs/cgroup/cpuset/slurm*/cpuset.cpus || true

echo "Trying a raw srun echo:"
srun --mpi=none echo "SRUN WORKS"

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

srun --mpi=none --cpu-bind=none --cpus-per-task=${NUM_THREADS} singularity exec --no-mount /cvmfs --env OMP_NUM_THREADS=${NUM_THREADS} ${SLURM_SUBMIT_DIR}/jupycpp.sif python3 ${SLURM_SUBMIT_DIR}/${SCRIPT} ${SLURM_SUBMIT_DIR}/${MATRIX_PATH} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
