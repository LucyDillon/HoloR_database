for i in *16S.fa; do awk '/^>/{p=/16S_rRNA/} p' $i; done >> 16S_rRNA.fasta
