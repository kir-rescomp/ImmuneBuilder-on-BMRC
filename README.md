# ImmuneBuilder on BMRC Cluster (deployed with Apptainer)

[ImmuneBuilder](https://github.com/oxpig/ImmuneBuilder) is a set of deep learning models for predicting the structures of immune receptor proteins (antibodies, nanobodies, TCRs).

---

## Why pre-download the weights?

BMRC compute nodes do not have internet access. By default, `ABodyBuilder2` attempts to download model weights from [Zenodo](https://zenodo.org/record/7258553) at runtime — this will fail on compute nodes with a proxy/connection error.

The solution is to download the four weight files (`antibody_model_1` – `antibody_model_4`) once from a login node (which has internet access) and store them on BMRC filesystem.

```bash
WEIGHTS_DIR=/gpfs3/well/kir/projects/mirror/training/immunebuilder/immunebuilder_weights
mkdir -p "${WEIGHTS_DIR}"

for i in 1 2 3 4; do
    wget -c "https://zenodo.org/record/7258553/files/antibody_model_${i}?download=1" \
         -O "${WEIGHTS_DIR}/antibody_model_${i}"
done
```

---

## Pointing the script to pre-downloaded weights

`ABodyBuilder2.__init__` accepts a `weights_dir` parameter. Pass the GPFS path to bypass the download step entirely:

```python
#!/usr/bin/env python3

from ImmuneBuilder import ABodyBuilder2

predictor = ABodyBuilder2(weights_dir="/gpfs3/well/kir/projects/mirror/training/immunebuilder/immunebuilder_weights")

output_file = "my_antibody.pdb"
sequences = {
  'H': 'EVQLVESGGGVVQPGGSLRLSCAASGFTFNSYGMHWVRQAPGKGLEWVAFIRYDGGNKYYADSVKGRFTISRDNSKNTLYLQMKSLRAEDTAVYYCANLKDSRYSGSYYDYWGQGTLVTVS',
  'L': 'VIWMTQSPSSLSASVGDRVTITCQASQDIRFYLNWYQQKPGKAPKLLISDASNMETGVPSRFSGSGSGTDFTFTISSLQPEDIATYYCQQYDNLPFTFGPGTKVDFK'
}

antibody = predictor.predict(sequences)
antibody.save(output_file)
```

---

## Slurm submission script with Apptainer - Using ABB2 Python API

The job is run inside an Apptainer container. Two environment variables are set to simplify execution:

- `APPTAINER_BIND` — mounts the required GPFS filesystems into the container, making both the input data and pre-downloaded weights accessible.
- `CMD` — shorthand for the `apptainer exec` call to avoid repetition.

```bash
#!/bin/bash

#SBATCH --job-name     immunebuilder-test
#SBATCH --cpus-per-task 2
#SBATCH --mem          2GB
#SBATCH --time         00:10:00
#SBATCH --output       slog/%j.out

export APPTAINER_BIND="/gpfs3/well,/gpfs3/users"
export CMD="apptainer exec /gpfs3/well/kir/projects/mirror/containers/immunebuilder.sif"

cd -P .

${CMD} ./abody_prediction_example.py
```

> `cd -P .` resolves any symlinks in the current working directory, ensuring paths are correctly interpreted inside the container.


## Slurm submission script with Apptainer - Using ABB2 Binary `ABodyBuilder2` 

```bash
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
```
