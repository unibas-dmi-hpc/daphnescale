include: "doe.smk"
include: "build.smk"
include: "matrices.smk"

rule all:
  input:
    expand("results/{benchmark}/seq/{lang}/{num_threads}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_WITH_MATRICES,\
      lang=LANGUAGES,\
      num_threads=1,\
      iter=ITERATIONS),
    expand("results/{benchmark}/par/{lang}/{num_threads}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_WITH_MATRICES,\
      lang=LANGUAGES,\
      num_threads=NUM_THREADS,\
      iter=ITERATIONS),       
    # expand("results/{benchmark}/seq/{lang}/{num_threads}/{iter}.dat",\
    #   matrix=MATRICES,\
    #   benchmark=SCRIPTS_WITHOUT_MATRICES,\
    #   lang=LANGUAGES,\
    #   num_threads=1,\
    #   iter=ITERATIONS),
    # expand("results/{benchmark}/par/{lang}/{num_threads}/{iter}.dat",\
    #   matrix=MATRICES,\
    #   benchmark=SCRIPTS_WITHOUT_MATRICES,\
    #   lang=LANGUAGES,\
    #   num_threads=NUM_THREADS,\
    #   iter=ITERATIONS),         

rule run_seq_expe_with_matrix:
  input:
    sbatch="sbatch_scripts/run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-seq/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta",
    jupycpp_sif="jupycpp.sif",
    daphne_sif="daphne-dev.sif",
    daphne_src="daphne-src/bin/daphne"
  output:
    "results/{benchmark}/seq/{lang}/{num_threads}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys())
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"]
  shell:
    """
    mkdir -p $(dirname {output}) 
    sbatch {input.sbatch} {wildcards.num_threads} {input.script} {input.mtx} {params.matrix_size} {output}
    """

rule run_par_expe_with_matrix:
  input:
    sbatch="sbatch_scripts/run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-par/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta",
    jupycpp_sif="jupycpp.sif",
    daphne_sif="daphne-dev.sif",
    daphne_src="daphne-src/bin/daphne"
  output:
    "results/{benchmark}/par/{lang}/{num_threads}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys())
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"]
  shell:
    """
    mkdir -p $(dirname {output}) 
    sbatch {input.sbatch} {wildcards.num_threads} {input.script} {input.mtx} {params.matrix_size} {output}
    """    

# rule run_seq_expe_without_matrix:
#   input:
#     sbatch="sbatch_scripts/run_vega_{lang}.sh",
#     script="benchmark_scripts/{benchmark}/{lang}/{benchmark}.{lang}",
#     jupycpp_sif="jupycpp.sif",
#     daphne_sif="daphne-dev.sif",
#     daphne_src="daphne-src/bin/daphne"
#   output:
#     "results/{benchmark}/seq/{lang}/{num_threads}/{iter}.dat"  
#   shell:
#     """
#     mkdir -p $(dirname {output}) 
#     sbatch --time=0-05:00:00 {input.sbatch} {wildcards.num_threads} {input.script} NA -1 {output}
#     """

