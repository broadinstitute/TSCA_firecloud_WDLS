workflow CallSomaticCNV {
	File gatk_jar
	File reference_fasta_dict
	File tumor_coverage
	File normals_pon
	String sample_id
	String external_id
    String docker_image

	call callSomaticCNV {
		input: 
			gatk_jar=gatk_jar,
			tumor_coverage=tumor_coverage,
			normals_pon=normals_pon,
			sample_id=sample_id,
            docker_image=docker_image,
            ref_fasta_dict=reference_fasta_dict
	}

	call createSegmentedFileForPlotting {
		input:
			tumor_tn_file=callSomaticCNV.tumor_tn,
			tumor_seg_file=callSomaticCNV.tumor_seg,
			sample_id=sample_id,
			external_id=external_id
	}
}

task callSomaticCNV {
	File gatk_jar
	File tumor_coverage
	File normals_pon
	String sample_id
    String docker_image
    File ref_fasta_dict

	command <<<
		java -jar 	${gatk_jar} NormalizeSomaticReadCounts \
    		-I 		${tumor_coverage} \
    		-PON	${normals_pon} \
    		-PTN 	${sample_id}.tumor.ptn.tsv \
    		-TN 	${sample_id}.tumor.tn.tsv

    	java -jar 	${gatk_jar} PerformSegmentation \
    		-TN 	${sample_id}.tumor.tn.tsv \
    		-O  	${sample_id}.tumor.seg \
    		-LOG

    	java -jar 	${gatk_jar} CallSegments \
    		-TN 	${sample_id}.tumor.tn.tsv \
    		-S 		${sample_id}.tumor.seg \
    		-O 		${sample_id}.tumor.called
            
        java -jar 	${gatk_jar} PlotSegmentedCopyRatio \
			-TN ${sample_id}.tumor.tn.tsv \
			-PTN ${sample_id}.tumor.ptn.tsv \
			-S ${sample_id}.tumor.seg \
			-SD ${ref_fasta_dict} \
			-O . \
			-pre ${sample_id} \
			-LOG

        touch normals_pon_used.txt
        echo ${normals_pon} >> normals_pon_used.txt
	>>>

	output {
    	File tumor_tn  = "${sample_id}.tumor.tn.tsv"
        File tumor_ptn = "${sample_id}.tumor.ptn.tsv"
        File tumor_seg = "${sample_id}.tumor.seg"
		File cnv_calls = "${sample_id}.tumor.called"
		File segmented_copy_ratio_img = "${sample_id}_FullGenome.png"
	}

	runtime {
		docker: "${docker_image}"
		memory: "8 GB"
		cpu: "1"
		disks: "local-disk 10 HDD"
		preemptible_attempts: "3"
	}
}

#### Create segmented CNV files for plotting
task createSegmentedFileForPlotting {
    File tumor_tn_file
    File tumor_seg_file
    String sample_id
    String external_id

    command <<<
        python /TSCA/create_segmented_file.py \
        --tn_file ${tumor_tn_file} \
        --seg_file ${tumor_seg_file} \
        --sample_id ${sample_id} \
        --external_id ${external_id}  \
        --out_dir .

    >>>

    output {
        File tumor_seg_for_plotting = "${sample_id}_complete_seg.txt"
    }

    runtime {
        docker: "mcadosch/tsca:latest"
        memory: "2 GB"
        cpu: "1"
        disks: "local-disk 10 HDD"
    }
}
