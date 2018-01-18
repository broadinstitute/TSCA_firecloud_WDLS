workflow depthOfCoverageTest {
	File ref_fasta
	File gene_list
	File interval_list
	File ref_fasta_index
	File ref_fasta_dict
    
	call depthOfCov {
		input: refFasta=ref_fasta,
			geneList=gene_list,
			intervalList=interval_list,
			refFastaIndex=ref_fasta_index,
			refFastaDict=ref_fasta_dict
	}
}

task depthOfCov {
	File inputBam
	File inputBamIndex
	File geneList
	Int memory
	Int minBaseQuality
	Int minMappingQuality
	String sampleName
	File refFasta
	File intervalList
	File refFastaDict
	File refFastaIndex


	command <<<
		java -Xmx${memory}g -jar /usr/GenomeAnalysisTK.jar \
		-R ${refFasta} \
		-T DepthOfCoverage \
		-o ${sampleName} \
		-omitBaseOutput \
		-pt sample \
		-geneList ${geneList} \
		-I ${inputBam} \
		-L ${intervalList} \
		--minBaseQuality ${minBaseQuality} \
		--minMappingQuality ${minMappingQuality}
        
	>>>

	output {
		File sample_gene_summary = "${sampleName}.sample_gene_summary"
		File sample_summary = "${sampleName}.sample_summary"
		File sample_statistics = "${sampleName}.sample_statistics"
		File sample_interval_summary = "${sampleName}.sample_interval_summary"
		File sample_interval_statistics = "${sampleName}.sample_interval_statistics"
	}

	runtime {
		docker: "broadinstitute/gatk3:3.7-0"
		memory: "8 GB"
		cpu: "1"
		disks: "local-disk 20 HDD"	
	}
}
