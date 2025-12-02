include: "doe.smk"
include: "matrices.smk"

EXPE_TYPES=[ "config", "scale"]

rule all:
  input:
    "data/all.csv",
    "data/all_mpi-daph.csv",
    "data/all_mpi-config.csv",
    "data/all_mpi-scale.csv",
    "data/all_mpi-daph-best.csv",
    "data/all_mpi-vs-omp.csv",
    "data/all_mpi-full-scale.csv",

rule merge_iterations:
  input:
    script="workflow/scripts/R/json_to_csv.R",
    data=expand("data/{{matrix}}/{{benchmark}}/{{lang}}/{{num_threads}}/{iter}.dat", iter=ITERATIONS)
  output:
    "data/grouped_iter/{matrix}_{benchmark}_{lang}_{num_threads}.csv"
  wildcard_constraints:
    matrix="[a-zA-Z0-9-]+"
  shell:
    "Rscript {input.script} {input.data} {wildcards.benchmark} {wildcards.num_threads} {wildcards.lang} {wildcards.matrix} {output}"

rule merge_iteration_csv:
  input:
    script="workflow/scripts/R/merge_all.R",
    data_with_matrices=expand("data/grouped_iter/{matrix}_{benchmark}_{lang}_{num_threads}.csv",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_WITH_MATRICES,\
      lang=LANGUAGES,\
      num_threads=NUM_THREADS),
    #data_without_matrices=expand("data/grouped_iter/{matrix}_{benchmark}_{lang}_{num_threads}.csv",\
    #  matrix=["NA"],\
    #  benchmark=SCRIPTS_WITHOUT_MATRICES,\
    #  lang=LANGUAGES,\
    #  num_threads=NUM_THREADS) 
  output:
    "data/all.csv"
  wildcard_constraints:
    matrix="[a-zA-Z0-9-]+"
  shell:
    "Rscript {input.script} {input.data_with_matrices} {output}"
    #"Rscript {input.script} {input.data_with_matrices} {input.data_without_matrices} {output}"


# MPI CONFIG --------------------------------------------------------------------------------------------------


rule merge_iterations_mpi:
  input:
    script="workflow/scripts/R/json_to_csv.R",
    data=expand("data/mpi-config/{{matrix}}/{{benchmark}}/{{lang}}/{{mpi_procs}}/{iter}.dat", iter=ITERATIONS)
  output:
    "data/mpi-config/grouped_iter/{matrix}_{benchmark}_{lang}_{mpi_procs}.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {wildcards.benchmark} {wildcards.mpi_procs} {wildcards.lang} {wildcards.matrix} {output}"

rule merge_iteration_csv_mpi:
  input:
    script="workflow/scripts/R/merge_all.R",
    data=expand("data/mpi-config/grouped_iter/{matrix}_{benchmark}_{lang}_{mpi_procs}.csv",\
                  matrix=MATRICES,\
                  benchmark=SCRIPTS_MPI,\
                  lang=["cpp", "py", "jl", "daph"],\
                  mpi_procs=MPI_DISTRIBUTION.keys())
  output:
    "data/all_mpi-config.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {output}"

# MPI SCALE --------------------------------------------------------------------------------------------------


rule merge_iterations_mpi_scale:
  input:
    script="workflow/scripts/R/json_to_csv.R",
    data=expand("data/mpi-scale/{{matrix}}/{{benchmark}}/{{lang}}/{{nb_nodes}}/{iter}.dat", iter=ITERATIONS)
  output:
    "data/mpi-scale/grouped_iter/{matrix}_{benchmark}_{lang}_{nb_nodes}.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {wildcards.benchmark} {wildcards.nb_nodes} {wildcards.lang} {wildcards.matrix} {output}"

rule merge_iteration_csv_mpi_scale:
  input:
    script="workflow/scripts/R/merge_all.R",
    data=expand("data/mpi-scale/grouped_iter/{matrix}_{benchmark}_{lang}_{nb_nodes}.csv",\
                  matrix=MATRICES,\
                  benchmark=SCRIPTS_MPI,\
                  lang=["cpp", "py", "jl"],\
                  nb_nodes=MPI_SCALE_NB_NODES),
    data_daph=expand("data/mpi-scale/grouped_iter/{matrix}_{benchmark}_{lang}_{nb_nodes}.csv",\
                  matrix=MATRICES,\
                  benchmark=SCRIPTS_MPI,\
                  lang=["daph"],\
                  nb_nodes=range(2, 11))
  output:
    "data/all_mpi-scale.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {input.data_daph} {output}"

# DAPH --------------------------------------------------------------------------------------------------

rule merge_iterations_mpi_daph:
  input:
    script="workflow/scripts/R/json_to_csv_daph.R",
    data=expand("data/mpi-daph/{{matrix}}/{{benchmark}}/{{layout}}/{{scheme}}/{iter}.dat", iter=ITERATIONS)
  output:
    "data/mpi-daph/grouped_iter/{matrix}_{benchmark}_{layout}_{scheme}.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {wildcards.benchmark} {wildcards.scheme} {wildcards.layout} {wildcards.matrix} {output}"

rule merge_iteration_csv_mpi_daph:
  input:
    script="workflow/scripts/R/merge_all.R",
    data=expand("data/mpi-daph/grouped_iter/{matrix}_{benchmark}_{layout}_{scheme}.csv",\
                  matrix=MATRICES,\
                  benchmark=SCRIPTS_MPI,\
                  layout=QUEUE_LAYOUTS,\
                  scheme=SCHEMES)
  output:
    "data/all_mpi-daph.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {output}"

# MPI SCALE --------------------------------------------------------------------------------------------------


rule merge_iterations_mpi_scale_daph_best:
  input:
    script="workflow/scripts/R/json_to_csv.R",
    data=expand("data/mpi-scale-daph-best/{{matrix}}/{{benchmark}}/{{nb_nodes}}/{iter}.dat", iter=ITERATIONS)
  output:
    "data/mpi-scale-daph-best/grouped_iter/{matrix}_{benchmark}_{nb_nodes}.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {wildcards.benchmark} {wildcards.nb_nodes} daph-best {wildcards.matrix} {output}"

rule merge_iteration_csv_mpi_scale_daph_best:
  input:
    script="workflow/scripts/R/merge_all.R",
    data=expand("data/mpi-scale-daph-best/grouped_iter/{matrix}_{benchmark}_{nb_nodes}.csv",\
                  matrix=MATRICES,\
                  benchmark=SCRIPTS_MPI,\
                  nb_nodes=MPI_SCALE_NB_NODES)
  output:
    "data/all_mpi-daph-best.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {output}"

# MPI VS OMP --------------------------------------------------------------------------------------------------


rule merge_iterations_mpi_vs_omp:
  input:
    script="workflow/scripts/R/json_to_csv_mpi_vs_omp.R",
    data=expand("data/mpi-vs-omp/{{type}}/{{matrix}}/{{benchmark}}/{{lang}}/{{procs}}/{iter}.dat", iter=ITERATIONS)
  output:
    "data/mpi-vs-omp/grouped_iter/{type}_{matrix}_{benchmark}_{lang}_{procs}.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
    type="mpi|omp"
  shell:
    "Rscript {input.script} {input.data} {wildcards.type} {wildcards.benchmark} {wildcards.procs} {wildcards.lang} {wildcards.matrix} {output}"

rule merge_iteration_csv_mpi_vs_omp:
  input:
    script="workflow/scripts/R/merge_all.R",
    data=expand("data/mpi-vs-omp/grouped_iter/{type}_{matrix}_{benchmark}_{lang}_{procs}.csv",\
                  type=["mpi", "omp"],\
                  matrix=["wikipedia-20070206"],\
                  benchmark=SCRIPTS_MPI,\
                  lang=LANGUAGES,\
                  procs=range(1, 21))
  output:
    "data/all_mpi-vs-omp.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {output}"

# MPI FULL SCALE --------------------------------------------------------------------------------------------------


rule merge_iterations_mpi_full_scale:
  input:
    script="workflow/scripts/R/json_to_csv.R",
    data=expand("data/mpi-full-scale/{{matrix}}/{{benchmark}}/{{lang}}/{{nb_nodes}}/{iter}.dat", iter=ITERATIONS)
  output:
    "data/mpi-full-scale/grouped_iter/{matrix}_{benchmark}_{lang}_{nb_nodes}.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {wildcards.benchmark} {wildcards.nb_nodes} {wildcards.lang} {wildcards.matrix} {output}"

rule merge_iteration_csv_mpi_full_scale:
  input:
    script="workflow/scripts/R/merge_all.R",
    data=expand("data/mpi-full-scale/grouped_iter/{matrix}_{benchmark}_{lang}_{nb_nodes}.csv",\
                  matrix=MATRICES,\
                  benchmark=SCRIPTS_MPI,\
                  lang=["cpp", "py", "jl"],\
                  nb_nodes=MPI_SCALE_NB_NODES),
    data_daph=expand("data/mpi-scale/grouped_iter/{matrix}_{benchmark}_{lang}_{nb_nodes}.csv",\
                  matrix=MATRICES,\
                  benchmark=SCRIPTS_MPI,\
                  lang=["daph"],\
                  nb_nodes=range(2, 11))
  output:
    "data/all_mpi-full-scale.csv"
  wildcard_constraints:
    matrix="|".join(matrices.keys()),
    benchmark="|".join(SCRIPTS_MPI),
  shell:
    "Rscript {input.script} {input.data} {input.data_daph} {output}"
