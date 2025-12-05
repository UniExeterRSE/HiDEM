#!/usr/bin/env python3
"""Parse HiDEM log files and report SLURM_NTASKS, SLURM_NNODES, NTOT min/max/avg and Duration.

Usage: python3 scripts/collect_run_stats.py /path/to/logdir [--out out.csv]
"""
import sys
import os
import re
import csv
from statistics import mean, stdev
import argparse


def parse_file(path):
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        txt = f.read()

    # SLURM values
    ntasks = None
    nnodes = None
    m = re.search(r'SLURM_NTASKS\s*=\s*(\d+)', txt)
    if m:
        ntasks = int(m.group(1))
    m = re.search(r'SLURM_NNODES\s*=\s*(\d+)', txt)
    if m:
        nnodes = int(m.group(1))

    # NTOT values
    ntot_strs = re.findall(r'NTOT:\s*(\d+)', txt)
    ntot_vals = [int(x) for x in ntot_strs]

    ntot_min = ntot_max = ntot_avg = None
    ntot_std = None
    if ntot_vals:
        ntot_min = min(ntot_vals)
        ntot_max = max(ntot_vals)
        ntot_avg = mean(ntot_vals)
        try:
            if len(ntot_vals) > 1:
                ntot_std = stdev(ntot_vals)
            else:
                ntot_std = None
        except Exception:
            ntot_std = None

    # Duration (seconds)
    duration = None
    m = re.search(r'Duration:\s*([0-9]+(?:\.[0-9]+)?)\s*seconds', txt)
    if m:
        duration = float(m.group(1))

    # Job ID: try several common patterns; fallback to filename
    jobid = None
    m = re.search(r'Job ID[:\s]*([0-9]+)', txt, re.IGNORECASE)
    if m:
        jobid = m.group(1)
    if not jobid:
        m = re.search(r'SLURM_JOBID\s*=\s*([0-9]+)', txt)
        if m:
            jobid = m.group(1)
    if not jobid:
        m = re.search(r'SLURM_JOB_ID\s*=\s*([0-9]+)', txt)
        if m:
            jobid = m.group(1)
    if not jobid:
        # fallback to basename so table still shows something useful
        jobid = os.path.basename(path)

    return {
        'JobID': jobid,
        'file': os.path.basename(path),
        'path': path,
        'SLURM_NTASKS': ntasks,
        'SLURM_NNODES': nnodes,
        'NTOT_min': ntot_min,
        'NTOT_max': ntot_max,
        'NTOT_avg': ntot_avg,
        'NTOT_stddev': ntot_std,
        'NTOT_rsd': (ntot_std / ntot_avg) * 100 if ntot_std is not None and ntot_avg else None,
        'Duration_s': duration,
        'NTOT_count': len(ntot_vals),
    }


def find_log_files(directory):
    # match typical log names; include files ending with .out.log
    files = []
    for entry in sorted(os.listdir(directory)):
        path = os.path.join(directory, entry)
        if os.path.isfile(path) and (entry.endswith('.out.log')):
            files.append(path)
    return files


def print_table(rows):
    headers = ['JobID', 'SLURM_NTASKS', 'SLURM_NNODES', 'NTOT_min', 'NTOT_max', 'NTOT_avg', 'NTOT_rsd', 'Duration_s']
    # compute widths
    col_vals = []
    for r in rows:
        col_vals.append([
            str(r.get('JobID','')),
            str(r['SLURM_NTASKS']) if r['SLURM_NTASKS'] is not None else '',
            str(r['SLURM_NNODES']) if r['SLURM_NNODES'] is not None else '',
            str(r['NTOT_min']) if r['NTOT_min'] is not None else '',
            str(r['NTOT_max']) if r['NTOT_max'] is not None else '',
            ('{:.4f}'.format(r['NTOT_avg'])) if r['NTOT_avg'] is not None else '',
            ('{:.4f}'.format(r['NTOT_rsd'])) if r.get('NTOT_rsd') is not None else '',
            ('{:.6f}'.format(r['Duration_s'])) if r['Duration_s'] is not None else '',
        ])

    # determine column widths
    col_widths = [0]*len(headers)
    for i,h in enumerate(headers):
        col_widths[i] = max(len(h), *(len(row[i]) for row in col_vals) if col_vals else [0])

    fmt = '  '.join('{:%d}' % w for w in col_widths)
    print(fmt.format(*headers))
    print('-' * (sum(col_widths) + 2 * (len(col_widths)-1)))
    for row in col_vals:
        print(fmt.format(*row))


def write_csv(rows, outpath):
    fieldnames = ['JobID','file','SLURM_NTASKS','SLURM_NNODES','NTOT_min','NTOT_max','NTOT_avg','NTOT_count','Duration_s','path']
    with open(outpath, 'w', newline='') as csvf:
        w = csv.DictWriter(csvf, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            out = {k: r.get(k) for k in fieldnames}
            w.writerow(out)



def main():
    parser = argparse.ArgumentParser(
        description='Collect NTOT statistics from HiDEM log files in a directory')
    parser.add_argument('directory', help='Path to directory containing log files')
    parser.add_argument('-o', '--out', dest='out_csv', help='Write results to CSV file')
    args = parser.parse_args()

    directory = args.directory
    out_csv = args.out_csv

    if not os.path.isdir(directory):
        print('Not a directory:', directory, file=sys.stderr)
        return 3

    files = find_log_files(directory)
    if not files:
        print('No log files found in', directory)
        return 0

    rows = []
    for f in files:
        try:
            rows.append(parse_file(f))
        except Exception as e:
            print('Error parsing', f, ':', e, file=sys.stderr)

    print_table(rows)
    if out_csv:
        write_csv(rows, out_csv)
        print('\nWrote CSV to', out_csv)

    return 0


if __name__ == '__main__':
    sys.exit(main())
