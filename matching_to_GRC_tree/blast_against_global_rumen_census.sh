#!/bin/sh
#SBATCH --time=23:59:00
#SBATCH --partition=k2-medpri,k2-bioinf
#SBATCH --mem=50G
#SBATCH --mail-user=l.dillon@qub.ac.uk
#SBATCH --mail-type=END,BEGIN,FAIL
#SBATCH --error=blast-%A-%a.err
#SBATCH --job-name=blast

module load apps/ncbiblast/2.15.0/gcc-14.1.0

blastn \
    -query all_16S_queries.fa \ # this is all barrnap holor results
    -db ../../all_for_70th-build_db \
    -task blastn \
    -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen" \
    -out blast_results.tsv
