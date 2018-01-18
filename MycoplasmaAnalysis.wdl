workflow MycoplasmaAnalysis {
    String sample_id
    String external_id
    File bam
    File bai

    call genderEstimate {
        input:
        sample_id=sample_id,
        external_id=external_id,
        depth_of_coverage_by_interval=depth_of_coverage_by_interval
    }
}

task genderEstimate {
    String sample_id
    String external_id
    File depth_of_coverage_by_interval
    
    command <<<
        cat /TSCA/docker_v

        python /TSCA/estimate_gender.py \
            --sample_id ${sample_id} \
            --external_id ${external_id} \
            --depth_of_cov_by_interval ${depth_of_coverage_by_interval}

        ls *
        ls /TSCA/*
    >>>

    output {
        File chromosome_coverage_dist = "${sample_id}.chromosome_cov_distribution.png"
        String gender_estimate = read_string("gender_estimate.txt")
    }
    
    runtime {
        docker: "mcadosch/tsca:latest"
        memory: "4 GB"
        cpu: "1"
        disks: "local-disk 20 HDD"
        preemptible_attempts: "2"
    }
}
