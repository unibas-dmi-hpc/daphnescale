include: "doe.smk"

rule all:
  input:
    expand("results/{benchmark}/{form}_nodes/{lang}/{nb_nodes}/{iter}.dat",\
      benchmark=SCRIPTS,\
      form=["mpi_scale"],\
      lang=["cpp","py","jl"],\
      nb_nodes=MPI_SCALE_NB_NODES,\
      iter=ITERATIONS),
    # expand("results/{benchmark}/{form}_nodes/daph/{scheme}-{layout}-{victim}/{nb_nodes}/{iter}.dat",\
    #   benchmark=SCRIPTS,\
    #   form=["mpi_scale"],\
    #   scheme=["static"],\
    #   layout=["centralized"],\
    #   victim=["seq"],\
    #   nb_nodes=MPI_SCALE_NB_NODES,\
    #   iter=ITERATIONS),  

rule run_expe_mpi_jupycpp:
  input:
    sbatch="sbatch_scripts/nomat_run_vega_{lang}_mpi.sh",
    script="benchmark_scripts/{benchmark}-mpi/{lang}/{benchmark}.{lang}",
  output:
    "results/{benchmark}/{form}_nodes/{lang}/{nb_nodes}/{iter}.dat"  
  wildcard_constraints:
    lang="cpp|py|jl",
    form="mpi_scale"
  params:
    tasks_per_node = 16,  # MPI process each with 1 thread for cpp, jl and py
    cpus_per_task = 1,
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
    sbatch  --job-name={wildcards.form}_{wildcards.benchmark}_{wildcards.lang}_{wildcards.nb_nodes}n_{wildcards.iter}r \
            --nodes={wildcards.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {params.cpus_per_task} {input.script} {output} {params.args}
    """

rule run_expe_mpi_daph:
  input:
    sbatch="sbatch_scripts/nomat_run_vega_daph_mpi.sh",
    daphne="daphne-src-mpi/bin/daphne",
    script="benchmark_scripts/{benchmark}-seq/daph/{benchmark}.daph",
  output:
    "results/{benchmark}/{form}_nodes/daph/{scheme}-{layout}-{victim}/{nb_nodes}/{iter}.dat" 
  wildcard_constraints:
    form="mpi_scale"
  params:
    tasks_per_node = 1,   # 1 process with many threads per process for daphne
    cpus_per_task = 16,
    scheme_uc = lambda w: w.scheme.upper(),
    layout_uc = lambda w: w.layout.upper(),
    victim_uc = lambda w: w.victim.upper(),
    nb_nodes_daph = lambda w: int(w.nb_nodes) + 1, # additonal node for coordinator    
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
    sbatch  --job-name={wildcards.form}_{wildcards.benchmark}_daph_{params.nb_nodes_daph}n_{wildcards.iter}r \
            --nodes={params.nb_nodes_daph} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} \
             {input.sbatch} {params.cpus_per_task} {input.script} {params.scheme_uc} {params.layout_uc} {params.victim_uc} {output} {params.args} 
    """

