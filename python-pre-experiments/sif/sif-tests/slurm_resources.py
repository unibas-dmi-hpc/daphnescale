import os

def get_slurm_resources():
    resources = {}
    slurm_vars = [
        'SLURM_JOB_ID',
        'SLURM_JOB_NAME',
        'SLURM_JOB_PARTITION',
        'SLURM_JOB_NUM_NODES',
        'SLURM_JOB_NODELIST',
        'SLURM_NTASKS_PER_NODE',
        'SLURM_CPUS_PER_TASK',
        'SLURM_MEM_PER_NODE',
        'SLURM_TIME'  # that one is not existing by default
    ]
    
    for var in slurm_vars:
        value = os.getenv(var)
        if value is not None:
            resources[var] = value
    
    return resources

if __name__ == '__main__':
    slurm_resources = get_slurm_resources()
    for key, value in slurm_resources.items():
        print(f"{key}: {value}")