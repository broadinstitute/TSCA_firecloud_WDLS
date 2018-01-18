workflow PlotSomaticCNVMaps {
	String tsca_id
    String disk_size
	Array[File] tumor_tn_files
    Array[File] tumor_seg_files
    Array[File] tumor_seg_files_for_plotting
    Array[String] sample_ids
	Array[String] external_validations
    Array[String] depth_of_cov_qc_results
    
    call plotSomaticCNVMaps {
    	input: 
        	tsca_id=tsca_id,
            tumor_tn_files=tumor_tn_files,
            tumor_seg_files=tumor_seg_files,
            sample_ids=sample_ids,
            external_validations=external_validations,
            depth_of_cov_qc_results=depth_of_cov_qc_results,
            tumor_seg_files_for_plotting=tumor_seg_files_for_plotting,
            disk_size=disk_size
    }

    output {
        File cnv_calls_tn_img = plotSomaticCNVMaps.cnv_calls_tn_img
        File cnv_calls_tn_raw = plotSomaticCNVMaps.cnv_calls_tn_raw
    }
}


task plotSomaticCNVMaps {
	String tsca_id
    String disk_size
	Array[File] tumor_tn_files
    Array[File] tumor_seg_files
    Array[File] tumor_seg_files_for_plotting
    Array[String] sample_ids
	Array[String] external_validations
    Array[String] depth_of_cov_qc_results
    
    
	command <<<
    	cat /TSCA/docker_v

        #### Plot unsegmented CNV Calls
    	python /TSCA/plot_somatic_cnv_calls.py 	--tsca_id ${tsca_id} \
        										--tn_files ${sep=" " tumor_tn_files} \
                                                --external_ids ${sep=" " external_validations} \
                                                --sample_ids ${sep=" " sample_ids}
        
        #### Plot segmented CNV Calls
        python /TSCA/plot_segmented_cnv_calls_from_files.py \
            --complete_seg_files ${sep=" " tumor_seg_files_for_plotting} \
            --sample_ids ${sep=" " sample_ids} \
            --external_ids ${sep=" " external_validations} \
            --depth_of_cov_qcs ${sep=" " depth_of_cov_qc_results}
            --set_name ${tsca_id} \
            --out_dir .
    >>>
    
    output {
        File cnv_calls_tn_img  = "${tsca_id}.cnv_calls.png"
        File cnv_calls_tn_img_unsegmented = "${tsca_id}.cnv_calls_unsegmented.png"
		File cnv_calls_tn_raw  = "${tsca_id}.cnv_calls.txt"   
    }
    
    runtime {
        docker: "mcadosch/tsca:latest"
        memory: "${disk_size}"
        cpu: "1"
        disks: "local-disk 10 HDD"
    }
}
