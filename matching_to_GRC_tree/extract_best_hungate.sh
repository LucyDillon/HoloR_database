MIN_PIDENT=97
MIN_QCOV=0.90
MAX_EVALUE=1e-10


awk -v pid=$MIN_PIDENT -v qcov=$MIN_QCOV -v val=$MAX_EVALUE \
  '($3 >= pid) && ($4 / $13 >= qcov) && ($11 <= val)' blast_HUNGATE_results_GRC.tsv | \
sort -k1,1 -k12,12gr | \
awk '!seen[$1]++' > best_hungate_hits.tsv
