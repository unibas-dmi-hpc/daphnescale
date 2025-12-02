include: "doe.smk"
include: "build.smk"
include: "matrices.smk"

rule all:
  input:       
    expand("results/{benchmark}/{matrix}/seq/{lang}/{num_threads}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SCRIPTS_WITH_MATRICES,\
      lang=LANGUAGES,\
      num_threads=[1],\
      iter=ITERATIONS),
    expand("results/{benchmark}/{matrix}/par/{lang}/{num_threads}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=SEQ_AS_PAR_SCRIPTS_WITH_MATRICES,\
      lang=LANGUAGES,\
      num_threads=NUM_THREADS_SEQ,\
      # num_threads=[32],\
      iter=ITERATIONS),
    expand("results/{benchmark}/{matrix}/par/{lang}/{num_threads}/{iter}.dat",\
      matrix=MATRICES,\
      benchmark=PAR_SCRIPTS_WITH_MATRICES,\
      lang=LANGUAGES,\
      num_threads=NUM_THREADS_PAR,\
      # num_threads=[32],\
      iter=ITERATIONS),
 
rule run_expe_seq:
  input:
    sbatch="sbatch_scripts/run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-seq/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta",
  output:
    "results/{benchmark}/{matrix}/seq/{lang}/{num_threads}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys())
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"]
  shell:
    """
    sbatch --job-name=seq_{wildcards.benchmark}_{wildcards.lang}_{wildcards.num_threads}t_{wildcards.iter}r \
           --cpus-per-task={wildcards.num_threads} {input.sbatch} {wildcards.num_threads} {input.script} {input.mtx} {params.matrix_size} {output}
    """

rule run_expe_par_with_seq:
  input:
    sbatch="sbatch_scripts/run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-seq/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta",
  output:
    "results/{benchmark}/{matrix}/par/{lang}/{num_threads}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys())
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"]
  shell:
    """
    sbatch --job-name=par_{wildcards.benchmark}_{wildcards.lang}_{wildcards.num_threads}t_{wildcards.iter}r \
           --cpus-per-task={wildcards.num_threads} {input.sbatch} {wildcards.num_threads} {input.script} {input.mtx} {params.matrix_size} {output}
    """

rule run_expe_par:
  input:
    sbatch="sbatch_scripts/run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-par/{lang}/{benchmark}.{lang}",
    mtx="matrices/{matrix}/{matrix}_ones.mtx",
    meta="matrices/{matrix}/{matrix}_ones.mtx.meta",
  output:
    "results/{benchmark}/{matrix}/par/{lang}/{num_threads}/{iter}.dat"  
  wildcard_constraints:
    matrix="|".join(matrices.keys())
  params:
    matrix_size = lambda w: matrices[w.matrix]["meta"]["numRows"]
  shell:
    """
    sbatch --job-name=par_{wildcards.benchmark}_{wildcards.lang}_{wildcards.num_threads}t_{wildcards.iter}r \
           --cpus-per-task={wildcards.num_threads} {input.sbatch} {wildcards.num_threads} {input.script} {input.mtx} {params.matrix_size} {output}
    """