#!/bin/bash

#SBATCH --job-name=daphnesched2
#SBATCH --nodes=1
#SBATCH --partition=cpu
#SBATCH --ntasks-per-node=1
#SBATCH --hint=nomultithread
#SBATCH --cpus-per-task=128
#              d-hh:mm:ss
#SBATCH --time=0-04:00:00
#SBATCH --wait
#SBATCH --mem=128G

set -ex

FOLDER=$1
TAG=$2

srun singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/daphne-dev.sif bash -c "cd ${FOLDER}; ./build.sh --no-deps ${TAG} --installPrefix /usr/local"

exit 0
