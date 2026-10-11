#!/usr/bin/env python3
##########################################################################################
# Converts gcovr lcov output (.info) into CDash Coverage.xml (+ optional
# CoverageLog.xml with line-by-line data, including sources and branch counts).
#
# usage: ccws_lcov2cdash.py <input.info> <output_dir> [--strip-prefix <p>] [--log]
#
# Site envelope attributes are emitted as "(empty)" placeholders, the submission
# script (ccws_cdash_submit.sh) substitutes site / build name / stamp, same as
# for Test.xml; paths are stripped of the given prefix to keep them identical
# across build machines.
#
# CDash file format reference: app/Validators/Schemas/{Coverage,common}.xsd of
# the CDash server, note the different casing of LOCUnTested (inside File) and
# LOCUntested (at Coverage level).
##########################################################################################

import argparse
import datetime
import os
import sys
from xml.sax.saxutils import escape, quoteattr

GENERATOR = 'ccws-lcov2cdash 1.0'


def parse_lcov(path):
    files = []
    cur = None
    with open(path, encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\n')
            if line == 'end_of_record':
                if cur is not None:
                    files.append(cur)
                cur = None
            elif line.startswith('SF:'):
                cur = {'path': line[3:], 'da': {}, 'brda': {}, 'lf': None, 'lh': None}
            elif cur is None:
                continue
            elif line.startswith('DA:'):
                parts = line[3:].split(',')
                cur['da'][int(parts[0])] = int(parts[1])
            elif line.startswith('BRDA:'):
                ln, _block, _branch, taken = line[5:].split(',')
                cur['brda'].setdefault(int(ln), []).append(taken)
            elif line.startswith('LF:'):
                cur['lf'] = int(line[3:])
            elif line.startswith('LH:'):
                cur['lh'] = int(line[3:])
    return files


def file_stats(rec):
    lf = rec['lf'] if rec['lf'] is not None else len(rec['da'])
    lh = rec['lh'] if rec['lh'] is not None else sum(1 for c in rec['da'].values() if c > 0)
    return lh, max(lf - lh, 0)


def relpath(path, prefix):
    if prefix and path.startswith(prefix):
        return path[len(prefix):].lstrip('/')
    return path


def fmt_dt(ts):
    return datetime.datetime.fromtimestamp(ts, datetime.timezone.utc).strftime('%b %d %H:%M')


def write_coverage_xml(files, out, prefix, now):
    tested = sum(file_stats(r)[0] for r in files)
    untested = sum(file_stats(r)[1] for r in files)
    loc = tested + untested
    pct = round(100.0 * tested / loc, 2) if loc else 0.0
    with open(out, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(f'<Site BuildName="(empty)" BuildStamp="(empty)" Name="(empty)" Generator="{GENERATOR}">\n')
        f.write('  <Coverage>\n')
        f.write(f'    <StartDateTime>{fmt_dt(now)}</StartDateTime>\n')
        f.write(f'    <StartTime>{now}</StartTime>\n')
        for rec in files:
            lh, lu = file_stats(rec)
            fp = relpath(rec['path'], prefix)
            fpc = round(100.0 * lh / (lh + lu), 2) if (lh + lu) else 0.0
            f.write(f'    <File Name={quoteattr(fp)} FullPath={quoteattr(fp)} Covered="{"true" if lh else "false"}">\n')
            f.write(f'      <LOCTested>{lh}</LOCTested>\n')
            f.write(f'      <LOCUnTested>{lu}</LOCUnTested>\n')
            f.write(f'      <PercentCoverage>{fpc}</PercentCoverage>\n')
            f.write('    </File>\n')
        f.write(f'    <LOCTested>{tested}</LOCTested>\n')
        f.write(f'    <LOCUntested>{untested}</LOCUntested>\n')
        f.write(f'    <LOC>{loc}</LOC>\n')
        f.write(f'    <PercentCoverage>{pct}</PercentCoverage>\n')
        f.write(f'    <EndDateTime>{fmt_dt(now)}</EndDateTime>\n')
        f.write(f'    <EndTime>{now}</EndTime>\n')
        f.write('  </Coverage>\n')
        f.write('</Site>\n')


def write_coveragelog_xml(files, out, prefix, now):
    with open(out, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(f'<Site BuildName="(empty)" BuildStamp="(empty)" Name="(empty)" Generator="{GENERATOR}">\n')
        f.write('  <CoverageLog>\n')
        f.write(f'    <StartTime>{now}</StartTime>\n')
        f.write(f'    <EndTime>{now + 1}</EndTime>\n')
        for rec in files:
            fp = relpath(rec['path'], prefix)
            try:
                with open(rec['path'], encoding='utf-8', errors='replace') as src:
                    lines = src.read().split('\n')
            except OSError as e:
                print(f'CCWS: cannot read {rec["path"]}: {e}', file=sys.stderr)
                continue
            f.write(f'    <File FullPath={quoteattr(fp)}>\n')
            f.write('      <Report>\n')
            for i, text in enumerate(lines, start=1):
                count = rec['da'].get(i, -1)
                branches = rec['brda'].get(i)
                attrs = f'Number="{i}" Count="{count}"'
                if branches:
                    bt = sum(1 for t in branches if t not in ('-', '0'))
                    bu = len(branches) - bt
                    attrs += f' BRANCHESTESTED="{bt}" BRANCHESUNTESTED="{bu}"'
                f.write(f'        <Line {attrs}>{escape(text)}</Line>\n')
            f.write('      </Report>\n')
            f.write('    </File>\n')
        f.write('  </CoverageLog>\n')
        f.write('</Site>\n')


def main():
    ap = argparse.ArgumentParser(description='converts gcovr lcov output to CDash Coverage.xml (+ optional CoverageLog.xml)')
    ap.add_argument('info', help='lcov input file, e.g. <pkg>.info produced by gcovr')
    ap.add_argument('outdir', help='output directory, e.g. per-package artifacts directory')
    ap.add_argument('--strip-prefix', default='', help='prefix removed from recorded paths, e.g. workspace source directory')
    ap.add_argument('--log', action='store_true', help='also generate CoverageLog.xml (line-by-line data with sources)')
    args = ap.parse_args()

    try:
        files = parse_lcov(args.info)
    except OSError as e:
        sys.exit(f'CCWS: cannot read {args.info}: {e}')
    if not files:
        sys.exit(f'CCWS: no coverage records found in {args.info}')

    os.makedirs(args.outdir, exist_ok=True)
    now = int(datetime.datetime.now(datetime.timezone.utc).timestamp())
    write_coverage_xml(files, os.path.join(args.outdir, 'Coverage.xml'), args.strip_prefix, now)
    if args.log:
        write_coveragelog_xml(files, os.path.join(args.outdir, 'CoverageLog.xml'), args.strip_prefix, now)
    tested = sum(file_stats(r)[0] for r in files)
    loc = sum(sum(file_stats(r)) for r in files)
    print(f'CCWS: {len(files)} files, {tested}/{loc} lines covered -> {args.outdir}')


if __name__ == '__main__':
    main()
