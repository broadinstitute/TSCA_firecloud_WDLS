workflow AggregateCoverageStats {
	String tsca_id
	String docker_image
    Array[String] sample_ids
    Array[File] sample_gene_summary_files
    Array[File] sample_interval_summary_files
    
	call aggregateCoverageStats {
    	input: 
            tsca_id=tsca_id,
            docker_image=docker_image,
            sample_ids=sample_ids,
            sample_gene_summary_files=sample_gene_summary_files,
            sample_interval_summary_files=sample_interval_summary_files
    }
}

task aggregateCoverageStats {
    String tsca_id
    String docker_image
    Array[String] sample_ids
    Array[File] sample_gene_summary_files
    Array[File] sample_interval_summary_files
	
    command <<<
		python /TSCA/aggregate_depth_of_cov_output.py	\
                    --statistic mean \
    				--interval gene \
                    --sample_ids ${sep=" " sample_ids} \
    				--files ${sep=" " sample_gene_summary_files} \
                    --tsca_id ${tsca_id}

        python /TSCA/aggregate_depth_of_cov_output.py   \
                    --statistic total \
                    --interval gene \
                    --sample_ids ${sep=" " sample_ids} \
                    --files ${sep=" " sample_gene_summary_files} \
                    --tsca_id ${tsca_id}

        python /TSCA/aggregate_depth_of_cov_output.py   \
                    --statistic mean \
                    --interval target \
                    --sample_ids ${sep=" " sample_ids} \
                    --files ${sep=" " sample_interval_summary_files} \
                    --tsca_id ${tsca_id}

        python /TSCA/aggregate_depth_of_cov_output.py   \
                    --statistic total \
                    --interval target \
                    --sample_ids ${sep=" " sample_ids} \
                    --files ${sep=" " sample_interval_summary_files} \
                    --tsca_id ${tsca_id}
    >>>
    
    output {
		File mean_DoC_all_samples_by_gene  = "${tsca_id}.depth_of_cov_by_gene.mean_cvg.txt"
        File total_DoC_all_samples_by_gene = "${tsca_id}.depth_of_cov_by_gene.total_cvg.txt"
        File mean_DoC_all_samples_by_target  = "${tsca_id}.depth_of_cov_by_target.mean_cvg.txt"
        File total_DoC_all_samples_by_target = "${tsca_id}.depth_of_cov_by_target.total_cvg.txt"
    }

	runtime {
		docker: "${docker_image}"
		memory: "4 GB"
		cpu: "1"
		disks: "local-disk 20 HDD"
		
	}
}