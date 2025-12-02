#!/bin/bash

#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=128G
#SBATCH --hint=nomultithread
#SBATCH --time=0-00:15:00

set -ex

PARTITIONING=STATIC
QUEUE_LAYOUT=CENTRALIZED
VICTIM_SELECTION=SEQ

NUM_THREADS=$1
SCRIPT=$2
MATRIX_PATH=$3
MATRIX_SIZE=$4 # unsued but kept to have the same api as for the other sbatch scripts
RESULT=$5

mkdir -p "$(dirname "${SLURM_SUBMIT_DIR}/${RESULT}")"

OPTIONS=""

if [ "${NUM_THREADS}" -gt "1" ]
then
  OPTIONS="--vec --num-threads=${NUM_THREADS} --partitioning=${PARTITIONING} --queue_layout=${QUEUE_LAYOUT} --victim_selection=${VICTIM_SELECTION} --pin-workers"
fi


srun --mpi=none  --cpus-per-task=${NUM_THREADS} singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/daphne-dev.sif ./daphne-src/bin/daphne \
					            --select-matrix-repr \
                      ${OPTIONS} \
					            --args f=\"${SLURM_SUBMIT_DIR}/${MATRIX_PATH}\"\
					            ${SLURM_SUBMIT_DIR}/${SCRIPT} &> ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
