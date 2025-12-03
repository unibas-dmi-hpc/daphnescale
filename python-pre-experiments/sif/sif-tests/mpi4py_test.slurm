#!/bin/bash
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=0-00:03:00
#SBATCH --hint=nomultithread
#SBATCH --mem=8G
#SBATCH --job-name=mpi4py-test
#SBATCH --output=mpi4py-test.out

module purge
module load OpenMPI/4.1.6-GCC-13.2.0

# Make sure this is visible to the job shell
export SINGULARITYENV_LD_LIBRARY_PATH="/cvmfs/sling.si/modules/el7/software/OpenMPI/4.1.6-GCC-13.2.0/lib:/opt/python314t/lib"
export UCX_TLS=self,sm
export OMPI_MCA_PML="ucx"
export PMIX_MCA_gds="hash"

echo ">>> On $(hostname)"
echo ">>> SINGULARITYENV_LD_LIBRARY_PATH = $SINGULARITYENV_LD_LIBRARY_PATH"

srun --mpi=pmix singularity exec -B /cvmfs:/cvmfs /ceph/hpc/data/d2025d03-111-users/python-test/singularity-sif/py314t/py314t.sif \
  python3 - << 'EOF'
import os
from mpi4py import MPI
rank = MPI.COMM_WORLD.Get_rank()
size = MPI.COMM_WORLD.Get_size()
print(f"[rank {rank}/{size}] LD_LIBRARY_PATH:", os.environ.get("LD_LIBRARY_PATH", ""))
print(f"[rank {rank}/{size}] MPI version:", MPI.Get_version())
EOF
