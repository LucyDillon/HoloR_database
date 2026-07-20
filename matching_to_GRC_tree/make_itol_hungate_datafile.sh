awk 'BEGIN{
print "DATASET_SYMBOL"
print "SEPARATOR TAB"
print "DATASET_LABEL\tMAG_hits"
print "COLOR\t#ffff00" # use yellow colour to match with OG hungate paper 
print ""
print "DATA"
}
{
print $2 "\t2\t15\t#ffff00\t1\t1"
}' best_hungate_hits_counts.tsv > GRC_hungate_hits_iTOL.txt
