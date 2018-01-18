workflow CalculateTargetCoverageWF {
	String sample_id
  File gatk
  File input_bam
  File interval_list
  Int padding
    
	call CalculateTargetCoverage {
    	input: 
        	sample_id=sample_id,
            gatk=gatk,
            input_bam=input_bam,
            interval_list=interval_list,
            padding=padding
    }
}

task CalculateTargetCoverage {
	String sample_id
  File gatk
  File input_bam
  File interval_list
  Int padding

  command <<<

    java -jar ${gatk} PadTargets \
       --targets ${interval_list} \
       --padding ${padding} \
       --output targets.padded.${padding}.tsv
       
  	java -jar ${gatk} CalculateTargetCoverage \
          -I ${input_bam} \
          -T targets.padded.${padding}.tsv \
          -transform PCOV \
          -groupBy SAMPLE \
          -targetInfo FULL \
          -O ${sample_id}.target_coverage.txt
  >>>
    
    output {
		File target_coverage = "${sample_id}.target_coverage.txt"
	}
    
    runtime {
    	docker: "broadinstitute/genomes-in-the-cloud:2.3-1498756809"
      memory: "10 GB" 
      cpu: "1"
      disks: "local-disk 10 HDD"
      preemptible_attempts: "2"
    }
}