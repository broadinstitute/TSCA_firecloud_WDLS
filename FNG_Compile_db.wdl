workflow FNG_Compile_db {
    Array[String] sample_ids
    Array[String] tsca_ids
    Array[File] pileup_pct_count_files

    call compile_db {
        input:
        sample_ids=sample_ids,
        pileup_pct_count_files=pileup_pct_count_files,
        tsca_ids=tsca_ids
    }
}

task compile_db {
    Array[String] sample_ids
    Array[String] tsca_ids
    Array[File] pileup_pct_count_files
    
    command <<<
        cat /TSCA/docker_v

        Rscript /TSCA/compile_fingerprinting_db.R \
            --pileup_pct_count_paths ${sep=" " pileup_pct_count_files}  \
            --samples_tsca_ids ${sep=" " tsca_ids}

    >>>

    output {
        File fingerprinting_db = "fingerprinting_db.txt"
    }
    
    runtime {
        docker: "mcadosch/tsca:latest"
        memory: "8 GB"
        cpu: "1"
        disks: "local-disk 20 HDD"
        preemptible_attempts: "2"
    }
}
