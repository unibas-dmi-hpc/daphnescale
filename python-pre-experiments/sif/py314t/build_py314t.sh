# Build instructions to create Python No-Gil container with Hosts gompi but installed mpi4py
rm -f py314t.sif
rm -rf py314t_sandbox

# 1. Build py314 sandbox without mpi4pi
singularity build --fakeroot --sandbox py314t_sandbox/ py314t.def

# 2. Install mpi4py inside the container, using host's gompi
module purge
module load gompi/2024a
singularity exec --writable py314t_sandbox \
    env CC=mpicc MPICC=mpicc \
    python3 -m pip install mpi4py --no-build-isolation

# 3. Build final container py314t.sif with mpi4py
singularity build --fakeroot py314t.sif py314t_sandbox

