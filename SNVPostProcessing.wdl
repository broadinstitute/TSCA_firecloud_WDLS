workflow SNVPostProcessing {
    String tsca_id
    Array[File] tumor_variant_files
    Array[String] external_ids
    Array[String] sample_ids
    Array[String] pair_types
    
    call aggregateSNVs {
        input: 
            tsca_id=tsca_id,
            tumor_variant_files=tumor_variant_files,
            external_ids=external_ids,
            sample_ids=sample_ids,
            pair_types=pair_types
    }

    output {
        File aggregate_snvs = aggregateSNVs.aggregate_snvs
    }
}

task aggregateSNVs {
    String tsca_id
    Array[File] tumor_variant_files
    Array[String] external_ids
    Array[String] sample_ids
    Array[String] pair_types
    
    command <<<
        cat /TSCA/docker_v
        python /TSCA/aggregate_snvs.py  --tsca_id ${tsca_id} \
                                        --tumor_variant_files ${sep=" " tumor_variant_files} \
                                        --external_ids ${sep=" " external_ids} \
                                        --sample_ids ${sep=" " sample_ids} \
                                        --pair_types ${sep=" " pair_types}
    >>>
    
    output {
        File aggregate_snvs  = "${tsca_id}.aggregate_somatic_SNVs.txt"
    }
    
    runtime {
        docker: "mcadosch/tsca:latest"
        memory: "4 GB"
        cpu: "1"
        disks: "local-disk 10 HDD"
    }

}
