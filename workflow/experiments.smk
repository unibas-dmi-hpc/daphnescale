include: "doe.smk"
include: "build.smk"

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
      iter=ITERATIONS),
 
rule run_expe_seq:
  input:
    sbatch="sbatch_scripts/run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-seq/{lang}/{benchmark}.{lang}",
  output:
    "results/{benchmark}/{form}/{lang}/{num_threads}/{iter}.dat"  
  wildcard_constraints:
      form="seq"    
  params:
    args=lambda w: " ".join(
        (
            str(ARGUMENTS[w.benchmark][w.form][key][0])
            if key in ARGUMENTS[w.benchmark][w.form]
            else str(getattr(w, key)). # takes the value from the wildcard
        )
        for key in ARGUMENTS[w.benchmark][w.form]["args"]
    )
  shell:
    """
    sbatch --job-name=seq_{wildcards.benchmark}_{wildcards.lang}_{wildcards.num_threads}t_{wildcards.iter}r \
           --cpus-per-task={wildcards.num_threads} {input.sbatch} {wildcards.num_threads} {input.script} {params.args} {output}
    """

rule run_expe_par_with_seq:
  input:
    sbatch="sbatch_scripts/run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-seq/{lang}/{benchmark}.{lang}",
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
           --cpus-per-task={wildcards.num_threads} {input.sbatch} {wildcards.num_threads} {input.script} {params.args} {output}
    """

rule run_expe_par:
  input:
    sbatch="sbatch_scripts/run_vega_{lang}.sh",
    script="benchmark_scripts/{benchmark}-par/{lang}/{benchmark}.{lang}",
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
           --cpus-per-task={wildcards.num_threads} {input.sbatch} {wildcards.num_threads} {input.script} {params.args} {output}
    """