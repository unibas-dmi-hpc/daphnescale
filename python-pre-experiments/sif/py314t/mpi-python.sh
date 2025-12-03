#!/bin/bash
# Wrapper to ensure MPI libraries are visible inside Singularity

MPI_LIBDIR="/cvmfs/sling.si/modules/el7/software/OpenMPI/4.1.6-GCC-13.2.0/lib"

export LD_LIBRARY_PATH="${MPI_LIBDIR}:${LD_LIBRARY_PATH}"

singularity exec -B /cvmfs:/cvmfs py314t.sif python3 "$@"
