# Build instructions to create Python No-Gil container with Hosts gompi but installed mpi4py
rm -f py314.sif
rm -rf py314_sandbox

# 1. Build py314 sandbox without mpi4py
singularity build --fakeroot --sandbox py314_sandbox/ py314.def

# 2. Install mpi4py inside the container, using host's gompi
module purge
module load gompi/2024a

singularity exec --no-mount /ceph --writable py314_sandbox \
    env CC=mpicc MPICC=mpicc \
    python3 -m pip install mpi4py --no-build-isolation

# 3. Build final container py314.sif with mpi4py included
singularity build --fakeroot py314.sif py314_sandbox

