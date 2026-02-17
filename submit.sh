#!/bin/bash

#SBATCH --job-name     immunebuilder-test
#SBATCH --cpus-per-tas 2 
#SBATCH --mem          2GB
#SBATCH --time         00:10:00
#SBATCH --output       slog/%j.out


# Speficy apptainer specific environment variables
# Primarily for binging the file system and another for exec comamnd to
# shorten the execution command 
export APPTAINER_BIND="/gpfs3/well,/gpfs3/users"
export CMD="apptainer exec /gpfs3/well/kir/projects/mirror/containers/immunebuilder.sif"

# if using symlinks, we have to resolve the current working directory path correctly with 
cd -P . 

${CMD} ./abody_prediction_example.py
