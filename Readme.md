This is a repository for all scripts used to create the HoloR database of ruminant-associated microbiomes.

Annotation scripts:

| Script | What it does it do? |
|--------|---------------------|
| bakta.sh| Predicts coding regions |
| barrnap.sh| Predicts tRNA and rRNA regions | 
| checkm2.sh| Predicts completeness and contamination |
|dbCAN.sh | Predicts carbohydrate-active enzyme annotations |
| eggNOG.sh | Functional gene family predictions. |
| gtdbtk.sh| Taxonomic predictions |
| ncbi_amrfinder.sh| Predicts ARGs|
|resfinder.sh | Predicts ARGs | 
| sourmash_sig.sh| Creates genome signatures|

Dereplication scripts:
| Script | What it does it do? |
|--------|---------------------|
| skder_100.sh| Used to dereplicate all 193,368 genomes and MAGs at 100% identity |
| skder_95.sh| Used to dereplicate at 95% on the medium/high quality genomes/MAgs | 

Add info on:
- kraken db
- blastp db
- dbCAN

  
