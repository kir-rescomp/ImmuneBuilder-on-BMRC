#!/bin/bash -e 

WEIGHTS_DIR=/gpfs3/well/kir/projects/mirror/training/immunebuilder/immunebuilder_weights
mkdir -p "${WEIGHTS_DIR}"

# ABodyBuilder2 uses an ensemble of 4 models from zenodo record 7258553
for i in 1 2 3 4; do
    wget -c "https://zenodo.org/record/7258553/files/antibody_model_${i}?download=1" \
         -O "${WEIGHTS_DIR}/antibody_model_${i}"
done
