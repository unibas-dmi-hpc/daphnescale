include: "doe.smk"
include: "matrices.smk"

rule all:
  input:
    expand("data/mpi-config/{matrix}/{benchmark}/{lang}/{mpi_procs}/{iter}.dat",\
      matrix=MATRICES_CONFIG,\
      benchmark=SCRIPTS_MPI,\
      lang=LANGUAGES,\
      mpi_procs=MPI_DISTRIBUTION.keys(),\
      iter=ITERATIONS),
    expand("data/mpi-scale/{matrix}/{benchmark}/{lang}/{nb_nodes}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_MPI,\
      lang=LANGUAGES,\
      nb_nodes=MPI_SCALE_NB_NODES,
      iter=ITERATIONS),
    expand("data/mpi-daph/{matrix}/{benchmark}/{layout}/{scheme}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_MPI,\
      layout=QUEUE_LAYOUTS,
      scheme=SCHEMES,\
      iter=ITERATIONS),
    expand("data/mpi-scale-daph-best/{matrix}/{benchmark}/{nb_nodes}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_MPI,\
      nb_nodes=MPI_SCALE_NB_NODES,
      iter=ITERATIONS),

rule run_expe_mpi_config:
  input:
    sbatch="sbatch_scripts/run_xeon_{lang}_mpi.sh",
    script="benchmark_scripts/{benchmark}-mpi/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/mpi-config/{matrix}/{benchmark}/{lang}/{mpi_procs}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI)
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"],
    tasks_per_node = lambda w: MPI_DISTRIBUTION[w.mpi_procs][0],
    cpus_per_task = lambda w: MPI_DISTRIBUTION[w.mpi_procs][1],
    nb_nodes = MPI_CONFIG_NB_NODES
  shell:
    "sbatch --nodes={params.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {params.cpus_per_task} {input.script} {input.mtx} {params.matrix_size} {output}"

rule run_expe_mpi_scale:
  input:
    sbatch="sbatch_scripts/run_xeon_{lang}_mpi.sh",
    script="benchmark_scripts/{benchmark}-mpi/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/mpi-scale/{matrix}/{benchmark}/{lang}/{nb_nodes}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI)
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"],
    tasks_per_node = 1,
    cpus_per_task = 20
  shell:
    "sbatch --nodes={wildcards.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {params.cpus_per_task} {input.script} {input.mtx} {params.matrix_size} {output}"

rule run_expe_mpi_daphne:
  input:
    sbatch="sbatch_scripts/run_xeon_daph_mpi_options.sh",
    script="benchmark_scripts/{benchmark}-mpi/daph/{benchmark}.daph",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/mpi-daph/{matrix}/{benchmark}/{layout}/{scheme}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
    scheme="|".join(SCHEMES),
    layout="|".join(QUEUE_LAYOUTS)
  params:
    nb_nodes = 4,
    tasks_per_node = 1,
    cpus_per_task = 20
  shell:
    "sbatch --nodes={params.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {params.cpus_per_task} {input.script} {input.mtx} {wildcards.scheme} {wildcards.layout} {output}"

rule run_expe_mpi_daphne_best:
  input:
    sbatch="sbatch_scripts/run_xeon_daph_mpi_options.sh",
    script="benchmark_scripts/{benchmark}-mpi/daph/{benchmark}.daph",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/mpi-scale-daph-best/{matrix}/{benchmark}/{nb_nodes}/{iter}.dat"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  params:
    tasks_per_node = 1,
    cpus_per_task = 20,
    scheme = "AUTO",
    layout = "CENTRALIZED"
  shell:
    "sbatch --nodes={wildcards.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {params.cpus_per_task} {input.script} {input.mtx} {params.scheme} {params.layout} {output}"
