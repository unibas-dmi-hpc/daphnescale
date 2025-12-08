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
ARGS="$@"

# build args string
ARG_STRING=""
i=0
for a in "${ARGS[@]}"; do
  key=$(printf "%s\n" n p q r s t u v w x y z | sed -n "$((i+1))p")
  if [ -z "${ARG_STRING}" ]; then
     ARG_STRING="${key}=${a}"
  else
     ARG_STRING="${ARG_STRING}, ${key}=${a}"
  fi
  i=$((i+1))
done

mkdir -p "$(dirname "${SLURM_SUBMIT_DIR}/${RESULT}")"

OPTIONS=""

if [ "${NUM_THREADS}" -gt "1" ]
then
  OPTIONS="--vec --num-threads=${NUM_THREADS} --partitioning=${PARTITIONING} --queue_layout=${QUEUE_LAYOUT} --victim_selection=${VICTIM_SELECTION} --pin-workers"
fi


srun --mpi=none  --cpus-per-task=${NUM_THREADS} singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/daphne-dev.sif ./daphne-src/bin/daphne \
					            --select-matrix-repr \
                      			${OPTIONS} \
					            --args "${ARG_STRING}" \
					            ${SLURM_SUBMIT_DIR}/${SCRIPT} &> ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
