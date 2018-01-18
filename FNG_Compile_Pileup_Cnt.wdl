workflow FNG_Compile_Pileup_Cnt {
	String sample_id
    File bam_file
    File bai_file
    File fluidgm_snp_path

    call compile_pileup_cnt {
        input:
        sample_id=sample_id,
        bam_file=bam_file,
        bai_file=bai_file,
        fluidgm_snp_path=fluidgm_snp_path
    }
}

task compile_pileup_cnt {
    String sample_id
    File bam_file
    File bai_file
    File fluidgm_snp_path

    command <<<
        cat /TSCA/docker_v
        Rscript /TSCA/compile_pileup_freq.R \
            --sample_id ${sample_id} \
            --bam_path ${bam_file} \
            --fluidgm_snp_path ${fluidgm_snp_path}

    >>>

    output {
        File pileup_pct_count = "${sample_id}_fng.pileup_pct_count.txt"
    }
    
    runtime {
        docker: "mcadosch/tsca:latest"
        memory: "4 GB"
        cpu: "1"
        disks: "local-disk 10 HDD"
        preemptible_attempts: "2"
    }
}
