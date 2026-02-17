#!/usr/bin/env python3 

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
