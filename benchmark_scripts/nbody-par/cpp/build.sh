set -xe
g++ nbody-par.cpp -o nbody-par -lm -O3 -fopenmp
