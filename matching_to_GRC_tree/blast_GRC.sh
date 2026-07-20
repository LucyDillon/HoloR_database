# I run this on the interactive node as there are very few queries
# THIS IS THE HUNGATE DATA AGAINST GRC
module load apps/ncbiblast/2.15.0/gcc-14.1.0

blastn -query hungate.fasta -db all_for_70th-build_db \
  -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen" \
  -out blast_HUNGATE_results_GRC.tsv
