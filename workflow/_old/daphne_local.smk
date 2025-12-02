include: "doe.smk"
include: "matrices.smk"
include: "build.smk"

rule all:
  input:
    expand("data/raw/{matrix}/{benchmark}/daph-schemes/{num_threads}/{scheme}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_WITH_MATRICES,\
      num_threads=20,\
      scheme=SCHEMES,\
      iter=ITERATIONS),

rule run_expe_with_matrix:
  input:
    sbatch="sbatch_scripts/run_xeon_daph_scheme.sh",
    script="benchmark_scripts/{benchmark}/daph/{benchmark}.daph",
    sif="daphne-dev.sif",
    src="daphne-src/bin/daphne",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/raw/{matrix}/{benchmark}/daph-schemes/{num_threads}/{scheme}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys())
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"]
  shell:
    "sbatch {input.sbatch} {wildcards.num_threads} {input.script} {input.mtx} {params.matrix_size} {wildcards.scheme} {output}"
