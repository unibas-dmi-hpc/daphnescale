set -xe

#mpic++ -DEIGEN_DONT_PARALLELIZE `pkg-config --cflags eigen3` -O3 -o nbody nbody.cpp
mpic++ nbody-mpi.cpp -o nbody-mpi -lm -O3 -fopenmp
