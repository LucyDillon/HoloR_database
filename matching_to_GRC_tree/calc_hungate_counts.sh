awk '!seen[$1]++ {print $2}' best_hungate_hits.tsv | sort | uniq -c > best_hungate_hits_counts.tsv
