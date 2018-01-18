workflow CreatePanelOfNormals {
    String PoN_name
    File gatk_jar
    File reference_fasta
    File reference_fasta_fai
    File reference_fasta_dict
    File interval_list

    Array[File] normal_vcf_files
    
    call createPanelOfNormals {
        input: 
            PoN_name=PoN_name,
            gatk_jar=gatk_jar,
            normal_vcf_files=normal_vcf_files,
            reference_fasta=reference_fasta,
            reference_fasta_fai=reference_fasta_fai,
            reference_fasta_dict=reference_fasta_dict, 
            interval_list=interval_list

    }
}

task createPanelOfNormals {
    String PoN_name
    File gatk_jar
    File reference_fasta
    File reference_fasta_fai
    File reference_fasta_dict
    File interval_list
    Array[File] normal_vcf_files
    
    command <<<
        ### Create VCF File for Mutect2 Analysis   
        java -jar ${gatk_jar} \
            -T CombineVariants \
            -R ${reference_fasta} \
            -V ${sep=" -V " normal_vcf_files} \
            -minN 2 \
            --setKey "null" \
            --filteredAreUncalled \
            --filteredrecordsmergetype KEEP_IF_ANY_UNFILTERED \
            -L ${interval_list} \
            --genotypemergeoption UNIQUIFY \
            -o ${PoN_name}.MuTect2_PON.vcf
    >>>
    
    output {
        File normals_pon_vcf = "${PoN_name}.MuTect2_PON.vcf"
    }
    
    runtime {
        docker: "broadinstitute/gatk3:3.7-0"
        memory: "10 GB"
        cpu: "1"
        disks: "local-disk 10 HDD"
    }
}
