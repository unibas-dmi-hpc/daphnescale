# To run

## Sequential

```console
 julia --project=. connected_components.jl ../../../matrices/amazon0601/amazon0601_ones.mtx
 ```

## Parallel

```console
 julia --threads 12 --project=. connected_components.jl ../../../matrices/amazon0601/amazon0601_ones.mtx
 ```
