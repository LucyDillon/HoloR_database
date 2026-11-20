# HoloR database 
This is a repository for all scripts used to create the HoloR database of ruminant-associated microbiomes.
## Custom databases:
We have developed three custom databases from our genomes specifically for ruminant research: Kraken2, BLASTp and dbCAN. 

### Development:
Please see the folder "custom_databases" for instructions on how each database was developed. 
Download:
To download our databases use the following commands:
#### Download data:
```
# Put wget script here 
```
#### Concatenate files for database
```
### concatenate
```
#### How to run custom DBs
##### Kraken2
```
kraken script
```
mem and cpu requirements
##### BLASTp
```
blast script
```
##### dbCAN
```
dbCAN script
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

