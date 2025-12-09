include: "doe.smk"

# RULE ORDER (THIS FIXES AMBIGUITY)
ruleorder: run_expe_par > run_expe_par_with_seq

# RULE ALL
rule all:
  input:   
    expand("results/{benchmark}/{form}/{lang}/{num_threads}/{iter}.dat",\
      benchmark=SCRIPTS,\
      form=["seq"],\
      lang=LANGUAGES,\
      num_threads=[1],\
      iter=ITERATIONS),
    expand("results/{benchmark}/{form}/{lang}/{num_threads}/{iter}.dat",\
      benchmark=SEQ_AS_PAR_SCRIPTS,\
      form=["par"],\
      lang=LANGUAGES,\
      # num_threads=NUM_THREADS_SEQ,\
      num_threads=[8],\
      iter=ITERATIONS),
    expand("results/{benchmark}/{form}/{lang}/{num_threads}/{iter}.dat",\
      benchmark=PAR_SCRIPTS,\
      form=["par"],\
      lang=LANGUAGES,\
      # num_threads=NUM_THREADS_PAR,\
      num_threads=[8],\
      iter=ITERATIONS)

# RULE SEQUENTIAL EXPERIMENT 
rule run_expe_seq:
  input:
    sbatch="sbatch_scripts/nomat_run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-{form}/{lang}/{benchmark}.{lang}",
    data=lambda w: INPUT_DATA.get(w.benchmark, [])
  output:
    "results/{benchmark}/{form}/{lang}/{num_threads}/{iter}.dat"  
  wildcard_constraints:
    form="seq"    
  params:
    args=lambda w: " ".join(
        (
            str(ARGUMENTS[w.benchmark][w.form][key][0])
            if key in ARGUMENTS[w.benchmark][w.form]
            else str(getattr(w, key)) # takes the value from the wildcard
        )
        for key in ARGUMENTS[w.benchmark][w.form]["args"]
    )
  shell:
    """
    sbatch --job-name=seq_{wildcards.benchmark}_{wildcards.lang}_{wildcards.num_threads}t_{wildcards.iter}r \
           --cpus-per-task={wildcards.num_threads} {input.sbatch} {wildcards.num_threads} {input.script} {output} {params.args}
    """

# RULE PARALLEL EXPERIMENT WITH SEQ IMPLEMENTATION
rule run_expe_par_with_seq:
  input:
    sbatch="sbatch_scripts/nomat_run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-seq/{lang}/{benchmark}.{lang}",
    data=lambda w: INPUT_DATA.get(w.benchmark, [])
  output:
    "results/{benchmark}/{form}/{lang}/{num_threads}/{iter}.dat"   
  wildcard_constraints:
    form="par"
  params:
    args=lambda w: " ".join(
        (
            str(ARGUMENTS[w.benchmark][w.form][key][0])
            if key in ARGUMENTS[w.benchmark][w.form]
            else str(getattr(w, key)) # takes the value from the wildcard
        )
        for key in ARGUMENTS[w.benchmark][w.form]["args"]
    )
  shell:
    """
    sbatch --job-name=par_{wildcards.benchmark}_{wildcards.lang}_{wildcards.num_threads}t_{wildcards.iter}r \
           --cpus-per-task={wildcards.num_threads} {input.sbatch} {wildcards.num_threads} {input.script} {output} {params.args}
    """

# RULE PARALLEL EXPERIMENT
rule run_expe_par:
  input:
    sbatch="sbatch_scripts/nomat_run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-{form}/{lang}/{benchmark}.{lang}",
    data=lambda w: INPUT_DATA.get(w.benchmark, [])
  output:
    "results/{benchmark}/{form}/{lang}/{num_threads}/{iter}.dat"  
  wildcard_constraints:
    form="par"
  params:
    args=lambda w: " ".join(
        (
            str(ARGUMENTS[w.benchmark][w.form][key][0])
            if key in ARGUMENTS[w.benchmark][w.form]
            else str(getattr(w, key)) # takes the value from the wildcard
        )
        for key in ARGUMENTS[w.benchmark][w.form]["args"]
    )
  shell:
    """
    sbatch --job-name=par_{wildcards.benchmark}_{wildcards.lang}_{wildcards.num_threads}t_{wildcards.iter}r \
           --cpus-per-task={wildcards.num_threads} {input.sbatch} {wildcards.num_threads} {input.script} {output} {params.args}
    """

# RULE GENERATE QUICKSORT INPUT
rule generate_quicksort_input:
  output:
    out=QS_INPUT
  params:
    N = ARRAY_SIZE,
    depth = MAX_DEPTH
  script:
    "scripts/python/generate_balanced_quicksort_input.py"