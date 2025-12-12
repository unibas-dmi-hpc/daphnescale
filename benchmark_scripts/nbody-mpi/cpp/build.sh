set -xe

mpic++ nbody.cpp -o nbody -lm -O3 -fopenmp
