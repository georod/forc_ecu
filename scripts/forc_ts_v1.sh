#!/bin/bash
#SBATCH --account=   # replace this with your own account
#SBATCH --mem-per-cpu=200G      # memory; default unit is megabytes --mem-per-cpu not needed, or mem=
#SBATCH --time=0-2:00           # time (DD-HH:MM)
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name=forc_ts
#SBATCH --output=%x-%j.out
#SBATCH --mail-user=
#SBATCH --mail-type=ALL
module restore spatial_modules3  # Adjust version and add the gcc mod>

Rscript ~/projects/def-mfortin/georod/scripts/github/forc_ecu/scripts/trend_breaks_create_ts_evi_v4_sv1.R


