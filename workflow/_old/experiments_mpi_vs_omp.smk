include: "doe.smk"
include: "matrices.smk"

rule all:
  input:
    expand("data/mpi-vs-omp/{sys}/{matrix}/{benchmark}/{lang}/{procs}/{iter}.dat",\
    sys=["mpi", "omp"],\
    matrix=["wikipedia-20070206"],\
    benchmark=SCRIPTS_MPI,\
    lang=LANGUAGES,\
    procs=range(1, 21),\
    iter=ITERATIONS)

rule run_expe_mpi:
  input:
    sbatch="sbatch_scripts/run_xeon_{lang}_mpi.sh",
    script="benchmark_scripts/{benchmark}-mpi/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/mpi-vs-omp/mpi/{matrix}/{benchmark}/{lang}/{mpi_procs}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI)
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"],
    cpus_per_task = 1,
    nb_nodes = 1
  shell:
    "sbatch --nodes={params.nb_nodes} \
            --ntasks-per-node={wildcards.mpi_procs} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {params.cpus_per_task} {input.script} {input.mtx} {params.matrix_size} {output}"

rule run_expe_omp:
  input:
    sbatch="sbatch_scripts/run_xeon_{lang}.sh",
    script="benchmark_scripts/{benchmark}/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta"
  output:
    "data/mpi-vs-omp/omp/{matrix}/{benchmark}/{lang}/{nb_threads}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI)
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"],
    cpus_per_task = 20,
    tasks_per_node = 1,
    nb_nodes = 1
  shell:
    "sbatch --nodes={params.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {wildcards.nb_threads} {input.script} {input.mtx} {params.matrix_size} {output}"
