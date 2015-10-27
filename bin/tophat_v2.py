# use python 2.7

import sys
import os
import os.path
import argparse
import subprocess
import re

DEFAULT_BIN_DIR = '/usr/local/bin'

def main():
	cmd = []

	# get command line arguments/options
	parser = argparse.ArgumentParser(description='run tophat')
	parser.add_argument('--seq1file', '--r1', required=True)
	parser.add_argument('--seq2file', '--r2')
	parser.add_argument('--bowtie_index_dir', '--bi', required=True)
	parser.add_argument('--prefix', '--p', required=True)
	parser.add_argument('--outdir', '--o', default=os.getcwd())
	parser.add_argument('--tophat_bin_dir', '--tb', default=DEFAULT_BIN_DIR)
	parser.add_argument('--bowtie_bin_dir', '--bb', default=DEFAULT_BIN_DIR)
	parser.add_argument('--samtools_bin_dir', '--sb', default=DEFAULT_BIN_DIR)
	parser.add_argument('--mate-inner-dist')
	parser.add_argument('--mate-std-dev')
	parser.add_argument('--min-anchor-length')
	parser.add_argument('--splice-mismatches')
	parser.add_argument('--min-intron-length')
	parser.add_argument('--max-intron-length')
	parser.add_argument('--max-insertion-length')
	parser.add_argument('--max-deletion-length')
	parser.add_argument('--num-threads')
	parser.add_argument('--max-multihits')
	parser.add_argument('--library-type')
	parser.add_argument('--bowtie_mode')
	parser.add_argument('--initial-read-mismatches')
	parser.add_argument('--segment-mismatches')
	parser.add_argument('--segment-length')
	parser.add_argument('--read-gap-length')
	parser.add_argument('--read-edit-dist')
	parser.add_argument('--min-coverage-intron')
	parser.add_argument('--max-coverage-intron')
	parser.add_argument('--min-segment-intron')
	parser.add_argument('--max-segment-intron')
	parser.add_argument('--raw-juncs')
	parser.add_argument('--GTF')
	parser.add_argument('--transcriptome-index')
	parser.add_argument('--insertions')
	parser.add_argument('--deletions')
	parser.add_argument('--args', '--a')
	parser.add_argument('--verbose', '--v')

	args = parser.parse_args()

	# if [--verbose] is defined then [--verbose] = True
	if (args.verbose != None):
		args.verbose = True

	if args.verbose == True:
		print "Processing " + args.seq1file + "..."
		if args.seq2file != None:
			print "Processing " + args.seq2file + "..."

	# if [--outdir] != currentWorkingDir then make new dir
	if (args.outdir != os.getcwd()) and (os.path.isdir(args.outdir) == False):
		try:
			print "Making output directory: '" + args.outdir + "' ..."
			proc = subprocess.Popen(['mkdir', args.outdir], stdout=subprocess.PIPE)
		except:
			print "ERROR failed making output directory"
			sys.exit(1)

	if args.verbose == True:
		print "Execute tophat..."

	cmd = [args.tophat_bin_dir + '/tophat', '--output-dir', args.outdir]

	# skip these options
	for arg in vars(args):
		if (arg == "seq1file") or (arg == "seq2file") or (arg == "bowtie_index_dir") or (arg == "prefix") or (arg == "outdir") or (arg == "tophat_bin_dir") or (arg == "bowtie_bin_dir") or (arg == "samtools_bin_dir") or (arg == "library_type") or (arg == "bowtie_mode") or (arg == "args") or (arg == "GTF") or (arg == "transcriptome_index") or (arg == "verbose") or (arg == "debug") or (arg == "help") or (arg == "man"):
			pass
		elif (vars(args)[arg] != None) and (vars(args)[arg] != ''):
			cmd.append("--" + arg.replace('_', '-'))
			cmd.append(vars(args)[arg])

	if (args.library_type != None) and (args.library_type != ''):
		cmd.append("--library-type")
		cmd.append(args.library_type)
	if (args.bowtie_mode != None) and (args.bowtie_mode != ''):
		cmd.append("--bowtie-n")
	if (args.GTF != None) and (args.GTF != ''):
		cmd.append("--GTF")
		cmd.append(args.GTF)
		if (args.transcriptome_index != None) and (args.transcriptome_index != ''):
			cmd.append("--transcriptome-index")
			cmd.append(args.transcriptome_index)
	if (args.args != None) and (args.args != ''):
		cmd.append(args.args)
	cmd.append(args.bowtie_index_dir + "/" + args.prefix)
	cmd.append(args.seq1file)
	if (args.seq2file != None) and (args.seq2file != ''):
		cmd.append(args.seq2file)

	if (cmd == None) or (len(cmd) == 0):
		print "ERROR bad command"
		sys.exit(1)

	try:
		proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
		exitcode = proc.wait()
	except:
		print "ERROR something went wrong when executing command"
		sys.exit(1)

	# verbose??
	if exitcode == 0:
		print "Executed successfully..."
	else:
		print "ALERT Command executed with errors. Error code: " + str(exitcode)
		sys.exit(1)

	# setup a prefix for files
	fileprefix = os.path.split(args.seq1file)[-1]
	fileprefix = re.sub(r".1_1_sequence.*", '', fileprefix)
	fileprefix = re.sub(r".sequence.*", '', fileprefix)
	fileprefix = re.sub(r".fastq.*", '', fileprefix)
	fileprefix = re.sub(r".fq.*", '', fileprefix)

	# renames files (might need error checking for outdir)
	if (os.path.isfile(args.outdir + "/accepted_hits.bam") == True):
		proc = subprocess.Popen(['mv', args.outdir + "/accepted_hits.bam", args.outdir + "/" + fileprefix + ".accepted_hits.bam"], stdout=subprocess.PIPE)
	if (os.path.isfile(args.outdir + "/accepted_hits.sam") == True):
		proc = subprocess.Popen(['mv', args.outdir + "/accepted_hits.sam", args.outdir + "/" + fileprefix + ".accepted_hits.sam"], stdout=subprocess.PIPE)
	if (os.path.isfile(args.outdir + "/deletions.bed") == True):
		proc = subprocess.Popen(['mv', args.outdir + "/deletions.bed", args.outdir + "/" + fileprefix + ".deletions.bed"], stdout=subprocess.PIPE)
	if (os.path.isfile(args.outdir + "/insertions.bed") == True):
		proc = subprocess.Popen(['mv', args.outdir + "/insertions.bed", args.outdir + "/" + fileprefix + ".insertions.bed"], stdout=subprocess.PIPE)
	if (os.path.isfile(args.outdir + "/junctions.bed") == True):
		proc = subprocess.Popen(['mv', args.outdir + "/junctions.bed", args.outdir + "/" + fileprefix + ".junctions.bed"], stdout=subprocess.PIPE)
	if (os.path.isfile(args.outdir + "/unmapped_left.fq.z") == True):
		proc = subprocess.Popen(['mv', args.outdir + "/unmapped_left.fq.z", args.outdir + "/" + fileprefix + ".unmapped_left.fq.z"], stdout=subprocess.PIPE)
	if (os.path.isfile(args.outdir + "/unmapped_right.fq.z") == True):
		proc = subprocess.Popen(['mv', args.outdir + "/unmapped_right.fq.z", args.outdir + "/" + fileprefix + ".unmapped_right.fq.z"], stdout=subprocess.PIPE)

	if args.verbose == True:
		print "DONE\n"

	#print cmd	

main()
