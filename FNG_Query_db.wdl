workflow FNG_Query_db {
    Array[String] sample_ids
    Array[String] external_ids
    String tsca_id
    File fingerprinting_db
    File fluidgm_snp_path

    call query_fng_db {
        input:
        sample_ids=sample_ids,
        external_ids=external_ids,
        tsca_id=tsca_id,
        fingerprinting_db=fingerprinting_db,
        fluidgm_snp_path=fluidgm_snp_path
    }
}

task query_fng_db {
    Array[String] sample_ids
    Array[String] external_ids
    String tsca_id
    File fingerprinting_db
    File fluidgm_snp_path

    command <<<
        cat /TSCA/docker_v
        Rscript /TSCA/query_fng_db.R \
            --sample_ids ${sep=" " sample_ids} \
            --external_ids ${sep=" " external_ids} \
            --tsca_id ${tsca_id} \
            --fingerprinting_db ${fingerprinting_db} \
            --fluidgm_snp_path ${fluidgm_snp_path}

        ls *
        ls /TSCA/*
    >>>

    output {
        File res_fingerprinting      = "${tsca_id}.res_fp.txt"
        File fng_diffs_matching      = "${tsca_id}.res_fp_mstLikelyMatches_summary.final.txt"
        File fng_indivs_not_matching = "${tsca_id}.failedSamples.NotMatchingIndivs.txt"
    }
    
    runtime {
        docker: "mcadosch/tsca:latest"
        memory: "4 GB"
        cpu: "1"
        disks: "local-disk 10 HDD"
        preemptible_attempts: "2"
    }
}
