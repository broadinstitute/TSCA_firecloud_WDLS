workflow DepthOfCovQC {
	String sample_id
	String docker_image
    Int min_depth
    File gene_summary_file
    File interval_summary_file
    
	call depthOfCovQC {
    	input: sample_id=sample_id,
        	min_depth=min_depth,
            docker_image=docker_image,
            gene_summary_file=gene_summary_file,
            interval_summary_file=interval_summary_file
    }
}

task depthOfCovQC {
	String sample_id
    String docker_image
    Int min_depth
	File gene_summary_file
    File interval_summary_file
	
    command <<<
		python /TSCA/depth_of_coverage_qc.py	--gene_summary_file ${gene_summary_file} \
												--interval_summary_file ${interval_summary_file} \
												--min_depth ${min_depth}
    >>>
    
    output {
		String qc_result = read_string("depth_of_cov_result.txt")
        String mean_gene_cvg = read_string("mean_gene_cvg.txt")
        String mean_interval_cvg = read_string("mean_interval_cvg.txt")
    }
	runtime {
		docker: "${docker_image}"
		memory: "4 GB"
		cpu: "1"
		disks: "local-disk 20 HDD"
		
	}
}