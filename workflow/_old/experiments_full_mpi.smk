
include: "doe.smk"
include: "matrices.smk"

rule all:
  input:
    expand("data/mpi-full-scale/{matrix}/{benchmark}/{lang}/{nb_nodes}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_MPI,\
      lang=["cpp", "jl", "py"],\
      nb_nodes=MPI_SCALE_NB_NODES,
      iter=ITERATIONS),

rule run_expe_full_mpi_scale:
  input:
    sbatch="sbatch_scripts/run_xeon_{lang}_mpi.sh",
    script="benchmark_scripts/{benchmark}-mpi/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/mpi-full-scale/{matrix}/{benchmark}/{lang}/{nb_nodes}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI)
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"],
    tasks_per_node = 20,
    cpus_per_task = 1
  shell:
    "sbatch --nodes={wildcards.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {params.cpus_per_task} {input.script} {input.mtx} {params.matrix_size} {output}"

