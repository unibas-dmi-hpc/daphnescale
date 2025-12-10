#!/bin/bash

#SBATCH --partition=cpu
#SBATCH --mem=128G
#SBATCH --hint=nomultithread
#SBATCH --time=0-00:15:00

set -ex

NUM_THREADS=$1
SCRIPT=$2
PARTITIONING=$3
QUEUE_LAYOUT=$4
VICTIM_SELECTION=$5
RESULT=$6
# All remaining arguments are benchmark-specific
shift 6
ARGS="$@"
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

export UCX_TLS=self,sm
export OMPI_MCA_PML="ucx"
export PMIX_MCA_gds="hash"

srun --mpi=pmix --cpus-per-task=${NUM_THREADS} singularity exec ${SLURM_SUBMIT_DIR}/daphne-dev.sif ./daphne-src-mpi/bin/daphne \
            --vec \
			--distributed \
			--num-threads=${NUM_THREADS} \
			--dist_backend=MPI \
			--select-matrix-repr \
			--pin-workers \
			--partitioning=${PARTITIONING} \
			--queue_layout=${QUEUE_LAYOUT} \
			--victim_selection=${VICTIM_SELECTION} \
            ${SLURM_SUBMIT_DIR}/${SCRIPT} ${ARG_STRING} &> ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
