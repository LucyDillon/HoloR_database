#!/usr/bin/env python3

import glob
import re
import os

# Output file
output = "all_16S.fasta"

n_files = 0
n_16s = 0
n_missing = 0

with open(output, "w") as out:

    for gff_file in glob.glob("*_rrna.gff"):

        fasta_file = gff_file.replace("_rrna.gff", "_rrna.fasta")

        if not os.path.exists(fasta_file):
            print(f"WARNING: FASTA not found for {gff_file}")
            continue

        n_files += 1

        # ------------------------------------------------------------
        # Read GFF and identify all 16S features
        # ------------------------------------------------------------
        targets = []

        with open(gff_file) as gff:
            for line in gff:

                if line.startswith("#"):
                    continue

                fields = line.rstrip("\n").split("\t")

                if len(fields) != 9:
                    continue

                seqid, source, feature, start, end, score, strand, phase, attributes = fields

                # Only rRNA features
                if feature != "rRNA":
                    continue

                # Identify 16S
                if (
                    "Name=16S_rRNA" not in attributes
                    and "product=16S ribosomal RNA" not in attributes
                    and "Alias=SSU_rRNA_bacteria" not in attributes
                ):
                    continue

                targets.append({
                    "seqid": seqid,
                    "start": int(start),
                    "end": int(end),
                    "strand": strand,
                    "attributes": attributes,
                })

        if not targets:
            continue

        # ------------------------------------------------------------
        # Read FASTA records
        # ------------------------------------------------------------
        records = {}

        with open(fasta_file) as fasta:

            header = None
            sequence = []

            for line in fasta:
                line = line.rstrip("\n")

                if line.startswith(">"):

                    # Save previous record
                    if header is not None:
                        records[header] = "".join(sequence)

                    header = line[1:].strip()
                    sequence = []

                else:
                    sequence.append(line.strip())

            # Save final record
            if header is not None:
                records[header] = "".join(sequence)

        # ------------------------------------------------------------
        # Match GFF 16S features to FASTA records
        # ------------------------------------------------------------
        sample = os.path.basename(gff_file).replace("_rrna.gff", "")

        for copy_number, target in enumerate(targets, start=1):

            found = False

            for fasta_header, sequence in records.items():

                # Expected FASTA header:
                # contig:start-end(strand)
                #
                # FASTA uses start = GFF start - 1
                pattern = r"^(.+):(\d+)-(\d+)\(([+-])\)$"
                match = re.match(pattern, fasta_header)

                if not match:
                    continue

                fasta_seqid = match.group(1)
                fasta_start = int(match.group(2))
                fasta_end = int(match.group(3))
                fasta_strand = match.group(4)

                if (
                    fasta_seqid == target["seqid"]
                    and fasta_start + 1 == target["start"]
                    and fasta_end == target["end"]
                    and fasta_strand == target["strand"]
                ):
                    # Unique identifier for this 16S copy
                    seq_id = f"{sample}_16S_{copy_number}"

                    out.write(
                        f">{seq_id} "
                        f"{target['seqid']}:{target['start']}-{target['end']}({target['strand']})\n"
                    )

                    # Wrap sequence at 80 characters
                    for i in range(0, len(sequence), 80):
                        out.write(sequence[i:i+80] + "\n")

                    n_16s += 1
                    found = True
                    break

            if not found:
                print(
                    f"WARNING: could not find FASTA sequence for "
                    f"{sample} {target['seqid']}:{target['start']}-{target['end']}({target['strand']})"
                )
                n_missing += 1

print()
print("Finished.")
print(f"GFF files processed: {n_files}")
print(f"16S sequences extracted: {n_16s}")
print(f"16S sequences missing: {n_missing}")
print(f"Output: {output}")
