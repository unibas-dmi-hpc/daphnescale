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

# Required fixed arguments
NUM_THREADS=$1
SCRIPT=$2
RESULT=$3
# All remaining arguments are benchmark-specific
shift 3
# Convert "$@" into an array ARGS[]
read -r -a ARGS <<< "$@"

# build args string
keys=(n p q r s t u v w x y z)
ARG_STRING=""
for i in "${!ARGS[@]}"; do
    key="${keys[$i]}"
    value="${ARGS[$i]}"
    ARG_STRING+="${key}=${value} "
done
# trim trailing space
ARG_STRING="${ARG_STRING%" "}"

mkdir -p "$(dirname "${SLURM_SUBMIT_DIR}/${RESULT}")"

OPTIONS=""

if [ "${NUM_THREADS}" -gt "1" ]
then
  OPTIONS="--vec --num-threads=${NUM_THREADS} --partitioning=${PARTITIONING} --queue_layout=${QUEUE_LAYOUT} --victim_selection=${VICTIM_SELECTION} --pin-workers"
fi

srun --mpi=none  --cpus-per-task=${NUM_THREADS} singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/daphne-dev.sif ./daphne-src/bin/daphne \
					            --select-matrix-repr \
                      ${OPTIONS} \
					            ${SLURM_SUBMIT_DIR}/${SCRIPT} ${ARG_STRING} \
                      &> ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
