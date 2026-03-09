# ABodyBuilder2 Job Arrays

## Slurm Script for a Single Sample 

```
#!/bin/bash

#SBATCH --job-name      immunebuilder-test
#SBATCH --cpus-per-task 6 
#SBATCH --mem           4GB
#SBATCH --time          00:30:00 
#SBATCH --output        slog/%j.out


# Speficy apptainer specific environment variables
# Primarily for binging the file system and another for exec comamnd to
# shorten the execution command 
export APPTAINER_BIND="/gpfs3/well,/gpfs3/users,/gpfs3/well/kir/projects/mirror/training/immunebuilder/immunebuilder_weights:/opt/conda/envs/immunebuilder/lib/python3.9/site-packages/ImmuneBuilder/trained_model"
export CMD="apptainer exec /gpfs3/well/kir/projects/mirror/containers/immunebuilder.sif"

# if using symlinks, we have to resolve the current working directory path correctly with 
cd -P . 


${CMD} ABodyBuilder2 --fasta_file /gpfs3/well/ldustin/projects/archive/Kahlio_PacBio_1/RIO_BCR_10/ab2/BCR10__m84227_251207_031623_s1_100008597_ccs_2.fasta \
  --output /gpfs3/well/ldustin/projects/archive/Kahlio_PacBio_1/RIO_BCR_10/ab2_pdb \
  --to_directory \
  --n_threads ${SLURM_CPUS_PER_TASK}
```

## Slurm array script for multiple inputs

### Testing

1. Created a subset of inputs in `/gpfs3/well/ldustin/projects/archive/Kahlio_PacBio_1/RIO_BCR_10/subset`
2. Count the number of files in the directory with `ls  subset| wc -l` ( we will need this number
   to decide the number of array tasks .i.e. `#SBATCH --array` range will be `0-(n-1)` where `n` is the output
   for above `ls input_directory| wc -l` command 


```bash
#!/bin/bash -e

#SBATCH --job-name      immunebuilder-array
#SBATCH --cpus-per-task 6
#SBATCH --mem           4GB
#SBATCH --time          00:10:00
#SBATCH --output        subset_slog/%A_%a.out
#SBATCH --array         0-9

# --- Paths ---
INPUT_DIR="/gpfs3/well/ldustin/projects/archive/Kahlio_PacBio_1/RIO_BCR_10/subset"
OUTPUT_DIR="/gpfs3/well/ldustin/projects/archive/Kahlio_PacBio_1/RIO_BCR_10/subset_pdb"

# --- Build file list and pick this task's file ---
mapfile -t FASTA_FILES < <(ls "${INPUT_DIR}"/*.fasta)
FASTA="${FASTA_FILES[$SLURM_ARRAY_TASK_ID]}"

# Safety check — exit cleanly if index is out of bounds
if [[ -z "$FASTA" ]]; then
    echo "No file for task ID ${SLURM_ARRAY_TASK_ID}, exiting."
    exit 0
fi

# --- Derive output directory name from filename (strip path + .fasta) ---
SAMPLE=$(basename "$FASTA" .fasta)
SAMPLE_OUT="${OUTPUT_DIR}/${SAMPLE}"
mkdir -p "$SAMPLE_OUT"

# --- Apptainer config ---
export APPTAINER_BIND="/gpfs3/well,/gpfs3/users,/gpfs3/well/kir/projects/mirror/training/immunebuilder/immunebuilder_weights:/opt/conda/envs/immunebuilder/lib/python3.9/site-packages/ImmuneBuilder/trained_model"
export CMD="apptainer exec /gpfs3/well/kir/projects/mirror/containers/immunebuilder.sif"

cd -P .

# --- Run ---
echo "Processing: ${FASTA}"
echo "Output to:  ${SAMPLE_OUT}"

${CMD} ABodyBuilder2 \
    --fasta_file "$FASTA" \
    --output "$SAMPLE_OUT" \
    --to_directory \
    --n_threads "${SLURM_CPUS_PER_TASK}"
```
#### Notes


**How each job knows which file to process**

When a SLURM array job runs, it launches many identical copies of the script simultaneously — 
each one gets a unique number via $SLURM_ARRAY_TASK_ID (0, 1, 2, 3, ...).

This snippet uses that number to assign each job its own input file:

```bash
mapfile -t FASTA_FILES < <(ls "${INPUT_DIR}"/*.fasta)
```
Reads all .fasta files in the input directory into a bash array called FASTA_FILES. 
The first file is index 0, the second is index 1, and so on.

```bash
FASTA="${FASTA_FILES[$SLURM_ARRAY_TASK_ID]}"
```
Picks the file at the position matching the current job's task ID. So job 0 processes 
the first file, job 1 the second, and so on — automatically, with no manual assignment needed.

```bash
if [[ -z "$FASTA" ]]; then
    echo "No file for task ID ${SLURM_ARRAY_TASK_ID}, exiting."
    exit 0
fi
```
A safety check. If the array was submitted with more tasks than there are files (e.g. 10 tasks but only 7 files), the extra jobs exit cleanly rather than crashing or producing an error.

Example: If your input directory contains sample_A.fasta, sample_B.fasta, sample_C.fasta, submitting --array=0-2 will spawn 3 jobs — each processing exactly one file.




