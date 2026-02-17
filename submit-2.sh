#!/bin/bash

#SBATCH --job-name      immunebuilder-test
#SBATCH --cpus-per-task 6 
#SBATCH --mem           4GB
#SBATCH --time          00:02:00 
#SBATCH --output        slog/%j.out


# Speficy apptainer specific environment variables
# Primarily for binging the file system and another for exec comamnd to
# shorten the execution command 
export APPTAINER_BIND="/gpfs3/well,/gpfs3/users,/gpfs3/well/kir/projects/mirror/training/immunebuilder/immunebuilder_weights:/opt/conda/envs/immunebuilder/lib/python3.9/site-packages/ImmuneBuilder/trained_model"
export CMD="apptainer exec /gpfs3/well/kir/projects/mirror/containers/immunebuilder.sif"

# if using symlinks, we have to resolve the current working directory path correctly with 
cd -P . 


${CMD} ABodyBuilder2 --fasta_file BCR5__m84227_251207_031623_s1_157159693_ccs_2.fasta \
  --output /gpfs3/well/kir/projects/mirror/training/immunebuilder/results \
  --to_directory \
  --n_threads ${SLURM_CPUS_PER_TASK}
