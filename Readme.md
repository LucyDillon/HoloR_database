# HoloR database 
The HoloR has been developed for ruminant microbiome researchers. We sourced 193,368 genomes and MAGs from various ruminant hosts and body sites. We dereplicated the data at 100% using skDER. Then we used CheckM2 to assess quality. Medium- and high-quality genomes were then taken to be the final dataset. We used consistent annotations across all the data (see Annotation scripts for details). We validated our database by using Bowtie2 to assess read mapping for ruminant microbiome samples of both internal (used to make the database) and external (not used in database development). We also developed custom databases, and the details of how to download and use them are below.

<img width="1228" height="809" alt="Screenshot 2026-11-20 at 14 32 36" src="https://github.com/user-attachments/assets/a5b0fe06-ab69-4e68-8683-382270436325" />
Figure 1: HoloR database sources and development.


## Custom databases:
We have developed three custom databases from our genomes specifically for ruminant research: Kraken2, BLASTp and dbCAN. 

#### Development:
Please see the folder "custom_databases" for instructions on how each database was developed. 

#### Download data:
```
# Put wget script here
wget https://pure.qub.ac.uk/en/datasets/HoloRxxxx
```
#### Concatenate files for databases
```
### Due to database file size restrictions, we need to concatenate the database files
# for the custom nonredundant protein BLAST database:
cat holoR_nonredundant_db.tar.gz* > Protein_holoR_nonredundant_db.tar.gz

# for all genomes:
cat fasta_files.tar.gz* > Genomes_fasta_files.tar.gz

# for custom HoloR Kraken2 database:
cat kraken_db.tar.gz* > HoloR_kraken_db.tar.gz

```
#### How to run custom DBs
##### Kraken2
```
kraken2 \
        --db /path/to/kraken_database \
        --paired read_1.fastq read_2.fastq \
        --confidence 0.1 \
        --classified-out classified-out.R#.fq \
        --unclassified-out unclassified-out.R#.fq \
        --output kraken_output_out.txt \
        --report kreport_out.txt \
        --threads 8 #change based on your usage
```
mem and cpu requirements
##### BLASTp
```
blastn -query test.fasta -db holoR_nonredundant_db \
  -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen" \
  -out output.tsv
```
##### dbCAN
```
run_dbcan CAZyme_annotation \
    --input_raw_data  test.faa \
    --mode            protein \
    --db_dir          dbCAN_dbs/ \
    --output_dir      test_dbCAN/ \
    --methods         diamond,hmm \
```



## Annotation scripts:

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

## Dereplication scripts:
| Script | What it does it do? |
|--------|---------------------|
| skder_100.sh| Used to dereplicate all 193,368 genomes and MAGs at 100% identity |
| skder_95.sh| Used to dereplicate at 95% on the medium/high quality genomes/MAgs | 

## Database validation:
### Read mapping
To validate our database, we mapped external ruminant microbiome samples to our database to understand how representative our database is of a random ruminant sample. For the complete workflow, please go into the read_mapping folder.

### Custom database validation
We tested our custom databases against the standard versions.


