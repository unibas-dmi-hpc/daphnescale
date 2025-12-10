#!/bin/bash

#SBATCH --partition=cpu
#SBATCH --mem=128G
#SBATCH --hint=nomultithread
#SBATCH --time=0-00:15:00

set -ex

# Required fixed arguments
NUM_THREADS=$1
SCRIPT=$2
RESULT=$3
# All remaining arguments are benchmark-specific
shift 3
ARGS="$@"

mkdir -p "$(dirname "${SLURM_SUBMIT_DIR}/${RESULT}")"

module purge
module load OpenMPI/4.1.6-GCC-13.2.0

# Pass host OpenMPI libs into the container
export SINGULARITYENV_LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/opt/python314t/lib"

# Tell mpi4py WHICH libmpi to dlopen
MPI_LIB="/cvmfs/sling.si/modules/el7/software/OpenMPI/4.1.6-GCC-13.2.0/lib/libmpi.so.40.30.6"
export SINGULARITYENV_MPI4PY_LIBMPI="$MPI_LIB"

# Transport UCX/OMPI/PMIX hints into the container as well
export UCX_TLS=self,sm
export OMPI_MCA_PML=ucx
export PMIX_MCA_gds=hash

export SINGULARITYENV_UCX_TLS="$UCX_TLS"
export SINGULARITYENV_OMPI_MCA_PML="$OMPI_MCA_PML"
export SINGULARITYENV_PMIX_MCA_gds="$PMIX_MCA_gds"

export OMP_NUM_THREADS=${NUM_THREADS}
export OPENBLAS_NUM_THREADS=${NUM_THREADS}
export MKL_NUM_THREADS=${NUM_THREADS}
export VECLIB_MAXIMUM_THREADS=${NUM_THREADS}
export NUMEXPR_NUM_THREADS=${NUM_THREADS}

srun --mpi=pmix --cpus-per-task=${NUM_THREADS} singularity exec -B /cvmfs:/cvmfs ${SLURM_SUBMIT_DIR}/py314t.sif python3 ${SLURM_SUBMIT_DIR}/${SCRIPT} ${ARGS} > ${SLURM_SUBMIT_DIR}/${RESULT}

exit 0
