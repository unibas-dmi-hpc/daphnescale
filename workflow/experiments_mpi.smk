include: "doe.smk"
include: "matrices.smk"

"results/{benchmark}/par/{lang}/{num_threads}/{iter}.dat"

rule all:
  input:
    expand("results/{benchmark}/mpi/{lang}/{mpi_procs}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_WITH_MATRICES,\
      lang=["cpp","py","jl"],\
      mpi_procs=MPI_DISTRIBUTION.keys(),\
      iter=ITERATIONS),
    expand("results/{benchmark}/mpi/daph/{scheme}-{layout}-{victim}/{mpi_procs}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_WITH_MATRICES,\
      mpi_procs=MPI_DISTRIBUTION.keys(),\
      scheme=["static"],\
      layout=["centralized"],\
      victim=["seq"],\
      iter=ITERATIONS),    

rule run_expe_mpi_jupycpp:
  input:
    sbatch="sbatch_scripts/run_vega_{lang}_mpi.sh",
    script="benchmark_scripts/{benchmark}-mpi/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/mpi/{matrix}/{benchmark}/{lang}/{mpi_procs}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI_WITH_MATRICES),
    lang="cpp|py|jl"
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"],
    tasks_per_node = lambda w: MPI_DISTRIBUTION[w.mpi_procs][0],
    cpus_per_task = lambda w: MPI_DISTRIBUTION[w.mpi_procs][1],
    nb_nodes = MPI_NB_NODES
  shell:
    """
    mkdir -p $(dirname {output}) 
    sbatch  --nodes={params.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {params.cpus_per_task} {input.script} {input.mtx} {params.matrix_size} {output}
    """

rule run_expe_mpi_daph:
  input:
    sbatch="sbatch_scripts/run_vega_daph_mpi.sh",
    daphne="daphne-src-mpi/bin/daphne",
    script="benchmark_scripts/{benchmark}/daph/{benchmark}.daph",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/mpi/{matrix}/{benchmark}/daph/{scheme}-{layout}-{victim}/{mpi_procs}/{iter}.dat" 
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI_WITH_MATRICES),
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"],
    tasks_per_node = lambda w: MPI_DISTRIBUTION[w.mpi_procs][0],
    cpus_per_task = lambda w: MPI_DISTRIBUTION[w.mpi_procs][1],
    nb_nodes = MPI_NB_NODES,
    scheme_uc = lambda w: w.scheme.upper(),
    layout_uc = lambda w: w.layout.upper(),
    victim_uc = lambda w: w.victim.upper()
  shell:
    """
    mkdir -p $(dirname {output})
    sbatch --nodes={params.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} \
             {input.sbatch} {params.cpus_per_task} {input.script} {input.mtx} {params.matrix_size} {params.scheme_uc} {params.layout_uc} {params.victim_uc} {output}
    """

