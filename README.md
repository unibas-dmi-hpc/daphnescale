# DaphneScale

Evaluating the tradeoff between scalability performance and ease of development

## Structure of the repository

### `benchmark_scripts`


Each of the folder contains the code for the sequential/parallel and distributed (`-mpi`) verions of the GAP Benchmark.

In each benchmark folder, there is one folder per language (`cpp`, `daph`, `jl`, `py`), note that that there is no `daph` folder for the `mpi` version as the mpi version is the same as the sequential one.

### `sbatch_scripts`

This folder contains the `sbatch` scripts used to execute the different languages in the different context (sequential, parallel, distributed).

The interface is as follow:

```console
sbatch ./sbatch_scripts/run_xeon_{LANG}.sh {NUM_THREADS} {SRC_FILE_PATH} {MATRIX_PATH} {MATRIX_SIZE} {OUTPUT_FILE}
```

where:

- `{LANG}` is the language short name (`cpp`, `daph`, `jl`, `py`)

- `{NUM_THREADS}` is the number of threads to use.

- `{SRC_FILE_PATH}` is the path to the source code file containing the benchmark

- `{MATRIX_PATH}` is the path to the `.mtx` file

- `{MATRIX_SIZE}` is the size of the matrix (i.e., the number of columns or rows (as we consider only square matrices, those are the same))

- `{OUTPUT_FILE}` is the path where to store the result of the execution

### `workflow`

This folder contains the heavy lifting of the experiments.

The workflow is managed by [Snakemake](https://snakemake.readthedocs.io/en/stable/).

On MiniHPC, you can load the Snakemake module:

```console
module load snakemake
```

#### `.smk` files

- `matrices.smk`: contains the information about the matrices used in the experiments (i.e., where to download, and some metadata)

  - The rules of this file download and decompress the matrices, then set up the metadata file (`.mtx.meta`) and fix the `.mtx` file so that all the linear algebra libraries used in the experiments read the matrices the same way.

- `doe.smk`: file containing the configuration about the **D**esign **O**f **E**xperiments. This is where to change the important parameters. Most of the others `.smk` files read this file.

- `build.smk`: file containing the steps to build DAPHNE (download source code (commit in `doe.smk`), download singularity image, and compile)

- `daphne_local.smk`: file containing the rules for a single node experiments with DAPHNE executing all the benchmark on all the matrices for a given number of threads, for a set of scheduling schemes, and repeated a given number of time (all the paramaters are defined in `doe.smk`).

- `experiments_mpi_vs_omp.smk`: file containing the rules for an experiment comparing the scaling ability of threads (`omp`, bad naming i know) and `mpi` processes on a single machine.

- `experiments_mpi.smk`: file containing the rules for an experiment comparing the scalability performance of all the languages.

- `experiments_full_mpi.smk`: file containing the rules for an experiments

- `analysis.smk`: file containing rules to produce the aggregated CSV files. **This workflow uses R, I recommand using the Nix Flake to get the R environment on your laptop, not miniHPC**


### Snakemake 101

**All the snakemake commands are to be ran from the root of the repository**

To dry-run a workflow:

```console
snakemake -s {WORKFLOW_FILE}.smk -n
```

To execute a workflow with 4 parallel processes:

```console
snakemake -s {WORKFLOW_FILE}.smk -c 4
```

As the data will be written on the NFS it is good practice to tell Snakemake that there might be some latency in the filesystem:

```console
snakemake -s {WORKFLOW_FILE}.smk -c 4 --latency-wait 60
```

Some other important flags:

- `--keep-going`: continue to execute the workflow even if one job failed.

- `--rerun-incomplete`: rerun jobs that have been stopped in a weird state before.

### `workflow/scripts`

This folder contains the source code for some scripts used in the repo (e.g., R analysis scripts, python script to update the `.mtx` files)

### `flake.nix` and `flake.lock`

[Nix](https://nixos.org) environement for the workflow (snakemake, python, cpp, julia, R), and to create the container for the non-DAPHNE languages.

Nix is not supported on MiniHPC, but I recomment to use Nix on your laptop.
