#!/bin/bash
# This script runs a series of experiments to estimate the value of Pi using different methods.

## script to run GCsnap cluster
path=/ceph/hpc/data/d2025d03-111-users/daphnescale/python-pre-experiments/
base_res_path=${path}results-py/
slurm_log_path=${base_res_path}slurm-logs/
mkdir -p "$slurm_log_path"

# which way to approximate Pi (py312 for Python v3.12 used for pyomp, py314 for Python v3.14 with GIL, py314 for Gil-free Python v3.14), s|t|p for serial, threads, processes
# parallel type python|omp gives 1 process and #N cpu cores, python itself either creats as many threads or processes as there are cores
# mpi needs number of ranks and 1 cpu core per rank
# profiling with scoreP was not possible, as host's scoreP lacks python bindings
# building a scoreP working with the container was not possbile as missmatch between host's openmpi and container's gompi
# and building scoreP inside the container was not possible due to missing build tools and libraries	
combos=( 	
	"seq py314t seq none"
	"mp-threads py314t python viztracer"
	"mp-map py314t python viztracer"
	"mp-imap py314t python viztracer"
	"mp-imap-unordered py314t python viztracer"  
	"omp4py-static py314t omp none"
	"omp4py-dynamic py314t omp none"
	"omp4py-guided py314t omp none"
	"mpi4py py314t mpi none"
	"seq py314 seq none"
	"mp-threads py314 python viztracer"
	"mp-map py314 python viztracer"
	"mp-imap py314 python viztracer"
	"mp-imap-unordered py314 python viztracer"  
	"mpi4py py314 mpi none"	
	"numba py312 python none"
	"pyomp py312 python none"	
)

profile=0 # 0 false --> performance experiment, 1 true --> profiling experiment

nodes=1  # single node experiments

# If profiling -> use a subfolder once
if (( profile == 1 )); then
    res_path="${base_res_path}profiling/"
    mkdir -p "$res_path"
	n=10000 # number of intervals in the numerical integral summation
	job_time="0-00:10:00"
    profiler="none"
	repetitions=1	
else
    res_path="$base_res_path"
	# number of intervals in the numerical integral summation
	raw="500_000_000"
	n=$(( $(tr -d '_' <<< "$raw") ))
	# time limit for each job
	job_time="0-00:05:00"
	repetitions=5
fi

for combo in "${combos[@]}" 
do

	# Extract values
	read kind sing_img parallel_type profiler <<< "$combo"

    # Disable profiling globally if requested
    if (( profile == 0 )); then
		if [[ "$parallel_type" == "seq" ]]; then
			ranks_per_node_list="1"
			cpus_per_rank_list="1"
		elif [[ "$parallel_type" == "python" || "$parallel_type" == "omp" ]]; then
			ranks_per_node_list="1"
			cpus_per_rank_list="1 2 4 8"
			#cpus_per_rank_list="4"
		elif [[ "$parallel_type" == "mpi" ]]; then
			ranks_per_node_list="1 2 4 8"
			# ranks_per_node_list="4"
			cpus_per_rank_list="1"
		fi			
	else
		if [[ "$parallel_type" == "seq" ]]; then
			ranks_per_node_list="1"
			cpus_per_rank_list="1"
		elif [[ "$parallel_type" == "python" || "$parallel_type" == "omp" ]]; then
			ranks_per_node_list="1"
			cpus_per_rank_list="8"
		elif [[ "$parallel_type" == "mpi" ]]; then
			ranks_per_node_list="8"
			cpus_per_rank_list="1"
		fi	
    fi
	
	for ranks_per_node in ${ranks_per_node_list}
	do

		for cpus_per_rank in ${cpus_per_rank_list}
		do

			ident_base=${kind}_${sing_img}_p${ranks_per_node}_t${cpus_per_rank}

			sbatch 	--array=1-${repetitions} \
					--export=ALL,time=${job_time},path=${path},res_path=${res_path},kind=${kind},sing_img=${sing_img},parallel_type=${parallel_type},profiler=${profiler},n=${n},nodes=${nodes},ranks_per_node=${ranks_per_node},cpus_per_task=${cpus_per_rank},ident_base=${ident_base},profile=${profile} \
					--nodes=${nodes} \
        			--ntasks-per-node=${ranks_per_node} \
        			--cpus-per-task=${cpus_per_rank} \
					--job-name=${ident_base} \
					--output=${slurm_log_path}${ident_base}_r%a.out \
					${path}pi_slurm.job

		done
	done
done


