# To Build

```console
./build.sh
```

# To Run

## Sequential

```console
./cc_seq ../../../matrices/amazon0601/amazon0601_ones.mtx 403394
```

## Parallel

```console
OMP_NUM_THREADS=12 ./cc_omp ../../../matrices/amazon0601/amazon0601_ones.mtx 403394
```
