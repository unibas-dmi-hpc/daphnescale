include: "doe.smk"

rule all:
  input:
    expand("results/{benchmark}/{form}/{lang}/{mpi_procs}/{iter}.dat",\
      benchmark=SCRIPTS,\
      form=["mpi_local"],\
      lang=["cpp","py","jl"],\
      mpi_procs=MPI_LOCAL.keys(),\
      iter=ITERATIONS),
    expand("results/{benchmark}/{form}/daph/{scheme}-{layout}-{victim}/{mpi_procs}/{iter}.dat",\
      benchmark=SCRIPTS,\
      form=["mpi_local"],\
      mpi_procs=MPI_LOCAL.keys(),\
      scheme=["static"],\
      layout=["centralized"],\
      victim=["seq"],\
      iter=ITERATIONS),    

rule run_expe_mpi_jupycpp:
  input:
    sbatch="sbatch_scripts/nomat_run_vega_{lang}_mpi.sh",
    script="benchmark_scripts/{benchmark}-mpi/{lang}/{benchmark}.{lang}",
    data=lambda w: INPUT_DATA.get(w.benchmark, [])
  output:
    "results/{benchmark}/{form}/{lang}/{mpi_procs}/{iter}.dat"  
  wildcard_constraints:
    lang="cpp|py|jl",
    form="mpi_local"    
  params:
    tasks_per_node = lambda w: MPI_LOCAL[w.mpi_procs][0],
    cpus_per_task = lambda w: MPI_LOCAL[w.mpi_procs][1],
    nb_nodes = 1,
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
    sbatch  --job-name={wildcards.form}_{wildcards.benchmark}_{wildcards.lang}_{params.tasks_per_node}r_{wildcards.iter}r \
            --nodes={params.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} {input.sbatch} {params.cpus_per_task} {input.script} {output} {params.args}
    """

rule run_expe_mpi_daph:
  input:
    sbatch="sbatch_scripts/nomat_run_vega_daph_mpi.sh",
    daphne="daphne-src-mpi/bin/daphne",
    script="benchmark_scripts/{benchmark}-seq/daph/{benchmark}.daph",
    data=lambda w: INPUT_DATA.get(w.benchmark, [])
  output:
    "results/{benchmark}/{form}/daph/{scheme}-{layout}-{victim}/{mpi_procs}/{iter}.dat" 
  wildcard_constraints:
    form="mpi_local"
  params:
    tasks_per_node = lambda w: MPI_LOCAL[w.mpi_procs][0] + 1, # additional task for coordinator
    cpus_per_task = lambda w: MPI_LOCAL[w.mpi_procs][1],
    nb_nodes = 1,
    scheme_uc = lambda w: w.scheme.upper(),
    layout_uc = lambda w: w.layout.upper(),
    victim_uc = lambda w: w.victim.upper(),
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
    sbatch  --job-name={wildcards.form}_{wildcards.benchmark}_daph_{params.tasks_per_node}r_{wildcards.iter}r \
            --nodes={params.nb_nodes} \
            --ntasks-per-node={params.tasks_per_node} \
            --cpus-per-task={params.cpus_per_task} \
             {input.sbatch} {params.cpus_per_task} {input.script} {params.scheme_uc} {params.layout_uc} {params.victim_uc} {output} {params.args} 
    """