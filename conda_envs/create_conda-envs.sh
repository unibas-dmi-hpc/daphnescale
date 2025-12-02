#!/bin/bash

ml Anaconda3/2023.07-2

# Code-metrics
# ------------
# create env from yml
conda env create -f code-metrics.yml

# install multimetric
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate code-metrics
cd /ceph/hpc/data/d2025d03-111-users/daphnescale/coding-productivity/multimetric
pip install -e .

# Plotting
# ------------
# create env from yml
conda env create -f plotting.yml

# Snakemake
# ------------
# create env from yml
conda env create -f snakemake.yml


