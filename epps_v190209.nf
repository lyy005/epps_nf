#!/usr/bin/env nextflow


params.reads = "$PWD/input/*{1,2}.fastq"

Channel
	.fromFilePairs( params.reads )
	.ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
	.set { read_pairs }

// trimmomatic

process filter {

	publishDir 'output', mode: 'copy', overwrite: true

	input:
	set dataset_id, file(forward) from read_pairs

	output:
	set dataset_id, file("${dataset_id}.pe.1.fq"), file("${dataset_id}.pe.2.fq") into (timmomatic_read_pairs)

	script:
	"""
	java -jar $PWD/bin/Trimmomatic-0.38/trimmomatic-0.38.jar PE -phred33 $forward ${dataset_id}.pe.1.fq ${dataset_id}.se.1.fq ${dataset_id}.pe.2.fq ${dataset_id}.se.2.fq ILLUMINACLIP:${PWD}/bin/Trimmomatic-0.38/adapters/combined.Illumina.fasta:3:30:6:1:TRUE SLIDINGWINDOW:10:20 MINLEN:50 2> trim.log
	"""
// or change combined.Illumina.fasta to any specific adapter list

}

// demultiplex

process demultiplex {
	publishDir 'output', mode: 'copy', overwrite: true
	
	input:
	set dataset_id, file(forward), file(reverse) from timmomatic_read_pairs

	output:
	// set dataset_id, file("*.F.fq"), file("*.R.fq") into (demul_read_pairs)
	set dataset_id, file("${dataset_id}.demul.F.fq"), file ("${dataset_id}.demul.R.fq") into (demul_read_pairs)
	
	"""
	perl $PWD/bin/Demultiplex_primer_v1.4_lite.pl ${forward} ${reverse} $PWD/input/primer.fas ${dataset_id}.demul.F.fq ${dataset_id}.demul.R.fq ${dataset_id}.report
	"""
}

// Merging forward and reverse reads with usearch
process merge {
	publishDir './output/', mode: 'copy', overwrite: true

	input:
	//val demul_id from demul_read_pairs_simple2
	set dataset_id, file(demul_F), file(demul_R) from demul_read_pairs

	output: 
	//set dataset_id, file("${dataset_id}.merged.rename.fasta") into merged_reads
	file("${dataset_id}.merged.rename.fasta") into merged_reads
	set dataset_id, file("${dataset_id}.merged.rename.fasta") into merged_reads2

	"""
	# USEARCH
	$PWD/bin/usearch -fastq_mergepairs ${demul_F} -reverse ${demul_R} -fastqout ${dataset_id}.merged.fastq
	$PWD/bin/usearch -fastq_filter ${dataset_id}.merged.fastq -fastq_maxee 0.5 -fastaout ${dataset_id}.merged.fasta -fastq_maxns 1
	# VSEARCH
	# $PWD/bin/vsearch-2.10.4-macos-x86_64/bin/vsearch --fastq_mergepairs ${demul_F} --reverse ${demul_R} --fastqout ${dataset_id}.merged.fastq
	# $PWD/bin/vsearch-2.10.4-macos-x86_64/bin/vsearch --fastq_filter ${dataset_id}.merged.fastq --fastq_maxee 0.5 --fastaout ${dataset_id}.merged.fasta --fastq_maxns 1
	perl $PWD/bin/rename_4.0_two_parameters.pl ${dataset_id}.merged.fasta ${dataset_id}.merged.rename.fasta
	"""
}

// Clustering with usearch
process otu_clustering {
	publishDir './output/step1_otu_clustering/', mode: 'copy', overwrite: true
	
	input:
	file('*.merged.rename.fasta') from merged_reads.toList()
	
	output:
	file("otus.fasta") into otu_reads
	file("otus.up") into otu_reads_up

	"""
	cat *.merged.rename.fasta > combined.fasta
	perl $PWD/bin/unique.pl combined.fasta combined.unique.fasta
	# USEARCH
	$PWD/bin/usearch -sortbysize combined.unique.fasta -fastaout combined.unique.sorted.fasta -minsize 2
	$PWD/bin/usearch -cluster_otus combined.unique.sorted.fasta -otus otus.fasta -uparseout otus.up -relabel otu -minsize 2

	# VSEARCH
	# $PWD/bin/vsearch-2.10.4-macos-x86_64/bin/vsearch --sortbysize combined.unique.fasta --output combined.unique.sorted.fasta --minsize 2
	# $PWD/bin/vsearch-2.10.4-macos-x86_64/bin/vsearch --uchime_denovo combined.unique.sorted.fasta --nonchimeras combined.unique.sorted.fasta.nonchim --fasta_width 0
	# $PWD/bin/vsearch-2.10.4-macos-x86_64/bin/vsearch --cluster_size combined.unique.sorted.fasta.nonchim --id 0.97 --strand plus --centroids otus.fasta --uc otus.up --relabel otu --minsize 2
	"""
}

// mapping reads to OTUs using usearch
process map {
	publishDir './output/step2_mapping/', mode: 'copy', overwrite: true

	input:
	set dataset_id, file(merged_reads_map) from merged_reads2
	file(otu) from otu_reads

	output:
	file("${dataset_id}.uc") into uc_files

	"""
	# USEARCH
	$PWD/bin/usearch -usearch_global ${merged_reads_map} -db $otu -id 0.97 -uc ${dataset_id}.uc -strand plus
	# VSEARCH
	# $PWD/bin/vsearch-2.10.4-macos-x86_64/bin/vsearch --usearch_global ${merged_reads_map} --db $otu --id 0.97 --uc ${dataset_id}.uc --strand plus
	"""
}

// plot with R
process plot {
	publishDir './output/step3_profiling_table/', mode: 'copy', overwrite: true

	input:
	file('*.uc') from uc_files.toList()
	
	output:
	file("combined.uc.table") into profiling_table
	file("plot.pdf") into plots

	"""
	cat *.uc > combined.uc
	perl $PWD/bin/profiling.pl combined.uc combined.uc.table
	Rscript --vanilla $PWD/bin/PCA.r combined.uc.table plot.pdf
	"""
}


/*
// rename channel again
merged_reads2 = merged_reads
	.collect()
	.flatMap {it.simpleName}

process quality_control {
	publishDir './output/', mode: 'copy', overwrite: true
	
	input:
	set demul_id, file(merged) from merged_reads

	output:
	set demul_id, file("${demul_id}.merged.fasta") into qc_merged_reads

	"""
	usearch -fastq_filter ${demul_id}.merged.fastq -fastq_maxee 0.5 -fastaout ${demul_id}.merged.fasta -fastq_maxns 1
	"""
}

process rename {
	publishDir './output/', mode: 'copy', overwrite: true
	
	input:
	set demul_id, file(qual) from qc_merged_reads

	output:
	file("${demul_id}.rename.fasta") into renamed_merged

	"""
	perl /Users/yy/Work/local/bin/eDNA_pipeline/eDNA_pipeline_nextflow/eDNA_test/rename_4.0_two_parameters.pl $qual ${demul_id}.rename.fasta
	"""
}
*/
