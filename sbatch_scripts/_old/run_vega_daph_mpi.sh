#!/bin/bash

#SBATCH --job-name=daphnesched2
#SBATCH --partition=cpu
#SBATCH --hint=nomultithread
#              d-hh:mm:ss
#SBATCH --time=0-02:00:00
#SBATCH --wait
#SBATCH --mem=128G

set -ex

NUM_THREADS=$1
SCRIPT=$2
MATRIX_PATH=$3
MATRIX_SIZE=$4 # unsued but kept to have the same api as for the other sbatch scripts
PARTITIONING=$5
QUEUE_LAYOUT=$6
VICTIM_SELECTION=$7
RESULT=$8

export UCX_TLS=self,sm
export OMPI_MCA_PML="ucx"
export PMIX_MCA_gds="hash"

srun --mpi=pmix_v3 --cpus-per-task=${NUM_THREADS} singularity exec ${SLURM_SUBMIT_DIR}/daphne-dev.sif ./daphne-src-mpi/bin/daphne \
            --vec \
			--distributed \
			--num-threads=${NUM_THREADS} \
			--dist_backend=MPI \
			--select-matrix-repr \
			--pin-workers \
			--partitioning=${PARTITIONING} \
			--queue_layout=${QUEUE_LAYOUT} \
			--victim_selection=${VICTIM_SELECTION} \
			--args f=\"${SLURM_SUBMIT_DIR}/${MATRIX_PATH}\" \
            ${SLURM_SUBMIT_DIR}/${SCRIPT} &> ${SLURM_SUBMIT_DIR}/${RESULT}



# srun --mpi=pmix --cpus-per-task=${NUM_THREADS} singularity exec --no-mount /cvmfs ${SLURM_SUBMIT_DIR}/daphne.sif daphne \
#             --vec \
# 			--distributed \
# 			--num-threads=${NUM_THREADS} \
# 			--dist_backend=MPI \
# 			--select-matrix-repr \
# 			--pin-workers \
# 			--partitioning=${PARTITIONING} \
# 			--queue_layout=${QUEUE_LAYOUT} \
# 			--victim_selection=${VICTIM_SELECTION} \
# 			-- args f=\"${SLURM_SUBMIT_DIR}/${MATRIX_PATH}\" \
#             ${SLURM_SUBMIT_DIR}/${SCRIPT} &> ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
