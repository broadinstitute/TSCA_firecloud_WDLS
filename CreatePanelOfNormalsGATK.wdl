workflow CreatePanelOfNormals {
    String PoN_name
    File gatk_jar
    Array[File] target_coverage_files
    
    call createPanelOfNormals {
        input: 
            PoN_name=PoN_name,
            gatk_jar=gatk_jar,
            target_coverage_files=target_coverage_files
    }

    output {
        File combined_normals = createPanelOfNormals.combined_normals
        File normals_pon = createPanelOfNormals.normals_pon
    }
}

task createPanelOfNormals {
    String PoN_name
    File gatk_jar
    Array[File] target_coverage_files
    
    command <<<
        java -jar ${gatk_jar} CombineReadCounts \
            -I ${sep=" -I " target_coverage_files}  \
            -O ${PoN_name}.combined_normals.txt
                    
        java -jar ${gatk_jar} CreatePanelOfNormals \
            -I ${PoN_name}.combined_normals.txt \
            -O ${PoN_name}.normals.pon \
            --disableSpark \
            --outputFailedSamples ${PoN_name}.failed_samples.txt \
            --extremeColumnMedianCountPercentileThreshold 2.5 \
            --minimumTargetFactorPercentileThreshold 25.0
    >>>
    
    output {
        File combined_normals = "${PoN_name}.combined_normals.txt"
        File normals_pon = "${PoN_name}.normals.pon"
        File failed_samples = "${PoN_name}.failed_samples.txt"
    }
    
    runtime {
        docker: "broadinstitute/gatk3:3.7-0"
        memory: "10 GB"
        cpu: "1"
        disks: "local-disk 10 HDD"
    }
}