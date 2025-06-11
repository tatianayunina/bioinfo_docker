#!/usr/bin/env python3

import argparse
import logging
import os
import sys
from datetime import datetime
from pysam import FastaFile

def setup_logger(log_path):
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        handlers=[
            logging.FileHandler(log_path),
            logging.StreamHandler(sys.stdout)
        ]
    )

def parse_args():
    parser = argparse.ArgumentParser(
        description="Script to convert allele1/allele2 to REF/ALT using GRCh38 reference genome."
    )
    parser.add_argument('--input', '-i', required=True, help='Input .tsv file (5-column allele file)')
    parser.add_argument('--output', '-o', required=True, help='Output .tsv file (with REF/ALT)')
    parser.add_argument('--refpath', '-r', required=True, help='Path to reference .fa files, e.g. /ref/GRCh38.d1.vd1_mainChr/sepChrs/')
    parser.add_argument('--log', '-l', default='convert_alleles.log', help='Log file path')
    return parser.parse_args()

def detect_reference(chrom, pos, allele1, allele2, refdir):
    fasta_path = os.path.join(refdir, f"{chrom}.fa")
    try:
        fasta = FastaFile(fasta_path)
        ref_base = fasta.fetch(chrom, int(pos) - 1, int(pos)).upper()
        fasta.close()
        if ref_base == allele1:
            return allele1, allele2
        elif ref_base == allele2:
            return allele2, allele1
        else:
            return None, None
    except Exception as e:
        logging.error(f"Could not fetch reference for {chrom}:{pos}: {e}")
        return None, None

def main():
    args = parse_args()
    setup_logger(args.log)

    if not os.path.exists(args.input):
        logging.error(f"Input file does not exist: {args.input}")
        sys.exit(1)

    if not os.path.exists(args.refpath):
        logging.error(f"Reference path not found: {args.refpath}")
        sys.exit(1)

    with open(args.input, 'r', encoding='utf-8') as fin, open(args.output, 'w', encoding='utf-8') as fout:
        header = fin.readline().strip().split('\t')
        if header != ['#CHROM', 'POS', 'ID', 'allele1', 'allele2']:
            logging.error("Input file header is invalid or not in expected format")
            sys.exit(1)

        fout.write("#CHROM\tPOS\tID\tREF\tALT\n")
        total = 0
        success = 0
        failed = 0

        for line in fin:
            total += 1
            fields = line.strip().split('\t')
            if len(fields) != 5:
                logging.warning(f"Skipping malformed line {total}: {line.strip()}")
                failed += 1
                continue
            chrom, pos, snp_id, allele1, allele2 = fields
            ref, alt = detect_reference(chrom, pos, allele1, allele2, args.refpath)
            if ref:
                fout.write(f"{chrom}\t{pos}\t{snp_id}\t{ref}\t{alt}\n")
                success += 1
            else:
                failed += 1
                logging.warning(f"Could not determine REF for {chrom}:{pos} {snp_id} {allele1}/{allele2}")

    logging.info(f"Completed. Total: {total}, Success: {success}, Failed: {failed}")

if __name__ == '__main__':
    main()